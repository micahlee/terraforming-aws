#!/bin/bash -exu

main() {
  export OM_TARGET="https://$(jq -r .ops_manager_dns < env-state/metadata)"

  echo "Creating Custom VM Extensions"

  if [[ -n "${PAS}" ]]; then
    om -k curl --path /api/v0/staged/vm_extensions/web-lb-security-groups -x PUT -d \
      '{"name": "web-lb-security-groups", "cloud_properties": { "security_groups": ["web_lb_security_group", "vms_security_group"] }}'
    om -k curl --path /api/v0/staged/vm_extensions/ssh-lb-security-groups -x PUT -d \
      '{"name": "ssh-lb-security-groups", "cloud_properties": { "security_groups": ["ssh_lb_security_group", "vms_security_group"] }}'
    om -k curl --path /api/v0/staged/vm_extensions/tcp-lb-security-groups -x PUT -d \
      '{"name": "tcp-lb-security-groups", "cloud_properties": { "security_groups": ["tcp_lb_security_group", "vms_security_group"] }}'
  else
    om -k curl --path /api/v0/staged/vm_extensions/pks-api-lb-security-groups -x PUT -d \
      '{"name": "pks-api-lb-security-groups", "cloud_properties": { "security_groups": ["pks_api_lb_security_group", "vms_security_group"] }}'
  fi
}

main "$@"
