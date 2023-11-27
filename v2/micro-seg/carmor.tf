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



# Cloud Armor Security Policy
resource "google_compute_security_policy" "armor_microseg" {
  name        = "armor-microseg"
  project     = google_project.micro_seg_project.project_id
  description = "Cloud Armor policy for microseg architecture"

  # Only works if you have CA managed protection plus subscription
  #    rule {
  #    action   = "deny(404)"
  #    priority = "2000"
  #    match {
  #      expr {
  #        expression = "evaluateThreatIntelligence('iplist-known-malicious-ips')"
  #      }
  #    }
  #    description = "Block known malicious IPs"
  #  }


  rule {
    action   = "deny(404)"
    priority = "50000"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "SQL injection"
  }

  rule {
    action   = "deny(404)"
    priority = "50100"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Cross-site scripting"
  }


  rule {
    action   = "deny(404)"
    priority = "50200"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Local file inclusion"
  }

  rule {
    action   = "deny(404)"
    priority = "50300"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rfi-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Remote file inclusion"
  }

  rule {
    action   = "deny(404)"
    priority = "50400"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Remote code execution"
  }


  rule {
    action   = "deny(404)"
    priority = "50500"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('methodenforcement-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Method enforcement"
  }


  rule {
    action   = "deny(404)"
    priority = "50600"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Scanner detection"
  }

  rule {
    action   = "deny(404)"
    priority = "50700"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('protocolattack-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Protocol attacks"
  }


  rule {
    action   = "deny(404)"
    priority = "50800"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('php-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "PHP injection"
  }

  rule {
    action   = "deny(404)"
    priority = "50900"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sessionfixation-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Session fixation"
  }



  rule {
    action   = "deny(404)"
    priority = "60000"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('java-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "Java attack"
  }


  rule {
    action   = "deny(404)"
    priority = "60100"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('nodejs-v33-stable', {'sensitivity': 3})"
      }
    }
    description = "NodeJS attack"
  }





  rule {
    action   = "deny(404)"
    priority = "90000"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('cve-canary', {'sensitivity': 0, 'opt_in_rule_ids': ['owasp-crs-v030001-id044228-cve', 'owasp-crs-v030001-id144228-cve','owasp-crs-v030001-id244228-cve','owasp-crs-v030001-id344228-cve']})"
      }
    }
    description = "Opt-in Other CVE canary rules"
  }


  rule {
    action   = "deny(404)"
    priority = "90100"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('json-sqli-canary', {'sensitivity':0, 'opt_in_rule_ids': ['owasp-crs-id942550-sqli']})"
      }
    }
    description = "Opt-in JSON SQLi canary rule"
  }














  /*
  rule {
    action   = "deny(403)"
    priority = "9009"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 1})"
      }
    }
    description = "block scanner detection"
  }
*/





  /*
  rule {
    action   = "allow"
    priority = "2000000000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0"]
      }
    }
    description = "allow rule"
  }
*/
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default allow"
  }

  depends_on = [
    time_sleep.wait_enable_service_api,
  ]
}




