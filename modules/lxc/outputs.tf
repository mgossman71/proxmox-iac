output "id" {
  description = "Container VM ID assigned by Proxmox"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "hostname" {
  description = "Container hostname"
  value       = proxmox_virtual_environment_container.this.initialization[0].hostname
}

output "ipv4_address" {
  description = "Container IPv4 address (with CIDR)"
  value       = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address
}

output "node_name" {
  description = "Proxmox node this container was deployed to"
  value       = proxmox_virtual_environment_container.this.node_name
}
