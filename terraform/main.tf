# Random suffix ensures globally unique names for Web App and SQL Server
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # e.g. "dotnetapp-dev-a1b2c3"
  unique_name = "${var.app_name}-${var.environment}-${random_string.suffix.result}"

  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# App Service Plan (Free F1 — Linux)
# ---------------------------------------------------------------------------

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.unique_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "F1"
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Linux Web App (.NET 8)
# ---------------------------------------------------------------------------

resource "azurerm_linux_web_app" "main" {
  name                = "app-${local.unique_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    # always_on is not supported on the Free (F1) tier
    always_on = false

    application_stack {
      dotnet_version = "8.0"
    }

    # Enforce minimum TLS 1.2
    minimum_tls_version = "1.2"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"   = var.environment == "prod" ? "Production" : "Development"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};User ID=${var.sql_admin_username};Password=${var.sql_admin_password};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Azure SQL Server
# ---------------------------------------------------------------------------

resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.unique_name}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Azure SQL Database (Basic — ~$5/month, 5 DTUs, 2 GB)
# ---------------------------------------------------------------------------

resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${local.unique_name}"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"
  tags      = local.common_tags
}

# Allow all Azure-hosted services to reach the SQL Server
# (IP 0.0.0.0 → 0.0.0.0 is the Azure "Allow Azure Services" sentinel range)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
