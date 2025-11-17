# Raspberry Pi Zero Yocto Project

## プロジェクト概要

Raspberry Pi Zero (初代) 向けのYocto Linuxビルド環境プロジェクト。
用途別に特化した複数のイメージを提供し、ユーザーが簡単にビルド・デプロイできる環境を構築。

### 目標

1. **再現性のあるビルド環境**
   - Docker対応
   - GitHub Actions自動化
   - 明確なドキュメント

2. **特化イメージの提供**
   - Webサーバー
   - VPNゲートウェイ
   - USB Webカメラサーバー

3. **CGNAT環境対応**
   - Cloudflare Tunnel統合
   - ダイナミックDNS対応
   - ポート転送不要

---

## アーキテクチャ

### レイヤー構成

```
yocto-pizero/
├── poky/                           # Yocto Project core (kirkstone)
├── meta-raspberrypi/               # Raspberry Pi BSP layer
├── meta-openembedded/              # 追加パッケージ
└── meta-rpi-zero-custom/           # カスタムレイヤー
    ├── recipes-core/images/
    │   ├── rpi-zero-custom-image.bb      # Webサーバー
    │   ├── rpi-zero-vpn-gateway.bb       # VPN
    │   └── rpi-zero-webcam-server.bb     # Webカメラ
    ├── recipes-vpn/vpn-scripts/          # VPN設定スクリプト
    └── recipes-webcam/webcam-scripts/    # カメラ設定スクリプト
```

### イメージ設計

#### 1. rpi-zero-custom-image (Webサーバー)
**目的**: 軽量なWebサーバーとして動作
**ベース**: core-image-minimal
**主要パッケージ**:
- nginx
- SSH (OpenSSH)
- opkg (パッケージマネージャー)
- 基本ツール (nano, htop)

**現状の課題**:
- Cloudflare Tunnel未対応 → CGNAT環境で外部公開不可

#### 2. rpi-zero-vpn-gateway (VPNゲートウェイ)
**目的**: 自宅VPNサーバー
**ベース**: core-image-minimal
**主要パッケージ**:
- WireGuard (推奨)
- OpenVPN (互換性)
- iptables (ファイアウォール)
- ddclient (DDNS)

**特徴**:
- 公開鍵認証
- IP転送有効化
- NAT設定済み

**現状の課題**:
- CGNAT環境では直接サーバー化不可
- 逆VPN方式（VPS中継）の説明が必要

#### 3. rpi-zero-webcam-server (Webカメラサーバー)
**目的**: USB Webカメラでストリーミング・タイムラプス
**ベース**: core-image-minimal
**主要パッケージ**:
- mjpg-streamer (ライブ配信)
- ffmpeg (動画変換)
- v4l-utils (カメラ制御)
- nginx (ギャラリー)
- Cloudflare Tunnel設定スクリプト

**特徴**:
- 汎用USB Webカメラ対応 (UVC)
- タイムラプス自動生成
- Cloudflare Tunnel対応 ✅

---

## ビルドシステム

### 3つのビルド方法

#### 1. GitHub Actions (推奨)
**利点**:
- ホストリソース不要
- クラウドで自動ビルド
- Releases自動作成

**制約**:
- タイムアウト: 6時間
- 1実行1イメージのみ
- ディスク容量の最適化が必要

#### 2. Docker
**利点**:
- ホスト環境を汚さない
- 再現性が高い
- 複数イメージの連続ビルド可能

**制約**:
- Docker必須
- ローカルディスク60GB+必要

#### 3. ネイティブ
**利点**:
- 最速
- 細かい制御可能

**制約**:
- 依存パッケージ多数
- ホスト環境に影響

---

## 技術スタック

### Yocto Project
- **ディストリビューション**: Poky
- **ブランチ**: kirkstone (LTS)
- **ターゲット**: raspberrypi0 (BCM2835)

### 主要コンポーネント

