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


#Create the service Account primary presentation
resource "google_service_account" "primary_sa_pplapp_presentation" {
  project      = var.microseg_project_id
  account_id   = "sa-pplapp-ppt-${var.primary_network_region}"
  display_name = "Compute service account"
}


#Create the service Account primary middleware
resource "google_service_account" "primary_sa_pplapp_middleware" {
  project      = var.microseg_project_id
  account_id   = "sa-pplapp-mdw-${var.primary_network_region}"
  display_name = "Compute service account to access MySQL pwd"
}


#Create the service Account secondary  presentation
resource "google_service_account" "secondary_sa_pplapp_presentation" {
  project      = var.microseg_project_id
  account_id   = "sa-pplapp-ppt-${var.secondary_network_region}"
  display_name = "Compute service account"
}

#Create the service Account secondary  middleware
resource "google_service_account" "secondary_sa_pplapp_middleware" {
  project      = var.microseg_project_id
  account_id   = "sa-pplapp-mdw-${var.secondary_network_region}"
  display_name = "Compute service account to access MySQL pwd"
}

