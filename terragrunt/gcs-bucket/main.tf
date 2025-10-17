terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # Adjust based on your Terraform version
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "bucket" {
  name          = var.bucket_name
  location      = var.location
  storage_class = var.storage_class

  uniform_bucket_level_access = true

  versioning {
    enabled = var.versioning
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}

output "bucket_name" {
  value = google_storage_bucket.bucket.name
}
