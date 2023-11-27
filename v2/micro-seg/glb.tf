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


# backend service with custom request and response headers
resource "google_compute_backend_service" "belb_pplapp_presentation" {
  name          = "belb-pplapp-presentation"
  project       = google_project.micro_seg_project.project_id
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 10
  enable_cdn    = false
  health_checks = [google_compute_health_check.default.id]


  # Adding backend for base region
  backend {
    group           = google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0

  }

  # Adding backend for region-a
  backend {
    group           = google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 0.5
  }
  security_policy = google_compute_security_policy.armor_microseg.self_link

  depends_on = [
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_security_policy.armor_microseg,
  ]
}


# URL map for the external load balancer
resource "google_compute_url_map" "glb_pplapp_presentation_urlmap" {
  name            = "glb-pplapp-presentation"
  default_service = google_compute_backend_service.belb_pplapp_presentation.id
  project         = google_project.micro_seg_project.project_id
  depends_on = [
    google_compute_backend_service.belb_pplapp_presentation,
  ]
}


# Proxy for the external load balancer
resource "google_compute_target_http_proxy" "glb_pplapp_presentation_proxy" {
  name     = "glb-pplapp-presentation-proxy"
  provider = google-beta
  url_map  = google_compute_url_map.glb_pplapp_presentation_urlmap.id
  project  = google_project.micro_seg_project.project_id
  depends_on = [
    google_compute_url_map.glb_pplapp_presentation_urlmap,
  ]
}



# Reserved IP address for the external load balancer
resource "google_compute_global_address" "glb_pplapp_presentation_address" {
  name         = "glb-pplapp-presentation-address"
  project      = google_project.micro_seg_project.project_id
  address_type = "EXTERNAL"
  depends_on = [
    google_compute_url_map.glb_pplapp_presentation_urlmap,
  ]
}


# Forwarding rule for the external load balancer
resource "google_compute_global_forwarding_rule" "glb_pplapp_presentation_rule" {
  name                  = "glb-pplapp-presentation-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.glb_pplapp_presentation_proxy.id
  ip_address            = google_compute_global_address.glb_pplapp_presentation_address.id
  project               = google_project.micro_seg_project.project_id
  depends_on = [
    google_compute_global_address.glb_pplapp_presentation_address,
    google_compute_target_http_proxy.glb_pplapp_presentation_proxy,

  ]
}
