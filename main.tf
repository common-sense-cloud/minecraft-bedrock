provider "google" {
  project     = var.project_id
  credentials = file("~/.config/gcloud/tf-sa-creds.json")
  region      = var.region
  zone        = var.zone
}

data "archive_file" "gcfzip" {
  type        = "zip"
  output_path = "add-user.zip"
  source_dir  = "${path.module}/functions/add-user/"
}

resource "google_compute_resource_policy" "stop-start-schedule" {
  name   = "stopschedule"
  region = var.region

  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 16 * * *"
    }
    vm_stop_schedule {
      schedule = "0 0 * * *"
    }
    time_zone = "US/Mountain"
  }
}

resource "google_compute_instance_iam_binding" "schedule_binding" {
  project       = var.project_id
  zone          = var.zone
  instance_name = "mc-server-v1"

  role = "roles/compute.instanceAdmin"
  members = [
    "serviceAccount:${var.client_email}"
  ]
}

module "mc-server" {
  source          = "./modules/gce-container"
  zone            = var.zone
  project_id      = var.project_id
  image           = "itzg/minecraft-bedrock-server"
  privileged_mode = true
  activate_tty    = true
  port            = 19132

  resource_policy = [google_compute_resource_policy.stop-start-schedule.id]

  env_variables = {
    EULA : "TRUE"
    OPS : "autonomaus"
    GAMEMODE : "survival"
    DIFFICULTY : "normal"
  }

  instance_name      = "mc-server-v1"
  network_name       = "default"
  subnetwork         = "default"
  subnetwork_project = "terraform-basics-12"

  depends_on = [google_compute_instance_iam_binding.schedule_binding]
}

module "start-function" {
  source               = "./modules/cloud-function"
  bucket-name          = "${var.project_id}-functions"
  object-name          = "start-server.zip"
  function-path        = "./functions/start-server/start-server.zip"
  function-name        = "strt-server"
  function-description = "javascript function that starts minecraft server"
  entry-point          = "startInstance"

}

module "stop-function" {
  source               = "./modules/cloud-function"
  bucket-name          = "${var.project_id}-functions"
  object-name          = "stop-server.zip"
  function-path        = "./functions/stop-server/stop-server.zip"
  function-name        = "stop-server"
  function-description = "javascript function that stops minecraft server"
  entry-point          = "stopInstance"
}

module "add-function" {
  source               = "./modules/cloud-function"
  bucket-name          = "${var.project_id}-functions"
  object-name          = "add-user.zip"
  function-path        = data.archive_file.gcfzip.output_path
  function-name        = "add-user"
  function-description = "python function that adds a user to minecraft server"
  entry-point          = "insert_fwRule"
  runtime              = "python39"
}