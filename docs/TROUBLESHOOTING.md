# トラブルシューティングガイド

Yocto Project ビルドでよくある問題と解決方法

## ビルドエラー

### 1. ディスク容量不足

**症状**:
```
ERROR: No space left on device
```

**解決方法**:
```bash
# ディスク容量を確認
df -h

# 不要なビルドファイルを削除
rm -rf build/tmp

# または、ビルド後に作業ディレクトリを自動削除
# local.conf に追加:
INHERIT += "rm_work"
```

### 2. ネットワークエラー

**症状**:
```
ERROR: Fetcher failure: Unable to fetch URL
```

**解決方法**:
```bash
# プロキシ設定を確認（必要な場合）
# local.conf に追加:
http_proxy = "http://proxy.example.com:8080"
https_proxy = "http://proxy.example.com:8080"

# ダウンロードを再試行
bitbake -c cleanall <パッケージ名>
bitbake <パッケージ名>
```

### 3. ビルド依存関係エラー

**症状**:
```
ERROR: Nothing PROVIDES 'xxx'
ERROR: xxx was skipped: missing required distro feature
```

**解決方法**:
```bash
# レイヤーの依存関係を確認
bitbake-layers show-layers

# 必要なレイヤーを追加
# bblayers.conf を編集

# 必要なDISTRO_FEATURESを追加
# local.conf に追加:
DISTRO_FEATURES:append = " systemd"
```

### 4. チェックサムエラー

**症状**:
```
ERROR: Checksum mismatch
```

**解決方法**:
```bash
# ダウンロードキャッシュをクリア
rm -rf downloads/<パッケージ名>

# 再ダウンロード
bitbake -c cleanall <パッケージ名>
bitbake <パッケージ名>

# または、レシピのSRCREVを更新
```

## ランタイムエラー

### 1. WiFiが接続できない

**症状**: WiFiインターフェースが見つからない、接続できない

**解決方法**:
```bash
# WiFiインターフェースを確認
ip link show

# ファームウェアを確認
dmesg | grep firmware

# local.conf に以下を追加してリビルド:
IMAGE_INSTALL:append = " linux-firmware-rpidistro-bcm43430"

# wpa_supplicant設定を確認
cat /etc/wpa_supplicant/wpa_supplicant.conf

# WiFiインターフェースを手動で起動
ifconfig wlan0 up
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
dhclient wlan0
```

### 2. SSH接続できない

**症状**: SSH接続が拒否される

**解決方法**:
```bash
# SSHサーバーの状態を確認（シリアルコンソールから）
systemctl status sshd
# または
systemctl status dropbear

# SSHサーバーを起動
systemctl start sshd

# イメージにSSHサーバーが含まれているか確認
# イメージレシピに以下が含まれているか確認:
EXTRA_IMAGE_FEATURES += "ssh-server-openssh"

# ネットワーク接続を確認
ip addr show
ping 8.8.8.8
```

### 3. カーネルパニック

**症状**: 起動時にカーネルパニックが発生

**解決方法**:
```bash
# シリアルコンソールでエラーメッセージを確認
# ブートログを確認

# config.txt の設定を確認（SDカードのbootパーティション）
# 以下を追加してデバッグ:
enable_uart=1
console=serial0,115200

# SDカードの整合性を確認
sudo fsck /dev/sdX2

# イメージを再書き込み
```

### 4. GPIO/I2C/SPIが使えない

**症状**: デバイスにアクセスできない

**解決方法**:
```bash
# デバイスツリーオーバーレイを有効化
# config.txt（SDカードのbootパーティション）に追加:
dtparam=i2c_arm=on
dtparam=spi=on

# または、local.confに追加してリビルド:
ENABLE_I2C = "1"
ENABLE_SPI = "1"
ENABLE_UART = "1"

# カーネルモジュールを確認
lsmod | grep i2c
lsmod | grep spi

# デバイスファイルを確認
ls -l /dev/i2c*
ls -l /dev/spidev*
```

## パフォーマンス問題

