# Cloudflare Terraform リソース設定例

## 目次

- [Cloudflare Terraform リソース設定例](#cloudflare-terraform-リソース設定例)
  - [目次](#目次)
  - [DNS レコード](#dns-レコード)
  - [ゾーン設定](#ゾーン設定)
  - [WAF Managed Rules](#waf-managed-rules)
    - [ゾーンレベルデプロイ](#ゾーンレベルデプロイ)
    - [アカウントレベルデプロイ (Enterprise)](#アカウントレベルデプロイ-enterprise)
    - [WAF 例外設定](#waf-例外設定)
    - [OWASP パラノイアレベル設定](#owasp-パラノイアレベル設定)
  - [WAF カスタムルール](#waf-カスタムルール)
  - [レート制限ルール](#レート制限ルール)
    - [基本的なレート制限](#基本的なレート制限)
    - [カスタムレスポンス付きレート制限](#カスタムレスポンス付きレート制限)
  - [DDoS Managed Rulesets](#ddos-managed-rulesets)
  - [Transform Rules](#transform-rules)
    - [URL リライト](#url-リライト)
  - [ロードバランサー](#ロードバランサー)
  - [カスタムルールセットのデプロイ](#カスタムルールセットのデプロイ)

---

## DNS レコード

```hcl
resource "cloudflare_dns_record" "www" {
  zone_id = var.zone_id
  name    = "www"
  content = "203.0.113.10"
  type    = "A"
  ttl     = 1
  proxied = true
  comment = "Domain verification record"
}
```

## ゾーン設定

```hcl
resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id    = var.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = var.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict"
}
```

## WAF Managed Rules

### ゾーンレベルデプロイ

```hcl
resource "cloudflare_ruleset" "zone_level_managed_waf" {
  zone_id     = var.zone_id
  name        = "Managed WAF entry point ruleset"
  description = "Zone-level WAF Managed Rules config"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules {
    ref         = "execute_cloudflare_managed_ruleset"
    description = "Execute Cloudflare Managed Ruleset"
    expression  = "true"
    action      = "execute"
    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee"
    }
  }

  rules {
    ref         = "execute_cloudflare_owasp_core_ruleset"
    description = "Execute Cloudflare OWASP Core Ruleset"
    expression  = "true"
    action      = "execute"
    action_parameters {
      id = "4814384a9e5d4991b9815dcfc25d2f1f"
    }
  }
}
```

### アカウントレベルデプロイ (Enterprise)

アカウントレベルのルールセットはEnterpriseプラン必須。expression の末尾に `and cf.zone.plan eq "ENT"` を含める。

```hcl
resource "cloudflare_ruleset" "account_level_managed_waf" {
  account_id  = var.account_id
  name        = "Managed WAF entry point ruleset"
  description = "Account-level WAF Managed Rules config"
  kind        = "root"
  phase       = "http_request_firewall_managed"

  rules {
    ref         = "execute_cloudflare_managed_ruleset_api_store"
    description = "Execute Cloudflare Managed Ruleset"
    expression  = "http.host in {\"api.example.com\" \"store.example.com\"} and cf.zone.plan eq \"ENT\""
    action      = "execute"
    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee"
    }
  }
}
```

### WAF 例外設定

例外ルールはマネージドルールセット実行ルールの **前** に配置する。

```hcl
# ルールセット全体のスキップ
rules {
  ref         = "skip_cloudflare_managed_ruleset"
  description = "Skip Cloudflare Managed Ruleset"
  expression  = "(http.request.uri.path eq \"/status\")"
  action      = "skip"
  action_parameters {
    rulesets = ["efb7b8c949ac4650a09736fc376e9aee"]
  }
}

# 特定ルールのスキップ
rules {
  ref         = "skip_specific_rules"
  description = "Skip specific WAF rules"
  expression  = "(http.request.uri.path eq \"/api/webhook\")"
  action      = "skip"
  action_parameters {
    rules = {
      "efb7b8c949ac4650a09736fc376e9aee" = "5de7edfa648c4d6891dc3e7f84534ffa,e3a567afc347477d9702d9047e97d760"
    }
  }
}
```

### OWASP パラノイアレベル設定

```hcl
rules {
  ref         = "execute_owasp_core_ruleset"
  description = "Execute Cloudflare OWASP Core Ruleset"
  expression  = "true"
  action      = "execute"
  action_parameters {
    id = "4814384a9e5d4991b9815dcfc25d2f1f"
    overrides {
      categories {
        category = "paranoia-level-3"
        enabled  = false
      }
      categories {
        category = "paranoia-level-4"
        enabled  = false
      }
      rules {
        id              = "6179ae15870a4bb7b2d480d4843b323c"
        action          = "log"
        score_threshold = 60
      }
    }
  }
}
```

## WAF カスタムルール

```hcl
resource "cloudflare_ruleset" "zone_custom_firewall" {
  zone_id     = var.zone_id
  name        = "Custom firewall rules"
  description = ""
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    ref         = "block_non_default_ports"
    description = "Block ports other than 80 and 443"
    expression  = "(not cf.edge.server_port in {80 443})"
    action      = "block"
  }
}
```

## レート制限ルール

### 基本的なレート制限

```hcl
resource "cloudflare_ruleset" "zone_rl" {
  zone_id     = var.zone_id
  name        = "Rate limiting for my zone"
  description = ""
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    ref         = "rate_limit_api_requests_ip"
    description = "Rate limit API requests by IP"
    expression  = "(http.request.uri.path matches \"^/api/\")"
    action      = "block"
    ratelimit {
      characteristics     = ["cf.colo.id", "ip.src"]
      period              = 60
      requests_per_period = 100
      mitigation_timeout  = 600
    }
  }
}
```

### カスタムレスポンス付きレート制限

```hcl
resource "cloudflare_ruleset" "zone_rl_custom_response" {
  zone_id     = var.zone_id
  name        = "Advanced rate limiting rule"
  description = ""
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    ref         = "rate_limit_with_custom_response"
    description = "Rate limit with custom JSON response"
    expression  = "http.host eq \"www.example.com\" and (http.request.uri.path matches \"^/api/\")"
    action      = "block"
    action_parameters {
      response {
        status_code  = 429
        content      = "{\"error\": \"rate_limited\"}"
        content_type = "application/json"
      }
    }
    ratelimit {
      characteristics     = ["ip.src", "cf.colo.id"]
      period              = 10
      requests_per_period = 5
      mitigation_timeout  = 30
      counting_expression = "(http.host eq \"www.example.com\") and (http.request.uri.path matches \"^/api/\") and (http.response.code eq 429)"
    }
  }
}
```

## DDoS Managed Rulesets

```hcl
resource "cloudflare_ruleset" "zone_level_http_ddos_config" {
  zone_id     = var.zone_id
  name        = "HTTP DDoS Attack Protection entry point ruleset"
  description = ""
  kind        = "zone"
  phase       = "ddos_l7"

  rules {
    ref         = "override_http_ddos_sensitivity"
    description = "Override HTTP DDoS rule sensitivity"
    expression  = "true"
    action      = "execute"
    action_parameters {
      id = "4d21379b4f9f4bb088e0729962c8b3cf"
      overrides {
        rules {
          id                = "<RULE_ID>"
          sensitivity_level = "low"
        }
      }
    }
  }
}
```

## Transform Rules

### URL リライト

```hcl
resource "cloudflare_ruleset" "transform_url_rewrite" {
  zone_id     = var.zone_id
  name        = "Transform Rule performing a static URL rewrite"
  description = ""
  kind        = "zone"
  phase       = "http_request_transform"

  rules {
    ref         = "rewrite_old_folder"
    description = "Rewrite /old-folder to /new-folder"
    expression  = "(http.request.uri.path matches \"^/old-folder\")"
    action      = "rewrite"
    action_parameters {
      uri {
        path {
          value = "/new-folder"
        }
      }
    }
  }
}
```

## ロードバランサー

```hcl
resource "cloudflare_load_balancer_pool" "example_lb_pool" {
  name = "example-lb-pool"
  origins {
    name    = "example-1"
    address = "198.51.100.1"
    enabled = true
  }
}

resource "cloudflare_load_balancer" "example_lb" {
  zone_id          = var.zone_id
  name             = "example-load-balancer.example.com"
  fallback_pool_id = cloudflare_load_balancer_pool.example_lb_pool.id
  default_pool_ids = [cloudflare_load_balancer_pool.example_lb_pool.id]
  description      = "Example load balancer"
  proxied          = true
}
```

## カスタムルールセットのデプロイ

アカウントレベルでカスタムルールセットを作成し、別リソースでデプロイする。

```hcl
resource "cloudflare_ruleset" "custom_ruleset" {
  account_id  = var.account_id
  name        = "Custom ruleset"
  description = ""
  kind        = "custom"
  phase       = "http_request_firewall_custom"

  rules {
    ref         = "my_custom_rule"
    description = "Block non-standard ports"
    expression  = "(not cf.edge.server_port in {80 443})"
    action      = "block"
  }
}

resource "cloudflare_ruleset" "deploy_custom_ruleset" {
  account_id  = var.account_id
  name        = "Deploy custom ruleset"
  description = ""
  kind        = "root"
  phase       = "http_request_firewall_custom"

  depends_on = [cloudflare_ruleset.custom_ruleset]

  rules {
    ref         = "deploy_custom_ruleset_example"
    description = "Deploy custom ruleset for example.com"
    expression  = "(cf.zone.name eq \"example.com\") and (cf.zone.plan eq \"ENT\")"
    action      = "execute"
    action_parameters {
      id = cloudflare_ruleset.custom_ruleset.id
    }
  }
}
```
