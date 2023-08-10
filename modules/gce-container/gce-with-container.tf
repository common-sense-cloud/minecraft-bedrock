
locals {
  # https://www.terraform.io/docs/language/values/locals.html
  instance_name = format("%s-%s", var.instance_name, substr(md5(module.gce-container.container.image), 0, 8))

  env_variables = [for var_name, var_value in var.env_variables : {
    name  = var_name
    value = var_value
  }]
}

module "gce-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image   = var.image
    command = var.custom_command
    port : var.port

    env = local.env_variables
    securityContext = {
      privileged : var.privileged_mode
    }
    tty : var.activate_tty


    volumeMounts = [
      {
        mountPath = "/data"
        name      = "mcdata"
        readOnly  = false
      },
    ]
  }

  volumes = [
    {
      name = "mcdata"

      emptyDir = {
        medium = "Memory"
      }
    },
  ]


  restart_policy = "Always"
}

resource "google_compute_instance" "vm" {
  project      = var.project_id
  name         = "mc-server-v1"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }

  network_interface {
    subnetwork_project = var.subnetwork_project
    subnetwork         = var.subnetwork
    access_config {}
  }

  resource_policies = var.resource_policy


  tags = ["minecraft-server"]

  metadata = {
    gce-container-declaration = module.gce-container.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  labels = {
    container-vm = module.gce-container.vm_container_label
  }

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

}