variable "subscription_id" {
  description = "Azure subscription ID. Set through ARM_SUBSCRIPTION_ID or a local tfvars file."
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Lowercase project name used in Azure resource names."
  type        = string
  default     = "taskboard"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must contain 3-20 lowercase letters, numbers, or hyphens."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "spaincentral"
}

variable "api_image" {
  description = "Fully qualified container image for the API, for example ghcr.io/user/taskboard-api:latest."
  type        = string
}

variable "registry_server" {
  description = "Optional private registry hostname, for example taskboardacr.azurecr.io."
  type        = string
  default     = ""
}

variable "registry_username" {
  description = "Optional private registry username."
  type        = string
  default     = ""
}

variable "registry_password" {
  description = "Optional private registry password. Keep it in a local tfvars file."
  type        = string
  sensitive   = true
  default     = ""
}

variable "redis_url" {
  description = "Optional Redis connection string override passed to the Container App secret."
  type        = string
  sensitive   = true
  default     = ""
}

variable "cors_origins" {
  description = "Comma-separated browser origins allowed by the API."
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Globally unique 3-24 character Azure Storage account name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase letters or numbers."
  }
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)
  default = {
    project   = "cloud-seminar-assignment"
    managedBy = "terraform"
  }
}
