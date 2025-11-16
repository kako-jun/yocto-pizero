# USB Webカメラサーバー セットアップガイド

Raspberry Pi ZeroをUSB Webカメラサーバーとして設定する完全ガイド

## 目次

1. [概要](#概要)
2. [必要なもの](#必要なもの)
3. [USB Webカメラセットアップ](#usb-webカメラセットアップ)
4. [Cloudflare Tunnel設定](#cloudflare-tunnel設定)
5. [タイムラプス撮影](#タイムラプス撮影)
6. [使い方](#使い方)
7. [トラブルシューティング](#トラブルシューティング)

---

## 概要

このガイドでは、Raspberry Pi Zeroと汎用USB Webカメラを使って、以下の機能を持つカメラサーバーを構築します。

### できること

- **ライブストリーミング**: mjpg-streamerで低遅延ストリーム配信
- **タイムラプス撮影**: 定期的に写真を撮影して動画化
- **Webギャラリー**: ブラウザで過去の画像・動画を閲覧
- **外部公開**: Cloudflare Tunnelで安全に外部公開（CGNAT対応）

### 使用技術

- **V4L2**: Linux標準のビデオキャプチャAPI
- **mjpg-streamer**: 軽量ストリーミングサーバー
- **ffmpeg**: 動画変換・タイムラプス作成
- **nginx**: Webギャラリー
- **Cloudflare Tunnel**: CGNAT環境でも外部公開可能

---

## 必要なもの

### ハードウェア

- **Raspberry Pi Zero** (初代)
- **USB Webカメラ** (UVC対応)
  - 推奨: Logicool C270, C310, C920など
  - 確認: `lsusb` で `Video` と表示されるもの
- **USB OTGケーブル** (Micro USB to USB-A)
- **microSDカード** (16GB以上推奨)
- **電源** (5V 1A以上)

### ソフトウェア

- `rpi-zero-webcam-server.bb` でビルドしたイメージ
- Cloudflareアカウント（外部公開する場合）

### USB Webカメラの互換性確認

Linux UVC (USB Video Class) 対応カメラが必要です。

**確認済み動作カメラ:**
- Logicool C270, C310, C615, C920, C922
- Microsoft LifeCam シリーズ
- Elecom UCAM シリーズ
- Buffalo BWC シリーズ

**確認方法:**
```bash
# カメラを接続後
lsusb
# → "Video" または "Camera" が表示されればOK

v4l2-ctl --list-devices
# → /dev/video0 などが表示される
```

---

## USB Webカメラセットアップ

### ステップ1: カメラの接続

1. USB WebカメラをRaspberry Pi ZeroのUSBポートに接続
   - USB OTGケーブルが必要な場合があります
2. Raspberry Pi Zeroを起動
3. SSHでログイン

```bash
ssh root@raspizero-webcam.local
```

### ステップ2: カメラ認識の確認

```bash
# USB デバイス確認
lsusb

# ビデオデバイス確認
ls /dev/video*
# → /dev/video0 が表示されればOK

# カメラ情報表示
v4l2-ctl --device=/dev/video0 --info
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

### ステップ3: セットアップスクリプト実行

```bash
/opt/webcam-scripts/setup-webcam.sh
```

**対話的に入力:**

```
使用するカメラデバイス [/dev/video0]:
→ Enter（デフォルト使用）

解像度（幅） [640]:
→ 640 または 1280

解像度（高さ） [480]:
→ 480 または 720

フレームレート [15]:
→ 15 〜 30（カメラ性能に依存）

ポート番号 [8080]:
→ Enter（デフォルト使用）
```

**出力例:**
```
mjpg-streamer started on port 8080
Stream URL: http://192.168.1.100:8080/?action=stream
Snapshot URL: http://192.168.1.100:8080/?action=snapshot
```

### ステップ4: 動作確認

```bash
# サービス状態確認
systemctl status webcam

# ブラウザでアクセス
# http://<Raspberry-Pi-IP>:8080/?action=stream
```

---

## Cloudflare Tunnel設定

CGNAT環境（ケーブルテレビ回線など）でも外部公開できます。

### 前提条件

- Cloudflareアカウント（無料）
- Cloudflareで管理しているドメイン

### ステップ1: セットアップスクリプト実行

```bash
/opt/webcam-scripts/setup-cloudflare-tunnel.sh
```

### ステップ2: Cloudflareログイン

```bash
# ブラウザが開くのでCloudflareにログイン
cloudflared tunnel login
```

ブラウザで認証が完了すると、認証情報が保存されます。

### ステップ3: トンネル作成

スクリプトが対話的に進めます：

```
トンネル名を入力 [raspizero-webcam]:
→ Enter（デフォルト使用）

ドメイン名: example.com
→ Cloudflareで管理しているドメイン

サブドメイン [webcam]:
→ webcam（webcam.example.comになる）

nginxポート [80]:
→ Enter

mjpg-streamerポート [8080]:
→ Enter
```

### ステップ4: DNS確認

数分待ってからアクセス：

```
Webギャラリー: https://webcam.example.com
ライブストリーム: https://stream.example.com/?action=stream
```

**メリット:**
- ✅ CGNAT環境でも動作
- ✅ 自動HTTPS（SSL証明書不要）
- ✅ DDoS保護
- ✅ ポート転送不要
- ✅ グローバルIP不要

---

## タイムラプス撮影

定期的に写真を撮影して、動画にまとめます。

### ステップ1: セットアップスクリプト実行

```bash
/opt/webcam-scripts/setup-timelapse.sh
```

### ステップ2: 撮影設定

```
使用するカメラデバイス [/dev/video0]:
→ Enter

撮影間隔（分） [5]:
→ 5（5分ごとに撮影）
→ 植物観察なら10〜30分
→ 工事現場なら1〜5分

解像度（幅） [1280]:
→ 1280 または 1920

解像度（高さ） [720]:
→ 720 または 1080

1日何回動画を生成しますか [1]:
→ 1: 毎日23:59に1本
→ 2: 12時と24時に2本
→ 4: 6時間ごとに4本
```

### ステップ3: 動作確認

```bash
# テスト撮影
/usr/local/bin/timelapse-capture.sh

# スナップショット確認
ls -lh /var/webcam/timelapse/

# 手動で動画生成（テスト）
/usr/local/bin/timelapse-video.sh

# 動画確認
ls -lh /var/webcam/videos/
```

### ステップ4: ログ確認

```bash
# タイムラプスログ
tail -f /var/log/timelapse.log

# cron設定確認
crontab -l
```

---

## 使い方

### ライブストリーム視聴

#### ローカルネットワークから

```
ストリーム: http://<Raspberry-Pi-IP>:8080/?action=stream
スナップショット: http://<Raspberry-Pi-IP>:8080/?action=snapshot
```

#### 外部から（Cloudflare Tunnel使用時）

```
https://webcam.example.com/
https://stream.example.com/?action=stream
```

### Webギャラリー

```
http://<Raspberry-Pi-IP>/
または
https://webcam.example.com/
```

**機能:**
- タイムラプス動画一覧
- スナップショット一覧
- 日付でフィルタ

### 手動撮影

```bash
# 今すぐスナップショット撮影
/usr/local/bin/timelapse-capture.sh

# 今すぐタイムラプス動画生成
/usr/local/bin/timelapse-video.sh
```

### ファイル管理

```bash
# スナップショット
ls /var/webcam/timelapse/

# タイムラプス動画
ls /var/webcam/videos/

# ディスク使用量確認
du -sh /var/webcam/*

# 古いファイル削除（例: 30日以上前）
find /var/webcam/videos/ -type f -mtime +30 -delete
```

---

## トラブルシューティング

### カメラが認識されない

```bash
# USB デバイス確認
lsusb

# カーネルログ確認
dmesg | grep -i video
dmesg | grep -i uvc

# カメラを接続し直す
# USB ケーブルを抜き差し
dmesg | tail -n 20
```

### ストリームが表示されない

```bash
# mjpg-streamer 状態確認
systemctl status webcam

# プロセス確認
ps aux | grep mjpg

# 手動起動（デバッグ）
systemctl stop webcam
/opt/webcam-scripts/webcam-start.sh

# ポート確認
netstat -an | grep 8080
```

### 画質が悪い

```bash
# 解像度を上げる
# setup-webcam.sh を再実行して 1280x720 または 1920x1080に変更

# フレームレートを下げる
# FPS を 15 → 10 に変更（帯域節約）

# 明るさ・コントラスト調整
v4l2-ctl --device=/dev/video0 --list-ctrls
v4l2-ctl --device=/dev/video0 --set-ctrl=brightness=128
v4l2-ctl --device=/dev/video0 --set-ctrl=contrast=128
```

### ディスク容量不足

```bash
# ディスク使用量確認
df -h

# 古い動画削除（30日以上前）
find /var/webcam/videos/ -type f -mtime +30 -delete

# ログローテーション設定
cat /etc/logrotate.d/timelapse
```

### Cloudflare Tunnelが動作しない

```bash
# cloudflared 状態確認
systemctl status cloudflared

# ログ確認
journalctl -u cloudflared -f

# 手動起動（デバッグ）
cloudflared tunnel --config /root/.cloudflared/config.yml run

# トンネル一覧確認
cloudflared tunnel list
```

### 夜間撮影が暗い

```bash
# 露出調整
v4l2-ctl --device=/dev/video0 --set-ctrl=exposure_auto=1
v4l2-ctl --device=/dev/video0 --set-ctrl=exposure_absolute=300

# ゲイン調整
v4l2-ctl --device=/dev/video0 --set-ctrl=gain=100

# IR LEDライト追加を検討
```

---

## 応用例

### 植物成長観察

```bash
# 30分ごとに撮影、1日1回動画生成
撮影間隔: 30分
動画生成: 1日1回
```

### 工事現場監視

```bash
# 5分ごとに撮影、1日4回動画生成
撮影間隔: 5分
動画生成: 1日4回（6時間ごと）
```

### ペット監視

```bash
# ライブストリームのみ、タイムラプスなし
setup-webcam.sh のみ実行
```

### 天候観測

```bash
# 10分ごとに撮影、1日2回動画生成
撮影間隔: 10分
動画生成: 1日2回（昼・夜）
```

---

## 推奨カメラ設定

| 用途 | 解像度 | FPS | 撮影間隔 | 動画/日 |
|------|--------|-----|----------|---------|
| 植物観察 | 1280x720 | 15 | 30分 | 1 |
| 工事現場 | 1920x1080 | 10 | 5分 | 4 |
| ペット監視 | 640x480 | 30 | - | - |
| 天候観測 | 1280x720 | 15 | 10分 | 2 |

---

## セキュリティ

### ローカルネットワークのみで使用

```bash
# Cloudflare Tunnelを使用しない
# ポート転送しない
# VPN経由でアクセス
```

### Basic認証の追加（nginx）

```bash
# パスワードファイル作成
apt-get install apache2-utils
htpasswd -c /etc/nginx/.htpasswd admin

# nginx設定
nano /etc/nginx/sites-available/default

# location / {
#     auth_basic "Restricted";
#     auth_basic_user_file /etc/nginx/.htpasswd;
# }

systemctl reload nginx
```

---

## 参考リソース

- [mjpg-streamer Documentation](https://github.com/jacksonliam/mjpg-streamer)
- [V4L2 API Specification](https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/v4l2.html)
- [ffmpeg Documentation](https://ffmpeg.org/documentation.html)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

---

## まとめ

### セットアップフロー

```bash
# 1. カメラセットアップ
/opt/webcam-scripts/setup-webcam.sh

# 2. 外部公開（オプション）
/opt/webcam-scripts/setup-cloudflare-tunnel.sh

# 3. タイムラプス（オプション）
/opt/webcam-scripts/setup-timelapse.sh

# 4. Webアクセス
# http://<IP>/ または https://webcam.example.com/
```

### よく使うコマンド

```bash
# サービス管理
systemctl status webcam
systemctl restart webcam
systemctl status cloudflared

# 手動撮影
/usr/local/bin/timelapse-capture.sh
/usr/local/bin/timelapse-video.sh

# ログ確認
tail -f /var/log/timelapse.log
journalctl -u webcam -f

# ファイル確認
ls -lh /var/webcam/videos/
du -sh /var/webcam/*
```
