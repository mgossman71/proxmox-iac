proxmox_endpoint     = "https://10.0.0.132:8006/api2/json"
proxmox_token_id     = "terraform@pve@pam!iac"
proxmox_token_secret = "PASTE_THE_REAL_TOKEN_SECRET_HERE"

node_name        = "pve-t0"
vmid             = 200
hostname         = "iac-test-lxc"
ipv4_address     = "10.0.0.98/24"
ipv4_gateway     = "10.0.0.3"
bridge           = "vmbr0"
datastore_id     = "local-lvm"
template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
