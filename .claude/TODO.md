# TODO リスト

## 🔥 優先度: 高（次にやるべきこと）

### Cloudflare Tunnel 統一対応
**期限**: なるべく早く
**理由**: ユーザーがCGNAT環境（ケーブルテレビ回線）のため、全イメージで外部公開できるようにする

**タスク**:
- [ ] 共通Cloudflare Tunnelレシピ作成
  - [ ] `meta-rpi-zero-custom/recipes-cloudflare/cloudflare-tunnel-scripts/` ディレクトリ作成
  - [ ] `cloudflare-tunnel-scripts_1.0.bb` レシピ作成
  - [ ] Webカメラの `setup-cloudflare-tunnel.sh` を汎用化
  - [ ] nginx/WireGuard/その他サービスに対応

- [ ] rpi-zero-custom-image に Cloudflare Tunnel 追加
  - [ ] IMAGE_INSTALL に cloudflare-tunnel-scripts 追加
  - [ ] セットアップ手順をREADMEに追記
  - [ ] テスト

- [ ] rpi-zero-vpn-gateway に Cloudflare Tunnel 追加
  - [ ] IMAGE_INSTALL に cloudflare-tunnel-scripts 追加
  - [ ] VPN over Cloudflare の説明追加
  - [ ] テスト

- [ ] ドキュメント更新
  - [ ] IMAGE_SELECTION.md: Cloudflare対応状況を更新
  - [ ] README.md: CGNAT対応を明記
  - [ ] 新規: CLOUDFLARE_TUNNEL.md 作成（共通ガイド）

**完了条件**:
- 全3イメージでCloudflare Tunnel使用可能
- ユーザーがCGNAT環境でも全機能を外部公開できる

---

### GitHub Actions 実ビルドテスト
**期限**: Cloudflare対応後
**理由**: 実際にビルドが動作するか検証が必要

**タスク**:
- [ ] 手動実行テスト
  - [ ] rpi-zero-custom-image
  - [ ] rpi-zero-vpn-gateway
  - [ ] rpi-zero-webcam-server

- [ ] タグプッシュテスト
  - [ ] v0.1.0 でテストリリース作成
  - [ ] Artifacts確認
  - [ ] Releasesページ確認

- [ ] 問題があれば修正
  - [ ] ディスク容量不足対策
  - [ ] タイムアウト対策
  - [ ] ワークフロー調整

**完了条件**:
- 3つのイメージすべてがGitHub Actionsでビルド成功
- Releasesから .wic.gz ファイルがダウンロード可能

---

## ⚡ 優先度: 中

### 追加の特化イメージ検討
**理由**: ユーザーの用途拡大

**候補**:
1. **rpi-zero-iot-sensor** (IoTセンサーハブ)
   - [ ] レシピ作成
   - [ ] Python3 + センサーライブラリ
   - [ ] MQTT クライアント
   - [ ] セットアップスクリプト
   - [ ] ドキュメント

2. **rpi-zero-netmon** (ネットワークモニター)
   - [ ] レシピ作成
   - [ ] tcpdump, wireshark-cli
   - [ ] ログ収集機能
   - [ ] ドキュメント

3. **rpi-zero-nas** (軽量NASサーバー)
   - [ ] レシピ作成
   - [ ] Samba設定
   - [ ] USB HDD対応
   - [ ] ドキュメント

**判断基準**: ユーザーリクエストがあれば実装

---

### ビルド高速化
**理由**: GitHub Actionsのタイムアウト対策

**タスク**:
- [ ] sstate-cache最適化
  - [ ] GitHub Actionsでのキャッシュサイズ確認
  - [ ] キャッシュキー改善
  - [ ] 複数ブランチでの共有検討

- [ ] rm_work有効化の影響確認
  - [ ] ビルド時間測定
  - [ ] ディスク使用量測定
  - [ ] デフォルト有効化を検討

- [ ] 並列ビルド最適化
  - [ ] GitHub ActionsのCPUコア数確認
  - [ ] BB_NUMBER_THREADS調整
  - [ ] PARALLEL_MAKE調整

