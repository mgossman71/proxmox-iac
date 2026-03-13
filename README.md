# proxmox-iac

Terraform infrastructure-as-code for deploying LXC containers and QEMU VMs on Proxmox using the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) provider.

---

## Repository structure

```
proxmox-iac/
├── modules/
│   ├── lxc/        # Reusable module for LXC containers
│   └── vm/         # Reusable module for QEMU VMs
└── stacks/
    └── lab/        # Example stack — has its own independent state
```

A **stack** is a directory under `stacks/` with its own Terraform state. Stacks are fully independent — deploying or destroying one has no effect on any other.

A **module** is a reusable building block. You never run `terraform` inside a module directory. Modules are called from stacks.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- Network access to your Proxmox API endpoint
- A Proxmox API token (see below)

---

## Step 1 — Create a Proxmox API token

Terraform authenticates to Proxmox using an API token, not a password.

### In the Proxmox web UI

1. Log in to your Proxmox web UI (e.g. `https://10.0.0.132:8006`)
2. Navigate to **Datacenter → Permissions → Users**
3. Create a dedicated user (e.g. `terraform@pam`) or use an existing one
4. Navigate to **Datacenter → Permissions → API Tokens**
5. Click **Add**, select your user, give the token a name (e.g. `iac`)
6. Uncheck **Privilege Separation** so the token inherits the user's permissions
7. Click **Add** — copy the token secret immediately, it is only shown once

The token ID will be in the format `user@realm!token-name` (e.g. `terraform@pam!iac`).

### Grant permissions

Navigate to **Datacenter → Permissions** and add a permission entry:

| Path | User/Token | Role |
|------|-----------|------|
| `/` | `terraform@pam!iac` | `PVEAdmin` or `Administrator` |

For a least-privilege setup, scope the path to `/vms` and `/nodes` with `PVEVMAdmin`.

### Via the Proxmox CLI (alternative)

```bash
# On a Proxmox node
pveum user add terraform@pam
pveum aclmod / -user terraform@pam -role PVEAdmin
pveum user token add terraform@pam iac --privsep=0
```

---

## Step 2 — Find available images and templates

### LXC templates (image method)

List templates already downloaded to a node:

```bash
# On a Proxmox node
pveam list local
```

Download a template from the Proxmox template repository:

```bash
# List available templates
pveam available --section system

# Download Ubuntu 24.04
pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

The `template_file_id` value for Terraform follows this format:

```
<storage>:vztmpl/<filename>
# e.g.
local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```

### LXC templates (clone method)

If you have built a container and converted it to a template in Proxmox, you can clone it instead of provisioning from a raw tarball. Cloned containers inherit all installed software and configuration from the template.

Find the VMID of your LXC template:

```bash
# On a Proxmox node — templates show status "stopped" with a lock icon in the UI
pct list
```

Note the VMID of your template (e.g. `100`). That is the value used for `clone_vm_id` in Terraform. If the template lives on shared storage (NFS, Ceph, etc.), it can be cloned to any node in the cluster.

### QEMU cloud images (image method)

Download a cloud image to Proxmox (run on a node):

```bash
# Ubuntu 24.04 cloud image
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Upload to Proxmox storage
qm importdisk 9999 noble-server-cloudimg-amd64.img local-lvm
# or upload via the UI: Datacenter → Storage → local → Content → Upload
```

The `disk_file_id` value for Terraform:

```
<storage>:iso/<filename>
# e.g.
local:iso/noble-server-cloudimg-amd64.img
```

### QEMU VM templates (clone method)

If you have built a VM and converted it to a template in Proxmox, you can clone it instead of provisioning from a cloud image. Cloned VMs inherit all installed software and configuration from the template.

Find the VMID of your QEMU template:

```bash
# On a Proxmox node
qm list
```

Note the VMID of your template (e.g. `500`). That is the value used for `clone_vm_id` in Terraform.

To verify whether a template has cloud-init (which allows Terraform to configure IP, hostname, and SSH keys on first boot):

```bash
qm config <vmid>
```

Look for a line containing `cloudinit` (e.g. `ide2: local-lvm:vm-501-cloudinit`). If present, set `cloud_init_enabled = true` in the VM entry and Terraform will apply IP/user/SSH config on first boot. If absent, set `cloud_init_enabled = false` — the VM will boot exactly as the template left it and cloud-init fields are ignored.

Cross-node cloning requires the template's storage to be accessible from both nodes (e.g. shared NFS or Ceph).

### List available storage and existing VMs via API

```bash
# List storage on a node
pvesm status

