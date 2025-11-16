# クイックスタートガイド

Raspberry Pi Zero 向け Yocto Project のクイックスタートガイド

## 前提条件の確認

### システム要件
- Ubuntu 20.04/22.04 または Debian 11/12
- 50GB以上の空きディスク容量
- 8GB以上のRAM（推奨: 16GB以上）
- インターネット接続

### 必要なパッケージのインストール

```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool
```

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-username/yocto-pizero.git
cd yocto-pizero
```

### 2. セットアップスクリプトの実行

```bash
./setup.sh
```

このスクリプトは以下を実行します：
- Poky（Yocto Project）のクローン
- meta-raspberrypi レイヤーのクローン
- meta-openembedded レイヤーのクローン
- カスタムレイヤーの作成
- 設定ファイルのコピー

**注意**: 初回は数分〜数十分かかります（ネットワーク速度による）

### 3. 設定ファイルの確認（オプション）

```bash
# local.conf を確認・編集
nano build/conf/local.conf

# bblayers.conf を確認
cat build/conf/bblayers.conf
```

主な設定項目：
- `BB_NUMBER_THREADS`: ビルドスレッド数（CPUコア数に合わせて調整）
- `PARALLEL_MAKE`: コンパイル並列数
- `DL_DIR`: ダウンロードキャッシュディレクトリ

## ビルド

### 方法1: ビルドスクリプトを使用（推奨）

```bash
# デフォルト（core-image-minimal）
./build.sh

# カスタムイメージ
./build.sh rpi-zero-custom-image
```

### 方法2: 手動ビルド

```bash
# Yocto環境をソース
source poky/oe-init-build-env build

# ビルド実行
bitbake core-image-minimal
# または
bitbake rpi-zero-custom-image
```

**ビルド時間**: 初回は2〜6時間程度（システム性能による）

## SDカードへの書き込み

### 1. イメージファイルの確認

```bash
ls -lh build/tmp/deploy/images/raspberrypi0/*.wic
```

### 2. SDカードの準備

SDカードを挿入し、デバイス名を確認：

```bash
lsblk
# 例: /dev/sdb （必ず正しいデバイスを確認！）
```

### 3. イメージの書き込み

```bash
# 警告: /dev/sdX は実際のSDカードデバイスに置き換えてください
# 間違えるとシステムが破壊されます！

sudo dd if=build/tmp/deploy/images/raspberrypi0/core-image-minimal-raspberrypi0.wic \
    of=/dev/sdX \
    bs=4M \
    status=progress

sudo sync
```

## 初回起動

### 1. SDカードをRaspberry Pi Zeroに挿入

### 2. シリアルコンソールまたはSSH接続

**デフォルト認証情報**:
- ユーザー名: `root`
- パスワード: なし（debug-tweaks有効時）

**SSH接続**:
```bash
# DHCPでIPアドレスを取得している場合
ssh root@raspizero.local
# または
ssh root@<IPアドレス>
```

### 3. WiFi設定（WiFi使用の場合）

```bash
# 設定テンプレートをコピー
cp /etc/wpa_supplicant/wpa_supplicant.conf.template \
   /etc/wpa_supplicant/wpa_supplicant.conf

# 設定を編集（SSID、パスワードを入力）
nano /etc/wpa_supplicant/wpa_supplicant.conf

# WiFiインターフェースを起動
ifup wlan0
```

## 次のステップ

- [カスタマイズガイド](./CUSTOMIZATION.md) - イメージのカスタマイズ方法
- [トラブルシューティング](./TROUBLESHOOTING.md) - よくある問題と解決方法
- [README.md](../README.md) - プロジェクト概要

## よくある質問

### Q: ビルドが途中で止まった
A: エラーメッセージを確認し、`bitbake -c cleanall <レシピ名>` で該当レシピをクリアしてから再実行

### Q: ディスク容量が足りない
A: `build/tmp` ディレクトリを削除するか、`INHERIT += "rm_work"` を local.conf に追加

### Q: WiFiが繋がらない
A: wpa_supplicant.conf の設定を確認、`wpa_cli status` でステータスを確認

### Q: SSH接続できない
A: シリアルコンソールで `systemctl status sshd` を確認、ネットワーク設定を確認
