output "cluster_name" {
  value = google_container_cluster.main.name
}

output "cluster_location" {
  value = google_container_cluster.main.location
}

output "registry_url" {
  description = "Prefix for image names, e.g. <registry_url>/backend:tag"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

# Needed by the Helm provider to talk to the cluster's API
output "cluster_endpoint" {
  value = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  value = google_container_cluster.main.master_auth[0].cluster_ca_certificate
}
