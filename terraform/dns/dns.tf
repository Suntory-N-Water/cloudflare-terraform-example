# =============================================================================
# DNS レコード - suntory-n-water.com
# =============================================================================
#
# 実際のレコードは cf-terraforming でインポートするか、
# Cloudflare ダッシュボードの DNS 設定を参照して記述してください。
#
# 例: ルートドメインの CNAME レコード（Cloudflare Workers 向け）
# resource "cloudflare_dns_record" "root" {
#   zone_id = var.zone_id
#   type    = "CNAME"
#   name    = "suntory-n-water.com"
#   content = "your-worker.your-subdomain.workers.dev"
#   proxied = true
#   ttl     = 1  # Auto
# }
#
# 例: www サブドメインのリダイレクト用 CNAME
# resource "cloudflare_dns_record" "www" {
#   zone_id = var.zone_id
#   type    = "CNAME"
#   name    = "www"
#   content = "suntory-n-water.com"
#   proxied = true
#   ttl     = 1
# }
