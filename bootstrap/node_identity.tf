
resource "google_service_account" "gke_nodes" {

  account_id = "gke-nodes"

  display_name = "GKE Autopilot nodes"

  depends_on = [google_project_service.apis]

}



locals {

  node_roles = [

    "roles/container.defaultNodeServiceAccount", # write logs and metrics, node basics

    "roles/artifactregistry.reader", # pull our images

  ]

}



resource "google_project_iam_member" "gke_nodes" {

  for_each = toset(local.node_roles)

  project = "gcp-lab-idir-2026"

  role = each.value

  member = "serviceAccount:${google_service_account.gke_nodes.email}"

}



# CI may attach this identity to the cluster, and do nothing else with it

resource "google_service_account_iam_member" "ci_uses_node_sa" {

  service_account_id = google_service_account.gke_nodes.name

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.ci.email}"

}