**完了条件**:
- 初回ビルド時間: 4時間以内
- 2回目以降: 1.5時間以内

---

### ドキュメント改善
**理由**: ユーザビリティ向上

**タスク**:
- [ ] クイックスタート動画作成（オプション）
- [ ] FAQセクション拡充
- [ ] 各イメージのユースケース追加
- [ ] スクリーンショット追加

---

## 💡 優先度: 低（将来的に）

### セキュリティ強化
- [ ] fail2ban 追加検討
- [ ] rootless 実行の検討
- [ ] SELinux/AppArmorの検討
- [ ] 自動セキュリティ更新

### 監視・ログ機能
- [ ] Prometheus exporter
- [ ] syslog-ng設定
- [ ] ログローテーション強化

### OTA更新対応
- [ ] mender 統合検討
- [ ] swupdate 検討
- [ ] A/Bパーティション構成

### パフォーマンス最適化
- [ ] イメージサイズ削減
- [ ] 起動時間短縮
- [ ] メモリ使用量最適化

---

## ✅ 完了済み

### 2025-11-17
- [x] プロジェクト初期セットアップ
- [x] setup.sh 作成
- [x] build.sh 作成
- [x] docker-build.sh 作成
- [x] GitHub Actions ワークフロー作成
- [x] rpi-zero-custom-image (Webサーバー) 作成
- [x] rpi-zero-vpn-gateway (VPN) 作成
- [x] rpi-zero-webcam-server (Webカメラ) 作成
- [x] VPNセットアップスクリプト作成
- [x] Webカメラセットアップスクリプト作成
- [x] ドキュメント整備
  - [x] README.md
  - [x] VPN_SETUP.md
  - [x] WEBCAM_SETUP.md
  - [x] IMAGE_SELECTION.md
  - [x] DOCKER_BUILD.md
  - [x] GITHUB_ACTIONS.md
  - [x] PACKAGE_MANAGEMENT.md
  - [x] TROUBLESHOOTING.md
  - [x] CUSTOMIZATION.md
- [x] イメージ選択方法の統一
- [x] プロジェクト管理ドキュメント作成 (CLAUDE.md, TODO.md)

---

## 📝 メモ・アイデア

### Cloudflare Tunnel 統一実装のポイント
- Webカメラの実装をベースに汎用化
- 各サービスのポート番号を柔軟に設定可能に
- 複数サービスの同時公開に対応
- 設定ファイル: `/root/.cloudflared/config.yml`
- サービス例:
  ```yaml
  ingress:
    - hostname: web.example.com
      service: http://localhost:80
    - hostname: vpn.example.com
      service: http://localhost:51820  # WireGuardステータスページなど
  ```

### ユーザー環境
- ケーブルテレビ回線
- CGNAT環境（共有グローバルIP）
- Cloudflareアカウント保有 ✅
- Raspberry Pi Zero 初代（余りもの）

### 今後の拡張案
1. Tailscale統合（VPN代替案）
2. 複数カメラ対応
3. モーション検知
4. AI画像認識（TensorFlow Lite）
5. スマートホームハブ化

---

## 🐛 既知の問題

### 未解決
- GitHub Actionsでの実ビルド未検証
- 実機でのテスト不足
- CGNAT環境でのVPN動作検証が必要

### 対処済み
- イメージ選択方法の不統一 → IMAGE_SELECTION.md作成で解決
- Dockerビルドスクリプトのヘルプ不足 → 更新済み

---

## 📊 進捗状況

**全体進捗**: 約 70%

- [x] 基本環境構築 (100%)
- [x] イメージ作成 (100%)
- [x] ビルド自動化 (100%)
- [x] ドキュメント (90%)
- [ ] Cloudflare統一対応 (0%) ← 次のタスク
- [ ] 実機テスト (0%)
- [ ] GitHub Actionsテスト (0%)

**次のマイルストーン**: Cloudflare Tunnel統一対応完了
**最終目標**: v1.0.0 正式リリース
