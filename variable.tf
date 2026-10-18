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

/******************************
    ORGANIZATION & PROJECT CONFIGURATION
******************************/

variable "organization_id" {
  type        = string
  description = "Organization ID to add tags at organization level."
  default     = "XXXXXXXXXXXX"
}

variable "billing_account" {
  type        = string
  description = "Billing account ID for project creation."
  default     = "XXXXX-XXXXX-XXXXX"
}

variable "create_new_project" {
  type        = bool
  description = "If true, Terraform will create a new project. If false, uses an existing project."
  default     = true
}

variable "csa_project_id" {
  type        = string
  description = "Project ID to deploy resources into when create_new_project is false."
  default     = "XXXXXXXXXXXXX"
}

variable "microseg_folder_name" {
  type        = string
  description = "Parent folder display name for resource project."
  default     = "CSA-Micro-Segment"
}

variable "microseg_project_name" {
  type        = string
  description = "Project name to deploy resources."
  default     = "csa-micro-segment"
}

variable "deletion_policy" {
  type        = string
  description = "The deletion policy for the created project. Permitted values are 'DELETE', 'PREVENT', or 'ABANDON'."
  default     = "DELETE"
}

variable "iam_secure_tag" {
  type        = string
  description = "Secure tag key for IAM governance and firewall microsegmentation."
  default     = "hr_pplapp"
}

/******************************
    NETWORK CONFIGURATION
******************************/

variable "vpc_network_name" {
  type        = string
  description = "VPC network name for the microsegmentation environment."
  default     = "vpc-microseg"
}

variable "primary_network_region" {
  type        = string
  description = "Primary network region for microsegmentation architecture."
  default     = "us-west1"
}

variable "primary_network_zone" {
  type        = string
  description = "Primary network zone."
  default     = "us-west1-c"
}

variable "primary_presentation_subnetwork" {
  type        = string
  description = "Subnet CIDR range for primary presentation layer."
  default     = "10.10.0.0/28"
}

variable "primary_middleware_subnetwork" {
  type        = string
  description = "Subnet CIDR range for primary middleware layer."
  default     = "10.30.0.0/28"
}

variable "primary_sub_proxy" {
  type        = string
  description = "Subnet CIDR range for primary proxy-only subnet (Internal HTTP Load Balancer)."
  default     = "10.31.0.0/26"
}

variable "primary_database_subnetwork" {
  type        = string
  description = "IP address / CIDR range reserved for Cloud SQL private VPC peering."
  default     = "10.50.0.0"
}

variable "primary_ilb_ip" {
  type        = string
  description = "Internal IP address for primary region Internal Load Balancer."
  default     = "10.30.0.10"
}

variable "secondary_network_region" {
  type        = string
  description = "Secondary network region."
  default     = "us-east1"
}

variable "secondary_network_zone" {
  type        = string
  description = "Secondary network zone."
  default     = "us-east1-c"
}

variable "secondary_presentation_subnetwork" {
  type        = string
  description = "Subnet CIDR range for secondary presentation layer."
  default     = "10.20.0.0/28"
}

variable "secondary_middleware_subnetwork" {
  type        = string
  description = "Subnet CIDR range for secondary middleware layer."
  default     = "10.40.0.0/28"
}

variable "secondary_sub_proxy" {
  type        = string
  description = "Subnet CIDR range for secondary proxy-only subnet (Internal HTTP Load Balancer)."
  default     = "10.41.0.0/26"
}

variable "secondary_ilb_ip" {
  type        = string
  description = "Internal IP address for secondary region Internal Load Balancer."
  default     = "10.40.0.10"
}
