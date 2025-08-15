# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=core.dev.terraform.tfstate" -backend-config="storage_account_name=enter your storage account here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
# terraform plan -var-file="dev.tfvars"
# terraform apply --auto-approve -var-file="dev.tfvars"

# backend configuration
terraform {
  backend "azurerm" {}
}

# provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# provider used for the domain controller subscription
provider "azurerm" {
  alias           = "domain_subscription"
  features {}
  subscription_id = "Enter your subscription id here"  
}

# data block to get the client config for the Key vault
data "azurerm_client_config" "current" {}

locals {
  json = {
    run = jsondecode(file("${path.module}/../../params/run.jsonc"))
  }
  
  tags = {
    ProdRef      = local.json.run.prodref
    ManagedBy    = local.json.run.managedby
    Environment  = local.json.run.envShort
    Workload       = var.workload
  }
}

resource "azurerm_resource_group" "rg-core" {
  name     = "rg-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location = var.resource_group_location
  tags = local.tags
}

resource "azurerm_virtual_network" "vnet-cascade" {
  depends_on = [ azurerm_network_security_group.nsg-iis, azurerm_network_security_group.nsg-sql, azurerm_network_security_group.nsg-app, azurerm_network_security_group.nsg-mgmt ]  
  name                 = "vnet-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  address_space        = var.vnet_address_space
  location             = azurerm_resource_group.rg-core.location
  resource_group_name  = azurerm_resource_group.rg-core.name
  tags = local.tags
}

resource "azurerm_subnet" "snet-iis" {
  depends_on = [ azurerm_network_security_group.nsg-iis]
    name                 = "snet-${local.json.run.productShort}-iis-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.rg-core.name
  virtual_network_name = azurerm_virtual_network.vnet-cascade.name
  address_prefixes     = var.snet_iis_address_prefix
}

resource "azurerm_subnet" "snet-sql" {
  depends_on = [ azurerm_network_security_group.nsg-sql]
  name                 = "snet-${local.json.run.productShort}-sql-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.rg-core.name
  virtual_network_name = azurerm_virtual_network.vnet-cascade.name
  address_prefixes     = var.snet_sql_address_prefix
}

resource "azurerm_subnet" "snet-mgmt" {
  depends_on = [ azurerm_network_security_group.nsg-mgmt]
  name                 = "snet-${local.json.run.productShort}-mgmt-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.rg-core.name
  virtual_network_name = azurerm_virtual_network.vnet-cascade.name
  address_prefixes     = var.snet_mgmt_address_prefix
}
resource "azurerm_subnet" "snet-app" {
  depends_on = [ azurerm_network_security_group.nsg-app]
  name                 = "snet-${local.json.run.productShort}-app-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.rg-core.name
  virtual_network_name = azurerm_virtual_network.vnet-cascade.name
  address_prefixes     = var.snet_app_address_prefix
}
resource "azurerm_subnet" "snet-rbq" {
  depends_on = [ azurerm_network_security_group.nsg-rbq]
  name                 = "snet-${local.json.run.productShort}-rbq-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.rg-core.name
  virtual_network_name = azurerm_virtual_network.vnet-cascade.name
  address_prefixes     = var.snet_rbq_address_prefix
}

