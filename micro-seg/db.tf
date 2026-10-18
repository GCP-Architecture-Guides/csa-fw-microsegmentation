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
# PRIVATE SERVICE NETWORKING (VPC PEERING FOR CLOUD SQL)
# ==============================================================================

# Reserved private IP range for VPC peering with Service Networking
resource "google_compute_global_address" "private_ip_address" {
  project       = local.csa_project_id
  name          = "google-managed-services-${var.vpc_network_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = var.primary_database_subnetwork
  network       = google_compute_network.primary_network.id

  depends_on = [
    google_compute_network.primary_network,
    time_sleep.wait_enable_service_api,
  ]
}

# Establish Private Service Networking connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.primary_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [
    google_compute_global_address.private_ip_address,
  ]
}

# ==============================================================================
# CLOUD SQL INSTANCE & DATABASE
# ==============================================================================

# Create DB Instance
resource "google_sql_database_instance" "private_sql_instance" {
  project = local.csa_project_id

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
      private_network                               = google_compute_network.primary_network.id
      ssl_mode                                      = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      ipv4_enabled                                  = false
      enable_private_path_for_google_cloud_services = true
    }
  }

  depends_on = [
    time_sleep.wait_enable_service_api,
    google_service_networking_connection.private_vpc_connection,
  ]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_sql_database" "mydb" {
  project  = local.csa_project_id
  instance = google_sql_database_instance.private_sql_instance.name
  name     = "mydb"

  depends_on = [
    time_sleep.wait_enable_service_api,
    google_sql_database_instance.private_sql_instance,
  ]
}

resource "google_sql_user" "db_password" {
  project  = local.csa_project_id
  instance = google_sql_database_instance.private_sql_instance.name
  name     = "root"
  password = google_secret_manager_secret_version.sql_db_user_password.secret_data

  depends_on = [
    time_sleep.wait_enable_service_api,
    google_sql_database_instance.private_sql_instance,
  ]
}

# Add required roles to the SQL service accounts for storage object import
resource "google_project_iam_member" "sql_object_access" {
  project    = local.csa_project_id
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_sql_database_instance.private_sql_instance.service_account_email_address}"
  depends_on = [google_sql_database_instance.private_sql_instance]
}

# Creating the bucket for sample sql data
resource "google_storage_bucket" "sample_data" {
  name                        = "sample-data-${local.csa_project_id}"
  location                    = "us-central1"
  force_destroy               = true
  project                     = local.csa_project_id
  uniform_bucket_level_access = true

  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}

# Add sql data file to storage bucket
resource "google_storage_bucket_object" "db_sample_data" {
  name   = "sample-db-data.sql"
  bucket = google_storage_bucket.sample_data.name
  source = "${path.module}/sample-db-data/sample-db-data.sql"

  depends_on = [
    google_storage_bucket.sample_data,
  ]
}

# Wait delay after enabling SQL SA storage permissions
resource "time_sleep" "wait_sql_sa_role" {
  depends_on      = [google_project_iam_member.sql_object_access]
  create_duration = "120s"
}

# Importing initial sample data from Cloud Storage to the SQL Database
resource "null_resource" "upload_db_data" {
  triggers = {
    project       = local.csa_project_id
    instance_name = google_sql_database_instance.private_sql_instance.name
    bucket_name   = google_storage_bucket.sample_data.name
    file_name     = google_storage_bucket_object.db_sample_data.name
  }

  provisioner "local-exec" {
    command     = "gcloud sql import sql ${self.triggers.instance_name} gs://${self.triggers.bucket_name}/${self.triggers.file_name} --database=${google_sql_database.mydb.name} --project=${self.triggers.project}"
    working_dir = path.module
  }

  depends_on = [
    time_sleep.wait_sql_sa_role,
    google_sql_database.mydb,
  ]
}
