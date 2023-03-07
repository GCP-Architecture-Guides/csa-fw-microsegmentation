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



resource "google_compute_network_firewall_policy" "primary" {
  name = "fwpol-microseg"

  description = "Global network firewall policy for micro segmentation architecture"
  project     = var.microseg_project_id

  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}


resource "google_compute_network_firewall_policy_association" "primary" {
  name              = "association"
  attachment_target = google_compute_network.primary_network.id
  firewall_policy   = google_compute_network_firewall_policy.primary.name
  project           = var.microseg_project_id
}


# allow access from health check ranges
resource "google_compute_network_firewall_policy_rule" "allow_health_check_glb" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access from Health Check and GLB to Web Servers"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 10000
  rule_name       = "allow-health-check"
  #  targetSecureTag   = true
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_ppl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_mdwl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_ppl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_mdwl_value.name}"
  }

  match {
    src_ip_ranges = ["130.211.0.0/22", "35.191.0.0/16"]



    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.pri_ppl_value,
    google_tags_tag_value.pri_mdwl_value,
    google_tags_tag_value.sec_ppl_value,
    google_tags_tag_value.sec_mdwl_value,
    google_compute_network_firewall_policy_association.primary,
  ]
}



# Allow access from Identity-Aware Proxy
resource "google_compute_network_firewall_policy_rule" "allow_iap" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access from Identity-Aware Proxy"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 11000
  rule_name       = "allow-iap"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_ppl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_mdwl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_ppl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_mdwl_value.name}"
  }

  match {
    src_ip_ranges = ["35.235.240.0/20"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [22]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.pri_ppl_value,
    google_tags_tag_value.pri_mdwl_value,
    google_tags_tag_value.sec_ppl_value,
    google_tags_tag_value.sec_mdwl_value,
    google_compute_network_firewall_policy_association.primary,
  ]
}




# Allow access from Global Load Balancer
resource "google_compute_network_firewall_policy_rule" "allow_glb" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access from Global load balancer"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 12000
  rule_name       = "allow-glb-access to presentation layer"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_ppl_value.name}"
  }


  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_ppl_value.name}"
  }


  match {
    src_ip_ranges = ["${google_compute_global_address.glb_pplapp_presentation_address.address}"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.pri_ppl_value,
    google_tags_tag_value.pri_mdwl_value,
    google_tags_tag_value.sec_ppl_value,
    google_tags_tag_value.sec_mdwl_value,
    google_compute_network_firewall_policy_association.primary,
    google_compute_global_address.glb_pplapp_presentation_address,
  ]
}


# Allow access from Internal Load Balancer
resource "google_compute_network_firewall_policy_rule" "allow_ilb" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access from Presentation to Middleware HTTP LBs"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 13000
  rule_name       = "allow-presentation-ilb-middleware"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]


  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_ppl_value.name}"
  }



  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_ppl_value.name}"
  }

  match {
    dest_ip_ranges = ["${google_compute_forwarding_rule.pri_ilb_pplapp_middleware_rule.ip_address}", "${google_compute_forwarding_rule.sec_ilb_pplapp_middleware_rule.ip_address}"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.pri_ppl_value,
    google_tags_tag_value.pri_mdwl_value,
    google_tags_tag_value.sec_ppl_value,
    google_tags_tag_value.sec_mdwl_value,
    google_compute_forwarding_rule.pri_ilb_pplapp_middleware_rule,
    google_compute_forwarding_rule.sec_ilb_pplapp_middleware_rule,
    google_compute_network_firewall_policy_association.primary,
  ]
}



# Allow access from HTTP LB Proxy subnet to Middleware 
resource "google_compute_network_firewall_policy_rule" "pri_allow_http_lb_proxy" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access from HTTP LB Proxy subnet to Middleware Primary"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 14000
  rule_name       = "allow-iap"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_mdwl_value.name}"
  }
  match {
    src_ip_ranges = ["${google_compute_subnetwork.primary_sub_proxy.ip_cidr_range}"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.pri_ppl_value,
    google_tags_tag_value.pri_mdwl_value,
    google_tags_tag_value.sec_ppl_value,
    google_tags_tag_value.sec_mdwl_value,
    google_compute_network_firewall_policy_association.primary,
  ]
}




# Allow access from HTTP LB Proxy subnet to Middleware 
resource "google_compute_network_firewall_policy_rule" "sec_allow_http_lb_proxy" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access from HTTP LB Proxy subnet to Middleware Secondary"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 14100
  rule_name       = "allow-iap"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_mdwl_value.name}"
  }
  match {
    src_ip_ranges = ["${google_compute_subnetwork.secondary_sub_proxy.ip_cidr_range}"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.pri_ppl_value,
    google_tags_tag_value.pri_mdwl_value,
    google_tags_tag_value.sec_ppl_value,
    google_tags_tag_value.sec_mdwl_value,
    google_compute_network_firewall_policy_association.primary,
  ]
}




