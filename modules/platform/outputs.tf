
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

