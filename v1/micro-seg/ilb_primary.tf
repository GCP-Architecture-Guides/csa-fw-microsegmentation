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
resource "google_compute_region_backend_service" "pri_ilb_pplapp_middleware" {
  name    = "ilb-pplapp-middleware-${var.primary_network_region}"
  project = var.microseg_project_id
  region  = var.primary_network_region
  #  provider  = google-beta
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 10
  enable_cdn            = false
  health_checks         = [google_compute_health_check.default.id]

  # Adding backend for primary region
  backend {
    group           = google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0

  }

  log_config {
    enable      = true
    sample_rate = 0.5
  }

  depends_on = [
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
  ]
}


# URL map for the external load balancer
resource "google_compute_region_url_map" "pri_ilb_pplapp_middleware_urlmap" {
  name = "ilb-pplapp-middleware-${var.primary_network_region}"
  #  provider        = google-beta
  default_service = google_compute_region_backend_service.pri_ilb_pplapp_middleware.id
  project         = var.microseg_project_id
  region          = var.primary_network_region
  depends_on = [
    google_compute_region_backend_service.pri_ilb_pplapp_middleware,
  ]
}


# Proxy for the internal load balancer
resource "google_compute_region_target_http_proxy" "pri_ilb_pplapp_middleware_proxy" {
  name     = "ilb-pplapp-middleware-proxy-${var.primary_network_region}"
  region   = var.primary_network_region
  provider = google-beta
  url_map  = google_compute_region_url_map.pri_ilb_pplapp_middleware_urlmap.id
  project  = var.microseg_project_id
  depends_on = [
    google_compute_region_url_map.pri_ilb_pplapp_middleware_urlmap,
  ]
}


resource "google_compute_address" "ilb_pplapp_presentation_address" {
  name         = "ilb-pplapp-middleware-address-${var.primary_network_region}"
  provider     = google-beta
  region       = var.primary_network_region
  network_tier = "PREMIUM"
  project      = var.microseg_project_id
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}



# Forwarding rule for the internal load balancer
resource "google_compute_forwarding_rule" "pri_ilb_pplapp_middleware_rule" {
  name                  = "ilb-pplapp-middleware-rule-${var.primary_network_region}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "80"
  ip_address            = var.primary_ilb_ip
  target                = google_compute_region_target_http_proxy.pri_ilb_pplapp_middleware_proxy.id
  network               = google_compute_network.primary_network.id
  subnetwork            = google_compute_subnetwork.primary_middleware_subnetwork.id
  network_tier          = "PREMIUM"
  region                = var.primary_network_region
  project               = var.microseg_project_id
  depends_on = [
    google_compute_region_target_http_proxy.pri_ilb_pplapp_middleware_proxy,
    google_compute_subnetwork.primary_sub_proxy,
    google_compute_subnetwork.primary_middleware_subnetwork,
  ]
}

