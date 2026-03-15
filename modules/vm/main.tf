terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.81"
    }
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  node_name = var.node_name
  vm_id     = var.vmid
  name      = var.name

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_dedicated
  }

  dynamic "disk" {
    for_each = var.clone_vm_id == null ? [1] : []
    content {
      datastore_id = var.datastore_id
      file_id      = var.disk_file_id
      interface    = "virtio0"
      size         = var.disk_size
      discard      = "on"
      iothread     = true
    }
  }

  dynamic "clone" {
    for_each = var.clone_vm_id != null ? [1] : []
    content {
      vm_id        = var.clone_vm_id
      node_name    = var.clone_node_name
      full         = true
      datastore_id = var.datastore_id
    }
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  dynamic "initialization" {
    for_each = var.cloud_init_enabled ? [1] : []
    content {
      datastore_id = var.datastore_id

      ip_config {
        ipv4 {
          address = var.ipv4_address
          gateway = var.ipv4_gateway
        }
      }

      user_account {
        username = var.ci_user
        keys     = var.ssh_public_keys
      }
    }
  }

  agent {
    enabled = var.agent_enabled
  }

  started = var.started
  tags    = var.tags
}
