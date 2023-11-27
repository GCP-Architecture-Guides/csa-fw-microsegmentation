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

resource "google_network_security_address_group" "private_google_apis" {

  name        = "private-google-apis"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Private Google APIs"
  type        = "IPV4"
  capacity    = "1"
  items       = ["199.36.153.8/30"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}


resource "google_network_security_address_group" "restricted_google_apis" {

  name        = "restricted-google-apis"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Restricted Google APIs"
  type        = "IPV4"
  capacity    = "1"
  items       = ["199.36.153.4/30"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}


resource "google_network_security_address_group" "hc_glb_grp" {

  name        = "hc-glb-grp"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Global Load Balancer and Health Check Source IPs"
  type        = "IPV4"
  capacity    = "2"
  items       = ["35.191.0.0/16", "130.211.0.0/22"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}


resource "google_network_security_address_group" "iap" {

  name        = "iap"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Identity-Aware Proxy Source IPs"
  type        = "IPV4"
  capacity    = "1"
  items       = ["35.235.240.0/20"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}



resource "google_network_security_address_group" "pplapp_middleware_ilb_grp" {

  name        = "pplapp-middleware-ilb-grp"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Internal Load Balancers for Middleware service"
  type        = "IPV4"
  capacity    = "2"
  items       = ["${var.primary_ilb_ip}", "${var.secondary_ilb_ip}"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}



resource "google_network_security_address_group" "primary_proxy_sub" {
  name        = "${var.primary_network_region}-proxy-sub"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Primary location proxy subnet"
  type        = "IPV4"
  capacity    = "1"
  items       = ["${var.primary_sub_proxy}"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}


resource "google_network_security_address_group" "secondary_proxy_sub" {

  name        = "${var.secondary_network_region}-proxy-sub"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "Secondary location proxy subnet"
  type        = "IPV4"
  capacity    = "1"
  items       = ["${var.secondary_sub_proxy}"]
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}

resource "google_network_security_address_group" "pplapp_sqldb" {

  name        = "pplapp-sqldb"
  parent      = google_project.micro_seg_project.id
  location    = "global"
  description = "SQL Database IP"
  type        = "IPV4"
  capacity    = "1"
  items       = ["${google_sql_database_instance.private_sql_instance.ip_address.0.ip_address}"]
  depends_on = [
    google_sql_database_instance.private_sql_instance,
  ]
}