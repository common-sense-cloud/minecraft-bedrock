provider "google" {
  project     = var.project_id
  credentials = file("~/.config/gcloud/tf-sa-creds.json")
  region      = var.region
  zone        = var.zone
}


module "mc-server" {
  source          = "./modules/gce-container"
  zone            = var.zone
  project_id      = var.project_id
  image           = "itzg/minecraft-bedrock-server"
  privileged_mode = true
  activate_tty    = true
  port            = 19132

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
  function-path        = "./functions/add-user/add-user.zip"
  function-name        = "add-user"
  function-description = "javascript function that adds a user to minecraft server"
  entry-point          = "makeFWRule"
}