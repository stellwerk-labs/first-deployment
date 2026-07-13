variable "enabled" {
  description = "Whether to create local KinD cluster"
  type        = bool
  default     = true
}

variable "prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "cluster_name" {
  description = "Name suffix for the KinD cluster (will be prefixed with var.prefix)"
  type        = string
  default     = "first-deployment-local"
}

variable "base_domain" {
  description = "Base domain for local cluster ingress (defaults to localtest.me which resolves to 127.0.0.1)"
  type        = string
  default     = "localtest.me"
}

variable "ingress_http_port" {
  description = "Host port to bind for HTTP traffic (must not conflict with other services)"
  type        = number
  default     = 80
}

variable "ingress_https_port" {
  description = "Host port to bind for HTTPS traffic (must not conflict with other services)"
  type        = number
  default     = 443
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
