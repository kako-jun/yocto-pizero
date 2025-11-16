# Yocto Project for Raspberry Pi Zero (1st Gen)

Raspberry Pi Zero (初代) 向けのカスタマイズされたYocto Linuxビルド環境

## 概要

このリポジトリは、Raspberry Pi Zero (BCM2835) 向けに最適化されたYocto Projectのビルド環境を提供します。

### ターゲットデバイス
- Raspberry Pi Zero (1st generation)
- CPU: ARM11 (BCM2835) 1GHz
- RAM: 512MB

### カスタマイズ内容
- `core-image-minimal` ベースの超軽量イメージ
- **nginx** 軽量Webサーバー
- SSH 有効化（リモート管理用）
- WiFi サポート（USB WiFiアダプタ使用時）
- **opkg** パッケージマネージャー（起動後のパッケージ追加が可能）
- 最小限のシステムツール（nano, htop）

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

## セットアップ手順

### 1. 環境のセットアップ
```bash
# このリポジトリをクローン（既にクローン済みの場合はスキップ）
git clone <repository-url>
cd yocto-pizero

# セットアップスクリプトを実行
./setup.sh
```

### 2. ビルド環境の初期化
```bash
# Yocto環境をソース
source poky/oe-init-build-env build

# 設定ファイルは自動的にコピーされます
```

### 3. イメージのビルド
```bash
# フルビルド（初回は数時間かかります）
bitbake core-image-minimal

# カスタムイメージをビルド
bitbake rpi-zero-custom-image
```

### 4. SDカードへの書き込み
```bash
# ビルド完了後、イメージは以下に生成されます
# build/tmp/deploy/images/raspberrypi0/

# SDカードに書き込み (例: /dev/sdX)
sudo dd if=build/tmp/deploy/images/raspberrypi0/rpi-zero-custom-image-raspberrypi0.wic of=/dev/sdX bs=4M status=progress
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
- [クイックスタートガイド](docs/QUICKSTART.md) - セットアップとビルド手順
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
