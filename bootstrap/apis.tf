
locals {

  apis = [

    "iam.googleapis.com",                  # service accounts and roles

    "iamcredentials.googleapis.com",       # short-lived tokens

    "sts.googleapis.com",                  # exchanges GitHub's token for a Google token

    "cloudresourcemanager.googleapis.com", # project-level IAM

    "compute.googleapis.com",              # network, router, NAT

    "container.googleapis.com",            # GKE

    "artifactregistry.googleapis.com",     # container images

    "storage.googleapis.com",              # the state bucket

  ]

}



resource "google_project_service" "apis" {

  for_each           = toset(local.apis)

  service            = each.value

  disable_on_destroy = false

}

