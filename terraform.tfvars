proxmox_endpoint     = "https://10.0.0.132:8006/api2/json"
proxmox_token_id     = "terraform@pve!iac"
proxmox_token_secret = "PUT_TOKEN_SECRET_HERE"

node_name        = "REPLACE_WITH_NODE_NAME"
vmid             = 200
hostname         = "iac-test-lxc"
ipv4_address     = "10.0.0.98/24"
ipv4_gateway     = "10.0.0.3"
bridge           = "vmbr0"
datastore_id     = "local-lvm"
template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
