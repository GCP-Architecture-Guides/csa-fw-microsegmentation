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


# Instance template for primary region presentation layer
resource "google_compute_instance_template" "pri_insttmpl_pplapp_presentation" {
  name    = "insttmpl-pplapp-presentation-${var.primary_network_region}"
  project = var.microseg_project_id

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



# Instance group manager for primary region presentation layer
resource "google_compute_region_instance_group_manager" "pri_instgrp_pplapp_presentation" {
  project = var.microseg_project_id

  name                           = "instgrp-pplapp-presentation-${var.primary_network_region}"
  provider                       = google-beta
  region                         = var.primary_network_region
  list_managed_instances_results = "PAGINATED"
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.pri_insttmpl_pplapp_presentation.id
    #    name              = "primary"
  }
  base_instance_name = "${var.primary_network_region}-prod-presentation"
  target_size        = 2

  # auto_healing_policies {
  #   health_check      = google_compute_health_check.default.id
  #   initial_delay_sec = 800
  # }
  depends_on = [
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
  ]
}

#######################################################################
# Wait delay after instance templates and instance group manager
resource "time_sleep" "wait_enable_for_instances" {

  create_duration  = "180s"
  destroy_duration = "45s"

  depends_on = [
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
  ]
}


## To get the compute region data information
data "google_compute_region_instance_group" "pri_instgrp_pplapp_presentation" {
  self_link = google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation.instance_group
  project   = var.microseg_project_id
  depends_on = [
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}

## To get insatnce group information
data "google_compute_instance_group" "pri_instgrp_pplapp_presentation" {
  name    = google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation.name
  zone    = "${var.primary_network_region}-a"
  project = var.microseg_project_id
  depends_on = [
    data.google_compute_instance_group.pri_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}



# To get individual instance id and zone information
data "google_compute_instance" "pri_instgrp_pplapp_presentation0" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.pri_instgrp_pplapp_presentation.instances[0].instance
  depends_on = [
    data.google_compute_instance_group.pri_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}



# Creating iam taging to compute instances pri_instgrp_pplapp_presentation
resource "null_resource" "iam_tag_pri_instgrp_pplapp_presentation0a" {
  triggers = {
    instance_group     = google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation.instance_group
    project            = var.microseg_project_id
    instance1_location = "${data.google_compute_instance.pri_instgrp_pplapp_presentation0[0].zone}"
    instance1_tag      = "${google_tags_tag_value.pri_ppl_value.namespaced_name}"
    instance1_id       = "${data.google_compute_instance.pri_instgrp_pplapp_presentation0[0].id}"
    # instance2_location = "${data.google_compute_instance.pri_instgrp_pplapp_presentation[1].zone}"
    # instance2_tag = "${google_tags_tag_value.pri_ppl_value.namespaced_name}"
    # instance2_id= "${data.google_compute_instance.pri_instgrp_pplapp_presentation[1].id}"
  }

  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.pri_instgrp_pplapp_presentation0[0].zone} --tag-value ${google_tags_tag_value.pri_ppl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.pri_instgrp_pplapp_presentation0[0].id}
    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
    EOT

    working_dir = path.module
  }


  depends_on = [
    data.google_compute_instance.pri_instgrp_pplapp_presentation0,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    google_tags_tag_value.pri_ppl_value,
    time_sleep.wait_enable_for_instances,
  ]
}



# To get individual instance id and zone information
data "google_compute_instance" "pri_instgrp_pplapp_presentation1" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.pri_instgrp_pplapp_presentation.instances[1].instance
  depends_on = [
    data.google_compute_instance_group.pri_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}



