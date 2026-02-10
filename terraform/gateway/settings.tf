# =============================================================================
# Gateway 設定 - TLS Decryption
# =============================================================================
#
# HTTP ポリシーで HTTPS トラフィックを検査するための前提条件。
# このリソースを apply する前に、スマホに Cloudflare ルート証明書を
# インストールしておく必要がある。
#
# 注意: このリソースはアカウントにつき 1 つのシングルトン。
# 既にダッシュボードで設定済みの場合は terraform import が必要:
#   terraform import cloudflare_zero_trust_gateway_settings.this <account_id>
#
# 参考: https://developers.cloudflare.com/cloudflare-one/traffic-policies/http-policies/tls-decryption/

resource "cloudflare_zero_trust_gateway_settings" "this" {
  account_id = var.account_id

  settings = {
    tls_decrypt = {
      enabled = true
    }
  }
}
