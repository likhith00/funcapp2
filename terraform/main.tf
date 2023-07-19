/*terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.65.0"
    }
  }
   backend "azurerm" {
    storage_account_name = azure_storage_account.functionstorage.name
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    use_azuread_auth     = true
    subscription_id      = var
    tenant_id            = "00000000-0000-0000-0000-000000000000"
  }
}*/

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "funcapprsg5849"
  location = "West Europe"
}


resource "azurerm_container_registry" "acr" {
  name                = "acr5849"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  location            = azurerm_resource_group.resourcegroup.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_storage_account" "functionstorage" {
  name                     = "storageacc5849"
  resource_group_name      = azurerm_resource_group.resourcegroup.name
  location                 = azurerm_resource_group.resourcegroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}



resource "azurerm_app_service_plan" "appserviceplan" {
  name                    = "funcapp-premiumPlan"
  resource_group_name     = azurerm_resource_group.resourcegroup.name
  location                = azurerm_resource_group.resourcegroup.location
  kind                    = "Linux"
  reserved                = true


  sku {
    tier = "Premium"
    size = "P1V2"
  }
}



resource "azurerm_function_app" "functionapp" {
    name                       = "funcapp5849-userapi39-funcapp"
    location                   =  azurerm_resource_group.resourcegroup.location
    resource_group_name        = azurerm_resource_group.resourcegroup.name
    app_service_plan_id        = azurerm_app_service_plan.appserviceplan.id
    storage_account_name       = azurerm_storage_account.functionstorage.name
    storage_account_access_key = azurerm_storage_account.functionstorage.primary_access_key
    version                    = "~2"

    app_settings = {
        FUNCTIONS_EXTENSION_VERSION               = "~2"
        DOCKER_REGISTRY_SERVER_URL                = azurerm_container_registry.acr.login_server
        DOCKER_REGISTRY_SERVER_USERNAME           = azurerm_container_registry.acr.admin_username
        DOCKER_REGISTRY_SERVER_PASSWORD           = azurerm_container_registry.acr.admin_password
        WEBSITE_CONTENTAZUREFILECONNECTIONSTRING  = azurerm_storage_account.functionstorage.primary_connection_string
        WEBSITE_CONTENTSHARE                      = azurerm_storage_account.functionstorage.name
        DOCKER_CUSTOM_IMAGE_NAME                  = "${azurerm_container_registry.acr.login_server}/pingtrigger:test"
    }

    site_config {
      always_on                 = true
      linux_fx_version          = "DOCKER|${azurerm_container_registry.acr.login_server}/funcapp"
      vnet_route_all_enabled = true 
    }

  

}

resource "azurerm_network_security_group" "nsg" {
  name                = "securitygroup5849"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet5849"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]


  subnet {
    name           = "nsg"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.nsg.id
  }
 

}

resource "azurerm_subnet" "funcapp" {
    name                 = "funcapp"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = ["10.0.2.0/24"]
    service_endpoints    = ["Microsoft.Sql","Microsoft.Storage"]

    delegation {
        name = "funcappDelegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }


  }


resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegration" {
  app_service_id = azurerm_function_app.functionapp.id
  subnet_id      = azurerm_subnet.funcapp.id
}


resource "azurerm_private_dns_zone" "pvtdns" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.resourcegroup.name
}


resource "azurerm_subnet" "pvtendpoint" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}
resource "azurerm_private_endpoint" "pvtconn" {
  name                = "my-private-endpoint5849"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  subnet_id           = azurerm_subnet.pvtendpoint.id

  private_service_connection {
    name                           = "my-private-connection5849"
    private_connection_resource_id = azurerm_function_app.functionapp.id
    subresource_names              = ["sites"]
    is_manual_connection = false
  }

}

resource "azurerm_public_ip" "publicip" {
  name                = "publicip5849"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "natgateway" {
  name                = "NatGateway5849"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku_name            = "Standard"
  
}

resource "azurerm_nat_gateway_public_ip_association" "natasso" {
  nat_gateway_id       = azurerm_nat_gateway.natgateway.id
  public_ip_address_id = azurerm_public_ip.publicip.id
}

resource "azurerm_subnet_nat_gateway_association" "gwassociation" {
  subnet_id      = azurerm_subnet.funcapp.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
}