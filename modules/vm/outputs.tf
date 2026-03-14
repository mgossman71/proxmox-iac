output "id" {
  description = "VM ID assigned by Proxmox"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ipv4_address" {
  description = "VM IPv4 address (with CIDR). Returns 'N/A' if cloud-init is disabled."
  value       = var.cloud_init_enabled ? proxmox_virtual_environment_vm.this.initialization[0].ip_config[0].ipv4[0].address : "N/A"
}

output "node_name" {
  description = "Proxmox node this VM was deployed to"
  value       = proxmox_virtual_environment_vm.this.node_name
}