# Creating iam taging to compute instances pri_instgrp_pplapp_presentation
resource "null_resource" "iam_tag_pri_instgrp_pplapp_presentation1a" {
  triggers = {
    instance_group = google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation.instance_group
    project        = var.microseg_project_id
    #      instance1_location = "${data.google_compute_instance.pri_instgrp_pplapp_presentation[0].zone}"
    #     instance1_tag = "${google_tags_tag_value.pri_ppl_value.namespaced_name}"
    #     instance1_id= "${data.google_compute_instance.pri_instgrp_pplapp_presentation[0].id}"
    instance2_location = "${data.google_compute_instance.pri_instgrp_pplapp_presentation1[1].zone}"
    instance2_tag      = "${google_tags_tag_value.pri_ppl_value.namespaced_name}"
    instance2_id       = "${data.google_compute_instance.pri_instgrp_pplapp_presentation1[1].id}"
  }


  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.pri_instgrp_pplapp_presentation1[1].zone} --tag-value ${google_tags_tag_value.pri_ppl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.pri_instgrp_pplapp_presentation1[1].id}
    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance2_location} --tag-value ${self.triggers.instance2_tag} --parent //compute.googleapis.com/${self.triggers.instance2_id}
    EOT

    working_dir = path.module
  }

  #${self.triggers.}
  depends_on = [
    data.google_compute_instance.pri_instgrp_pplapp_presentation1,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_presentation,
    google_compute_instance_template.pri_insttmpl_pplapp_presentation,
    google_tags_tag_value.pri_ppl_value,
    time_sleep.wait_enable_for_instances,
  ]
}




# Instance template for primary region middleware layer
resource "google_compute_instance_template" "pri_insttmpl_pplapp_middleware" {
  name    = "insttmpl-pplapp-middleware-${var.primary_network_region}"
  project = var.microseg_project_id

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
    PROJ_ID = "${var.microseg_project_id}"
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



# Instance group manager for primary region middleware layer
resource "google_compute_region_instance_group_manager" "pri_instgrp_pplapp_middleware" {
  project = var.microseg_project_id

  name     = "instgrp-pplapp-middleware-${var.primary_network_region}"
  provider = google-beta
  region   = var.primary_network_region
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.pri_insttmpl_pplapp_middleware.id
    #    name              = "primary"
  }
  base_instance_name = "${var.primary_network_region}-prod-middleware"
  target_size        = 2

  # auto_healing_policies {
  #   health_check      = google_compute_health_check.default.id
  #   initial_delay_sec = 800
  # }
  depends_on = [
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
  ]
}




## To get the compute region data information
data "google_compute_region_instance_group" "pri_instgrp_pplapp_middleware" {
  self_link = google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware.instance_group
  project   = var.microseg_project_id
  depends_on = [
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    time_sleep.wait_enable_for_instances,
  ]
}

## To get insatnce group information
data "google_compute_instance_group" "pri_instgrp_pplapp_middleware" {
  name    = google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware.name
  zone    = "${var.primary_network_region}-a"
  project = var.microseg_project_id
  depends_on = [
    data.google_compute_instance_group.pri_instgrp_pplapp_middleware,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    time_sleep.wait_enable_for_instances,
  ]
}

# To get individual instance id and zone information
data "google_compute_instance" "pri_instgrp_pplapp_middleware0" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.pri_instgrp_pplapp_middleware.instances[0].instance
  depends_on = [
    data.google_compute_instance_group.pri_instgrp_pplapp_middleware,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    time_sleep.wait_enable_for_instances,
  ]
}



# Creating iam taging to compute instances pri_instgrp_pplapp_middleware
resource "null_resource" "iam_tag_pri_instgrp_pplapp_middleware0a" {
  triggers = {
    instance_group     = google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware.instance_group
    project            = var.microseg_project_id
    instance1_location = "${data.google_compute_instance.pri_instgrp_pplapp_middleware0[0].zone}"
    instance1_tag      = "${google_tags_tag_value.pri_mdwl_value.namespaced_name}"
    instance1_id       = "${data.google_compute_instance.pri_instgrp_pplapp_middleware0[0].id}"
    #  instance2_location = "${data.google_compute_instance.pri_instgrp_pplapp_middleware[1].zone}"
    #  instance2_tag = "${google_tags_tag_value.pri_mdwl_value.namespaced_name}"
    #  instance2_id= "${data.google_compute_instance.pri_instgrp_pplapp_middleware[1].id}"
  }


  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.pri_instgrp_pplapp_middleware0[0].zone} --tag-value ${google_tags_tag_value.pri_mdwl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.pri_instgrp_pplapp_middleware0[0].id}

    EOT
    working_dir = path.module
  }


  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
    EOT
    working_dir = path.module
  }

  depends_on = [
    data.google_compute_instance.pri_instgrp_pplapp_middleware0,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    google_tags_tag_value.pri_mdwl_value,
    google_compute_network_firewall_policy_rule.allow_private_access,
    time_sleep.wait_enable_for_instances,
  ]
}