resource "azurerm_subnet" "snet-sqlmi" {
  depends_on = [ azurerm_network_security_group.nsg-sqlmi]
  name                 = "snet-${local.json.run.productShort}-sqlmi-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.rg-core.name
  virtual_network_name = azurerm_virtual_network.vnet-cascade.name
  address_prefixes     = var.snet_sqlmi_address_prefix

  delegation {
    name = "delegation-sql-managed-instance"
    
    service_delegation {
      name    = "Microsoft.Sql/managedInstances"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}
resource "azurerm_network_security_group" "nsg-iis" {
  depends_on = [ azurerm_resource_group.rg-core ]
  name                ="nsg-${local.json.run.productShort}-iis-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name

security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSQL"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_network_security_group" "nsg-sqlmi" {
  depends_on = [ azurerm_resource_group.rg-core ]
  name                ="nsg-${local.json.run.productShort}-sqlmi-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name

security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSQL"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_network_security_group" "nsg-sql" {
  depends_on = [ azurerm_resource_group.rg-core ]
  name                = "nsg-${local.json.run.productShort}-sql-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name

security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSQL"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_network_security_group" "nsg-mgmt" {
  depends_on = [ azurerm_resource_group.rg-core ]
  name                = "nsg-${local.json.run.productShort}-mgmt-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name

security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSQL"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_network_security_group" "nsg-app" {
  depends_on = [ azurerm_resource_group.rg-core ]
  name                = "nsg-${local.json.run.productShort}-app-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name

security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSQL"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_network_security_group" "nsg-rbq" {
  depends_on = [ azurerm_resource_group.rg-core ]
  name                = "nsg-${local.json.run.productShort}-rbq-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name

security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "iis" {
  subnet_id                 = azurerm_subnet.snet-iis.id
  network_security_group_id = azurerm_network_security_group.nsg-iis.id
}

resource "azurerm_subnet_network_security_group_association" "sql" {
  subnet_id                 = azurerm_subnet.snet-sql.id
  network_security_group_id = azurerm_network_security_group.nsg-sql.id
}

resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.snet-mgmt.id
  network_security_group_id = azurerm_network_security_group.nsg-mgmt.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.snet-app.id
  network_security_group_id = azurerm_network_security_group.nsg-app.id
}

resource "azurerm_subnet_network_security_group_association" "sqlmi" {
  subnet_id                 = azurerm_subnet.snet-sqlmi.id
  network_security_group_id = azurerm_network_security_group.nsg-sqlmi.id
}

resource "azurerm_subnet_network_security_group_association" "rbq" {
  subnet_id                 = azurerm_subnet.snet-rbq.id
  network_security_group_id = azurerm_network_security_group.nsg-rbq.id
}

# Loab balancer

resource "azurerm_public_ip" "lb-ip" {
  name                = "lbip-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name
  allocation_method   = "Static"
  tags = local.tags
}

resource "azurerm_lb" "lb" {
  name                = "lbe-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb-ip.id
  }
  tags = local.tags
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "bepool-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  loadbalancer_id     = azurerm_lb.lb.id
}

resource "azurerm_lb_outbound_rule" "prod_outbound" {
  name                = "obrule-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }

  allocated_outbound_ports = 0    # 0 = Azure default allocation
  idle_timeout_in_minutes  = 4
  enable_tcp_reset         = true
}


resource "azurerm_route_table" "routetable" {
  name                = "rt-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name = azurerm_resource_group.rg-core.name
  location            = azurerm_resource_group.rg-core.location
  tags = local.tags
}

resource "azurerm_subnet_route_table_association" "rta" {
    depends_on = [ azurerm_route_table.routetable ]
    subnet_id            = azurerm_subnet.snet-sqlmi.id
    route_table_id       = azurerm_route_table.routetable.id
}

resource "azurerm_key_vault" "core-kv" {
  name                = "kv-${local.json.run.productShort}-${local.json.run.envShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.rg-core.location
  resource_group_name = azurerm_resource_group.rg-core.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  enable_rbac_authorization = true
  tags = local.tags
 }

# create a private dns zone and link it to the virtual network

resource "azurerm_private_dns_zone" "core-dns-zone" {
  name                = "${local.json.run.productShort}-${local.json.run.envShort}.com"
  resource_group_name = azurerm_resource_group.rg-core.name
  tags = local.tags
}

#link the private dns zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "core-dns-zone-link" {
  name                  = "link-${local.json.run.productShort}-${local.json.run.envShort}-${var.workload}"
  resource_group_name   = azurerm_resource_group.rg-core.name
  private_dns_zone_name = azurerm_private_dns_zone.core-dns-zone.name
  virtual_network_id    = azurerm_virtual_network.vnet-cascade.id
  registration_enabled  = true
}

resource "random_password" "iisvm" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric = true
  override_special = "!@#$%&*()-_=+"
}

resource "random_password" "appvm" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric = true
  override_special = "!@#$%&*()-_=+"
}

resource "random_password" "sqlmi" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric = true
  override_special = "!@#$%&*()-_=+"
}

resource "random_password" "rbqvm" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric = true
  override_special = "!@#$%&*()-_=+"
}

# create few secrets under the key vault with random values that are compatibel with VM passwords
resource "azurerm_key_vault_secret" "iisvmpassword" {
  name         = "iisvmpassword"
  value        = random_password.iisvm.result
  key_vault_id = azurerm_key_vault.core-kv.id
}
resource "azurerm_key_vault_secret" "appvmpassword" {
  name         = "appvmpassword"
  value        = random_password.appvm.result
  key_vault_id = azurerm_key_vault.core-kv.id
}
resource "azurerm_key_vault_secret" "sqlmipassword" {
  name         = "sqlmipassword"
  value        = random_password.sqlmi.result
  key_vault_id = azurerm_key_vault.core-kv.id
}

resource "azurerm_key_vault_secret" "sqladminpassword" {
  name         = "sqladminpassword"
  value        = random_password.sqlmi.result
  key_vault_id = azurerm_key_vault.core-kv.id
}
