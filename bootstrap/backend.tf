
terraform {

  backend "gcs" {

    bucket = "gcp-lab-idir-2026-tfstate"

    prefix = "bootstrap" # folder inside the bucket; later the dev env will use its own prefix

  }

}