| 用途 | パッケージ | バージョン/備考 |
|------|-----------|----------------|
| Webサーバー | nginx | 軽量HTTP/HTTPS |
| VPN | WireGuard | 最新プロトコル |
| VPN | OpenVPN | 互換性重視 |
| ストリーミング | mjpg-streamer | MJPEG配信 |
| 動画処理 | ffmpeg | タイムラプス作成 |
| カメラ | V4L2 | Linux標準 |
| トンネル | cloudflared | Cloudflare Tunnel |
| パッケージ管理 | opkg | 軽量 |

### ネットワーク構成

```
[インターネット]
      |
[ケーブルモデム/ルーター] (CGNAT環境)
      |
[Raspberry Pi Zero]
      |
      +-- nginx (ポート80/443)
      +-- WireGuard (ポート51820)
      +-- mjpg-streamer (ポート8080)
      |
      +-- Cloudflare Tunnel (逆接続)
            └─> https://example.com
```

---

## 現在の状態

### ✅ 完成済み

1. **基本ビルド環境**
   - setup.sh (自動セットアップ)
   - build.sh (ビルドスクリプト)
   - docker-build.sh (Dockerビルド)
   - GitHub Actions ワークフロー

2. **3つの特化イメージ**
   - rpi-zero-custom-image (Webサーバー)
   - rpi-zero-vpn-gateway (VPN)
   - rpi-zero-webcam-server (Webカメラ)

3. **セットアップスクリプト**
   - VPN: setup-wireguard.sh, wireguard-add-client.sh, setup-ddns.sh
   - Webカメラ: setup-webcam.sh, setup-timelapse.sh, setup-cloudflare-tunnel.sh

4. **ドキュメント**
   - README.md (概要・ビルド方法)
   - VPN_SETUP.md (VPN完全ガイド)
   - WEBCAM_SETUP.md (Webカメラ完全ガイド)
   - IMAGE_SELECTION.md (イメージ選択ガイド)
   - DOCKER_BUILD.md (Dockerビルドガイド)
   - GITHUB_ACTIONS.md (CI/CD自動化ガイド)

### ⚠️ 課題・改善点

1. **Cloudflare Tunnel対応の不統一**
   - ✅ Webカメラ: 対応済み
   - ❌ Webサーバー: 未対応
   - ❌ VPN: 未対応

2. **CGNAT環境での制約**
   - VPNゲートウェイは直接サーバー化不可
   - 逆VPN方式（VPS中継）の説明が不足

3. **パッケージの最適化**
   - イメージサイズの削減余地あり
   - 不要な依存パッケージの整理

4. **テスト不足**
   - 実機でのテストが必要
   - GitHub Actionsでのビルド未検証

---

## 次のステップ

### 優先度: 高

#### Cloudflare Tunnel の統一対応
**目的**: 全イメージでCGNAT環境に対応

**実装案**:
```
meta-rpi-zero-custom/recipes-cloudflare/
└── cloudflare-tunnel-scripts/
    ├── cloudflare-tunnel-scripts_1.0.bb
    └── files/
        └── setup-cloudflare-tunnel.sh (共通化)

各イメージに追加:
IMAGE_INSTALL:append = " cloudflare-tunnel-scripts "
```

**作業タスク**:
1. [ ] 共通Cloudflare Tunnelレシピ作成
2. [ ] rpi-zero-custom-imageに追加
3. [ ] rpi-zero-vpn-gatewayに追加
4. [ ] ドキュメント更新

#### GitHub Actionsでの実ビルドテスト
1. [ ] 手動実行でテスト
2. [ ] タグプッシュでリリーステスト
3. [ ] Artifactsダウンロード確認

### 優先度: 中

#### 他の特化イメージ追加
**候補**:
1. **IoTセンサーハブ** (rpi-zero-iot-sensor)
   - Python3 + I2C/SPI/GPIO
   - MQTTクライアント
   - センサーライブラリ

2. **ネットワークモニター** (rpi-zero-netmon)
   - tcpdump, wireshark-cli
   - iftop, nethogs
   - ログ収集

3. **軽量NASサーバー** (rpi-zero-nas)
   - Samba
   - USB HDD対応
   - rsync

#### ビルド高速化
1. [ ] sstate-cacheの最適化
   - GitHub Actionsでのキャッシュ改善
   - 共有可能なキャッシュサーバー検討

