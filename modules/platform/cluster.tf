resource "google_container_cluster" "main" {
  # Accepted risks and false positives, reviewed (see docs/SECURITY_EXCEPTIONS.md)
  # checkov:skip=CKV_GCP_20:Public control plane is intentional (GitHub-hosted runners have changing IPs); every call requires IAM
  # checkov:skip=CKV_GCP_65:Google Groups for RBAC needs Google Workspace; out of scope for this lab
  # checkov:skip=CKV_GCP_69:Autopilot always runs the GKE metadata server; not configurable
  # checkov:skip=CKV_GCP_12:Autopilot always enforces NetworkPolicy (Dataplane V2); not configurable
  # checkov:skip=CKV_GCP_61:VPC flow logs planned for later; intranode visibility is already on in Autopilot
  # checkov:skip=CKV_GCP_66:Binary Authorization planned once CI signs images; enabling it before would enforce nothing

  project  = var.project_id
  name     = "${var.name}-gke"
  location = var.region # a region, not a zone: Autopilot is always regional

  enable_autopilot = true

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.main.id

  # Labels: who owns it and what it is, also used for cost reports
  resource_labels = {
    env   = "dev"
    app   = "iris"
    owner = "idir"
  }

  # VPC-native: pods and services take their IPs from the subnet's secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private nodes, public control plane (decision A)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  # No client certificates: access only through Google identities (already the default, now explicit)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Nodes run as the dedicated identity, not the default Compute account
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = var.node_service_account
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD" # install the Gateway API and GKE gateway classes
  }

  release_channel {
    channel = "REGULAR" # automatic upgrades, at a moderate pace
  }

  deletion_protection = false # the provider defaults to true, which would block our Destroy button
}
