
resource "google_container_cluster" "main" {

  project  = var.project_id

  name     = "${var.name}-gke"

  location = var.region # a region, not a zone: Autopilot is always regional



  enable_autopilot = true



  network    = google_compute_network.vpc.id

  subnetwork = google_compute_subnetwork.main.id



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



  # Nodes run as the dedicated identity, not the default Compute account

  cluster_autoscaling {

    auto_provisioning_defaults {

      service_account = var.node_service_account

      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    }

  }



  release_channel {

    channel = "REGULAR" # automatic upgrades, at a moderate pace

  }



  deletion_protection = false # the provider defaults to true, which would block our Destroy button

}

