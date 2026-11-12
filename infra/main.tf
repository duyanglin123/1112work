terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "app" {
  name     = "rg-${var.project_name}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "app" {
  name                = "law-${var.project_name}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_app_environment" "app" {
  name                       = "cae-${var.project_name}"
  location                   = azurerm_resource_group.app.location
  resource_group_name        = azurerm_resource_group.app.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.app.id
  tags                       = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_managed_redis" "app" {
  name                      = "redis-${var.project_name}"
  location                  = azurerm_resource_group.app.location
  resource_group_name       = azurerm_resource_group.app.name
  sku_name                  = "Balanced_B0"
  high_availability_enabled = false
  public_network_access     = "Enabled"
  tags                      = var.tags

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
  }
}

locals {
  frontend_origin = trimsuffix(azurerm_storage_account.frontend.primary_web_endpoint, "/")
  allowed_origins = var.cors_origins != "" ? var.cors_origins : local.frontend_origin
}

resource "azurerm_container_app" "api" {
  name                         = "api-${var.project_name}"
  container_app_environment_id = azurerm_container_app_environment.app.id
  resource_group_name          = azurerm_resource_group.app.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  secret {
    name  = "redis-url"
    value = var.redis_url != "" ? var.redis_url : "rediss://:${urlencode(azurerm_managed_redis.app.default_database[0].primary_access_key)}@${azurerm_managed_redis.app.hostname}:${azurerm_managed_redis.app.default_database[0].port}/0"
  }

  dynamic "secret" {
    for_each = var.registry_password != "" ? [1] : []
    content {
      name  = "registry-password"
      value = var.registry_password
    }
  }

  dynamic "registry" {
    for_each = var.registry_server != "" ? [1] : []
    content {
      server               = var.registry_server
      username             = var.registry_username
      password_secret_name = "registry-password"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "api"
      image  = var.api_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "REDIS_URL"
        secret_name = "redis-url"
      }

      env {
        name  = "ALLOWED_ORIGINS"
        value = local.allowed_origins
      }
    }
  }
}

resource "azurerm_storage_account" "frontend" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_storage_account_static_website" "frontend" {
  storage_account_id = azurerm_storage_account.frontend.id
  index_document     = "index.html"
  error_404_document = "index.html"
}

data "azurerm_storage_container" "frontend" {
  name               = "$web"
  storage_account_id = azurerm_storage_account.frontend.id
  depends_on         = [azurerm_storage_account_static_website.frontend]
}

resource "azurerm_storage_blob" "frontend_index" {
  name                 = "index.html"
  storage_container_id = data.azurerm_storage_container.frontend.id
  type                 = "Block"
  source               = "${path.module}/../frontend/index.html"
  content_type         = "text/html"
}

resource "azurerm_storage_blob" "frontend_script" {
  name                 = "app.js"
  storage_container_id = data.azurerm_storage_container.frontend.id
  type                 = "Block"
  source               = "${path.module}/../frontend/app.js"
  content_type         = "application/javascript"
}

resource "azurerm_storage_blob" "frontend_styles" {
  name                 = "styles.css"
  storage_container_id = data.azurerm_storage_container.frontend.id
  type                 = "Block"
  source               = "${path.module}/../frontend/styles.css"
  content_type         = "text/css"
}

resource "azurerm_storage_blob" "frontend_config" {
  name                 = "config.js"
  storage_container_id = data.azurerm_storage_container.frontend.id
  type                 = "Block"
  source_content       = replace(file("${path.module}/../frontend/config.js"), "http://localhost:8000", "https://${azurerm_container_app.api.ingress[0].fqdn}")
  content_type         = "application/javascript"
}