2. [ ] rm_workの活用
   - ディスク容量削減
   - ビルド速度への影響検証

### 優先度: 低

#### 応用機能
1. **OTA更新**
   - mender統合
   - swupdate検討

2. **セキュリティ強化**
   - SELinux/AppArmor
   - fail2ban

3. **監視・ログ**
   - Prometheus exporter
   - Grafana連携

---

## ユーザーフィードバック

### 質問履歴

1. **ケーブルテレビ回線でVPNは可能か？**
   - 回答: CGNAT環境の場合は直接不可
   - 解決策: Cloudflare Tunnel, Tailscale, VPS中継
   → Cloudflare Tunnel対応を優先課題に

2. **汎用Webカメラでタイムラプスできるか？**
   - 回答: USB Webカメラ対応イメージを作成
   → rpi-zero-webcam-server完成

3. **イメージ選択方法は？**
   - 回答: 各ビルド方法で統一的に選択可能に
   → IMAGE_SELECTION.md作成、スクリプト更新

4. **CloudflareはWebカメラだけか？**
   - 回答: 現状はWebカメラのみ
   → 次のタスク: 全イメージに展開

---

## メンテナンス方針

### バージョン管理

#### タグ命名規則
```
v<major>.<minor>.<patch>[-<image>]

例:
v1.0.0              # 全般リリース
v1.0.0-webserver    # Webサーバー特化
v1.0.0-vpn          # VPN特化
v1.0.0-webcam       # Webカメラ特化
```

#### ブランチ戦略
- `main`: 安定版
- `develop`: 開発版
- `claude/*`: 作業ブランチ

### 更新サイクル

1. **Yocto Projectバージョン**
   - 年1回メジャーアップデート検討
   - LTSバージョンを優先

2. **セキュリティパッチ**
   - 月1回の定期更新
   - 重大な脆弱性は即時対応

3. **機能追加**
   - ユーザーリクエスト優先
   - Issue/PRベース

---

## ドキュメント管理

### ドキュメント一覧

| ファイル | 対象読者 | 内容 |
|---------|---------|------|
| README.md | 初めて見る人 | 概要・クイックスタート |
| QUICKSTART.md | ビルドしたい人 | ネイティブビルド手順 |
| IMAGE_SELECTION.md | イメージ選択に迷う人 | 全イメージ比較・選択ガイド |
| DOCKER_BUILD.md | Docker使いたい人 | Docker完全ガイド |
| GITHUB_ACTIONS.md | 自動化したい人 | CI/CD設定ガイド |
| VPN_SETUP.md | VPN構築したい人 | VPN完全設定手順 |
| WEBCAM_SETUP.md | カメラ使いたい人 | カメラ完全設定手順 |
| PACKAGE_MANAGEMENT.md | パッケージ管理したい人 | opkg使い方 |
| TROUBLESHOOTING.md | 困っている人 | トラブル解決 |
| CUSTOMIZATION.md | カスタマイズしたい人 | レシピ作成方法 |

### ドキュメント更新ルール

1. **新機能追加時**
   - README.mdに概要追加
   - 専用ドキュメント作成（必要に応じて）
   - セットアップスクリプトにヘルプ追加

2. **設定変更時**
   - 該当ドキュメント更新
   - 変更履歴をコミットメッセージに記載

3. **トラブル発見時**
   - TROUBLESHOOTING.mdに追記

---

## 参考リンク

### 公式ドキュメント
- [Yocto Project](https://www.yoctoproject.org/)
- [meta-raspberrypi](https://meta-raspberrypi.readthedocs.io/)
- [Raspberry Pi公式](https://www.raspberrypi.org/documentation/)

### コミュニティ
- [Yocto Mailing List](https://lists.yoctoproject.org/g/yocto)
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)

---

## 変更履歴

### 2025-11-17
- プロジェクト開始
- 基本ビルド環境構築
- 3つの特化イメージ作成
- Docker/GitHub Actions対応
- ドキュメント整備
- 次の課題: Cloudflare Tunnel統一対応
