resource "google_artifact_registry_repository" "images" {
  # checkov:skip=CKV_GCP_84:Google-managed encryption is on; customer-managed keys add KMS cost and key management for no gain here

  project       = var.project_id
  location      = var.region
  repository_id = "${var.name}-images"
  format        = "DOCKER"
  description   = "Container images for the iris platform"

  # A tag, once pushed, can never be moved to another image:
  # the commit ID in the manifests always means the same bytes
  docker_config {
    immutable_tags = true
  }
}
