output "containers" {
  description = "All deployed LXC containers in this stack"
  value = {
    for k, v in module.containers : k => {
      id           = v.id
      hostname     = v.hostname
      ipv4_address = v.ipv4_address
      node_name    = v.node_name
    }
  }
}

output "vms" {
  description = "All deployed QEMU VMs in this stack"
  value = {
    for k, v in module.vms : k => {
      id           = v.id
      name         = v.name
      ipv4_address = v.ipv4_address
      node_name    = v.node_name
    }
  }
}
