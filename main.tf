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


##  This code creates demo environment for CSA Network Firewall microsegmentation ##
##  This demo code is not built for production workload ##


module "micro_seg" {
  source                            = "./micro-seg"
  create_new_project                = var.create_new_project
  organization_id                   = var.organization_id
  billing_account                   = var.billing_account
  microseg_project_name             = var.microseg_project_name
  microseg_folder_name              = var.microseg_folder_name
  csa_project_id                    = var.csa_project_id
  iam_secure_tag                    = var.iam_secure_tag
  vpc_network_name                  = var.vpc_network_name
  primary_network_region            = var.primary_network_region
  primary_network_zone              = var.primary_network_zone
  primary_presentation_subnetwork   = var.primary_presentation_subnetwork
  primary_middleware_subnetwork     = var.primary_middleware_subnetwork
  primary_database_subnetwork       = var.primary_database_subnetwork
  primary_sub_proxy                 = var.primary_sub_proxy
  primary_ilb_ip                    = var.primary_ilb_ip
  secondary_network_region          = var.secondary_network_region
  secondary_network_zone            = var.secondary_network_zone
  secondary_presentation_subnetwork = var.secondary_presentation_subnetwork
  secondary_middleware_subnetwork   = var.secondary_middleware_subnetwork
  secondary_sub_proxy               = var.secondary_sub_proxy
  secondary_ilb_ip                  = var.secondary_ilb_ip
  skip_delete                       = var.skip_delete
}

