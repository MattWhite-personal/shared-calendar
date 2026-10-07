terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.7.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraformrg"
    storage_account_name = "terraformstoragefe832e63"
    container_name       = "terraform"
    key                  = "shared-calendar.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

provider "azuread" {
  features {}
  use_oidc = true
}

resource "azurerm_resource_group" "shared_calendar" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "function" {
  name                          = var.function_storage_account_name
  resource_group_name           = azurerm_resource_group.shared_calendar.name
  location                      = azurerm_resource_group.shared_calendar.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  tags                          = local.tags
}

resource "azurerm_service_plan" "function" {
  name                = var.function_plan_name
  location            = azurerm_resource_group.shared_calendar.location
  resource_group_name = azurerm_resource_group.shared_calendar.name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

resource "azurerm_linux_function_app" "calendar" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.shared_calendar.location
  resource_group_name        = azurerm_resource_group.shared_calendar.name
  service_plan_id            = azurerm_service_plan.function.id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  https_only                 = true

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"
    FUNCTIONS_WORKER_RUNTIME    = "node"
    WEBSITE_RUN_FROM_PACKAGE    = "1"
    AzureWebJobsStorage         = azurerm_storage_account.function.primary_connection_string
  }

  site_config {
    application_stack {
      node_version = "20"
    }
    always_on = false
  }

  tags = local.tags
}

resource "azurerm_static_web_app" "calendar" {
  name                = var.static_web_app_name
  resource_group_name = azurerm_resource_group.shared_calendar.name
  location            = var.static_web_app_location
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = local.tags
}

resource "azurerm_cosmosdb_account" "calendar" {
  name                          = var.cosmosdb_account_name
  location                      = azurerm_resource_group.shared_calendar.location
  resource_group_name           = azurerm_resource_group.shared_calendar.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  free_tier_enabled             = true
  public_network_access_enabled = true
  tags                          = local.tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.shared_calendar.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "function_identity" {
  resource_group_name = azurerm_resource_group.shared_calendar.name
  account_name        = azurerm_cosmosdb_account.calendar.name
  role_definition_id  = "${azurerm_cosmosdb_account.calendar.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_linux_function_app.calendar.identity[0].principal_id
  scope               = azurerm_cosmosdb_account.calendar.id
}

resource "azuread_application" "calendar" {
  display_name            = var.app_registration_name
  owners                  = [var.sibling_1_object_id, var.sibling_2_object_id, var.sibling_3_object_id]
  sign_in_audience        = "AzureADMyOrg"
  prevent_duplicate_names = true
}

resource "azuread_service_principal" "calendar" {
  client_id                    = azuread_application.calendar.client_id
  app_role_assignment_required = true
  owners                       = [var.sibling_1_object_id, var.sibling_2_object_id, var.sibling_3_object_id]
}
