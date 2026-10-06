variable "repository" {
  description = "GitHub repository name."
  type        = string
  default     = "shared-calendar"
}

variable "location" {
  description = "Azure region for shared infrastructure resources."
  type        = string
  default     = "UK South"
}

variable "resource_group_name" {
  description = "Name of the shared resource group for this application."
  type        = string
  default     = "rg-whitefam-shared-calendar"
}

variable "static_web_app_name" {
  description = "Name of the Azure Static Web App resource."
  type        = string
  default     = "stapp-shared-calendar"
}

variable "static_web_app_location" {
  description = "Azure region for the Azure Static Web App."
  type        = string
  default     = "westeurope"
}

variable "function_plan_name" {
  description = "Name of the Azure Functions consumption plan."
  type        = string
  default     = "asp-shared-calendar"
}

variable "function_app_name" {
  description = "Name of the Azure Function App."
  type        = string
  default     = "func-shared-calendar"
}

variable "function_storage_account_name" {
  description = "Storage account name used by the Function App runtime. Must be globally unique and 3-24 chars, lowercase letters and numbers only."
  type        = string
  default     = "stsharedcalfn01"
}

variable "cosmosdb_account_name" {
  description = "Cosmos DB account name. Must be globally unique."
  type        = string
  default     = "cosmos-shared-calendar-01"
}

variable "app_registration_name" {
  description = "Display name for the Azure AD application registration."
  type        = string
  default     = "shared-calendar"
}

variable "sibling_1_object_id" {
  description = "Object ID for sibling 1. This is an input-only value and is used as an app/service principal owner."
  type        = string
}

variable "sibling_2_object_id" {
  description = "Object ID for sibling 2. This is an input-only value and is used as an app/service principal owner."
  type        = string
}

variable "sibling_3_object_id" {
  description = "Object ID for sibling 3. This is an input-only value and is used as an app/service principal owner."
  type        = string
}
