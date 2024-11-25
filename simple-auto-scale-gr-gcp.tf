provider "google" {
  project = "cool-agility-442507-c5"
  region  = "us-central1"
}

resource "google_compute_instance_template" "app_template" {
  name         = "instance-template"
  machine_type = "e2-micro"

  disk {
    auto_delete  = true
    boot         = true
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
  }

  network_interface {
    network       = "default"
    access_config {}
  }

  metadata_startup_script = <<EOT
#!/bin/bash
sudo apt update
sudo apt install -y apache2
sudo systemctl start apache2
EOT
}

resource "google_compute_health_check" "app_health_check" {
  name               = "app-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  http_health_check {
    port = 80
  }
}

resource "google_compute_region_instance_group_manager" "sample_instance_group_manager" {
  name               = "app-instance-group"
  base_instance_name = "app-instance"
  region             = "us-central1"

  version {
    instance_template = google_compute_instance_template.app_template.self_link
  }

  auto_healing_policies {
    health_check     = google_compute_health_check.app_health_check.self_link
    initial_delay_sec = 60
  }
}

resource "google_compute_region_autoscaler" "app_autoscaler" {
  name   = "app-autoscaler"
  target = google_compute_region_instance_group_manager.sample_instance_group_manager.id

  autoscaling_policy {
    max_replicas = 3
    min_replicas = 1

    cpu_utilization {
      target = 0.5
    }
  }
}

output "instance_group_manager" {
  value       = google_compute_region_instance_group_manager.sample_instance_group_manager.name
  description = "Instance group name"
}
