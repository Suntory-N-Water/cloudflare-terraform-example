# YouTube Shorts ブロック調査記録(アーカイブ)

> **注意**: この調査は以前の `terraform/gateway/` 構成で実施したものです。
> Gateway リソースは削除済みのため、本ドキュメントはアーカイブとして残しています。

## 目的

iPhone の Safari / YouTube アプリで YouTube Shorts(`/shorts` パス)のみをブロックする。
通常の YouTube 動画には影響を与えない。

## 構成

- Cloudflare Zero Trust Gateway(HTTP ポリシー)で URL パスベースのブロックを実現する
- Terraform(Cloudflare Provider v5)でポリシーを管理
- iPhone に WARP アプリをインストールし、Gateway 経由でトラフィックを検査

## 作成済みリソース(削除済み)

### Terraform リソース(terraform/gateway/ — 削除済み)

| ファイル | 内容 |
|---|---|
| provider.tf | Cloudflare Provider v5 |
| vars.tf | account_id 変数 |
| settings.tf | TLS decryption 有効化 |
| policies.tf | 2つのポリシー(下記) |

### Gateway ポリシー

| ポリシー名 | フィルタ | 条件 | 目的 |
|---|---|---|---|
| Block YouTube Shorts | HTTP (`http`) | `youtube.com` ドメイン + `/shorts` パス | Shorts ページをブロック |
| Block YouTube QUIC | Network (`l4`) | `youtube.com` の UDP 443 | QUIC をブロックし HTTPS にフォールバックさせる |

### スマホ側セットアップ

- WARP アプリ(1.1.1.1)インストール済み、Zero Trust 組織にログイン・接続済み
- Cloudflare ルート証明書インストール済み(iOS プロファイル + 証明書信頼設定で有効化)

### ダッシュボード側設定

- Proxy: オン
- TLS decryption: オン
- デバイス登録ポリシー: 設定済み(One-time PIN 認証)

## 確認済みの事実

### 正常に動作していること

- HTTP 検査は機能している(`www.aso-taro.jp` 等の HTTP/HTTPS サイトが Gateway HTTP ログに表示される)
- DNS は Gateway を経由している(DNS ポリシーで `youtube.com` をブロックしたところ、実際にブロックされた)
- WARP モードは `warp`(Traffic and DNS)で正しい
- TLS decryption は有効で、YouTube CDN ドメイン(`i.ytimg.com`, `yt3.ggpht.com`, `lh3.googleusercontent.com`)は HTTP ログに表示される

### 問題の症状

- `www.youtube.com` が Gateway の **全レイヤー**(DNS / HTTP / Network)のログに表示されない
- HTTP ポリシー自体は正しい条件式だが、トラフィックが HTTP 検査を通過しないためマッチしない
- QUIC ブロックポリシーも Network ログにマッチ記録がない

## 未解決の課題

`www.youtube.com` の HTTPS トラフィックが Gateway の HTTP 検査を通過しない根本原因が不明。
DNS は Gateway 経由であり、TLS decryption も他サイトでは機能している。
YouTube CDN ドメインは検査対象になるが、`www.youtube.com` 本体だけが対象外になっている。

## 検討した仮説

### 仮説 1: ECH(Encrypted Client Hello)

TLS ClientHello の SNI が暗号化されて Gateway がホスト名を識別できない可能性。

**調査結果: 可能性は低い。**
ECH のサーバーサイド展開はほぼ Cloudflare に限定されており、Google/YouTube が ECH を使用している確認は取れなかった。

### 仮説 2: HTTP/2 コネクション合体

別の Google サービスへの既存コネクション上で `youtube.com` のトラフィックが処理され、Gateway が個別に検出できない可能性。

**未検証。**

### 仮説 3: Gateway のデフォルト Do Not Inspect 動作

Cloudflare Gateway が証明書ピンニング等の問題回避のため、特定のアプリケーション(Google/YouTube を含む)を自動的に TLS 検査対象外にしている可能性。
手動で作成した Do Not Inspect ポリシーは存在しないが、Gateway 側のデフォルト動作として除外されている可能性がある。

**未検証。ダッシュボードの Settings > TLS Decryption 周辺に該当設定があるか確認が必要。**

### 仮説 4: iOS Safari 固有の挙動

Safari が WARP トンネルを部分的にバイパスしている、または Google ドメインに対して特殊な名前解決・接続を行っている可能性。
iOS Chrome での確認で切り分け可能だが、未実施。

**未検証。**

## 代替アプローチ(未実施)

HTTP ポリシーでの URL パスベースブロックが困難な場合の代替手段:

- iOS のスクリーンタイムで YouTube Shorts を制限
- YouTube アプリの設定で Shorts を非表示にする方法の調査
- ブラウザ拡張機能による Shorts 非表示(iOS Safari では不可)
