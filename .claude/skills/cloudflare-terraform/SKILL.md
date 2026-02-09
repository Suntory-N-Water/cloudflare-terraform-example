---
name: cloudflare-terraform
description: Cloudflare Terraform プロバイダーを使ったインフラ設定のベストプラクティスガイド。Cloudflare リソースの Terraform コード作成、DNS レコード、WAF ルールセット、レート制限、DDoS 対策、Transform Rules、ロードバランサー、ゾーン設定などの .tf ファイル作成時に使用する。「Cloudflare の Terraform を書いて」「WAF ルールを Terraform で設定」「DNS レコードを追加」「レート制限を設定」「Cloudflare の設定をコードで管理」などのリクエストで起動する。
---

# Cloudflare Terraform ベストプラクティス

Cloudflare Terraform プロバイダー（v5）を使ってインフラ設定を作成する際のガイドライン。

## プロバイダー設定

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "cloudflare" {
  # API トークンは環境変数 CLOUDFLARE_API_TOKEN から自動読み込み
}
```

認証情報は .tf ファイルにハードコードせず、環境変数を使う。

## ディレクトリ構成

アカウント > ゾーン > プロダクト の階層で分離する。

```
project/
├── account_a/
│   ├── users/
│   │   ├── provider.tf
│   │   ├── users.tf
│   │   └── vars.tf
│   └── zone_a/
│       ├── dns/
│       │   ├── dns.tf
│       │   ├── provider.tf
│       │   └── vars.tf
│       └── waf/
│           ├── waf.tf
│           ├── provider.tf
│           └── vars.tf
```

ファイル命名規則:

- `provider.tf` - プロバイダー設定
- `<subject>.tf` - リソース定義（dns.tf, waf.tf など）
- `vars.tf` - 変数定義

## 必須ルール

### 認証情報の安全管理

- API トークンは環境変数 `CLOUDFLARE_API_TOKEN` で渡す
- `terraform.tfvars` は `.gitignore` に含める
- CI/CD では Vault 等のシークレット管理ツールを使う

### .gitignore

```
.terraform/
*.tfstate*
.terraform.lock.hcl
terraform.tfvars
```

### 変数は sensitive フラグを付ける

```hcl
variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}
```

### Terraform 管理下のリソースは Terraform でのみ変更する

ダッシュボードや API で直接変更すると state が不一致になる。

### ルールセットには必ず ref フィールドを付ける

`ref` がないと、ルールセット変更時にルール ID が変わる。

```hcl
rules {
  ref         = "unique_rule_identifier"  # 必須
  description = "Rule description"
  expression  = "true"
  action      = "execute"
}
```

### モジュールは避ける（または控えめに使う）

モジュールや dynamic ブロックは予期しない問題を引き起こしやすい。リソースを直接定義する方が安全。

### 環境分離にはアカウントを分ける

staging と production でアカウントを分離する（例: `example.com` と `example-staging.com`）。アカウントレベルのリソース（LB モニター、プール等）が共有されるため。

## ゾーンレベル vs アカウントレベル

| 項目            | ゾーンレベル | アカウントレベル                   |
| --------------- | ------------ | ---------------------------------- |
| scope           | 単一ゾーン   | 複数ゾーン                         |
| kind            | `"zone"`     | `"root"`                           |
| ID パラメータ   | `zone_id`    | `account_id`                       |
| プラン要件      | なし         | Enterprise + 有料アドオン          |
| expression 要件 | なし         | 末尾に `and cf.zone.plan eq "ENT"` |

## 主要 phase 一覧

| phase                             | 用途                           |
| --------------------------------- | ------------------------------ |
| `http_request_firewall_managed`   | WAF Managed Rules              |
| `http_request_firewall_custom`    | WAF カスタムルール             |
| `http_ratelimit`                  | レート制限ルール               |
| `ddos_l7`                         | HTTP DDoS 対策                 |
| `ddos_l4`                         | ネットワークレイヤー DDoS 対策 |
| `http_request_transform`          | URL リライト                   |
| `http_request_late_transform`     | リクエストヘッダー変更         |
| `http_response_headers_transform` | レスポンスヘッダー変更         |

## WAF 例外ルールの配置順序

例外（skip）ルールは、対象のマネージドルールセット実行ルールの **前に** 配置する。

```hcl
resource "cloudflare_ruleset" "waf" {
  # ...
  rules { ... action = "skip" ... }      # 1. 例外ルール（先）
  rules { ... action = "execute" ... }    # 2. 実行ルール（後）
}
```

## 既存リソースのインポート

`cf-terraforming` を使って既存の Cloudflare 設定を Terraform に取り込む。

```sh
# 設定ファイル生成
cf-terraforming generate \
  --email $CLOUDFLARE_EMAIL \
  --token $CLOUDFLARE_API_TOKEN \
  -z $CLOUDFLARE_ZONE_ID \
  --resource-type cloudflare_record > dns.tf

# state インポートコマンド生成
cf-terraforming import \
  --resource-type cloudflare_record \
  --email $CLOUDFLARE_EMAIL \
  --key $CLOUDFLARE_API_KEY \
  --zone $CLOUDFLARE_ZONE_ID
```

## リモートバックエンド（R2）

```hcl
terraform {
  backend "s3" {
    bucket                      = "<BUCKET_NAME>"
    key                         = "/some/key/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    access_key                  = "<R2_ACCESS_KEY>"
    secret_key                  = "<R2_ACCESS_SECRET>"
    endpoints = {
      s3 = "https://<ACCOUNT_ID>.r2.cloudflarestorage.com"
    }
  }
}
```

## リファレンス

- リソース設定例: [references/resource-examples.md](references/resource-examples.md) を参照。DNS、WAF、レート制限、DDoS、Transform Rules、ロードバランサー等のコード例を収録。
- トラブルシューティング: [references/troubleshooting.md](references/troubleshooting.md) を参照。よくあるエラーと解決方法を収録。
