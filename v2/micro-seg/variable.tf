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

}

variable "billing_account" {

}


variable "microseg_folder_name" {

}

variable "microseg_project_name" {

}


variable "iam_secure_tag" {
}

variable "vpc_network_name" {

}

variable "primary_network_region" {

}

variable "primary_network_zone" {

}

variable "primary_presentation_subnetwork" {

}
variable "primary_middleware_subnetwork" {

}
variable "primary_sub_proxy" {
}

variable "primary_database_subnetwork" {

}

variable "primary_ilb_ip" {

}


variable "secondary_network_region" {

}

variable "secondary_network_zone" {
}


variable "secondary_presentation_subnetwork" {

}

variable "secondary_middleware_subnetwork" {

}
variable "secondary_sub_proxy" {
}

variable "secondary_ilb_ip" {

}

variable "skip_delete" {
}

