
terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source = "hashicorp/google"

      version = "~> 6.0"

    }

  }

  backend "gcs" {

    bucket = "gcp-lab-idir-2026-tfstate"

    prefix = "envs/dev" # separate state from the bootstrap

  }

}



provider "google" {

  project = "gcp-lab-idir-2026"

  region = "europe-west1"

}

