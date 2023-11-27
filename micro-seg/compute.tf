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

/* 
## Changing TF instance template to gcloud command to add IAM tags
# Instance template for primary region presentation layer
resource "google_compute_instance_template" "pri_insttmpl_pplapp_presentation" {
  name    = "insttmpl-pplapp-presentation-${var.primary_network_region}"
  project = local.csa_project_id

  provider = google-beta
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.primary_presentation_subnetwork.id

  }
  instance_description = "Basic compute instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }
  metadata_startup_script = file("${path.module}/scripts/pri-pst-ins-temp-startup.sh")
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.primary_sa_pplapp_presentation.email
    scopes = ["cloud-platform"]
  }
  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.primary_presentation_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.primary_sa_pplapp_presentation,
  ]
}
*/

## IAM TAG at instance template
# Creating iam taging to compute instances pri_instgrp_pplapp_presentation
resource "null_resource" "pri_insttmpl_pplapp_presentation" {
  triggers = {
    region    = var.primary_network_region
    project   = "${local.csa_project_id}"
    subnet    = "${google_compute_subnetwork.primary_presentation_subnetwork.id}"
    tag_key   = "${google_tags_tag_key.key.id}"
    tag_value = "${google_tags_tag_value.pri_ppl_value.id}"
    srv_email = google_service_account.primary_sa_pplapp_presentation.email
  }

  provisioner "local-exec" {
    command     = <<EOT
  gcloud compute instance-templates create insttmpl-pplapp-presentation-${self.triggers.region} \
  --resource-manager-tags="${self.triggers.tag_key}"="${self.triggers.tag_value}" \
  --region="${self.triggers.region}" \
  --project="${self.triggers.project}" \
  --subnet="${self.triggers.subnet}" \
  --shielded-integrity-monitoring \
  --shielded-secure-boot \
  --shielded-vtpm \
  --machine-type=f1-micro \
  --image-family="debian-11" \
  --image-project=debian-cloud \
  --configure-disk=auto-delete=true \
  --metadata-from-file=startup-script=scripts/pri-pst-ins-temp-startup.sh \
  --service-account="${self.triggers.srv_email}" \
  --scopes=cloud-platform \
  --no-address 
  EOT
    working_dir = path.module
  }

  #  provisioner "local-exec" {
  #    when    = destroy
  #    command = <<EOT
  #    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
  #    EOT
  #
  #    working_dir = path.module
  #  }
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







# Instance group manager for primary region presentation layer
resource "google_compute_region_instance_group_manager" "pri_instgrp_pplapp_presentation" {
  project = local.csa_project_id

  name     = "instgrp-pplapp-presentation-${var.primary_network_region}"
  provider = google-beta
  region   = var.primary_network_region
  # distribution_policy_zones  = ["${var.primary_network_zone}"]
  list_managed_instances_results = "PAGINATED"
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = "projects/${local.csa_project_id}/global/instanceTemplates/insttmpl-pplapp-presentation-${var.primary_network_region}"
    # google_compute_instance_template.pri_insttmpl_pplapp_presentation.id
    #    name              = "primary"
  }
  base_instance_name = "${var.primary_network_region}-prod-presentation"
  target_size        = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }
  depends_on = [
    #   google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    resource.null_resource.pri_insttmpl_pplapp_presentation,
  ]
}





/*
## Changing TF instance template to gcloud command to add IAM tags
# Instance template for primary region middleware layer
resource "google_compute_instance_template" "pri_insttmpl_pplapp_middleware" {
  name    = "insttmpl-pplapp-middleware-${var.primary_network_region}"
  project = local.csa_project_id

  provider = google-beta
  #  tags     = ["http-server"]
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.primary_middleware_subnetwork.id
    #  access_config {
    # add external ip to fetch packages
    #   }
  }
  instance_description = "Basic compute instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true

  }

  metadata_startup_script = file("${path.module}/scripts/pri-mdl-ins-temp-startup.sh")
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.primary_sa_pplapp_middleware.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    DB_SEC  = "${google_secret_manager_secret.sql_db_user_password.secret_id}"
    PROJ_ID = "${local.csa_project_id}"
  }
  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.primary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.primary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password
  ]
}
*/


