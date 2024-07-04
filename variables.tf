#######################
# OIDC CONFIGURATION
#######################

variable "provider_arn" {
  type        = string
  description = "the oidc provider arn"
}

variable "terraform_cloud_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "Terraform Cloud hostname, without https://"
}

variable "terraform_cloud_audience" {
  type        = string
  default     = "aws.workload.identity"
  description = "Terraform Cloud audience"
}

variable "openid_provider_certs" {
  type      = list(string)
  sensitive = true
}


variable "db_credentials" {
  type = object({
    username = string
    password = string
  })

  sensitive = true
}


variable "image_uri" {
  type = string

  sensitive = true
}
variable "secret_arn" {
  type      = string
  sensitive = true
}
