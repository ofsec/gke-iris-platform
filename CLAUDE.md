# gke-iris-platform: context for Claude Code

## Who and why
- Idir Brigui, DevOps/Cloud/MLOps freelancer (Morocco, CKAD). This repo is a hands-on lab to prepare
  GCP interviews (AFD.Tech/Accenture, Renault project: TOMORROW) and InDataCore (2 days later).
- Goal is real understanding, not just interview lines. He is tired: keep the pace efficient.

## How to work with Idir (important)
- Short messages, one idea at a time, then a quick check. Zoom out first, then zoom in.
- Before building anything non-trivial, present the design (goal, options, trade-offs, a recommendation)
  and let HIM decide. Never take design decisions silently.
- Build step by step and say what each step does and why. After a step, give him the "interview line".
- Run the commands yourself (gcloud, kubectl, gh, terraform, docker are available and authenticated in Cloud Shell).
- Ask before anything destructive or costly (destroy, deleting resources, paid services).

## Architecture (all working end to end)
- GCP project gcp-lab-idir-2026, region europe-west1. App URL: http://34.107.216.49 (repo variable APP_URL).
- bootstrap/: applied by hand (state gs://gcp-lab-idir-2026-tfstate/bootstrap). APIs, state bucket, CI service
  account github-terraform, Workload Identity Federation for GitHub OIDC (immutable sub format
  repo:ofsec@129588801/gke-iris-platform@1390853644:...), node SA gke-nodes, backend identity.
- modules/platform + envs/dev: applied by GitHub Actions (terraform.yml: plan on PR, apply/destroy on
  workflow_dispatch -f action=apply|destroy). VPC + NAT + deny-all firewall, private GKE Autopilot cluster
  iris-dev-gke (public endpoint), Artifact Registry iris-dev-images (immutable tags), Cloud Armor
  policy iris-dev-edge (armor.tf), ArgoCD installed by the Terraform helm provider (envs/dev/argocd.tf).
- apps/backend: FastAPI, loads the newest model from the Vertex AI Model Registry (Workload Identity,
  KSA iris/iris-backend), POST /predict {"instances": [[6.0,2.9,4.5,1.5]]}, GET /healthz.
- apps/frontend: nginx-unprivileged, strict CSP (no unsafe-inline, JS/CSS in app.js/style.css), proxies /predict.
- k8s/: kustomize, deployed by ArgoCD (app "iris", auto-sync, prune, selfHeal). Gateway API
  (gke-l7-global-external-managed), NetworkPolicies (default deny; frontend ingress 8080; backend only from
  frontend), GCPBackendPolicy armor.yaml attaches Cloud Armor. Pods: UID 10001, read-only root FS, limits.
- CI: build.yml (build, Trivy CRITICAL/HIGH blocks, keyless push, bot commits new tags to k8s/kustomization.yaml),
  security.yml (Checkov, gitleaks, CodeQL), dast.yml (nightly ZAP baseline, .zap/rules.tsv promotes fixed rules to FAIL).
- Accepted risks / skips are documented in docs/SECURITY_EXCEPTIONS.md. Every Checkov skip needs a written reason.

## Gotchas learned the hard way
- The CI bot commits to main after every build: always `git pull --rebase` before pushing.
- `kustomize edit` rewrites kustomization.yaml with list items flush left: new entries must be `- file.yaml`, no indent.
- Autopilot forbids privileged pods, hostPath, hostNetwork: no node-exporter DaemonSet. New pods can wait
  1-3 min for a node (scale-up).
- ArgoCD polls Git ~every 3 min. "Healthy" or "rollout finished" may refer to the OLD version: verify the real
  signal (the image tag, a header, a response), not a status field.
- Cloud Armor changes take ~5-7 min to reach Google's edge even when the policy shows Attached.
- Pin third-party GitHub Actions by commit SHA.

## Current task: monitoring (decided: option B)
1. DONE (PR #6): Prometheus (server only) + Grafana in namespace monitoring, deployed as ArgoCD
   multi-source apps (chart from Helm repo + values from monitoring/ in Git).
2. DONE (PR #7): backend instrumented with prometheus_client on /metrics (traffic, errors, latency
   histogram, predictions per species); NetworkPolicy allows monitoring -> backend:8080.
3. DONE (PR #8): Grafana golden-signals + SLO dashboard, loaded by the dashboard sidecar.
   PR #9 (right-size requests: ArgoCD, Prometheus reload sidecar, Grafana) open; argocd.tf part needs
   a terraform apply via workflow_dispatch after merge.
4. If time allows: Datadog 14-day trial, agent via Helm (allowed on Autopilot), compare with Prometheus.
5. ELK: concepts only (EFK with Fluent Bit, ELK vs Loki vs Cloud Logging) - too heavy for tonight.
Then (short, concepts): FinOps, hybrid (GKE Enterprise/Anthos, Interconnect/VPN, Config Sync),
BigQuery/Pub/Sub, then a mock AFD.Tech interview.

## Loose ends (later)
- Cloud Armor: enable LB logging in GCPBackendPolicy (logging.enabled) to review preview decisions, then
  set armor_preview=false. Log4j rule (priority 900) is already enforced and verified (403).
- Vertex pipelines bucket not in Terraform; ArgoCD ApplicationSet chart key; Node 20 actions (checkout@v4...);
  Dependabot/Renovate; VPC flow logs; Binary Authorization.
- To save credit when stopping: `gh workflow run terraform.yml -f action=destroy` (everything comes back from Git).
