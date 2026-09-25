variable "prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_location" {
  description = "Azure region/location"
  type        = string
  default     = "East US"
}

variable "azure_client_id" {
  description = "Azure service principal client ID (optional, uses workload identity if not provided)"
  type        = string
  default     = ""
}

variable "azure_client_secret" {
  description = "Azure service principal client secret (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "orchestrator_org" {
  description = "Platform Orchestrator organization name"
  type        = string
}

variable "orchestrator_auth_token" {
  description = "Platform Orchestrator auth token"
  type        = string
  sensitive   = true
}

variable "public_key_pem" {
  description = "Public key PEM for Platform Orchestrator API runner registration"
  type        = string
  sensitive   = true
}

variable "private_key_pem" {
  description = "Private key PEM for runner pod authentication"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "Platform Orchestrator project ID"
  type        = string
}

variable "env_type_id" {
  description = "Platform Orchestrator environment type ID"
  type        = string
}

variable "vm_fleet_resource_type_id" {
  description = "VM Fleet resource type ID (from root module)"
  type        = string
}
variable "orchestrator_api_url" {
  description = "Public HTTPS API origin of the existing Orchestrator"
  type        = string
}

variable "orchestrator_ca_pem" {
  description = "Optional PEM CA for the installation HTTPS certificate"
  type        = string
  default     = ""
}
