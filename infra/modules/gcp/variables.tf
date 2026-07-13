variable "enabled" {
  description = "Whether to create GCP resources"
  type        = bool
  default     = true
}

variable "prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project id"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
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