# To get individual instance id and zone information
data "google_compute_instance" "pri_instgrp_pplapp_middleware1" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.pri_instgrp_pplapp_middleware.instances[1].instance
  depends_on = [
    data.google_compute_instance_group.pri_instgrp_pplapp_middleware,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    time_sleep.wait_enable_for_instances,
  ]
}


# Creating iam taging to compute instances pri_instgrp_pplapp_middleware
resource "null_resource" "iam_tag_pri_instgrp_pplapp_middleware1a" {
  triggers = {
    instance_group = google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware.instance_group
    project        = var.microseg_project_id
    #   instance1_location = "${data.google_compute_instance.pri_instgrp_pplapp_middleware1[1].zone}"
    # instance1_tag = "${google_tags_tag_value.pri_mdwl_value.namespaced_name}"
    #  instance1_id= "${data.google_compute_instance.pri_instgrp_pplapp_middleware1[1].id}"
    instance2_location = "${data.google_compute_instance.pri_instgrp_pplapp_middleware1[1].zone}"
    instance2_tag      = "${google_tags_tag_value.pri_mdwl_value.namespaced_name}"
    instance2_id       = "${data.google_compute_instance.pri_instgrp_pplapp_middleware1[1].id}"
  }


  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.pri_instgrp_pplapp_middleware1[1].zone} --tag-value ${google_tags_tag_value.pri_mdwl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.pri_instgrp_pplapp_middleware1[1].id}

    EOT
    working_dir = path.module
  }


  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance2_location} --tag-value ${self.triggers.instance2_tag} --parent //compute.googleapis.com/${self.triggers.instance2_id}
    EOT
    working_dir = path.module
  }

  depends_on = [
    data.google_compute_instance.pri_instgrp_pplapp_middleware1,
    google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware,
    google_compute_instance_template.pri_insttmpl_pplapp_middleware,
    google_tags_tag_value.pri_mdwl_value,
    google_compute_network_firewall_policy_rule.allow_private_access,
    time_sleep.wait_enable_for_instances,
  ]
}











# Instance template for secondary region presentation layer
resource "google_compute_instance_template" "sec_insttmpl_pplapp_presentation" {
  name    = "insttmpl-pplapp-presentation-${var.secondary_network_region}"
  project = var.microseg_project_id

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



# Instance group manager for secondary region presentation layer
resource "google_compute_region_instance_group_manager" "sec_instgrp_pplapp_presentation" {
  project = var.microseg_project_id

  name     = "instgrp-pplapp-presentation-${var.secondary_network_region}"
  provider = google-beta
  region   = var.secondary_network_region
  #  distribution_policy_zones  = ["us-central1-a", "us-central1-f"]

  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.sec_insttmpl_pplapp_presentation.id
  }
  base_instance_name = "${var.secondary_network_region}-prod-presentation"
  target_size        = 2

  #  auto_healing_policies {
  #   health_check      = google_compute_health_check.default.id
  #   initial_delay_sec = 800
  # }
  depends_on = [
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    google_compute_health_check.default,
    google_dns_record_set.spf,
    google_compute_network_firewall_policy_rule.allow_private_access,
  ]
}




## To get the compute region data information
data "google_compute_region_instance_group" "sec_instgrp_pplapp_presentation" {
  self_link = google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation.instance_group
  project   = var.microseg_project_id
  depends_on = [
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}

## To get insatnce group information
data "google_compute_instance_group" "sec_instgrp_pplapp_presentation" {
  name    = google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation.name
  zone    = "${var.secondary_network_region}-a"
  project = var.microseg_project_id
  depends_on = [
    data.google_compute_instance_group.sec_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}

# To get individual instance id and zone information
data "google_compute_instance" "sec_instgrp_pplapp_presentation0" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.sec_instgrp_pplapp_presentation.instances[0].instance
  depends_on = [
    data.google_compute_instance_group.sec_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}


# Creating iam taging to compute instances sec_instgrp_pplapp_presentation
resource "null_resource" "iam_tag_sec_instgrp_pplapp_presentation0a" {
  triggers = {
    instance_group     = google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation.instance_group
    project            = var.microseg_project_id
    instance1_location = "${data.google_compute_instance.sec_instgrp_pplapp_presentation0[0].zone}"
    instance1_tag      = "${google_tags_tag_value.sec_ppl_value.namespaced_name}"
    instance1_id       = "${data.google_compute_instance.sec_instgrp_pplapp_presentation0[0].id}"
    #  instance2_location = "${data.google_compute_instance.sec_instgrp_pplapp_presentation0[1].zone}"
    #  instance2_tag = "${google_tags_tag_value.sec_ppl_value.namespaced_name}"
    #  instance2_id= "${data.google_compute_instance.sec_instgrp_pplapp_presentation0[1].id}"
  }

  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.sec_instgrp_pplapp_presentation0[0].zone} --tag-value ${google_tags_tag_value.sec_ppl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.sec_instgrp_pplapp_presentation0[0].id}
    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
    EOT
    working_dir = path.module
  }

  depends_on = [data.google_compute_instance.sec_instgrp_pplapp_presentation0,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    google_tags_tag_value.sec_ppl_value,
    time_sleep.wait_enable_for_instances,
  ]
}




