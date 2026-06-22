output "web_app_url" {
  description = "Public HTTPS URL of the deployed web application"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "web_app_name" {
  description = "Name of the Azure Web App (use this for `az webapp deploy`)"
  value       = azurerm_linux_web_app.main.name
}

output "resource_group_name" {
  description = "Name of the resource group containing all resources"
  value       = azurerm_resource_group.main.name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Name of the SQL database"
  value       = azurerm_mssql_database.main.name
}

output "deploy_command" {
  description = "Azure CLI command to deploy a .zip package to the web app"
  value       = "az webapp deploy --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_linux_web_app.main.name} --src-path <your-app.zip> --type zip"
}
