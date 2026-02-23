terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# API トークンは環境変数 CLOUDFLARE_API_TOKEN から自動読み込み
provider "cloudflare" {}
