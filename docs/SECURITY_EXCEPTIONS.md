# Security exceptions

Every finding the scanners report is either fixed, or listed here with the reason it is accepted.
Each exception is also written next to the code it concerns (`checkov:skip` comments and annotations),
so it is reviewed in the same pull request as the code.

## Accepted risks

| Check | Resource | Reason |
| --- | --- | --- |
| CKV_GCP_20 | GKE cluster | Public control plane is intentional: GitHub-hosted runners have changing IPs, so an IP allowlist is impossible. Every call still requires a Google identity with IAM rights. Production would use a private endpoint and a self-hosted runner in the VPC. |
| CKV_GCP_65 | GKE cluster | RBAC with Google Groups needs Google Workspace; out of scope for a solo lab. |
| CKV_GCP_84 | Artifact Registry | Google-managed encryption is on. Customer-managed keys (KMS) add cost and key management for no gain here. |
| CKV_GCP_62 | State bucket | Cloud Audit Logs already record who reads and writes the Terraform state. |
| CKV_K8S_43 | Deployments | Images are referenced by commit tag, in a registry with immutable tags: a tag can never be repointed to other bytes. |

## False positives

| Check | Resource | Reason |
| --- | --- | --- |
| CKV_GCP_69 | GKE cluster | Autopilot always runs the GKE metadata server. |
| CKV_GCP_12 | GKE cluster | Autopilot always enforces NetworkPolicy (Dataplane V2). |
| CKV_DOCKER_2 | Dockerfiles | Kubernetes probes check health; Docker's HEALTHCHECK is ignored by Kubernetes. |

## Planned

| Check | Resource | Plan |
| --- | --- | --- |
| CKV_GCP_26, CKV_GCP_61 | Subnet, cluster | Enable VPC flow logs with sampling, once the logging budget is set. |
| CKV_GCP_66 | GKE cluster | Enable Binary Authorization once CI signs images; before that it would enforce nothing. |
