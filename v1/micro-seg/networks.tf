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


# VPC
resource "google_compute_network" "primary_network" {
  name = var.vpc_network_name
  #  provider                = google-beta
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
  project                         = var.microseg_project_id
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]

}


/* 
# Delete default network and firewall rules
resource "null_resource" "delete_def_network" {
  triggers = {
    project            = var.microseg_project_id
  }

  provisioner "local-exec" {
    command     = <<EOT
    gcloud compute firewall-rules -q delete default-allow-internal --project ${var.microseg_project_id}
    gcloud compute firewall-rules -q delete default-allow-rdp --project ${var.microseg_project_id}
    gcloud compute firewall-rules -q delete default-allow-ssh --project ${var.microseg_project_id}
    gcloud compute firewall-rules -q delete default-allow-icmp --project ${var.microseg_project_id}
    gcloud compute networks delete default -q --project ${var.microseg_project_id}
    EOT
    working_dir = path.module
  } 
  depends_on = [
     time_sleep.wait_enable_service_api,
  ]
}
*/



# Primary presentation layer subnet
resource "google_compute_subnetwork" "primary_presentation_subnetwork" {
  name = "sub-presentation-${var.primary_network_region}"
  #  provider      = google-beta
  ip_cidr_range = var.primary_presentation_subnetwork
  region        = var.primary_network_region
  network       = google_compute_network.primary_network.id
  project       = var.microseg_project_id
  # Enabling VPC flow logs
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  # Enable private Google acces
  private_ip_google_access = true
  depends_on = [
    google_compute_network.primary_network,
    null_resource.vpc_peering_setup,
  ]
}

# Primary middleware layer subnet
resource "google_compute_subnetwork" "primary_middleware_subnetwork" {
  name = "sub-middleware-${var.primary_network_region}"
  #  provider      = google-beta
  ip_cidr_range = var.primary_middleware_subnetwork
  region        = var.primary_network_region
  network       = google_compute_network.primary_network.id
  project       = var.microseg_project_id
  # Enabling VPC flow logs
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  # Enable private Google acces
  private_ip_google_access = true
  depends_on = [
    google_compute_network.primary_network,
    null_resource.vpc_peering_setup,
  ]
}


# Create a CloudRouter for primary middleware subnet
resource "google_compute_router" "primary_middleware_router" {
  project = var.microseg_project_id
  name    = "cloudr-microseg-${var.primary_network_region}"
  region  = var.primary_network_region
  network = google_compute_network.primary_network.id

  bgp {
    asn = 64514
  }
  depends_on = [
    google_compute_network.primary_network,
  ]
}

# Configure a CloudNAT for primary middleware subnet
resource "google_compute_router_nat" "primary_middleware_nats" {
  project                            = var.microseg_project_id
  name                               = "cloudnat-microseg-${var.primary_network_region}"
  router                             = google_compute_router.primary_middleware_router.name
  region                             = google_compute_router.primary_middleware_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.primary_middleware_subnetwork.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ALL"
  }
  depends_on = [
    google_compute_router.primary_middleware_router,
    google_compute_subnetwork.primary_middleware_subnetwork,
  ]
}












# Primary sub-proxy subnet for load balancer
resource "google_compute_subnetwork" "primary_sub_proxy" {
  name = "sub-proxy-${var.primary_network_region}"
  #  provider      = google-beta
  ip_cidr_range = var.primary_sub_proxy
  region        = var.primary_network_region
  network       = google_compute_network.primary_network.id
  project       = var.microseg_project_id
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"

  depends_on = [
    google_compute_network.primary_network,
    null_resource.vpc_peering_setup,
  ]
}



# Secondary presentation layer subnet
resource "google_compute_subnetwork" "secondary_presentation_subnetwork" {
  name = "sub-presentation-${var.secondary_network_region}"
  #  provider      = google-beta
  ip_cidr_range = var.secondary_presentation_subnetwork
  region        = var.secondary_network_region
  network       = google_compute_network.primary_network.id
  project       = var.microseg_project_id
  # Enabling VPC flow logs
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  # Enable private Google acces
  private_ip_google_access = true
  depends_on = [
    google_compute_network.primary_network,
    null_resource.vpc_peering_setup,
  ]
}

# Secondary middleware layer subnet
resource "google_compute_subnetwork" "secondary_middleware_subnetwork" {
  name = "sub-middleware-${var.secondary_network_region}"
  #  provider      = google-beta
  ip_cidr_range = var.secondary_middleware_subnetwork
  region        = var.secondary_network_region
  network       = google_compute_network.primary_network.id
  project       = var.microseg_project_id
  # Enabling VPC flow logs
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  # Enable private Google acces
  private_ip_google_access = true
  depends_on = [
    google_compute_network.primary_network,
    null_resource.vpc_peering_setup,
  ]
}


# Create a CloudRouter for secondary middleware subnet
resource "google_compute_router" "secondary_middleware_router" {
  project = var.microseg_project_id
  name    = "cloudr-microseg-${var.secondary_network_region}"
  region  = var.secondary_network_region
  network = google_compute_network.primary_network.id

  bgp {
    asn = 64514
  }
  depends_on = [google_compute_network.primary_network]
}

# Configure a CloudNAT for secondary middleware subnet
resource "google_compute_router_nat" "secondary_middleware_nats" {
  project                            = var.microseg_project_id
  name                               = "cloudnat-microseg-${var.secondary_network_region}"
  router                             = google_compute_router.secondary_middleware_router.name
  region                             = google_compute_router.secondary_middleware_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.secondary_middleware_subnetwork.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ALL"
  }
  depends_on = [
    google_compute_router.secondary_middleware_router,
    google_compute_subnetwork.secondary_middleware_subnetwork,
  ]
}



# Primary sub-proxy subnet for load balancer
resource "google_compute_subnetwork" "secondary_sub_proxy" {
  name = "sub-proxy-${var.secondary_network_region}"
  #  provider      = google-beta
  ip_cidr_range = var.secondary_sub_proxy
  region        = var.secondary_network_region
  network       = google_compute_network.primary_network.id
  project       = var.microseg_project_id
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"

  depends_on = [
    google_compute_network.primary_network,
    null_resource.vpc_peering_setup,
  ]
}
