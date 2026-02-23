## プロジェクト概要

Cloudflare の各種サービスを Terraform で管理するリポジトリ。
Cloudflare Terraform Provider v5 を使用。

## ディレクトリ構成

```
terraform/
  └── zone/        # ゾーン設定(TLS/証明書、セキュリティ、DNS、速度)
docs/
  └── youtube-shorts-block-investigation.md  # Gateway 調査記録(アーカイブ)
```

プロダクト単位でディレクトリを分割する構成。新しい Cloudflare プロダクトを追加する場合は `terraform/<product>/` にディレクトリを作成する。

## Terraform コマンド

```bash
# プロジェクトルートから実行
source .env && terraform -chdir=terraform/zone init
source .env && terraform -chdir=terraform/zone plan
source .env && terraform -chdir=terraform/zone apply
```

## 認証

- API トークンは環境変数 `CLOUDFLARE_API_TOKEN` で渡す(provider ブロックにハードコードしない)
- `.env.example` を `.env` にコピーしてトークンを設定(`export` 形式)
- `zone_id` は `terraform.tfvars` で管理(git 管理外)
- API トークンに必要な権限:
  - ゾーン > ゾーン > 読み取り
  - ゾーン > ゾーン設定 > 編集
  - ゾーン > SSL および証明書 > 編集
  - ゾーン > DNS > 編集

## 管理リソース一覧(terraform/zone/)

### settings.tf - ゾーン設定

| リソース | setting_id | 説明 |
|---|---|---|
| cloudflare_zone_setting | always_use_https | HTTP → HTTPS 301 リダイレクト |
| cloudflare_zone_setting | security_header | HSTS(max-age=1年, includeSubDomains, preload) |
| cloudflare_zone_setting | min_tls_version | 最低 TLS バージョン(1.2) |
| cloudflare_zone_setting | tls_1_3 | TLS 1.3 有効化 |
| cloudflare_zone_setting | opportunistic_encryption | Opportunistic Encryption 有効化 |
| cloudflare_zone_setting | automatic_https_rewrites | 混在コンテンツ自動書き換え |
| cloudflare_zone_setting | browser_check | Browser Integrity Check |
| cloudflare_zone_setting | challenge_ttl | チャレンジ有効時間(30分) |
| cloudflare_zone_setting | http3 | HTTP/3(QUIC)有効化 |
| cloudflare_zone_setting | 0rtt | 0-RTT Connection Resumption |

※ HTTP/2 は Cloudflare で常時有効のため Terraform 管理対象外

### dns.tf - DNS 設定

| リソース | 説明 |
|---|---|
| cloudflare_zone_dnssec | DNSSEC 有効化 |
| cloudflare_dns_record (SPF) | `v=spf1 -all` メール送信全拒否 |
| cloudflare_dns_record (DMARC) | `v=DMARC1; p=reject` 認証失敗メール拒否 |

## コーディング規約

- Terraform ファイル内のコメント・description は日本語で記述
- ファイル構成: `provider.tf` / `vars.tf` / `settings.tf` / `dns.tf` のように機能ごとに分割
- リソースには設定内容の詳細な説明コメントを付与
