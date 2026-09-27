
resource "google_storage_bucket" "tfstate" {

  name                        = "gcp-lab-idir-2026-tfstate"

  location                    = "europe-west1"

  uniform_bucket_level_access = true       # access only through IAM, no per-file permissions

  public_access_prevention    = "enforced" # can never be made public, even by mistake



  versioning {

    enabled = true # every version of the state is kept, so a bad state can be rolled back

  }



  lifecycle_rule {

    condition {

      num_newer_versions = 10 # once a version has 10 newer ones...

    }

    action {

      type = "Delete" # ...delete it, so old versions don't pile up forever

    }

  }



  depends_on = [google_project_service.apis] # create the APIs first

}

