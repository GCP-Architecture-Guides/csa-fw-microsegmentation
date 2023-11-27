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



########################### IAM Tags#############

resource "google_tags_tag_key" "key" {
  # parent     = "organizations/${var.organization_id}"
  parent     = "projects/${local.csa_project_number}"
  short_name = var.iam_secure_tag

  description = "For use with network firewall."
  purpose     = "GCE_FIREWALL"
  purpose_data = {
    network = "${local.csa_project_id}/${var.vpc_network_name}"
  }
  depends_on = [
    time_sleep.wait_enable_service_api,
    google_compute_network.primary_network,
  ]
}

resource "google_tags_tag_value" "pri_ppl_value" {
  parent      = "tagKeys/${google_tags_tag_key.key.name}"
  short_name  = "${var.primary_network_region}_prod_presentation"
  description = "Tag for primary prod presentation."
  depends_on = [
    google_tags_tag_key.key,
  ]
}

resource "google_tags_tag_value" "pri_mdwl_value" {
  parent      = "tagKeys/${google_tags_tag_key.key.name}"
  short_name  = "${var.primary_network_region}_prod_middleware"
  description = "Tag for primary prod middleware."
  depends_on = [
    google_tags_tag_key.key,
  ]
}

resource "google_tags_tag_value" "sec_ppl_value" {
  parent      = "tagKeys/${google_tags_tag_key.key.name}"
  short_name  = "${var.secondary_network_region}_prod_presentation"
  description = "Tag for secondary prod presentation."
}

resource "google_tags_tag_value" "sec_mdwl_value" {
  parent      = "tagKeys/${google_tags_tag_key.key.name}"
  short_name  = "${var.secondary_network_region}_prod_middleware"
  description = "Tag for secondary prod middleware."
  depends_on = [
    google_tags_tag_key.key,
  ]
}


resource "google_tags_tag_value" "quart_tag_value" {
  parent      = "tagKeys/${google_tags_tag_key.key.name}"
  short_name  = "quarantine"
  description = "Tag for incident response"
  depends_on = [
    google_tags_tag_key.key,
  ]
}
