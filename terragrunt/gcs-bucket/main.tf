terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = "my-static-project-id"
  region  = "us-central1"
}

resource "google_storage_bucket" "demo_bucket" {
  name          = "my-static-demo-bucket-1234"
  location      = "US"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  labels = {
    environment = "dev"
    owner       = "terragrunt-example"
  }
}

output "bucket_name" {
  value = google_storage_bucket.demo_bucket.name
}
