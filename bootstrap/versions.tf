
terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source  = "hashicorp/google"

      version = "~> 6.0"

    }

  }

}



provider "google" {

  project = "gcp-lab-idir-2026"

  region  = "europe-west1"

}

