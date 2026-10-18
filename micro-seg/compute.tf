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

# ==============================================================================
# PRIMARY REGION: PRESENTATION LAYER
# ==============================================================================

resource "google_compute_instance_template" "pri_insttmpl_pplapp_presentation" {
  name_prefix = "insttmpl-pplapp-presentation-${var.primary_network_region}-"
  project     = local.csa_project_id
  description = "Primary region presentation layer instance template"

  machine_type   = "f1-micro"
  can_ip_forward = false

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.primary_presentation_subnetwork.id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  metadata_startup_script = file("${path.module}/scripts/pri-pst-ins-temp-startup.sh")

  service_account {
    email  = google_service_account.primary_sa_pplapp_presentation.email
    scopes = ["cloud-platform"]
  }

  resource_manager_tags = {
    (google_tags_tag_key.key.id) = google_tags_tag_value.pri_ppl_value.id
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.primary_presentation_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.primary_sa_pplapp_presentation,
    google_tags_tag_key.key,
    google_tags_tag_value.pri_ppl_value,
  ]
}

resource "google_compute_region_instance_group_manager" "pri_instgrp_pplapp_presentation" {
  project                        = local.csa_project_id
  name                           = "instgrp-pplapp-presentation-${var.primary_network_region}"
  region                         = var.primary_network_region
  base_instance_name             = "${var.primary_network_region}-prod-presentation"
  target_size                    = 2
  list_managed_instances_results = "PAGINATED"

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.pri_insttmpl_pplapp_presentation.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }

  depends_on = [
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
  ]
}

# ==============================================================================
# PRIMARY REGION: MIDDLEWARE LAYER
# ==============================================================================

resource "google_compute_instance_template" "pri_insttmpl_pplapp_middleware" {
  name_prefix = "insttmpl-pplapp-middleware-${var.primary_network_region}-"
  project     = local.csa_project_id
  description = "Primary region middleware layer instance template"

  machine_type   = "f1-micro"
  can_ip_forward = false

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.primary_middleware_subnetwork.id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  metadata_startup_script = file("${path.module}/scripts/pri-mdl-ins-temp-startup.sh")

  metadata = {
    DB_SEC  = google_secret_manager_secret.sql_db_user_password.secret_id
    PROJ_ID = local.csa_project_id
  }

  service_account {
    email  = google_service_account.primary_sa_pplapp_middleware.email
    scopes = ["cloud-platform"]
  }

  resource_manager_tags = {
    (google_tags_tag_key.key.id) = google_tags_tag_value.pri_mdwl_value.id
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.primary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.primary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password,
    google_tags_tag_key.key,
    google_tags_tag_value.pri_mdwl_value,
  ]
}

resource "google_compute_region_instance_group_manager" "pri_instgrp_pplapp_middleware" {
  project            = local.csa_project_id
  name               = "instgrp-pplapp-middleware-${var.primary_network_region}"
  region             = var.primary_network_region
  base_instance_name = "${var.primary_network_region}-prod-middleware"
  target_size        = 2

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.pri_insttmpl_pplapp_middleware.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }

  depends_on = [
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
  ]
}

# ==============================================================================
# SECONDARY REGION: PRESENTATION LAYER
# ==============================================================================

resource "google_compute_instance_template" "sec_insttmpl_pplapp_presentation" {
  name_prefix = "insttmpl-pplapp-presentation-${var.secondary_network_region}-"
  project     = local.csa_project_id
  description = "Secondary region presentation layer instance template"

  machine_type   = "f1-micro"
  can_ip_forward = false

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.secondary_presentation_subnetwork.id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  metadata_startup_script = file("${path.module}/scripts/sec-pst-ins-temp-startup.sh")

  service_account {
    email  = google_service_account.secondary_sa_pplapp_presentation.email
    scopes = ["cloud-platform"]
  }

  resource_manager_tags = {
    (google_tags_tag_key.key.id) = google_tags_tag_value.sec_ppl_value.id
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.secondary_presentation_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.secondary_sa_pplapp_presentation,
    google_tags_tag_key.key,
    google_tags_tag_value.sec_ppl_value,
  ]
}

resource "google_compute_region_instance_group_manager" "sec_instgrp_pplapp_presentation" {
  project            = local.csa_project_id
  name               = "instgrp-pplapp-presentation-${var.secondary_network_region}"
  region             = var.secondary_network_region
  base_instance_name = "${var.secondary_network_region}-prod-presentation"
  target_size        = 2

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.sec_insttmpl_pplapp_presentation.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }

  depends_on = [
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
  ]
}

# ==============================================================================
# SECONDARY REGION: MIDDLEWARE LAYER
# ==============================================================================

resource "google_compute_instance_template" "sec_insttmpl_pplapp_middleware" {
  name_prefix = "insttmpl-pplapp-middleware-${var.secondary_network_region}-"
  project     = local.csa_project_id
  description = "Secondary region middleware layer instance template"

  machine_type   = "f1-micro"
  can_ip_forward = false

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.secondary_middleware_subnetwork.id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  metadata_startup_script = file("${path.module}/scripts/sec-mdl-ins-temp-startup.sh")

  metadata = {
    DB_SEC  = google_secret_manager_secret.sql_db_user_password.secret_id
    PROJ_ID = local.csa_project_id
  }

  service_account {
    email  = google_service_account.secondary_sa_pplapp_middleware.email
    scopes = ["cloud-platform"]
  }

  resource_manager_tags = {
    (google_tags_tag_key.key.id) = google_tags_tag_value.sec_mdwl_value.id
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.secondary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.secondary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password,
    google_tags_tag_key.key,
    google_tags_tag_value.sec_mdwl_value,
  ]
}

resource "google_compute_region_instance_group_manager" "sec_instgrp_pplapp_middleware" {
  project            = local.csa_project_id
  name               = "instgrp-pplapp-middleware-${var.secondary_network_region}"
  region             = var.secondary_network_region
  base_instance_name = "${var.secondary_network_region}-prod-middleware"
  target_size        = 2

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.sec_insttmpl_pplapp_middleware.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }

  depends_on = [
    google_compute_health_check.default,
  ]
}
