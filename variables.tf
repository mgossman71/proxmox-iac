variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "node_name" {
  type = string
}

variable "vmid" {
  type = number
}

variable "hostname" {
  type = string
}

variable "ipv4_address" {
  type = string
}

variable "ipv4_gateway" {
  type = string
}

variable "bridge" {
  type = string
}

variable "datastore_id" {
  type = string
}

variable "template_file_id" {
  type = string
}
