# ./main.tf

module "networks" {
  for_each = local.config_networks
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/network?ref=main"


  network_name          = each.value.name
  network_ip_range      = each.value.ip_range
  network_subnet_ranges = each.value.subnet_ranges
}

module "node_group" {
  source     = "./modules/node_group"
  nodes      = local.config_nodes
  public_key = var.public_key
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("files/templates/hosts.tftpl", {
    nodes = [for node in module.node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
  })
  filename = "ansible_hosts"
}