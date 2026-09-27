resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions OIDC"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com" # GitHub signs the tokens
  }

  # Fields of GitHub's token that GCP keeps, and their names on the GCP side
  attribute_mapping = {
    "google.subject"                = "assertion.sub"                 # unique ID of the workflow run's identity
    "attribute.repository"          = "assertion.repository"          # e.g. ofsec/gke-iris-platform
    "attribute.repository_owner_id" = "assertion.repository_owner_id" # numeric ID of the GitHub account
    "attribute.ref"                 = "assertion.ref"                 # the branch, e.g. refs/heads/main
  }

  # Hard filter: the repository name AND the owner's numeric ID must match.
  # Names can be renamed or re-registered by someone else; the numeric ID cannot.
  attribute_condition = "(assertion.sub == \"repo:ofsec/gke-iris-platform:ref:refs/heads/main\" || assertion.sub == \"repo:ofsec/gke-iris-platform:pull_request\") && assertion.repository_owner_id == \"129588801\""
}

# Workflows from our repository may act as the CI service account
resource "google_service_account_iam_member" "github_acts_as_ci" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/ofsec/gke-iris-platform"
}
