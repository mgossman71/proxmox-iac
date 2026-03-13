# ── Required ───────────────────────────────────────────────────────────────────

variable "vmid" {
  description = "Unique VM ID (must not conflict with other VMs/CTs on the cluster)"
  type        = number
}

variable "node_name" {
  description = "Proxmox node to deploy this VM on"
  type        = string
}

variable "name" {
  description = "VM name (displayed in Proxmox UI)"
  type        = string
}

variable "ipv4_address" {
  description = "Static IPv4 address with CIDR notation (e.g. 10.0.0.50/24)"
  type        = string
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway"
  type        = string
}

variable "disk_file_id" {
  description = "Cloud image file ID already present on the datastore (e.g. local:iso/ubuntu-24.04-server-cloudimg-amd64.img)"
  type        = string
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "bridge" {
  description = "Network bridge to attach the VM interface to"
  type        = string
  default     = "vmbr0"
}

# ── Storage ────────────────────────────────────────────────────────────────────

variable "datastore_id" {
  description = "Proxmox datastore for the primary disk"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Primary disk size in GB"
  type        = number
  default     = 20
}

# ── Compute ────────────────────────────────────────────────────────────────────

variable "cpu_cores" {
  description = "Number of vCPU cores"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "CPU model exposed to the guest (x86-64-v2-AES is a safe modern default)"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "memory_dedicated" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 2048
}

# ── Cloud-init ─────────────────────────────────────────────────────────────────

variable "ci_user" {
  description = "Initial user account created by cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_keys" {
  description = "SSH public keys to authorize for the initial user"
  type        = list(string)
  default     = []
}

# ── VM behaviour ───────────────────────────────────────────────────────────────

variable "agent_enabled" {
  description = "Enable the QEMU guest agent (requires agent installed in the guest)"
  type        = bool
  default     = true
}

variable "started" {
  description = "Start the VM after creation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Proxmox tags to apply to the VM"
  type        = list(string)
  default     = ["iac"]
}
