# =============================================================================
# Gateway HTTP ポリシー
# =============================================================================
#
# 参考: https://developers.cloudflare.com/cloudflare-one/traffic-policies/http-policies/common-policies/

# -----------------------------------------------------------------------------
# YouTube Shorts ブロック
# -----------------------------------------------------------------------------
#
# youtube.com（www.youtube.com, m.youtube.com 含む）の /shorts パスへの
# アクセスをブロックする。通常の YouTube 動画は影響を受けない。
#
# traffic 条件式の説明:
#   - any(http.request.domains[*] == "youtube.com")
#     → Domain セレクタ。youtube.com とその全サブドメインにマッチ。
#       www.youtube.com, m.youtube.com の両方を捕捉する。
#   - http.request.uri matches "/shorts.*"
#     → URI セレクタ + 正規表現。/shorts で始まるパスにマッチ。
#       例: /shorts/abcd1234, /shorts?feature=share
#
# 条件式のパターンは公式ドキュメント "Block sites by URL"
# （reddit.com/r/gaming の例）に準拠。

resource "cloudflare_zero_trust_gateway_policy" "block_youtube_shorts" {
  account_id     = var.account_id
  name           = "Block YouTube Shorts"
  description    = "YouTube Shorts へのアクセスをブロック"
  precedence     = 2000
  enabled        = true
  action         = "block"
  filters        = ["http"]
  traffic        = "any(http.request.domains[*] == \"youtube.com\") and http.request.uri matches \"/shorts.*\""
  identity       = ""
  device_posture = ""
}
