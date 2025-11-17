# Yocto Project for Raspberry Pi Zero (1st Gen)

Raspberry Pi Zero (初代) 向けのカスタマイズされたYocto Linuxビルド環境

## 概要

このリポジトリは、Raspberry Pi Zero (BCM2835) 向けに最適化されたYocto Projectのビルド環境を提供します。

### ターゲットデバイス
- Raspberry Pi Zero (1st generation)
- CPU: ARM11 (BCM2835) 1GHz
- RAM: 512MB

### 利用可能なイメージ

このプロジェクトには3つの特化イメージがあります：

#### 1. **rpi-zero-custom-image** - 軽量Webサーバー
- nginx 軽量Webサーバー
- SSH リモートアクセス
- opkg パッケージマネージャー
- 最小限のツール（nano, htop）

#### 2. **rpi-zero-vpn-gateway** - VPNゲートウェイ
- WireGuard VPN（高速・モダン）
- OpenVPN（互換性重視）
- ダイナミックDNS対応（DuckDNS, No-IP等）
- ファイアウォール（iptables）
- 📄 [VPNセットアップガイド](docs/VPN_SETUP.md)

#### 3. **rpi-zero-webcam-server** - USB Webカメラサーバー
- USB Webカメラサポート（V4L2/UVC）
- ライブストリーミング（mjpg-streamer）
- タイムラプス撮影（ffmpeg）
- Cloudflare Tunnel（CGNAT環境対応）
- Webギャラリー（nginx）
- 📄 [Webカメラセットアップガイド](docs/WEBCAM_SETUP.md)

**どのイメージを選ぶか？** → [イメージ選択ガイド](docs/IMAGE_SELECTION.md)

**注意**: Raspberry Pi Zero 初代には内蔵WiFi/Bluetoothはありません。ネットワーク接続にはUSB WiFiアダプタまたはUSB-Ethernet変換が必要です。

## 前提条件

### システム要件
- Ubuntu 20.04/22.04 または Debian 11/12
- 最小 50GB の空きディスク容量
- 最小 8GB RAM (推奨: 16GB以上)
- インターネット接続

### 必要なパッケージ
```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool
```

## ビルド方法

このプロジェクトは3つの方法でビルドできます：

### 方法1: GitHub Actions で自動ビルド（推奨）

**最も簡単！** GitHubのWebUIからイメージを選択してビルド：

#### 手動実行（イメージ選択可能）
1. GitHubリポジトリページの **Actions** タブ
2. **Build Yocto Image for Raspberry Pi Zero** を選択
3. **Run workflow** → イメージを選択:
   - `rpi-zero-custom-image` - Webサーバー
   - `rpi-zero-vpn-gateway` - VPNゲートウェイ
   - `rpi-zero-webcam-server` - Webカメラサーバー
4. 数時間後、Artifactsからダウンロード

#### タグプッシュ（自動リリース）
```bash
git tag v1.0.0
git push origin v1.0.0
```

- ビルド時間: 3〜6時間（初回）、1〜3時間（2回目以降）
- 必要なもの: GitHubアカウントのみ
- 詳細: [GitHub Actions ガイド](docs/GITHUB_ACTIONS.md)

### 方法2: Docker でビルド（クリーン環境）

**ホストを汚さない！** Dockerコンテナ内でビルド：

```bash
# Webサーバー（デフォルト）
./docker-build.sh

# VPNゲートウェイ
./docker-build.sh rpi-zero-vpn-gateway

# Webカメラサーバー
./docker-build.sh rpi-zero-webcam-server

# ステップバイステップ
./docker-build.sh --setup
./docker-build.sh --build-only rpi-zero-vpn-gateway
```

- 前提条件: Docker, docker-compose
- ビルド時間: 2〜6時間
- 詳細: [Docker ビルドガイド](docs/DOCKER_BUILD.md)

### 方法3: ネイティブビルド（従来の方法）

**直接ビルド：** ホストシステムに直接セットアップ：

#### 前提条件
- Ubuntu 20.04/22.04 または Debian 11/12
- 最小 50GB の空きディスク容量
- 最小 8GB RAM (推奨: 16GB以上)

#### 必要なパッケージ
```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool
```

#### セットアップとビルド
```bash
# セットアップスクリプトを実行
./setup.sh

# ビルド実行（イメージ指定）
./build.sh                          # Webサーバー（デフォルト）
./build.sh rpi-zero-vpn-gateway     # VPNゲートウェイ
./build.sh rpi-zero-webcam-server   # Webカメラサーバー
```

詳細: [クイックスタートガイド](docs/QUICKSTART.md)、[イメージ選択ガイド](docs/IMAGE_SELECTION.md)

---

## SDカードへの書き込み

ビルド完了後（どの方法でも）：

```bash
# イメージファイルの場所
# - ネイティブ/Docker: build/tmp/deploy/images/raspberrypi0/
# - GitHub Actions: Releases からダウンロード

# 圧縮ファイルを解凍（.wic.gzの場合）
gunzip rpi-zero-custom-image-raspberrypi0.wic.gz

# SDカードに書き込み（要注意: /dev/sdX を正しいデバイスに置き換える！）
sudo dd if=rpi-zero-custom-image-raspberrypi0.wic of=/dev/sdX bs=4M status=progress
sudo sync
```

## カスタマイズ

### カスタムレイヤー
`meta-rpi-zero-custom` レイヤーにカスタマイズを追加できます：

- レシピ: `meta-rpi-zero-custom/recipes-*`
- イメージ定義: `meta-rpi-zero-custom/recipes-core/images/`
- 設定: `meta-rpi-zero-custom/conf/`

### 独自パッケージの追加
```bash
# meta-rpi-zero-custom/recipes-example/hello/hello_1.0.bb にレシピを作成
bitbake hello
```

## トラブルシューティング

### ビルドエラー
- ディスク容量を確認: `df -h`
- ビルドキャッシュのクリア: `bitbake -c cleanall <recipe-name>`

### WiFi設定（USB WiFiアダプタ使用時）
起動後、`/etc/wpa_supplicant/wpa_supplicant.conf` を編集してWiFi設定を行います。

### パッケージの追加
起動後に `opkg` を使ってパッケージを追加できます：
```bash
opkg update
opkg install git curl vim
```
詳細は [パッケージ管理ガイド](docs/PACKAGE_MANAGEMENT.md) を参照してください。

### Webサーバーへのアクセス
起動後、Raspberry Pi ZeroのIPアドレスにブラウザでアクセス：
```
http://<Raspberry-Pi-Zero-IP>/
```

## ドキュメント

### ビルド方法
- [GitHub Actions ガイド](docs/GITHUB_ACTIONS.md) - 自動ビルド＆リリース
- [Docker ビルドガイド](docs/DOCKER_BUILD.md) - Dockerを使ったビルド
- [クイックスタートガイド](docs/QUICKSTART.md) - ネイティブビルド手順

### カスタマイズ＆運用
- [パッケージ管理ガイド](docs/PACKAGE_MANAGEMENT.md) - opkgによるパッケージ管理
- [カスタマイズガイド](docs/CUSTOMIZATION.md) - イメージのカスタマイズ方法
- [トラブルシューティング](docs/TROUBLESHOOTING.md) - よくある問題と解決方法

## 参考情報
- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [meta-raspberrypi Layer](https://github.com/agherzan/meta-raspberrypi)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [nginx Documentation](https://nginx.org/en/docs/)

## ライセンス
各Yoctoレイヤーのライセンスに従います。
