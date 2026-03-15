locals {
  # ── Stack-wide defaults ──────────────────────────────────────────────────────
  # These apply to every container/VM unless overridden in the instance map.
  # Change a default here and it propagates to all instances that haven't
  # explicitly set that field.

  container_defaults = {
    ipv4_gateway     = null
    bridge           = "vmbr1"
    datastore_id     = "truenas-nvme"
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
    ipv4_gateway     = null
    bridge           = "vmbr1"
    datastore_id     = "truenas-nvme"
    cpu_cores        = 2
    cpu_type         = "x86-64-v2-AES"
    memory_dedicated = 2048
    disk_size        = 20
    ci_user          = "ubuntu"
    ssh_public_keys  = []
    agent_enabled    = true
    started          = true
    tags             = ["iac", "lab"]
    # Provisioning mode — set exactly one per VM.
    # disk_file_id: provision from a cloud image already downloaded to the node.
    # clone_vm_id:  clone an existing QEMU template (faster, pre-configured).
    # clone_node_name: source node for clone_vm_id (required for cross-node clones).
    disk_file_id       = null
    clone_vm_id        = null
    clone_node_name    = null
    cloud_init_enabled = true
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
  #   Proxmox automatically creates a full clone when cloning cross-node (node_name differs
  #   from clone_node_name). Same-node clones from a template are also full by default.
  #   Cross-node cloning requires the template's storage to be accessible from both nodes
  #   (e.g. shared NFS or Ceph).
  #
  #   clone_node_name is only required when the template lives on a DIFFERENT node
  #   than the one you are deploying to.
  #
  # "my-clone-1" = merge(local.container_defaults, {
  #   vmid             = 220              # unique ID across the whole cluster
  #   node_name        = "pve-t1"         # node to create the clone ON (can differ from template node)
  #   hostname         = "my-clone-1"
  #   ipv4_address     = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.50/24"
  #   ipv4_gateway     = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
  #   clone_vm_id      = 100              # VMID of the source LXC template
  #   clone_node_name  = "pve-t0"         # node where VMID 100 lives (required for cross-node)
  #   cpu_cores        = 2                # override template value (optional)
  #   memory_dedicated = 1024             # MB; override template value (optional)
  #   disk_size        = 8                # GB; must be >= template disk size
  #   tags             = ["iac", "lab", "clone"]
  # })

  containers = {
    "lxc-clone-1" = merge(local.container_defaults, {
      vmid            = 900
      node_name       = "pve4"
      hostname        = "lxc-clone-1"
      datastore_id    = "truenas-nvme"
      ipv4_address    = "dhcp"
      ipv4_gateway    = null
      clone_vm_id     = 700
      clone_node_name = "pve3"
      cpu_cores       = 2
      memory_dedicated = 1024
      tags            = ["iac", "lab"]
    })

    "lxc-clone-2" = merge(local.container_defaults, {
      vmid            = 901
      node_name       = "pve4"
      hostname        = "lxc-clone-2"
      datastore_id    = "truenas-nvme"
      ipv4_address    = "dhcp"
      ipv4_gateway    = null
      clone_vm_id     = 700
      clone_node_name = "pve3"
      cpu_cores       = 2
      memory_dedicated = 1024
      tags            = ["iac", "lab"]
    })
  }

  # ── QEMU VMs ─────────────────────────────────────────────────────────────────
  # To add a VM: copy an example below into vms = { }, adjust the fields, and
  # run: terraform apply
  # To remove a VM: delete its block and run: terraform apply
  #
  # Choose ONE provisioning method per VM:
  #
  #   METHOD 1 — Image (cloud image)
  #   Provisions a fresh VM from a cloud image already downloaded to the node.
  #   Use this when you want a clean OS install configured entirely via cloud-init.
  #   Requires the image file to exist on the target node's datastore.
  #
  # "my-vm-1" = merge(local.vm_defaults, {
  #   vmid             = 400              # unique ID across the whole cluster
  #   node_name        = "pve-t0"         # node to create the VM on
  #   name             = "my-vm-1"        # VM display name in Proxmox
  #   ipv4_address     = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.50/24"
  #   ipv4_gateway     = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
  #   disk_file_id     = "local:iso/ubuntu-24.04-server-cloudimg-amd64.img"
  #   cpu_cores        = 2                # override default (optional)
  #   memory_dedicated = 2048             # MB; override default (optional)
  #   disk_size        = 20               # GB; override default (optional)
  #   ci_user          = "ubuntu"         # cloud-init user created on first boot
  #   ssh_public_keys  = [file("~/.ssh/id_rsa.pub")]  # SSH public keys for ci_user
  #   tags             = ["iac", "lab", "vm"]
  # })
  #
  #   METHOD 2 — Clone (from an existing QEMU template)
  #   Clones a VM you have already built and converted to a template in Proxmox.
  #   Use this when you want a VM with software and configuration already baked in.
  #   Always creates a full (independent) clone. The cloned disk is placed on
  #   datastore_id. Cross-node cloning requires shared storage (NFS, Ceph, etc.).
  #   If the template has cloud-init, ipv4_address/ci_user/ssh_public_keys apply
  #   on first boot; otherwise those fields are ignored.
  #
  # Example A — clone with cloud-init (VMID 501, template has cloud-init installed)
  # cloud-init will set the IP, user, and SSH keys on first boot.
  #
  # "my-vm-clone-1" = merge(local.vm_defaults, {
  #   vmid               = 410              # unique ID across the whole cluster
  #   node_name          = "pve-t0"         # node to create the clone ON
  #   name               = "my-vm-clone-1"  # VM display name in Proxmox
  #   ipv4_address       = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.60/24"
  #   ipv4_gateway       = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
  #   clone_vm_id        = 501              # VMID 501 has cloud-init installed
  #   clone_node_name    = null             # null = same node as template; set "pve-t0" for cross-node
  #   datastore_id       = "truenas-nvme"      # datastore for the cloned disk
  #   cloud_init_enabled = true             # true because VMID 501 has cloud-init
  #   cpu_cores          = 2                # override template value (optional)
  #   memory_dedicated   = 2048             # MB; override template value (optional)
  #   tags               = ["iac", "lab", "clone"]
  # })
  #
  # Example B — clone without cloud-init (VMID 500, no cloud-init installed)
  # VM boots exactly as the template left it; IP/user must be managed manually.
  #
  # "my-vm-clone-2" = merge(local.vm_defaults, {
  #   vmid               = 411
  #   node_name          = "pve-t0"
  #   name               = "my-vm-clone-2"
  #   ipv4_address       = "dhcp"           # ignored — cloud-init not present
  #   ipv4_gateway       = null             # ignored — cloud-init not present
  #   clone_vm_id        = 500              # VMID 500 has NO cloud-init installed
  #   clone_node_name    = null
  #   datastore_id       = "truenas-nvme"
  #   cloud_init_enabled = false            # false because VMID 500 has no cloud-init
  #   tags               = ["iac", "lab", "clone"]
  # })

  vms = {
    # Same-node clone — template (501) and new VM both on pve-t0
   "vm-test-1" = merge(local.vm_defaults, {
     vmid               = 800
     node_name          = "pve4"
     name               = "vm-test-1"
     ipv4_address       = "dhcp"
     ipv4_gateway       = null
     clone_vm_id        = 600
     clone_node_name    = "pve3"
     datastore_id       = "truenas-nvme"
     cloud_init_enabled = true
     tags               = ["iac", "lab"]
   })
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
  disk_file_id       = each.value.disk_file_id
  clone_vm_id        = each.value.clone_vm_id
  clone_node_name    = each.value.clone_node_name
  cloud_init_enabled = each.value.cloud_init_enabled
  bridge             = each.value.bridge
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
