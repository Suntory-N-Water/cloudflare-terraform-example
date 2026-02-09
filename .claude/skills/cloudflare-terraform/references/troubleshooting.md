# Cloudflare Terraform トラブルシューティング

## 目次

- [DNS レコード作成時の 403 認証エラー](#dns-レコード作成時の-403-認証エラー)
- [ルールセット更新時のルール ID 変更](#ルールセット更新時のルール-id-変更)
- [Terraform state とリモートの不一致](#terraform-state-とリモートの不一致)

---

## DNS レコード作成時の 403 認証エラー

### 症状

```
Error: failed to create DNS record: HTTP status 403: Authentication error (10000)
```

### 原因

`data.cloudflare_zones` を使用する際にインデックス `[0]` を付けていない。

### 修正

```hcl
# 誤り
zone_id = data.cloudflare_zones.example_com.id

# 正しい
zone_id = data.cloudflare_zones.example_com.zones[0].id
```

---

## ルールセット更新時のルール ID 変更

### 症状

`cloudflare_ruleset` リソースを変更すると、既存のルールが削除されて新しいルールが作成される（ルール ID が変わる）。

### 原因

API がTerraform設定の新しいルールと既存ルールを対応付けできない。

### 修正

全てのルールに `ref` フィールドを追加する。`ref` はルールセット内で一意の外部識別子。

```hcl
rules {
  ref         = "my_unique_rule_ref"  # これを追加
  description = "My rule"
  expression  = "true"
  action      = "execute"
  # ...
}
```

注意: `ref` 値を変更すると新しいルールが作成される。

`cf-terraforming` でインポートした場合、`ref` はルール ID と同じ値で自動設定される。

---

## Terraform state とリモートの不一致

### 症状

`terraform plan` で予期しない差分が表示される。リソースの再作成が提案される。

### 原因

Terraform管理下のリソースをダッシュボードやAPIで直接変更した。

### 修正

1. Terraform管理下のリソースは必ずTerraformで変更する
2. 既にずれた場合は `terraform import` で状態を再同期する
3. `cf-terraforming` で既存設定をTerraformに取り込む
