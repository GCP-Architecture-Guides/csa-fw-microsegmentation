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


resource "google_dns_managed_zone" "cloud_dns" {
  name       = "cloud-google-zone"
  dns_name   = "cloud.google.com."
  project    = local.csa_project_id
  visibility = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.primary_network.id
    }
  }
  depends_on = [time_sleep.wait_enable_service_api,
    google_compute_network.primary_network,
  ]
}

resource "google_dns_record_set" "spf" {
  name         = "packages.${google_dns_managed_zone.cloud_dns.dns_name}"
  managed_zone = google_dns_managed_zone.cloud_dns.name
  type         = "A"
  ttl          = 300
  project      = local.csa_project_id
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
  depends_on   = [google_dns_managed_zone.cloud_dns]
}


resource "google_dns_managed_zone" "private_zone" {
  name       = "private-zone"
  dns_name   = "microseg.private."
  project    = local.csa_project_id
  visibility = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.primary_network.id
    }
  }
  depends_on = [time_sleep.wait_enable_service_api]
}

resource "google_dns_record_set" "pri_ilb_pplapp_middleware" {
  name         = "hr_pplapp_us-west1_prod_middleware.${google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  project      = local.csa_project_id
  rrdatas      = ["${google_compute_forwarding_rule.pri_ilb_pplapp_middleware_rule.ip_address}"]
  depends_on = [google_dns_managed_zone.private_zone,
    google_compute_forwarding_rule.pri_ilb_pplapp_middleware_rule,
  ]
}


resource "google_dns_record_set" "sec_ilb_pplapp_middleware" {
  name         = "hr_pplapp_us-east1_prod_middleware.${google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  project      = local.csa_project_id
  rrdatas      = ["${google_compute_forwarding_rule.sec_ilb_pplapp_middleware_rule.ip_address}"]
  depends_on = [google_dns_managed_zone.private_zone,
    google_compute_forwarding_rule.sec_ilb_pplapp_middleware_rule,
  ]
}




resource "google_dns_record_set" "sec_ilb_pplapp_sqldb_microseg" {
  name         = "hr_pplapp_us-west1_sqldb-microseg.${google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  project      = local.csa_project_id
  rrdatas      = ["${google_sql_database_instance.private_sql_instance.ip_address.0.ip_address}"]
  depends_on = [
    google_dns_managed_zone.private_zone,
    google_sql_database_instance.private_sql_instance,
  ]
}




resource "google_dns_managed_zone" "google_apis" {
  name       = "google-apis"
  dns_name   = "googleapis.com."
  project    = local.csa_project_id
  visibility = "private"
  private_visibility_config {
    networks {
      network_url = google_compute_network.primary_network.id
    }
  }
  depends_on = [time_sleep.wait_enable_service_api,
    google_compute_network.primary_network,
  ]
}

resource "google_dns_record_set" "google_apis_1" {
  name         = "restricted.${google_dns_managed_zone.google_apis.dns_name}"
  managed_zone = google_dns_managed_zone.google_apis.name
  type         = "A"
  ttl          = 300
  project      = local.csa_project_id
  rrdatas      = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
  depends_on   = [google_dns_managed_zone.google_apis]
}


resource "google_dns_record_set" "google_apis_2" {
  name         = "*.${google_dns_managed_zone.google_apis.dns_name}"
  managed_zone = google_dns_managed_zone.google_apis.name
  type         = "CNAME"
  ttl          = 300
  project      = local.csa_project_id
  rrdatas      = ["restricted.googleapis.com."]
  depends_on   = [google_dns_managed_zone.google_apis]
}