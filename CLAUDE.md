## プロジェクト概要

Cloudflare の各種サービスを Terraform で管理するサンプルリポジトリ。
Cloudflare Terraform Provider v5 を使用。

## ディレクトリ構成

```
terraform/
  └── gateway/     # Zero Trust Gateway(HTTP ポリシー、TLS Decryption 設定)
```

プロダクト単位でディレクトリを分割する構成。新しい Cloudflare プロダクトを追加する場合は `terraform/<product>/` にディレクトリを作成する。

## Terraform コマンド

```bash
# 各ディレクトリに cd してから実行
cd terraform/gateway

terraform init
terraform plan
terraform apply
```

## 認証

- API トークンは環境変数 `CLOUDFLARE_API_TOKEN` で渡す(provider ブロックにハードコードしない)
- `.env.example` を `.env` にコピーしてトークンを設定
- `account_id` は `terraform.tfvars` で管理(git 管理外)

## コーディング規約

- Terraform ファイル内のコメント・description は日本語で記述
- ファイル構成: `provider.tf` / `vars.tf` / `settings.tf` / `policies.tf` のように機能ごとに分割
- ポリシーリソースには traffic 条件式の詳細な説明コメントを付与
