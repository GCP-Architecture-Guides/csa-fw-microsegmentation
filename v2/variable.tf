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

# set specific variables here for your own deployment

/******************************
    REQUIRED TO CHANGE
******************************/

variable "organization_id" {
  type        = string
  description = "Organization ID to add tags at Org level"
  default     = "XXXXXX" ## Update the org id
}

variable "billing_account" {
  type        = string
  description = "billing account required"
  default     = "XXXXX-XXXXX-XXXXXX" ## Update the billing account
}

/*****************************
RECOMMENDED DEFAULTS - DO NOT CHANGE

unless you really really want to :)
*****************************/


variable "microseg_folder_name" {
  type        = string
  description = "Project ID to deploy resources"
  default     = "CSA-Micro-Segment"
}

variable "microseg_project_name" {
  type        = string
  description = "Project ID to deploy resources"
  default     = "csa-micro-segment"
}

variable "skip_delete" {
  description = " If true, the Terraform resource can be deleted without deleting the Project via the Google API."
  default     = "false"
}

variable "iam_secure_tag" {
  type        = string
  description = "Project ID to deploy resources"
  default     = "hr_pplapp"

}



variable "vpc_network_name" {
  type        = string
  description = "VPC network name"
  default     = "vpc-microseg"
}

variable "primary_network_region" {
  type        = string
  description = "Primary network region for micro segmentation architecture"
  default     = "us-west1"
}

variable "primary_network_zone" {
  type        = string
  description = "Primary network zone"
  default     = "us-west1-c"
}

variable "primary_presentation_subnetwork" {
  type        = string
  description = "Subnet range for primary presentation layer"
  default     = "10.10.0.0/28"
}
variable "primary_middleware_subnetwork" {
  type        = string
  description = "Subnet range for primary middleware layer"
  default     = "10.30.0.0/28"
}


variable "primary_sub_proxy" {
  type        = string
  description = "Subnet range proxy-only network for internal load balancer"
  default     = "10.31.0.0/26"
}

variable "primary_database_subnetwork" {
  type        = string
  description = "Subnet range for primary middleware layer"
  default     = "10.50.0.0"
}


variable "primary_ilb_ip" {
  type        = string
  description = "IP address for primary region internalload balancer"
  default     = "10.30.0.10"
}


variable "secondary_ilb_ip" {
  type        = string
  description = "IP address for secondary region internal load balancer"
  default     = "10.40.0.10"
}



variable "secondary_network_region" {
  type        = string
  description = "Secondary network region"
  default     = "us-east1"
}

variable "secondary_network_zone" {
  type        = string
  description = "Secondary network zone"
  default     = "us-east1-c"
}



variable "secondary_presentation_subnetwork" {
  type        = string
  description = "Subnet range for secondary presentation layer"
  default     = "10.20.0.0/28"
}

variable "secondary_middleware_subnetwork" {
  type        = string
  description = "Subnet range for secondary middleware layer"
  default     = "10.40.0.0/28"
}

variable "secondary_sub_proxy" {
  type        = string
  description = "Subnet range proxy-only network for internal load balancer"
  default     = "10.41.0.0/26"
}

