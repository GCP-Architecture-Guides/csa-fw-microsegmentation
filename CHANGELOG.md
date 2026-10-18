# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Standard `.gitignore` file to prevent `.terraform/`, `*.tfstate`, provider caches, and sensitive `.tfvars` from being tracked in version control.
- `deletion_policy` variable (type `string`, default `"DELETE"`) replacing deprecated `skip_delete` on `google_project`.
- Modern Terraform `required_providers` specification in `provider.tf` constraining `hashicorp/google` and `hashicorp/google-beta` to `>= 5.0`, `hashicorp/time` `>= 0.9`, and `hashicorp/random` `>= 3.5`.
- Comprehensive variable types and descriptions across all variables in `variable.tf` and `micro-seg/variable.tf`.
- Output descriptions in root `outputs.tf` and `micro-seg/outputs.tf`.

### Changed
- **Native Instance Templates**: Migrated 4 compute instance templates (`pri_insttmpl_pplapp_presentation`, `pri_insttmpl_pplapp_middleware`, `sec_insttmpl_pplapp_presentation`, `sec_insttmpl_pplapp_middleware`) from `null_resource` and `local-exec` `gcloud compute instance-templates create` to native declarative `google_compute_instance_template` resources leveraging modern `resource_manager_tags`.
- **Native VPC Peering**: Replaced `null_resource.vpc_peering_setup` with native `google_compute_global_address` and `google_service_networking_connection` resources for Cloud SQL private service networking.
- **SQL SSL Mode Modernization**: Replaced deprecated `require_ssl = false` on `google_sql_database_instance` with `ssl_mode = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"`.
- **Firewall Rule Hygiene**: Fixed copy-pasted rule names and descriptions across `micro-seg/firewall.tf` (`allow-iap` rule names corrected for HTTP load balancer proxy rules; egress deny rules corrected from `deny-ingress-*` to `deny-egress-*`).
- **Modern HCL2 Syntax**: Updated legacy list index `.0.` to `[0]` and removed redundant string interpolations across `micro-seg/address_group.tf` and `micro-seg/dns.tf`.
- **Formatting**: Applied `terraform fmt -recursive` across the entire codebase.
- **Documentation**: Updated `README.md` with prerequisites, modern architecture details, and correct repository clone URLs.

### Removed
- Removed obsolete dead file `micro-seg/micro-seg-arch.tf`.
- Removed stale `depends_on = [null_resource.vpc_peering_setup]` across subnet definitions in `micro-seg/networks.tf`.
