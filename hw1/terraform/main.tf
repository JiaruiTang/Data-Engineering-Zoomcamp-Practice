terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.1"
    }
  }
}

provider "google" {
  # Configuration options
  # Credentials only needs to be set if you do not have the GOOGLE_APPLICATION_CREDENTIALS set
  # export GOOGLE_APPLICATION_CREDENTIALS="/Users/jiarui/.gcloud/my-service-account.json"
  project = "dev-moment-449121-d4"
  region  = "US-EAST4"
}

resource "google_storage_bucket" "hw1-bucket" {
  name     = "dev-moment-449121-d4-terra-bucket"
  location = "US"

  # Optional, but recommended settings:
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 // days
    }
  }

  force_destroy = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "first_dataset"
  project    = "dev-moment-449121-d4"
  location   = "US"
}