### 1. ビルドが遅い

**解決方法**:
```bash
# 並列ビルド設定を最適化
# local.conf を編集:
BB_NUMBER_THREADS = "8"  # CPUコア数に合わせる
PARALLEL_MAKE = "-j 8"   # CPUコア数に合わせる

# 共有ステートキャッシュを使用
SSTATE_DIR = "/path/to/shared/sstate-cache"

# ダウンロードキャッシュを共有
DL_DIR = "/path/to/shared/downloads"
```

### 2. ディスク I/O がボトルネック

**解決方法**:
```bash
# tmpをRAMディスクに配置（十分なRAMがある場合）
# /etc/fstab に追加:
tmpfs /path/to/build/tmp tmpfs defaults,size=20G 0 0

# または、SSDを使用
```

## デバッグテクニック

### 1. ビルドログの確認

```bash
# 詳細なログを出力
bitbake -v -D <イメージ名>

# 特定のタスクのログを確認
cat build/tmp/work/<arch>/<package>/<version>/temp/log.do_compile
```

### 2. パッケージ情報の確認

```bash
# パッケージの環境変数を表示
bitbake -e <パッケージ名> | less

# 依存関係グラフの生成
bitbake -g <イメージ名>
dot -Tpng task-depends.dot -o deps.png

# インストールされるパッケージ一覧
bitbake -g <イメージ名> && cat pn-depends.dot | grep -v -e '-native' | grep -v digraph | grep -v -e '-image' | awk '{print $1}' | sort | uniq
```

### 3. devshell の使用

```bash
# パッケージのビルド環境に入る
bitbake -c devshell <パッケージ名>

# 手動でコンパイルを試行
$CC $CFLAGS source.c -o output
```

### 4. シリアルコンソール接続

```bash
# UARTピンヘッダーを使用（GPIO 14/15）
# screen, minicom, picocom などを使用

screen /dev/ttyUSB0 115200

# または
minicom -D /dev/ttyUSB0 -b 115200
```

## よくある質問

### Q: ビルドが何時間経っても終わらない

**A**:
- 初回ビルドは2〜6時間かかることが普通です
- システムのCPU/メモリ/ディスク速度に依存します
- `top` や `htop` でビルドプロセスを監視してください
- ネットワークが遅い場合、ダウンロードに時間がかかります

### Q: イメージサイズが大きすぎる

**A**:
```bash
# 不要なパッケージを削除
# イメージレシピから IMAGE_INSTALL:append を確認

# DISTRO_FEATURES を最小化
# local.conf で最小限の機能のみ有効化

# 圧縮イメージを使用
IMAGE_FSTYPES = "wic.gz wic.bz2"
```

### Q: アップデート後にビルドが失敗する

**A**:
```bash
# 全てのレイヤーを同じブランチに合わせる
cd poky && git checkout kirkstone
cd ../meta-raspberrypi && git checkout kirkstone
cd ../meta-openembedded && git checkout kirkstone

# クリーンビルド
rm -rf build/tmp
bitbake <イメージ名>
```

### Q: カスタムレシピが認識されない

**A**:
```bash
# レイヤーが bblayers.conf に含まれているか確認
bitbake-layers show-layers

# レイヤーを追加
bitbake-layers add-layer ../meta-rpi-zero-custom

# レシピを検索
bitbake-layers show-recipes | grep <レシピ名>
```

## サポートリソース

### 公式ドキュメント
- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [BitBake User Manual](https://docs.yoctoproject.org/bitbake/)
- [meta-raspberrypi Documentation](https://meta-raspberrypi.readthedocs.io/)

### コミュニティ
- [Yocto Project Mailing List](https://lists.yoctoproject.org/g/yocto)
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)
- Stack Overflow（タグ: yocto, bitbake, raspberry-pi）

### ログファイルの場所
- ビルドログ: `build/tmp/work/*/temp/`
- カーネルログ: `dmesg` または `/var/log/messages`
- システムログ: `journalctl` または `/var/log/syslog`
