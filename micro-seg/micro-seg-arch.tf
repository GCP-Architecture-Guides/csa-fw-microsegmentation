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

/*
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
  ])

  service                    = each.key
  project                    = var.microseg_project_id
  disable_on_destroy         = true
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
  project = var.microseg_project_id

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


*/
