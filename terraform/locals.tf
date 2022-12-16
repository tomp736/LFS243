# ./locals.tf

locals {
  config          = jsondecode(file("files/config.json"))
  config_networks = { for network in local.config.networks : network.id => network }
  config_nodes    = { for node in local.config.nodes : node.id => node if node.state == "enabled" }
}