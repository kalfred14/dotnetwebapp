variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-dotnet-app"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "West US 2"
}

variable "app_name" {
  description = "Base name used to derive resource names (lowercase letters and hyphens only)"
  type        = string
  default     = "dotnetapp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.app_name))
    error_message = "app_name must be 3-21 lowercase letters, digits, or hyphens and start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "sql_admin_username" {
  description = "SQL Server administrator login name"
  type        = string
  default     = "sqladmin"

  validation {
    condition     = !contains(["admin", "administrator", "sa", "root", "login", "guest"], lower(var.sql_admin_username))
    error_message = "sql_admin_username cannot be a reserved SQL Server login name."
  }
}

variable "sql_admin_password" {
  description = "SQL Server administrator password (min 8 chars, must include uppercase, lowercase, digit, and special char)"
  type        = string
  sensitive   = true
}
