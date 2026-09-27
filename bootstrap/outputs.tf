
output "workload_identity_provider" {

  description = "Full provider name, used by GitHub Actions to authenticate"

  value = google_iam_workload_identity_pool_provider.github.name

}



output "ci_service_account" {

  description = "Service account GitHub Actions acts as"

  value = google_service_account.ci.email

}



output "state_bucket" {

  description = "Bucket holding every Terraform state of the platform"

  value = google_storage_bucket.tfstate.name

}



output "gke_node_service_account" {

  description = "Service account the GKE nodes run as"

  value = google_service_account.gke_nodes.email

}

