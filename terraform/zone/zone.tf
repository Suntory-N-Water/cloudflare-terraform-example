# =============================================================================
# ゾーン設定 - suntory-n-water.com
# =============================================================================
#
# 実際の設定値は Cloudflare ダッシュボードの現在の値を確認して記述してください。
#
# 例: SSL/TLS、セキュリティ、パフォーマンス関連のゾーン設定
# resource "cloudflare_zone_setting" "ssl" {
#   zone_id    = var.zone_id
#   setting_id = "ssl"
#   value      = "full"
# }
#
# resource "cloudflare_zone_setting" "min_tls_version" {
#   zone_id    = var.zone_id
#   setting_id = "min_tls_version"
#   value      = "1.2"
# }
#
# resource "cloudflare_zone_setting" "always_use_https" {
#   zone_id    = var.zone_id
#   setting_id = "always_use_https"
#   value      = "on"
# }
#
# resource "cloudflare_zone_setting" "tls_1_3" {
#   zone_id    = var.zone_id
#   setting_id = "tls_1_3"
#   value      = "on"
# }
#
# resource "cloudflare_zone_setting" "automatic_https_rewrites" {
#   zone_id    = var.zone_id
#   setting_id = "automatic_https_rewrites"
#   value      = "on"
# }
