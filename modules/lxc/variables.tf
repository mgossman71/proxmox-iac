# ── Required ───────────────────────────────────────────────────────────────────

variable "vmid" {
  description = "Unique container ID (must not conflict with other VMs/CTs on the cluster)"
  type        = number
}

variable "node_name" {
  description = "Proxmox node to deploy this container on"
  type        = string
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "ipv4_address" {
  description = "Static IPv4 address with CIDR notation (e.g. 10.0.0.97/24), or \"dhcp\""
  type        = string
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway. Not required when using DHCP."
  type        = string
  default     = null
}

variable "template_file_id" {
  description = "LXC template file ID (e.g. local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst). Mutually exclusive with clone_vm_id."
  type        = string
  default     = null

  validation {
    condition = (
      (var.template_file_id != null && var.clone_vm_id == null) ||
      (var.template_file_id == null && var.clone_vm_id != null)
    )
    error_message = "Exactly one of template_file_id or clone_vm_id must be specified."
  }
}

variable "clone_vm_id" {
  description = "VMID of an existing LXC template to clone. Mutually exclusive with template_file_id."
  type        = number
  default     = null
}

variable "clone_node_name" {
  description = "Node where the clone source template lives. Required when cloning cross-node (i.e. template is on a different node than the deployment target)."
  type        = string
  default     = null
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "bridge" {
  description = "Network bridge to attach the container interface to"
  type        = string
  default     = "vmbr0"
}

# ── Storage ────────────────────────────────────────────────────────────────────

variable "datastore_id" {
  description = "Proxmox datastore for the root disk"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 8
}

# ── OS ─────────────────────────────────────────────────────────────────────────

variable "os_type" {
  description = "OS type hint for Proxmox (ubuntu, debian, centos, etc.)"
  type        = string
  default     = "ubuntu"
}

# ── Compute ────────────────────────────────────────────────────────────────────

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_dedicated" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 1024
}

variable "memory_swap" {
  description = "Swap size in MB"
  type        = number
  default     = 512
}

# ── Container behaviour ────────────────────────────────────────────────────────

variable "unprivileged" {
  description = "Run as an unprivileged container"
  type        = bool
  default     = true
}

variable "nesting" {
  description = "Allow nested virtualisation inside the container"
  type        = bool
  default     = true
}

variable "started" {
  description = "Start the container after creation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Proxmox tags to apply to the container"
  type        = list(string)
  default     = ["iac"]
}
