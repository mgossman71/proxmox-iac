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
    # clone_full:       create full clone (independent copy); set false for linked clone.
    template_file_id = null
    clone_vm_id      = null
    clone_node_name  = null
    clone_full       = true
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
  # To add a container: copy an example below into containers = { }, adjust the
  # fields, and run: terraform apply
  # To remove a container: delete its block and run: terraform apply
  #
  # Choose ONE provisioning method per container:
  #
  #   METHOD 1 — Image (tarball template)
  #   Boots a fresh container from an LXC template tarball stored on the node.
  #   Use this when you want a clean OS with no pre-installed software.
  #   Requires the .tar.zst file to already exist on the target node's local storage.
  #
  # "my-lxc-1" = merge(local.container_defaults, {
  #   vmid             = 210              # unique ID across the whole cluster
  #   node_name        = "pve-t0"         # node to create the container on
  #   hostname         = "my-lxc-1"       # container hostname
  #   ipv4_address     = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.50/24"
  #   ipv4_gateway     = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
  #   template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  #   cpu_cores        = 2                # override default (optional)
  #   memory_dedicated = 1024             # MB; override default (optional)
  #   disk_size        = 8                # GB; override default (optional)
  #   tags             = ["iac", "lab", "lxc"]
  # })
  #
  #   METHOD 2 — Clone (from an existing LXC template on the cluster)
  #   Clones a container you have already built and marked as a template in Proxmox.
  #   Use this when you want a container that already has software/config baked in.
  #
  #   Clone types:
  #     - Full clone (clone_full = true):  independent copy of the template; required for
  #       cross-node cloning with shared storage; larger disk footprint but no parent dependency.
  #     - Linked clone (clone_full = false): incremental copy; smaller disk footprint but
  #       depends on parent template still existing; must be on same node.
  #
  #   clone_node_name is only required when the template lives on a DIFFERENT node
  #   than the one you are deploying to (cross-node clone); template must be on shared storage.
  #
  # "my-clone-1" = merge(local.container_defaults, {
  #   vmid             = 220              # unique ID across the whole cluster
  #   node_name        = "pve-t1"         # node to create the clone ON (can differ from template node)
  #   hostname         = "my-clone-1"
  #   ipv4_address     = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.50/24"
  #   ipv4_gateway     = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
  #   clone_vm_id      = 100              # VMID of the source LXC template
  #   clone_node_name  = "pve-t0"         # node where VMID 100 lives (required for cross-node)
  #   clone_full       = true             # true=full clone (independent); false=linked (depends on parent)
  #   cpu_cores        = 2                # override template value (optional)
  #   memory_dedicated = 1024             # MB; override template value (optional)
  #   disk_size        = 8                # GB; must be >= template disk size
  #   tags             = ["iac", "lab", "clone"]
  # })

  containers = {
    "my-clone-1" = merge(local.container_defaults, {
      vmid            = 310
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

    "my-clone-2" = merge(local.container_defaults, {
      vmid            = 311
      node_name       = "pve-t1"
      hostname        = "my-clone-2"
      ipv4_address    = "dhcp"
      ipv4_gateway    = null
      clone_vm_id     = 100
      clone_node_name = "pve-t0"
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
  # To add a VM: copy the example below into vms = { }, adjust the fields, and
  # run: terraform apply
  # To remove a VM: delete its block and run: terraform apply
  #
  # VMs use cloud-init for first-boot configuration (hostname, IP, SSH keys).
  # The disk_file_id must point to a cloud image already downloaded to the node.
  # To download a cloud image via Terraform, see:
  #   https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file
  #
  # "my-vm-1" = merge(local.vm_defaults, {
  #   vmid             = 301              # unique ID across the whole cluster
  #   node_name        = "pve-t0"         # node to create the VM on
  #   name             = "my-vm-1"        # VM display name in Proxmox
  #   ipv4_address     = "10.0.0.50/24"   # static CIDR required for VMs (no DHCP via cloud-init)
  #   ipv4_gateway     = "10.0.0.3"       # default gateway
  #   disk_file_id     = "local:iso/ubuntu-24.04-server-cloudimg-amd64.img"
  #   cpu_cores        = 2                # override default (optional)
  #   memory_dedicated = 2048             # MB; override default (optional)
  #   disk_size        = 20               # GB; override default (optional)
  #   ci_user          = "ubuntu"         # cloud-init user created on first boot
  #   ssh_public_keys  = [file("~/.ssh/id_rsa.pub")]  # list of SSH public keys for ci_user
  #   tags             = ["iac", "lab", "vm"]
  # })

  vms = {
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
  clone_full       = each.value.clone_full
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