# To get individual instance id and zone information
data "google_compute_instance" "sec_instgrp_pplapp_presentation1" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.sec_instgrp_pplapp_presentation.instances[1].instance
  depends_on = [
    data.google_compute_instance_group.sec_instgrp_pplapp_presentation,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    time_sleep.wait_enable_for_instances,
  ]
}


# Creating iam taging to compute instances sec_instgrp_pplapp_presentation
resource "null_resource" "iam_tag_sec_instgrp_pplapp_presentation1a" {
  triggers = {
    instance_group = google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation.instance_group
    project        = var.microseg_project_id
    #        instance1_location = "${data.google_compute_instance.sec_instgrp_pplapp_presentation1[0].zone}"
    #   instance1_tag = "${google_tags_tag_value.sec_ppl_value.namespaced_name}"
    #   instance1_id= "${data.google_compute_instance.sec_instgrp_pplapp_presentation[0].id}"
    instance2_location = "${data.google_compute_instance.sec_instgrp_pplapp_presentation1[1].zone}"
    instance2_tag      = "${google_tags_tag_value.sec_ppl_value.namespaced_name}"
    instance2_id       = "${data.google_compute_instance.sec_instgrp_pplapp_presentation1[1].id}"
  }


  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.sec_instgrp_pplapp_presentation1[1].zone} --tag-value ${google_tags_tag_value.sec_ppl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.sec_instgrp_pplapp_presentation1[1].id}

    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance2_location} --tag-value ${self.triggers.instance2_tag} --parent //compute.googleapis.com/${self.triggers.instance2_id}
    EOT
    working_dir = path.module
  }

  depends_on = [data.google_compute_instance.sec_instgrp_pplapp_presentation1,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_presentation,
    google_compute_instance_template.sec_insttmpl_pplapp_presentation,
    google_tags_tag_value.sec_ppl_value,
    time_sleep.wait_enable_for_instances,
  ]
}







# Instance template for secondary region middleware layer
resource "google_compute_instance_template" "sec_insttmpl_pplapp_middleware" {
  name    = "insttmpl-pplapp-middleware-${var.secondary_network_region}"
  project = var.microseg_project_id

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
    PROJ_ID = "${var.microseg_project_id}"
  }
  depends_on = [
    google_compute_network.primary_network,
    google_compute_subnetwork.secondary_middleware_subnetwork,
    google_dns_record_set.spf,
    google_service_account.secondary_sa_pplapp_middleware,
    google_secret_manager_secret.sql_db_user_password,
  ]
}



# Instance group manager for secondary region middleware layer
resource "google_compute_region_instance_group_manager" "sec_instgrp_pplapp_middleware" {
  project = var.microseg_project_id

  name     = "instgrp-pplapp-middleware-${var.secondary_network_region}"
  provider = google-beta
  region   = var.secondary_network_region
  #  distribution_policy_zones  = ["us-central1-a", "us-central1-f"]

  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.sec_insttmpl_pplapp_middleware.id
  }
  base_instance_name = "${var.secondary_network_region}-prod-middleware"
  target_size        = 2

  # auto_healing_policies {
  #   health_check      = google_compute_health_check.default.id
  #   initial_delay_sec = 800
  # }
  depends_on = [
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    google_compute_health_check.default,
  ]
}



## To get the compute region data information
data "google_compute_region_instance_group" "sec_instgrp_pplapp_middleware" {
  self_link = google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware.instance_group
  project   = var.microseg_project_id
  depends_on = [
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    time_sleep.wait_enable_for_instances,
  ]
}

