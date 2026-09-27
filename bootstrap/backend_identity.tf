
# The backend pod (namespace "iris", Kubernetes service account "iris-backend")

# may read model files from the Vertex pipeline bucket, and nothing else.

resource "google_storage_bucket_iam_member" "backend_reads_models" {

  bucket = "gcp-lab-idir-2026-pipelines"

  role = "roles/storage.objectViewer"

  member = "principal://iam.googleapis.com/projects/848642814315/locations/global/workloadIdentityPools/gcp-lab-idir-2026.svc.id.goog/subject/ns/iris/sa/iris-backend"

}




# The backend pod may look up models in the Vertex Model Registry (read-only)

resource "google_project_iam_member" "backend_reads_registry" {

  project = "gcp-lab-idir-2026"

  role = "roles/aiplatform.viewer"

  member = "principal://iam.googleapis.com/projects/848642814315/locations/global/workloadIdentityPools/gcp-lab-idir-2026.svc.id.goog/subject/ns/iris/sa/iris-backend"

}