# Network Firewall rule to allow the Middleware Layer to communicate with the SQL DB 
resource "google_compute_network_firewall_policy_rule" "allow_fwpol_microseg_db1" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Rule to allow VMs access to Private Google APIs1"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 15000
  rule_name       = "allow-mdl-db"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.sec_mdwl_value.name}"
  }

  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.pri_mdwl_value.name}"
  }


  match {
    dest_ip_ranges = ["${google_sql_database_instance.private_sql_instance.ip_address.0.ip_address}"] ## SQL IP Address

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [3306]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
    google_sql_database_instance.private_sql_instance,
  ]
}





# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "allow_private_access" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Rule to allow VMs access to Private Google APIs"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 80000
  rule_name       = "allow-private-access"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_ip_ranges = ["199.36.153.8/30"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "allow_restricted_access" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Rule to allow VMs access to Restricted Google APIs"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 80010
  rule_name       = "allow-restricted-access"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_ip_ranges = ["199.36.153.4/30"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}

/*
## Network Firewall terraform does not support FQDN yet; We will be using a local-exec to setup this firewall rule
## Network Firewall rule for your instances to download packages private access 
## https://github.com/hashicorp/terraform-provider-google/issues/13688
resource "google_compute_network_firewall_policy_rule" "allow_restricted_access_php" {
  project         = var.microseg_project_id
  action          = "allow"
  description     = "Allow access to install PHP Google Client Libraries"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 80100
  rule_name       = "allow-restricted-access-php"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_fqdns = ["repo.packagist.org", "api.github.com",  "codeload.github.com"]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}
*/



# Network Firewall rule for your instances to download packages private access 
resource "null_resource" "allow_restricted_access_php" {
  triggers = {
    project     = var.microseg_project_id
    policy_name = "${google_compute_network_firewall_policy.primary.name}"
  }

  provisioner "local-exec" {
    command     = <<EOT
    gcloud beta compute network-firewall-policies rules create 80100 --action allow --firewall-policy "${google_compute_network_firewall_policy.primary.name}" --description "Allow access to install PHP Google Client Libraries" --direction EGRESS --dest-fqdns repo.packagist.org,api.github.com,codeload.github.com --layer4-configs tcp:443 --enable-logging --no-disabled --global-firewall-policy --project "${var.microseg_project_id}"
    EOT
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
    gcloud beta compute network-firewall-policies rules delete 80100  --firewall-policy "${self.triggers.policy_name}" --project "${self.triggers.project}" --global-firewall-policy
    EOT
    working_dir = path.module
  }

  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}








# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv4" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv4"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000000
  rule_name       = "deny-ingress-ipv4"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    src_ip_ranges = ["0.0.0.0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv6" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv6"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000001
  rule_name       = "deny-ingress-ipv6"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    src_ip_ranges = ["0::0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}

# Deny egress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv4" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv4"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000010
  rule_name       = "deny-ingress-ipv4"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_ip_ranges = ["0.0.0.0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Deny egress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv6" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv6"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000011
  rule_name       = "deny-ingress-ipv6"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_ip_ranges = ["0::0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}



##################### Deny rules for Quarantine Tag ############

# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv4_quarantine" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv4-quarantine"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 5000
  rule_name       = "deny-ingress-ipv4"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.quart_tag_value.name}"
  }
  match {
    src_ip_ranges = ["0.0.0.0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
    google_tags_tag_value.quart_tag_value,
  ]
}


# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv6_quarantine" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv6-quarantine"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 5001
  rule_name       = "deny-ingress-ipv6"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.quart_tag_value.name}"
  }

  match {
    src_ip_ranges = ["0::0/0"]


    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
    google_tags_tag_value.quart_tag_value,
  ]
}

# Deny egress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv4_quarantine" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv4-quarantine"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 5010
  rule_name       = "deny-ingress-ipv4"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.quart_tag_value.name}"
  }

  match {
    dest_ip_ranges = ["0.0.0.0/0"]


    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
    google_tags_tag_value.quart_tag_value,
  ]
}


# Deny egress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv6_quarantine" {
  project         = var.microseg_project_id
  action          = "deny"
  description     = "deny-ingress-ipv6-quarantine"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 5011
  rule_name       = "deny-ingress-ipv6"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.quart_tag_value.name}"
  }

  match {
    dest_ip_ranges = ["0::0/0"]


    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
    google_tags_tag_value.quart_tag_value,
  ]
}


