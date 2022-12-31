# ./main.tf

module "networks" {
  for_each = local.config_networks
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/network?ref=1.0.2"


  network_name          = each.value.name
  network_ip_range      = each.value.ip_range
  network_subnet_ranges = each.value.subnet_ranges
}

data "hetznerdns_zone" "dns_zone" {
  name = "labrats.work"
}

module "node_group" {
  source = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/node_group?ref=1.0.2"
  nodes  = local.config_nodes
  public_keys = [
    var.public_key
  ]
  sshd_config = {
    ssh_user = "sysadmin"
    ssh_port = "2222"
  }
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

resource "hetznerdns_record" "dns_record" {
  for_each = module.node_group.nodes

  zone_id = data.hetznerdns_zone.dns_zone.id
  name    = replace("*.${each.value.name}", ".labrats.work", "")
  value   = each.value.ipv4_address
  type    = "A"
  ttl     = 60
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