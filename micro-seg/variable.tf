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

variable "organization_id" {
  type        = string
  description = "Organization ID to attach resource manager tags."
}

variable "billing_account" {
  type        = string
  description = "Billing account ID to associate with the created project."
}

variable "create_new_project" {
  type        = bool
  description = "Whether to create a new project (true) or use an existing one (false)."
}

variable "csa_project_id" {
  type        = string
  description = "Existing project ID if create_new_project is false."
}

variable "microseg_folder_name" {
  type        = string
  description = "Folder display name created under organization if create_new_project is true."
}

variable "microseg_project_name" {
  type        = string
  description = "Project name prefix to create if create_new_project is true."
}

variable "deletion_policy" {
  type        = string
  description = "Project deletion policy: DELETE, PREVENT, or ABANDON."
  default     = "DELETE"
}

variable "iam_secure_tag" {
  type        = string
  description = "Secure tag key for IAM governance and firewall microsegmentation."
}

variable "vpc_network_name" {
  type        = string
  description = "VPC network name for microsegmentation environment."
}

variable "primary_network_region" {
  type        = string
  description = "Primary Google Cloud region."
}

variable "primary_network_zone" {
  type        = string
  description = "Primary Google Cloud zone."
}

variable "primary_presentation_subnetwork" {
  type        = string
  description = "Subnet CIDR for primary presentation layer."
}

variable "primary_middleware_subnetwork" {
  type        = string
  description = "Subnet CIDR for primary middleware layer."
}

variable "primary_sub_proxy" {
  type        = string
  description = "Subnet CIDR for primary proxy-only subnet for internal load balancer."
}

variable "primary_database_subnetwork" {
  type        = string
  description = "IP address / CIDR reserved for Cloud SQL private VPC peering."
}

variable "primary_ilb_ip" {
  type        = string
  description = "Static internal IP address for primary region Internal Load Balancer."
}

variable "secondary_network_region" {
  type        = string
  description = "Secondary Google Cloud region."
}

variable "secondary_network_zone" {
  type        = string
  description = "Secondary Google Cloud zone."
}

variable "secondary_presentation_subnetwork" {
  type        = string
  description = "Subnet CIDR for secondary presentation layer."
}

variable "secondary_middleware_subnetwork" {
  type        = string
  description = "Subnet CIDR for secondary middleware layer."
}

variable "secondary_sub_proxy" {
  type        = string
  description = "Subnet CIDR for secondary proxy-only subnet for internal load balancer."
}

variable "secondary_ilb_ip" {
  type        = string
  description = "Static internal IP address for secondary region Internal Load Balancer."
}
