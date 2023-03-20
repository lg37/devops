resource "azurerm_firewall_policy_rule_collection_group" "hubfirewall-policy-rules" {
  name               = "hubfirewall-policy-rules"
  firewall_policy_id = azurerm_firewall_policy.hubfirewall-policy.id
  priority           = 500
  application_rule_collection {
    name     = "app_rule_collection1"
    priority = 500
    action   = "Allow"
    rule {
      name = "allow_google"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.2.1.4"]
      destination_fqdns = ["*.google.com"]
    }
  }

  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 400
    action   = "Allow"
    rule {
      name                  = "network_rule_collection1_rule1"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.2.1.4"]
      destination_addresses = ["192.168.1.1", "192.168.1.2"]
      destination_ports     = ["80", "1000-2000"]
    }
  }

  nat_rule_collection {
    name     = "nat_rule_collection1"
    priority = 300
    action   = "Dnat"
    rule {
      name                = "ssh_nat"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = data.azurerm_public_ip.firewall-pip.ip_address
      destination_ports   = ["22"]
      translated_address  = "10.2.1.4"
      translated_port     = "22"
    }
  }
}