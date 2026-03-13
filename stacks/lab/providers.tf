terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.81"
    }
  }
}

# Credentials are read automatically from environment variables — no tfvars needed.
#
#   export PROXMOX_VE_ENDPOINT="https://10.0.0.132:8006/"
#   export PROXMOX_VE_API_TOKEN="terraform@pam!iac=<your-token-secret>"
#   export PROXMOX_VE_INSECURE="true"   # omit if you have a valid TLS cert
#
provider "proxmox" {}