## IAM TAG at instance template
# Creating iam taging to compute instances pri_instgrp_pplapp_middleware
resource "null_resource" "pri_insttmpl_pplapp_middleware" {
  triggers = {
    region    = var.primary_network_region
    project   = "${local.csa_project_id}"
    subnet    = "${google_compute_subnetwork.primary_middleware_subnetwork.id}"
    tag_key   = "${google_tags_tag_key.key.id}"
    tag_value = "${google_tags_tag_value.pri_mdwl_value.id}"
    srv_email = "${google_service_account.primary_sa_pplapp_middleware.email}"
    DB_SEC    = "${google_secret_manager_secret.sql_db_user_password.secret_id}"
  }

  provisioner "local-exec" {
    command     = <<EOT
  gcloud compute instance-templates create insttmpl-pplapp-middleware-${self.triggers.region} \
  --resource-manager-tags="${self.triggers.tag_key}"="${self.triggers.tag_value}" \
  --region="${self.triggers.region}" \
  --project="${self.triggers.project}" \
  --subnet="${self.triggers.subnet}" \
  --shielded-integrity-monitoring \
  --shielded-secure-boot \
  --shielded-vtpm \
  --machine-type=f1-micro \
  --image-family="debian-11" \
  --image-project=debian-cloud \
  --configure-disk=auto-delete=true \
  --metadata-from-file=startup-script=scripts/pri-mdl-ins-temp-startup.sh \
  --metadata=DB_SEC="${self.triggers.DB_SEC}",PROJ_ID="${self.triggers.project}" \
  --service-account="${self.triggers.srv_email}" \
  --scopes=cloud-platform \
  --no-address 
  EOT
    working_dir = path.module
  }

  #  provisioner "local-exec" {
  #    when    = destroy
  #    command = <<EOT
  #    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
  #    EOT
  #
  #    working_dir = path.module
  #  }


  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.primary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.primary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password,
    google_tags_tag_key.key,
    google_tags_tag_value.pri_ppl_value,
  ]
}


# Instance group manager for primary region middleware layer
resource "google_compute_region_instance_group_manager" "pri_instgrp_pplapp_middleware" {
  project = local.csa_project_id

  name     = "instgrp-pplapp-middleware-${var.primary_network_region}"
  provider = google-beta
  region   = var.primary_network_region
  #      distribution_policy_zones  = ["${var.primary_network_zone}"]

  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = "projects/${local.csa_project_id}/global/instanceTemplates/insttmpl-pplapp-middleware-${var.primary_network_region}"
    # google_compute_instance_template.pri_insttmpl_pplapp_middleware.id
    #    name              = "primary"
  }
  base_instance_name = "${var.primary_network_region}-prod-middleware"
  target_size        = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }
  depends_on = [
    #    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    resource.null_resource.pri_insttmpl_pplapp_middleware,
  ]
}













/*
## Changing TF instance template to gcloud command to add IAM tags
# Instance template for secondary region presentation layer
resource "google_compute_instance_template" "sec_insttmpl_pplapp_presentation" {
  name    = "insttmpl-pplapp-presentation-${var.secondary_network_region}"
  project = local.csa_project_id

  provider = google-beta
  #  tags     = ["http-server"]
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.secondary_presentation_subnetwork.id
    #  access_config {
    # add external ip to fetch packages
    #   }
  }
  instance_description = "Basic compute instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true

  }

  metadata_startup_script = file("${path.module}/scripts/sec-pst-ins-temp-startup.sh")
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.secondary_sa_pplapp_presentation.email
    scopes = ["cloud-platform"]
  }
  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.secondary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.secondary_sa_pplapp_presentation,

  ]
}
*/


## IAM TAG at instance template
# Creating iam taging to compute instances sec_instgrp_pplapp_presentation
resource "null_resource" "sec_insttmpl_pplapp_presentation" {
  triggers = {
    region    = var.secondary_network_region
    project   = "${local.csa_project_id}"
    subnet    = "${google_compute_subnetwork.secondary_presentation_subnetwork.id}"
    tag_key   = "${google_tags_tag_key.key.id}"
    tag_value = "${google_tags_tag_value.sec_ppl_value.id}"
    srv_email = "${google_service_account.secondary_sa_pplapp_presentation.email}"
  }

  provisioner "local-exec" {
    command     = <<EOT
  gcloud compute instance-templates create insttmpl-pplapp-presentation-${self.triggers.region} \
  --resource-manager-tags="${self.triggers.tag_key}"="${self.triggers.tag_value}" \
  --region="${self.triggers.region}" \
  --project="${self.triggers.project}" \
  --subnet="${self.triggers.subnet}" \
  --shielded-integrity-monitoring \
  --shielded-secure-boot \
  --shielded-vtpm \
  --machine-type=f1-micro \
  --image-family="debian-11" \
  --image-project=debian-cloud \
  --configure-disk=auto-delete=true \
  --metadata-from-file=startup-script=scripts/sec-pst-ins-temp-startup.sh \
  --service-account="${self.triggers.srv_email}" \
  --scopes=cloud-platform \
  --no-address 
  EOT
    working_dir = path.module
  }

  #  provisioner "local-exec" {
  #    when    = destroy
  #    command = <<EOT
  #    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
  #    EOT
  #
  #    working_dir = path.module
  #  }

  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.secondary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_service_account.secondary_sa_pplapp_presentation,
    google_tags_tag_key.key,
    google_tags_tag_value.sec_ppl_value,
  ]
}





