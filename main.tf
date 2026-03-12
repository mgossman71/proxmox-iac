terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.81"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint

  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"

  insecure = true
}

resource "proxmox_virtual_environment_container" "test_lxc" {
  node_name = var.node_name
  vm_id     = var.vmid

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "debian"
  }

  disk {
    datastore_id = var.datastore_id
    size         = 8
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  unprivileged = true
  started      = true

  tags = ["iac", "lab", "lxc"]
}
