# イメージビルド方法まとめ

このプロジェクトには3つの特化イメージがあります。

## 📦 利用可能なイメージ

| イメージ名 | 用途 | 主な機能 |
|-----------|------|----------|
| **rpi-zero-custom-image** | 軽量Webサーバー | nginx, SSH, opkg |
| **rpi-zero-vpn-gateway** | VPNゲートウェイ | WireGuard, OpenVPN, DDNS |
| **rpi-zero-webcam-server** | USB Webカメラサーバー | mjpg-streamer, タイムラプス, Cloudflare Tunnel |
| core-image-minimal | 最小限のベースイメージ | SSH, 基本ツール |

---

## 🚀 ビルド方法

### 方法1: GitHub Actions（推奨・簡単）

#### 手動実行（イメージ選択可能）

1. GitHubリポジトリページへ移動
2. **Actions** タブをクリック
3. **Build Yocto Image for Raspberry Pi Zero** を選択
4. **Run workflow** ボタンをクリック
5. ドロップダウンから**イメージを選択**:
   - `rpi-zero-custom-image` - Webサーバー
   - `rpi-zero-vpn-gateway` - VPNゲートウェイ
   - `rpi-zero-webcam-server` - Webカメラサーバー
   - `core-image-minimal` - 最小イメージ
6. **Run workflow** を実行

ビルド完了後、**Artifacts** からダウンロード可能（30日間保存）

#### タグプッシュ（自動リリース作成）

特定のイメージ用にタグを作成：

```bash
# Webサーバーイメージ
git tag v1.0.0-webserver
git push origin v1.0.0-webserver

# VPNゲートウェイ
git tag v1.0.0-vpn
git push origin v1.0.0-vpn

# Webカメラサーバー
git tag v1.0.0-webcam
git push origin v1.0.0-webcam
```

**注意**: タグプッシュ時は、GitHub Actionsのワークフローでデフォルトイメージ（rpi-zero-custom-image）がビルドされます。別のイメージをビルドしたい場合は手動実行を使用してください。

---

### 方法2: Docker（ローカルビルド）

#### イメージ指定してビルド

```bash
# Webサーバー（デフォルト）
./docker-build.sh
./docker-build.sh rpi-zero-custom-image

# VPNゲートウェイ
./docker-build.sh rpi-zero-vpn-gateway

# Webカメラサーバー
./docker-build.sh rpi-zero-webcam-server

# 最小イメージ
./docker-build.sh core-image-minimal
```

#### ステップバイステップ

```bash
# セットアップのみ（初回）
./docker-build.sh --setup

# 特定イメージをビルド
./docker-build.sh --build-only rpi-zero-vpn-gateway

# コンテナシェルに入る
./docker-build.sh --shell
# シェル内で:
source poky/oe-init-build-env build
bitbake rpi-zero-webcam-server
```

---

### 方法3: ネイティブビルド

#### 直接bitbakeコマンド

```bash
# セットアップ（初回のみ）
./setup.sh

# Yocto環境をソース
source poky/oe-init-build-env build

# イメージをビルド
bitbake rpi-zero-custom-image
# または
bitbake rpi-zero-vpn-gateway
# または
bitbake rpi-zero-webcam-server
```

#### ビルドスクリプト使用

```bash
# デフォルト（Webサーバー）
./build.sh

# イメージ指定
./build.sh rpi-zero-vpn-gateway
./build.sh rpi-zero-webcam-server
```

---

## 📥 ビルド成果物の場所

### GitHub Actions

- **手動実行**: Actionsページ → 実行ジョブ → Artifacts → `yocto-raspberrypi0-image` をダウンロード
- **タグプッシュ**: Releasesページから `.wic.gz` ファイルをダウンロード

### Docker / ネイティブ

```bash
build/tmp/deploy/images/raspberrypi0/

# ファイル例:
# - rpi-zero-custom-image-raspberrypi0.wic
# - rpi-zero-vpn-gateway-raspberrypi0.wic
# - rpi-zero-webcam-server-raspberrypi0.wic
```

---

## 🎯 イメージ選択ガイド

### どのイメージを選ぶべきか？

#### シンプルなWebサーバーが欲しい
→ **rpi-zero-custom-image**
```bash
./docker-build.sh rpi-zero-custom-image
```

#### 自宅VPNサーバーを構築したい
→ **rpi-zero-vpn-gateway**
```bash
./docker-build.sh rpi-zero-vpn-gateway
```
- WireGuard（高速・モダン）
- OpenVPN（互換性重視）
- DDNS対応（動的IP対応）