# Instance group manager for secondary region presentation layer
resource "google_compute_region_instance_group_manager" "sec_instgrp_pplapp_presentation" {
  project = local.csa_project_id

  name     = "instgrp-pplapp-presentation-${var.secondary_network_region}"
  provider = google-beta
  region   = var.secondary_network_region
  #  distribution_policy_zones  = ["${var.secondary_network_zone}"]

  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = "projects/${local.csa_project_id}/global/instanceTemplates/insttmpl-pplapp-presentation-${var.secondary_network_region}"

    # google_compute_instance_template.sec_insttmpl_pplapp_presentation.id
  }
  base_instance_name = "${var.secondary_network_region}-prod-presentation"
  target_size        = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }
  depends_on = [
    #   google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
    resource.null_resource.sec_insttmpl_pplapp_presentation,
  ]
}








/*
## Changing TF instance template to gcloud command to add IAM tags
# Instance template for secondary region middleware layer
resource "google_compute_instance_template" "sec_insttmpl_pplapp_middleware" {
  name    = "insttmpl-pplapp-middleware-${var.secondary_network_region}"
  project = local.csa_project_id

  provider = google-beta
  #  tags     = ["http-server"]
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = google_compute_network.primary_network.id
    subnetwork = google_compute_subnetwork.secondary_middleware_subnetwork.id

  }
  instance_description = "Basic compute instances"
  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true

  }

  metadata_startup_script = file("${path.module}/scripts/sec-mdl-ins-temp-startup.sh")
  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.secondary_sa_pplapp_middleware.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    DB_SEC  = "${google_secret_manager_secret.sql_db_user_password.secret_id}"
    PROJ_ID = "${local.csa_project_id}"
  }
  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.secondary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_service_account.secondary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password,
  ]
}
*/


## IAM TAG at instance template
# Creating iam taging to compute instances sec_insttmpl_pplapp_middleware
resource "null_resource" "sec_insttmpl_pplapp_middleware" {
  triggers = {
    region    = var.secondary_network_region
    project   = "${local.csa_project_id}"
    subnet    = "${google_compute_subnetwork.secondary_middleware_subnetwork.id}"
    tag_key   = "${google_tags_tag_key.key.id}"
    tag_value = "${google_tags_tag_value.sec_mdwl_value.id}"
    srv_email = "${google_service_account.secondary_sa_pplapp_middleware.email}"
    DB_SEC    = "${google_secret_manager_secret.sql_db_user_password.secret_id}"
  }

  provisioner "local-exec" {
    command     = <<EOT
  gcloud compute instance-templates create insttmpl-pplapp-middleware-${self.triggers.region} \
  --resource-manager-tags="${self.triggers.tag_key}"="${self.triggers.tag_value}" \
  --region="${self.triggers.region}" \
  --project="${self.triggers.project}" \
  --subnet="${self.triggers.subnet}" \
  --shielded-integrity-monitoring \
  --shielded-secure-boot \
  --shielded-vtpm \
  --machine-type=f1-micro \
  --image-family="debian-11" \
  --image-project=debian-cloud \
  --configure-disk=auto-delete=true \
  --metadata-from-file=startup-script=scripts/sec-mdl-ins-temp-startup.sh \
  --metadata=DB_SEC="${self.triggers.DB_SEC}",PROJ_ID="${self.triggers.project}" \
  --service-account="${self.triggers.srv_email}" \
  --scopes=cloud-platform \
  --no-address 
  EOT
    working_dir = path.module
  }

  #  provisioner "local-exec" {
  #    when    = destroy
  #    command = <<EOT
  #    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
  #    EOT
  #
  #    working_dir = path.module
  #  }


  depends_on = [
    google_compute_subnetwork.secondary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_service_account.secondary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password,
    google_compute_network.primary_network,
    google_compute_network_firewall_policy_rule.allow_private_access,
    google_tags_tag_key.key,
    google_tags_tag_value.sec_mdwl_value,
  ]
}








# Instance group manager for secondary region middleware layer
resource "google_compute_region_instance_group_manager" "sec_instgrp_pplapp_middleware" {
  project = local.csa_project_id

  name     = "instgrp-pplapp-middleware-${var.secondary_network_region}"
  provider = google-beta
  region   = var.secondary_network_region
  #  distribution_policy_zones  = ["${var.secondary_network_zone}"]

  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = "projects/${local.csa_project_id}/global/instanceTemplates/insttmpl-pplapp-middleware-${var.secondary_network_region}"

    # google_compute_instance_template.sec_insttmpl_pplapp_middleware.id
  }
  base_instance_name = "${var.secondary_network_region}-prod-middleware"
  target_size        = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 800
  }
  depends_on = [
    #  google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    google_compute_health_check.default,
    resource.null_resource.sec_insttmpl_pplapp_middleware
  ]
}