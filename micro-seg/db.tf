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




# Creating iam taging to compute instances pri_instgrp_pplapp_presentation
resource "null_resource" "vpc_peering_setup" {
  triggers = {
    project      = var.microseg_project_id
    network_name = "${var.vpc_network_name}"
  }

  provisioner "local-exec" {
    command     = <<EOT
gcloud compute addresses create google-managed-services-${var.vpc_network_name} --global --purpose=VPC_PEERING  --addresses=${var.primary_database_subnetwork} --prefix-length=24 --network=projects/${var.microseg_project_id}/global/networks/${var.vpc_network_name} --project=${var.microseg_project_id}
gcloud services vpc-peerings connect --service=servicenetworking.googleapis.com --ranges=google-managed-services-${var.vpc_network_name} --network=${var.vpc_network_name} --project=${var.microseg_project_id}
    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud compute addresses delete google-managed-services-${self.triggers.network_name} --project=${self.triggers.project} --global
        EOT
    working_dir = path.module
  }

  depends_on = [
    google_compute_network.primary_network
  ]
}


# Create DB Instance
resource "google_sql_database_instance" "private_sql_instance" {
  project = var.microseg_project_id

  deletion_protection = false
  name                = "sub-sqldb-microseg"
  region              = var.primary_network_region

  database_version = "MYSQL_8_0"

  settings {
    tier              = "db-f1-micro"
    disk_size         = 10
    disk_type         = "PD_HDD"
    availability_type = "REGIONAL"

    backup_configuration {
      binary_log_enabled = true
      enabled            = true
    }

    ip_configuration {
      private_network = google_compute_network.primary_network.id
      require_ssl     = false
      ipv4_enabled    = false
      /*
      authorized_networks {
        value = var.primary_middleware_subnetwork
        name  = "sub-middleware-${var.primary_network_region}"
      }
      authorized_networks {
        value = var.secondary_middleware_subnetwork
        name  = "sub-middleware-${var.secondary_network_region}"
      }

      #       dynamic "authorized_networks" {
      #   for_each = google_compute_region_instance_group_manager.pri_instgrp_pplapp_middleware
      #       iterator = pri_instgrp_pplapp_middleware
      #       content {
      #         name  = pri_instgrp_pplapp_middleware.value.name
      #         value = pri_instgrp_pplapp_middleware.value.network_interface.0.access_config.0.nat_ip
      #       }
      #   }
      #    dynamic "authorized_networks" {
      #    for_each = google_compute_region_instance_group_manager.sec_instgrp_pplapp_middleware
      #        iterator = sec_instgrp_pplapp_middleware
      #        content {
      #          name  = sec_instgrp_pplapp_middleware.value.name
      #          value = sec_instgrp_pplapp_middleware.value.network_interface.0.access_config.0.nat_ip
      #        }
      #   }. */
    }
  }

  depends_on = [
    time_sleep.wait_enable_service_api,
    null_resource.vpc_peering_setup,
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}


resource "google_sql_database" "mydb" {
  project  = var.microseg_project_id
  instance = google_sql_database_instance.private_sql_instance.name
  name     = "mydb"
  depends_on = [
    time_sleep.wait_enable_service_api,
    google_sql_database_instance.private_sql_instance,
  ]
}



resource "google_sql_user" "db_password" {
  project  = var.microseg_project_id
  instance = google_sql_database_instance.private_sql_instance.name
  name     = "root"
  password = google_secret_manager_secret_version.sql_db_user_password.secret_data

  depends_on = [time_sleep.wait_enable_service_api,
    google_sql_database_instance.private_sql_instance,
  ]
}





# Add required roles to the SQL service accounts for storage object import
resource "google_project_iam_member" "sql_object_access" {
  project    = var.microseg_project_id
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_sql_database_instance.private_sql_instance.service_account_email_address}"
  depends_on = [google_sql_database_instance.private_sql_instance]
}


#Creating the bucket for smple sql data
resource "google_storage_bucket" "sample_data" {
  name                        = "sample-data-${var.microseg_project_id}"
  location                    = "us-central1"
  force_destroy               = true
  project                     = var.microseg_project_id
  uniform_bucket_level_access = true
  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}

# Add zip file to the Cloud Function's source code bucket
resource "google_storage_bucket_object" "db_sample_data" {
  name   = "sample-db-data.sql"
  bucket = google_storage_bucket.sample_data.name
  source = "${path.module}/sample-db-data/sample-db-data.sql"
  depends_on = [
    google_storage_bucket.sample_data,
  ]
}

# Wait delay after enabling APIs
resource "time_sleep" "wait_sql_sa_role" {
  depends_on      = [google_project_iam_member.sql_object_access]
  create_duration = "120s"
}



# Importing data from storage object to the SQL Database
resource "null_resource" "upload_db_data" {
  triggers = {
    project      = var.microseg_project_id
    network_name = "${var.vpc_network_name}"
  }

  provisioner "local-exec" {
    command     = <<EOT
gcloud sql import sql ${google_sql_database_instance.private_sql_instance.name} gs://${google_storage_bucket.sample_data.name}/${google_storage_bucket_object.db_sample_data.name} --database=${google_sql_database.mydb.name} --project=${var.microseg_project_id}
    EOT
    working_dir = path.module
  }

  depends_on = [
    time_sleep.wait_sql_sa_role,
  ]
}
