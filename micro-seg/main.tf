##  Copyright 2023 Google LLC
##  
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##  
##      https://www.apache.org/licenses/LICENSE-2.0
##  
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.


##  This code creates demo environment for CSA Network Firewall microsegmentation  ##
##  This demo code is not built for production workload ##



resource "random_id" "random_suffix" {
  byte_length = 4
}



# Create Folder in GCP Organization
resource "google_folder" "micro_seg_folder" {
  display_name = var.microseg_folder_name
  parent       = "organizations/${var.organization_id}"
}


# Create the project
resource "google_project" "micro_seg_project" {
  billing_account = var.billing_account
  #org_id          = var.organization_id    # Only one of `org_id` or `folder_id` may be specified
  folder_id   = google_folder.micro_seg_folder.name # Only one of `org_id` or `folder_id` may be specified
  name        = var.microseg_project_name
  project_id  = "${var.microseg_project_name}-${random_id.random_suffix.hex}"
  skip_delete = var.skip_delete
}


# Enable the necessary API services
resource "google_project_service" "armor_api_service" {
  for_each = toset([
    "servicenetworking.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "dns.googleapis.com",
    "secretmanager.googleapis.com",
    "networksecurity.googleapis.com",
  ])

  service                    = each.key
  project                    = google_project.micro_seg_project.project_id
  disable_on_destroy         = false
  disable_dependent_services = true

}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service_api" {
  depends_on       = [google_project_service.armor_api_service]
  create_duration  = "45s"
  destroy_duration = "45s"
}



# health check
resource "google_compute_health_check" "default" {
  project = google_project.micro_seg_project.project_id

  name                = "health-check"
  provider            = google-beta
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = "80"
  }

  log_config {
    enable = true
  }

  depends_on = [
    time_sleep.wait_enable_service_api,
  ]

}



