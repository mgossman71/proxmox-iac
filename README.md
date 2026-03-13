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

### LXC templates

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

### QEMU cloud images

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

Add a new entry to the `containers` map. The `merge()` call applies the
stack-wide defaults — only specify fields that differ from them:

```hcl
containers = {
  "lxc-test-1" = merge(local.container_defaults, {
    vmid             = 200
    node_name        = "pve-t0"
    hostname         = "lxc-test-1"
    ipv4_address     = "dhcp"
    ipv4_gateway     = null
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    tags             = ["iac", "lab"]
  })

  # Add a second container — only override what differs from the defaults
  "lxc-test-2" = merge(local.container_defaults, {
    vmid             = 201
    node_name        = "pve-t1"        # different node
    hostname         = "lxc-test-2"
    ipv4_address     = "10.0.0.98/24"  # static IP
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cpu_cores        = 4               # override default of 2
    memory_dedicated = 2048            # override default of 1024
    tags             = ["iac", "lab", "db"]
  })
}
```

Then run `terraform apply`.

### Adding a QEMU VM

Add a new entry to the `vms` map in the same file:

```hcl
vms = {
  "vm-test-1" = merge(local.vm_defaults, {
    vmid             = 300
    node_name        = "pve-t0"
    name             = "vm-test-1"
    ipv4_address     = "10.0.0.50/24"
    disk_file_id     = "local:iso/noble-server-cloudimg-amd64.img"
    cpu_cores        = 4
    memory_dedicated = 4096
    disk_size        = 40
    ssh_public_keys  = [file("~/.ssh/id_rsa.pub")]
    tags             = ["iac", "lab"]
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
  ipv4_gateway     = "10.0.0.3"
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

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `vmid` | yes | — | Unique container ID |
| `node_name` | yes | — | Proxmox node name |
| `hostname` | yes | — | Container hostname |
| `ipv4_address` | yes | — | CIDR address or `"dhcp"` |
| `ipv4_gateway` | no | `null` | Gateway — omit when using DHCP |
| `template_file_id` | yes | — | LXC template file ID |
| `bridge` | no | `vmbr0` | Network bridge |
| `datastore_id` | no | `local-lvm` | Storage for root disk |
| `disk_size` | no | `8` | Root disk size in GB |
| `os_type` | no | `ubuntu` | OS type hint |
| `cpu_cores` | no | `2` | vCPU cores |
| `memory_dedicated` | no | `1024` | RAM in MB |
| `memory_swap` | no | `512` | Swap in MB |
| `unprivileged` | no | `true` | Run unprivileged |
| `nesting` | no | `true` | Allow nested virtualisation |
| `started` | no | `true` | Start after creation |
| `tags` | no | `["iac"]` | Proxmox tags |

### `modules/vm` — QEMU VM

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `vmid` | yes | — | Unique VM ID |
| `node_name` | yes | — | Proxmox node name |
| `name` | yes | — | VM name |
| `ipv4_address` | yes | — | CIDR address or `"dhcp"` |
| `ipv4_gateway` | yes | — | Default gateway |
| `disk_file_id` | yes | — | Cloud image file ID |
| `bridge` | no | `vmbr0` | Network bridge |
| `datastore_id` | no | `local-lvm` | Storage for primary disk |
| `disk_size` | no | `20` | Disk size in GB |
| `cpu_cores` | no | `2` | vCPU cores |
| `cpu_type` | no | `x86-64-v2-AES` | CPU model |
| `memory_dedicated` | no | `2048` | RAM in MB |
| `ci_user` | no | `ubuntu` | cloud-init user |
| `ssh_public_keys` | no | `[]` | SSH public keys for cloud-init |
| `agent_enabled` | no | `true` | Enable QEMU guest agent |
| `started` | no | `true` | Start after creation |
| `tags` | no | `["iac"]` | Proxmox tags |

---

## Inspecting deployed state

After `terraform apply`, view what was deployed:

```bash
# Summary of all containers and VMs in the stack
terraform output

# Detailed state of a specific resource
terraform state show 'module.containers["lxc-test-1"].proxmox_virtual_environment_container.this'
```
