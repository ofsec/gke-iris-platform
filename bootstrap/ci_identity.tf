
resource "google_service_account" "ci" {

  account_id = "github-terraform"

  display_name = "GitHub Actions - Terraform"

  depends_on = [google_project_service.apis]

}



locals {

  ci_roles = [

    "roles/compute.networkAdmin", # VPC, subnet, Cloud Router, Cloud NAT

    "roles/container.admin", # create, update, delete GKE clusters

    "roles/artifactregistry.admin", # create the image repository

    "roles/serviceusage.serviceUsageConsumer", # allowed to call the enabled APIs

  ]

}



resource "google_project_iam_member" "ci" {

  for_each = toset(local.ci_roles)

  project = "gcp-lab-idir-2026"

  role = each.value

  member = "serviceAccount:${google_service_account.ci.email}"

}



# Read and write the state files, in this one bucket only

resource "google_storage_bucket_iam_member" "ci_state" {

  bucket = google_storage_bucket.tfstate.name

  role = "roles/storage.objectAdmin"

  member = "serviceAccount:${google_service_account.ci.email}"

}

