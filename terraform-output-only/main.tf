terraform {
  required_version = ">= 1.0"
}

locals {
  environment = var.environment
  application = var.application

  tags = {
    Environment = local.environment
    Application = local.application
    ManagedBy   = "Terraform"
  }
}
