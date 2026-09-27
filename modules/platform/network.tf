
resource "google_compute_network" "vpc" {

  project                 = var.project_id

  name                    = "${var.name}-vpc"

  auto_create_subnetworks = false # no default subnet in every region: we define our own

}



resource "google_compute_subnetwork" "main" {

  project                  = var.project_id

  name                     = "${var.name}-subnet"

  region                   = var.region

  network                  = google_compute_network.vpc.id

  ip_cidr_range            = var.nodes_cidr

  private_ip_google_access = true # private nodes can still reach Google APIs (Artifact Registry, GCS)



  secondary_ip_range {

    range_name    = "pods"

    ip_cidr_range = var.pods_cidr

  }

  secondary_ip_range {

    range_name    = "services"

    ip_cidr_range = var.services_cidr

  }

}



# Cloud NAT lives on a Cloud Router

resource "google_compute_router" "main" {

  project = var.project_id

  name    = "${var.name}-router"

  region  = var.region

  network = google_compute_network.vpc.id

}



# Outbound-only internet access for the private nodes

resource "google_compute_router_nat" "main" {

  project                            = var.project_id

  name                               = "${var.name}-nat"

  router                             = google_compute_router.main.name

  region                             = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"



  subnetwork {

    name                    = google_compute_subnetwork.main.id

    source_ip_ranges_to_nat = ["ALL_IP_RANGES"] # nodes and pods

  }



  log_config {

    enable = true

    filter = "ERRORS_ONLY" # log only failed translations, to keep log costs low

  }

}

