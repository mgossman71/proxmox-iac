locals {
  # ── Stack-wide defaults ──────────────────────────────────────────────────────
  # These apply to every container/VM unless overridden in the instance map.
  # Change a default here and it propagates to all instances that haven't
  # explicitly set that field.

  container_defaults = {
    ipv4_gateway     = "10.0.0.3"
    bridge           = "vmbr0"
    datastore_id     = "local-lvm"
    os_type          = "ubuntu"
    disk_size        = 8
    cpu_cores        = 2
    memory_dedicated = 1024
    memory_swap      = 512
    nesting          = true
    unprivileged     = true
    started          = true
    tags             = ["iac", "lab"]
    # Provisioning mode — set exactly one per container.
    # template_file_id: provision from a raw LXC template tarball.
    # clone_vm_id:      clone an existing LXC template (faster, pre-configured).
    # clone_node_name:  source node for clone_vm_id (required for cross-node clones).
    template_file_id = null
    clone_vm_id      = null
    clone_node_name  = null
  }

  vm_defaults = {
    ipv4_gateway     = "10.0.0.3"
    bridge           = "vmbr0"
    datastore_id     = "local-lvm"
    cpu_cores        = 2
    cpu_type         = "x86-64-v2-AES"
    memory_dedicated = 2048
    disk_size        = 20
    ci_user          = "ubuntu"
    ssh_public_keys  = []
    agent_enabled    = true
    started          = true
    tags             = ["iac", "lab"]
  }

  # ── LXC Containers ───────────────────────────────────────────────────────────
  # To add a new container: copy any block, change the key and required fields.
  # To remove a container: delete its block and run terraform apply.
  # To change a node: update node_name (Proxmox handles the rest).
  #
  # Provisioning modes (set exactly one per container):
  #   template_file_id  — provision from a raw LXC template tarball (default method)
  #   clone_vm_id       — clone an existing LXC template (faster; inherits pre-installed software)
  #
  # Cross-node clone example (template on pve-t0, deploy to pve-t1):
  #
  # "my-clone-1" = merge(local.container_defaults, {
  #   vmid             = 211
  #   node_name        = "pve-t1"       # deploy here
  #   hostname         = "my-clone-1"
  #   ipv4_address     = "dhcp"
  #   ipv4_gateway     = null
  #   clone_vm_id      = 100
  #   clone_node_name  = "pve-t0"       # source node where VMID 100 lives
  #   tags             = ["iac", "lab", "clone"]
  # })

  containers = {
    "my-clone-1" = merge(local.container_defaults, {
      vmid            = 210
      node_name       = "pve-t0"
      hostname        = "my-clone-1"
      ipv4_address    = "dhcp"
      ipv4_gateway    = null
      clone_vm_id     = 100
      clone_node_name = null
      cpu_cores       = 2
      memory_dedicated = 1024
      tags            = ["iac", "lab", "clone"]
    })

    "lxc-test-1" = merge(local.container_defaults, {
      vmid             = 200
      node_name        = "pve-t1"
      hostname         = "lxc-test-1"
      ipv4_address     = "dhcp"
      ipv4_gateway     = null
      template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
      tags             = ["iac", "lab", "lxc"]
    })

    "lxc-test-2" = merge(local.container_defaults, {
      vmid             = 201
      node_name        = "pve-t1"
      hostname         = "lxc-test-2"
      ipv4_address     = "dhcp"
      ipv4_gateway     = null
      template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
      tags             = ["iac", "lab", "lxc"]
    })

    "lxc-test-3" = merge(local.container_defaults, {
      vmid             = 202
      node_name        = "pve-t1"
      hostname         = "lxc-test-2"
      ipv4_address     = "dhcp"
      ipv4_gateway     = null
      template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
      tags             = ["iac", "lab", "lxc"]
    })
  }

  # ── QEMU VMs ─────────────────────────────────────────────────────────────────
  # Expects a cloud image already present on the target node's datastore.
  # See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file
  #
  # To add a new VM: copy any block, change the key and required fields.

  vms = {
    # Example: uncomment and adjust to deploy a QEMU VM.
    #
    # "k8s-control-01" = merge(local.vm_defaults, {
    #   vmid         = 301
    #   node_name    = "pve-t0"
    #   name         = "k8s-control-01"
    #   ipv4_address = "10.0.0.50/24"
    #   disk_file_id = "local:iso/ubuntu-24.04-server-cloudimg-amd64.img"
    #   cpu_cores    = 4
    #   memory_dedicated = 4096
    #   disk_size    = 40
    #   ssh_public_keys = [file("~/.ssh/id_rsa.pub")]
    #   tags         = ["iac", "lab", "k8s"]
    # })
  }
}

# ── Deploy containers ─────────────────────────────────────────────────────────

module "containers" {
  for_each = local.containers
  source   = "../../modules/lxc"

  vmid             = each.value.vmid
  node_name        = each.value.node_name
  hostname         = each.value.hostname
  ipv4_address     = each.value.ipv4_address
  ipv4_gateway     = each.value.ipv4_gateway
  template_file_id = each.value.template_file_id
  clone_vm_id      = each.value.clone_vm_id
  clone_node_name  = each.value.clone_node_name
  bridge           = each.value.bridge
  datastore_id     = each.value.datastore_id
  os_type          = each.value.os_type
  disk_size        = each.value.disk_size
  cpu_cores        = each.value.cpu_cores
  memory_dedicated = each.value.memory_dedicated
  memory_swap      = each.value.memory_swap
  nesting          = each.value.nesting
  unprivileged     = each.value.unprivileged
  started          = each.value.started
  tags             = each.value.tags
}

# ── Deploy VMs ────────────────────────────────────────────────────────────────

module "vms" {
  for_each = local.vms
  source   = "../../modules/vm"

  vmid             = each.value.vmid
  node_name        = each.value.node_name
  name             = each.value.name
  ipv4_address     = each.value.ipv4_address
  ipv4_gateway     = each.value.ipv4_gateway
  disk_file_id     = each.value.disk_file_id
  bridge           = each.value.bridge
  datastore_id     = each.value.datastore_id
  disk_size        = each.value.disk_size
  cpu_cores        = each.value.cpu_cores
  cpu_type         = each.value.cpu_type
  memory_dedicated = each.value.memory_dedicated
  ci_user          = each.value.ci_user
  ssh_public_keys  = each.value.ssh_public_keys
  agent_enabled    = each.value.agent_enabled
  started          = each.value.started
  tags             = each.value.tags
}
