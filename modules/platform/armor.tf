# Cloud Armor: the WAF in front of the global load balancer.
# Requests are filtered at Google's edge, before they reach GKE.
# Attached to the frontend Service by k8s/armor.yaml (GCPBackendPolicy).

variable "armor_preview" {
  description = "true = log what would be blocked, block nothing. Flip to false once the logs show no false positives."
  type        = bool
  default     = true
}

locals {
  # Google-managed OWASP signatures. Sensitivity 1 = fewest false positives.
  owasp_rules = {
    1000 = { name = "sqli", expr = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})" }
    1001 = { name = "xss", expr = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})" }
    1002 = { name = "lfi", expr = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 1})" }
    1003 = { name = "rce", expr = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1})" }
    1004 = { name = "log4j", expr = "evaluatePreconfiguredWaf('cve-canary', {'sensitivity': 1})" }
  }
}

resource "google_compute_security_policy" "edge" {
  project     = var.project_id
  name        = "${var.name}-edge"
  description = "WAF and rate limiting for the iris frontend"

  # Parse JSON bodies, so the rules also inspect what is POSTed to /predict
  advanced_options_config {
    json_parsing = "STANDARD"
    log_level    = "VERBOSE" # logs which signature matched: needed to review preview mode
  }

  dynamic "rule" {
    for_each = local.owasp_rules
    content {
      priority    = rule.key
      action      = "deny(403)"
      preview     = var.armor_preview
      description = "OWASP ${rule.value.name}"
      match {
        expr {
          expression = rule.value.expr
        }
      }
    }
  }

  # More than 100 requests a minute from one IP gets a 429: /predict costs CPU
  rule {
    priority    = 2000
    action      = "throttle"
    preview     = var.armor_preview
    description = "Rate limit per client IP"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }

  # Every policy ends with a default rule: here, allow what nothing above blocked
  rule {
    priority    = 2147483647
    action      = "allow"
    description = "Default: allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

output "armor_policy_name" {
  value = google_compute_security_policy.edge.name
}