## To get insatnce group information
data "google_compute_instance_group" "sec_instgrp_pplapp_middleware" {
  name    = google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware.name
  zone    = "${var.secondary_network_region}-a"
  project = var.microseg_project_id
  depends_on = [
    data.google_compute_instance_group.sec_instgrp_pplapp_middleware,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
  ]
}

# To get individual instance id and zone information
data "google_compute_instance" "sec_instgrp_pplapp_middleware0" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.sec_instgrp_pplapp_middleware.instances[0].instance
  depends_on = [
    data.google_compute_instance_group.sec_instgrp_pplapp_middleware,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    google_dns_record_set.spf,
    time_sleep.wait_enable_for_instances,

  ]
}


# Creating iam taging to compute instances sec_instgrp_pplapp_middleware
resource "null_resource" "iam_tag_sec_instgrp_pplapp_middleware0a" {
  triggers = {
    instance_group     = google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware.instance_group
    project            = var.microseg_project_id
    instance1_location = "${data.google_compute_instance.sec_instgrp_pplapp_middleware0[0].zone}"
    instance1_tag      = "${google_tags_tag_value.sec_mdwl_value.namespaced_name}"
    instance1_id       = "${data.google_compute_instance.sec_instgrp_pplapp_middleware0[0].id}"
    #   instance2_location = "${data.google_compute_instance.sec_instgrp_pplapp_middleware[1].zone}"
    #   instance2_tag = "${google_tags_tag_value.sec_mdwl_value.namespaced_name}"
    #   instance2_id= "${data.google_compute_instance.sec_instgrp_pplapp_middleware[1].id}"
  }


  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.sec_instgrp_pplapp_middleware0[0].zone} --tag-value ${google_tags_tag_value.sec_mdwl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.sec_instgrp_pplapp_middleware0[0].id}
    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance1_location} --tag-value ${self.triggers.instance1_tag} --parent //compute.googleapis.com/${self.triggers.instance1_id}
   EOT
    working_dir = path.module
  }

  depends_on = [
    data.google_compute_instance.sec_instgrp_pplapp_middleware0,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    google_tags_tag_value.sec_mdwl_value,
    time_sleep.wait_enable_for_instances,
  ]
}



# To get individual instance id and zone information
data "google_compute_instance" "sec_instgrp_pplapp_middleware1" {
  count     = 2
  project   = var.microseg_project_id
  self_link = data.google_compute_region_instance_group.sec_instgrp_pplapp_middleware.instances[1].instance
  depends_on = [
    data.google_compute_instance_group.sec_instgrp_pplapp_middleware,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    google_dns_record_set.spf,
    time_sleep.wait_enable_for_instances,

  ]
}


# Creating iam taging to compute instances sec_instgrp_pplapp_middleware
resource "null_resource" "iam_tag_sec_instgrp_pplapp_middleware1a" {
  triggers = {
    instance_group = google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware.instance_group
    project        = var.microseg_project_id
    #             instance1_location = "${data.google_compute_instance.sec_instgrp_pplapp_middleware[0].zone}"
    #   instance1_tag = "${google_tags_tag_value.sec_mdwl_value.namespaced_name}"
    #   instance1_id= "${data.google_compute_instance.sec_instgrp_pplapp_middleware[0].id}"
    instance2_location = "${data.google_compute_instance.sec_instgrp_pplapp_middleware1[1].zone}"
    instance2_tag      = "${google_tags_tag_value.sec_mdwl_value.namespaced_name}"
    instance2_id       = "${data.google_compute_instance.sec_instgrp_pplapp_middleware1[1].id}"
  }



  provisioner "local-exec" {
    command     = <<EOT
    gcloud resource-manager tags bindings create --location ${data.google_compute_instance.sec_instgrp_pplapp_middleware1[1].zone} --tag-value ${google_tags_tag_value.sec_mdwl_value.namespaced_name} --parent //compute.googleapis.com/${data.google_compute_instance.sec_instgrp_pplapp_middleware1[1].id}

    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud resource-manager tags bindings delete --location ${self.triggers.instance2_location} --tag-value ${self.triggers.instance2_tag} --parent //compute.googleapis.com/${self.triggers.instance2_id}
    EOT
    working_dir = path.module
  }

  depends_on = [
    data.google_compute_instance.sec_instgrp_pplapp_middleware1,
    google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware,
    google_compute_instance_template.sec_insttmpl_pplapp_middleware,
    google_tags_tag_value.sec_mdwl_value,
    time_sleep.wait_enable_for_instances,
  ]
}

