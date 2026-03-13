terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.81"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  node_name = var.node_name
  vm_id     = var.vmid

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_address != "dhcp" ? var.ipv4_gateway : null
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  dynamic "operating_system" {
    for_each = var.clone_vm_id == null ? [1] : []
    content {
      template_file_id = var.template_file_id
      type             = var.os_type
    }
  }

  dynamic "clone" {
    for_each = var.clone_vm_id != null ? [1] : []
    content {
      vm_id = var.clone_vm_id
      full  = var.clone_full
      node_name = var.clone_node_name
    }
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_dedicated
    swap      = var.memory_swap
  }

  features {
    nesting = var.nesting
  }

  unprivileged = var.unprivileged
  started      = var.started
  tags         = var.tags
}