#### USB Webカメラで監視・タイムラプスしたい
→ **rpi-zero-webcam-server**
```bash
./docker-build.sh rpi-zero-webcam-server
```
- ライブストリーミング
- タイムラプス撮影
- Cloudflare Tunnel（CGNAT対応）

#### 最小限から自分でカスタマイズしたい
→ **core-image-minimal**
```bash
./docker-build.sh core-image-minimal
```

---

## 🔄 複数イメージを連続ビルド

### GitHub Actionsで複数実行

1. Actionsページで手動実行
2. 1つ目のイメージを選択して実行
3. 完了後、再度手動実行
4. 2つ目のイメージを選択して実行

### Dockerで複数ビルド

```bash
# セットアップは1回のみ
./docker-build.sh --setup

# 各イメージをビルド
./docker-build.sh --build-only rpi-zero-custom-image
./docker-build.sh --build-only rpi-zero-vpn-gateway
./docker-build.sh --build-only rpi-zero-webcam-server
```

### ネイティブで複数ビルド

```bash
source poky/oe-init-build-env build

# 連続ビルド
bitbake rpi-zero-custom-image
bitbake rpi-zero-vpn-gateway
bitbake rpi-zero-webcam-server
```

---

## ⏱️ ビルド時間の目安

| イメージ | 初回ビルド | 2回目以降（キャッシュあり） |
|---------|-----------|------------------------|
| core-image-minimal | 2-3時間 | 30分-1時間 |
| rpi-zero-custom-image | 3-4時間 | 1-1.5時間 |
| rpi-zero-vpn-gateway | 3-4時間 | 1-1.5時間 |
| rpi-zero-webcam-server | 4-5時間 | 1.5-2時間 |

**高速化のコツ:**
- キャッシュ（downloads, sstate-cache）を活用
- 並列ビルド数を増やす（CPUコア数に応じて）
- SSDを使用

---

## 📋 ビルドオプション比較

| 項目 | GitHub Actions | Docker | ネイティブ |
|------|---------------|--------|----------|
| セットアップ | 自動 | 簡単 | 手動 |
| イメージ選択 | UI選択 | コマンド引数 | bitbake引数 |
| ビルド時間 | 3-6時間 | 2-6時間 | 2-6時間 |
| ディスク容量 | 不要（クラウド） | 60GB+ | 60GB+ |
| 並列実行 | 1つずつ | 可能 | 可能 |
| 成果物DL | Web経由 | ローカル | ローカル |

---

## 💡 よくある質問

### Q: デフォルトでビルドされるイメージは？

**A**: `rpi-zero-custom-image`（nginx Webサーバー）

### Q: GitHub Actionsで全イメージをビルドできる？

**A**: 手動実行を複数回行うことで可能です。1回の実行では1つのイメージのみ。

### Q: イメージ名を間違えたらどうなる？

**A**: bitbakeがエラーを出します。正しいイメージ名は以下の通り：
- `rpi-zero-custom-image`
- `rpi-zero-vpn-gateway`
- `rpi-zero-webcam-server`
- `core-image-minimal`

### Q: カスタムイメージを作りたい場合は？

**A**: 既存イメージをコピーして修正：

```bash
cp meta-rpi-zero-custom/recipes-core/images/rpi-zero-custom-image.bb \
   meta-rpi-zero-custom/recipes-core/images/my-custom-image.bb

# 編集
nano meta-rpi-zero-custom/recipes-core/images/my-custom-image.bb

# ビルド
bitbake my-custom-image
```

---

## 🔧 トラブルシューティング

### イメージが見つからない

```bash
# 利用可能なイメージを確認
bitbake-layers show-recipes | grep rpi-zero

# 出力例:
# rpi-zero-custom-image
# rpi-zero-vpn-gateway
# rpi-zero-webcam-server
```

### ビルドが途中で失敗

```bash
# 失敗したレシピをクリーン
bitbake -c cleanall <レシピ名>

# 再ビルド
bitbake <イメージ名>
```

### 複数イメージでディスク不足

```bash
# 古いビルドをクリーンアップ
rm -rf build/tmp

# または rm_work を有効化（build/conf/local.conf）
INHERIT += "rm_work"
```

---

## 📚 関連ドキュメント

- [GitHub Actions ビルドガイド](GITHUB_ACTIONS.md)
- [Docker ビルドガイド](DOCKER_BUILD.md)
- [VPNセットアップガイド](VPN_SETUP.md)
- [Webカメラセットアップガイド](WEBCAM_SETUP.md)
