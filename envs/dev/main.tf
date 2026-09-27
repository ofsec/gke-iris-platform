
module "platform" {

  source = "../../modules/platform"



  project_id = "gcp-lab-idir-2026"

  region = "europe-west1"

  name = "iris-dev"



  nodes_cidr = "10.10.0.0/20"

  pods_cidr = "10.20.0.0/16"

  services_cidr = "10.30.0.0/20"

  node_service_account = "gke-nodes@gcp-lab-idir-2026.iam.gserviceaccount.com"

}