# List all VMs and containers
qm list
pct list
```

---

## Step 3 — Set environment variables

Credentials are never stored in files. Export these in your shell before running any Terraform commands:

```bash
export PROXMOX_VE_ENDPOINT='https://10.0.0.132:8006/'
export PROXMOX_VE_API_TOKEN='terraform@pam!iac=your-token-secret-here'
export PROXMOX_VE_INSECURE='true'   # omit if you have a valid TLS certificate
```

> **Note:** Use single quotes around the token value. Double quotes cause bash to
> interpret the `!` character as a history expansion event.

To avoid re-exporting on every session, add them to a `.envrc` file in the repo
root and use [direnv](https://direnv.net/), or add them to your shell profile.
**Never commit credential values to git.**

---

## Step 4 — Deploy a stack

```bash
cd stacks/lab

terraform init     # download providers, once per stack
terraform plan     # preview what will be created/changed/destroyed
terraform apply    # apply the changes
```

To destroy everything in a stack:

```bash
terraform destroy
```

---

## How to add or remove machines

All machine definitions live in `stacks/<stack-name>/main.tf`. Open that file and
edit the `containers` or `vms` map.

### Adding an LXC container

There are two provisioning methods. Choose one per container.

#### Method 1 — Image (tarball template)

Provisions a fresh container from an LXC tarball already downloaded to the node. Use this when you want a clean OS with no pre-installed software.

```hcl
containers = {
  "lxc-test-1" = merge(local.container_defaults, {
    vmid             = 200
    node_name        = "pve-t0"
    hostname         = "lxc-test-1"
    ipv4_address     = "dhcp"           # or static: "10.0.0.50/24"
    ipv4_gateway     = null             # null for DHCP; set for static
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    tags             = ["iac", "lab", "lxc"]
  })
}
```

#### Method 2 — Clone (from an existing LXC template)

Clones a container you have already built and marked as a template in Proxmox. Use this when you want a container that already has software and configuration baked in. Cross-node cloning requires the template to be on shared storage (NFS, Ceph, etc.).

```hcl
containers = {
  # Same-node clone — template and new container on the same node
  "my-clone-1" = merge(local.container_defaults, {
    vmid            = 310
    node_name       = "pve-t0"
    hostname        = "my-clone-1"
    ipv4_address    = "dhcp"
    ipv4_gateway    = null
    clone_vm_id     = 100              # VMID of the LXC template
    clone_node_name = null             # null when template is on the same node
    tags            = ["iac", "lab", "clone"]
  })

  # Cross-node clone — template on pve-t0, deploy to pve-t1
  "my-clone-2" = merge(local.container_defaults, {
    vmid            = 311
    node_name       = "pve-t1"         # node to deploy the clone ON
    hostname        = "my-clone-2"
    ipv4_address    = "dhcp"
    ipv4_gateway    = null
    clone_vm_id     = 100              # VMID of the LXC template
    clone_node_name = "pve-t0"         # node where the template lives
    tags            = ["iac", "lab", "clone"]
  })
}
```

Then run `terraform apply`.

### Adding a QEMU VM

There are two provisioning methods. Choose one per VM.

#### Method 1 — Image (cloud image)

Provisions a fresh VM from a cloud image already downloaded to the node. Use this when you want a clean OS configured entirely via cloud-init on first boot.

```hcl
vms = {
  "my-vm-1" = merge(local.vm_defaults, {
    vmid             = 400
    node_name        = "pve-t0"
    name             = "my-vm-1"
    ipv4_address     = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.50/24"
    ipv4_gateway     = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
    disk_file_id     = "local:iso/ubuntu-24.04-server-cloudimg-amd64.img"
    cpu_cores        = 2                # override default (optional)
    memory_dedicated = 2048             # MB; override default (optional)
    disk_size        = 20               # GB; override default (optional)
    ci_user          = "ubuntu"         # cloud-init user created on first boot
    ssh_public_keys  = [file("~/.ssh/id_rsa.pub")]
    tags             = ["iac", "lab", "vm"]
  })
}
```

#### Method 2 — Clone (from an existing QEMU template)

Clones a VM you have already built and converted to a template in Proxmox. Use this when you want a VM with software and configuration already baked in. Always creates a full (independent) clone. The cloned disk is placed on `datastore_id`. Cross-node cloning requires shared storage (NFS, Ceph, etc.).

If the template has cloud-init, `ipv4_address`, `ci_user`, and `ssh_public_keys` are applied on first boot. If not, those fields are ignored and the VM boots with whatever the template had configured.

```hcl
vms = {
  # Same-node clone — template and new VM on the same node
  "my-vm-clone-1" = merge(local.vm_defaults, {
    vmid               = 410
    node_name          = "pve-t0"
    name               = "my-vm-clone-1"
    ipv4_address       = "dhcp"           # "dhcp" or static CIDR e.g. "10.0.0.60/24"
    ipv4_gateway       = null             # null for DHCP; set IP e.g. "10.0.0.3" for static
    clone_vm_id        = 501              # VMID of the QEMU template (with cloud-init)
    clone_node_name    = null             # null when template is on the same node
    datastore_id       = "local-lvm"      # datastore for the cloned disk
    cloud_init_enabled = true             # true because this template has cloud-init
    cpu_cores          = 2                # override template value (optional)
    memory_dedicated   = 2048             # MB; override template value (optional)
    tags               = ["iac", "lab", "clone"]
  })

  # Cross-node clone — template on pve-t0, deploy to pve-t1
  "my-vm-clone-2" = merge(local.vm_defaults, {
    vmid               = 411
    node_name          = "pve-t1"         # node to deploy the clone ON
    name               = "my-vm-clone-2"
    ipv4_address       = "dhcp"           # ignored when cloud_init_enabled = false
    ipv4_gateway       = null             # ignored when cloud_init_enabled = false
    clone_vm_id        = 500              # VMID of the QEMU template (no cloud-init)
    clone_node_name    = "pve-t0"         # node where the template lives
    datastore_id       = "local-lvm"      # datastore for the cloned disk
    cloud_init_enabled = false            # set false if template has no cloud-init installed
    tags               = ["iac", "lab", "clone"]
  })
}
```

### Removing a machine

Delete its entry from the map and run `terraform apply`. Terraform will destroy
only that machine and leave all others untouched.

---

## Stack-wide defaults

Each stack defines defaults at the top of `main.tf` that apply to every machine
unless overridden per instance:

```hcl
container_defaults = {
  ipv4_gateway     = null        # null = DHCP; override per instance for static
  bridge           = "vmbr0"
  datastore_id     = "local-lvm"
  cpu_cores        = 2
  memory_dedicated = 1024
  ...
}
```

Change a default here to propagate it to all machines that haven't explicitly
overridden that field.

---

## Creating a new stack

A stack is just a directory with three files. Copy an existing one:

```bash
cp -r stacks/lab stacks/production
```

Then edit `stacks/production/main.tf`:

1. Update `container_defaults` / `vm_defaults` for the new environment
   (different gateway, datastore, network bridge, etc.)
2. Define the machines for this stack in the `containers` and `vms` maps
3. Clear out any machines copied from the template stack

Initialize and deploy:

```bash
cd stacks/production
terraform init
terraform apply
```

Each stack has its own `.terraform/` directory and state file — `production` and
`lab` are completely independent.

---

## Module reference

### `modules/lxc` — LXC container

Set exactly one of `template_file_id` or `clone_vm_id` per container.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `vmid` | yes | — | Unique container ID |
| `node_name` | yes | — | Proxmox node to deploy on |
| `hostname` | yes | — | Container hostname |
| `ipv4_address` | yes | — | CIDR address or `"dhcp"` |
| `ipv4_gateway` | no | `null` | Gateway — omit when using DHCP |
| `template_file_id` | no* | `null` | LXC tarball template file ID — use for image provisioning |
| `clone_vm_id` | no* | `null` | VMID of an existing LXC template to clone |
| `clone_node_name` | no | `null` | Source node for `clone_vm_id` — required for cross-node cloning |
| `bridge` | no | `vmbr0` | Network bridge |
| `datastore_id` | no | `local-lvm` | Storage for root disk |
| `disk_size` | no | `8` | Root disk size in GB |
| `os_type` | no | `ubuntu` | OS type hint (image method only) |
| `cpu_cores` | no | `2` | vCPU cores |
| `memory_dedicated` | no | `1024` | RAM in MB |
| `memory_swap` | no | `512` | Swap in MB |
| `unprivileged` | no | `true` | Run unprivileged |
| `nesting` | no | `true` | Allow nested virtualisation |
| `started` | no | `true` | Start after creation |
| `tags` | no | `["iac"]` | Proxmox tags |

*Exactly one of `template_file_id` or `clone_vm_id` must be provided.

### `modules/vm` — QEMU VM

Set exactly one of `disk_file_id` or `clone_vm_id` per VM.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `vmid` | yes | — | Unique VM ID |
| `node_name` | yes | — | Proxmox node to deploy on |
| `name` | yes | — | VM display name in Proxmox |
| `ipv4_address` | yes | — | CIDR address (e.g. `10.0.0.50/24`) or `"dhcp"` |
| `ipv4_gateway` | no | `null` | Default gateway — omit when using DHCP |
| `disk_file_id` | no* | `null` | Cloud image file ID — use for image provisioning |
| `clone_vm_id` | no* | `null` | VMID of an existing QEMU template to clone |
| `clone_node_name` | no | `null` | Source node for `clone_vm_id` — required for cross-node cloning |
| `bridge` | no | `vmbr0` | Network bridge |
| `datastore_id` | no | `local-lvm` | Storage for the disk (image method) or cloned disk (clone method) |
| `disk_size` | no | `20` | Disk size in GB (image method only; clone inherits template size) |
| `cpu_cores` | no | `2` | vCPU cores |
| `cpu_type` | no | `x86-64-v2-AES` | CPU model |
| `memory_dedicated` | no | `2048` | RAM in MB |
| `cloud_init_enabled` | no | `true` | Apply cloud-init on first boot. Set `false` when cloning a template without cloud-init installed |
| `ci_user` | no | `ubuntu` | cloud-init user (ignored when `cloud_init_enabled = false`) |
| `ssh_public_keys` | no | `[]` | SSH public keys for cloud-init user (ignored when `cloud_init_enabled = false`) |
| `agent_enabled` | no | `true` | Enable QEMU guest agent |
| `started` | no | `true` | Start after creation |
| `tags` | no | `["iac"]` | Proxmox tags |

*Exactly one of `disk_file_id` or `clone_vm_id` must be provided.

---

## Inspecting deployed state

After `terraform apply`, view what was deployed:

```bash
# Summary of all containers and VMs in the stack
terraform output

# Detailed state of a specific resource
terraform state show 'module.containers["lxc-test-1"].proxmox_virtual_environment_container.this'
```
