# VPNゲートウェイ セットアップガイド

Raspberry Pi ZeroをVPNゲートウェイとして設定する完全ガイド

## 目次

1. [概要](#概要)
2. [前提条件の確認](#前提条件の確認)
3. [WireGuard VPN セットアップ](#wireguard-vpn-セットアップ)
4. [ダイナミックDNS 設定](#ダイナミックdns-設定)
5. [ルーター設定](#ルーター設定)
6. [クライアント接続](#クライアント接続)
7. [トラブルシューティング](#トラブルシューティング)

---

## 概要

このガイドでは、Raspberry Pi Zeroを使って自宅VPNサーバーを構築します。

### できること

- 外出先から自宅ネットワークへ安全にアクセス
- 公衆WiFi利用時のセキュリティ向上
- 海外から日本のサービスにアクセス
- スマホ・PC・タブレットから接続可能

### 使用技術

- **WireGuard**: 最新の高速VPNプロトコル（推奨）
- **OpenVPN**: 互換性重視の従来型VPN
- **ダイナミックDNS**: 動的IPアドレス対応

---

## 前提条件の確認

### 1. インターネット回線の確認

#### グローバルIPアドレスの確認

```bash
# Raspberry Pi Zero上で実行
curl ifconfig.me

# ルーター管理画面で確認
# WAN側IPアドレスと上記が同じ → グローバルIP（OK）
# 違う → CGNAT環境（VPNサーバー不可）
```

**CGNAT環境の場合:**
- ケーブルテレビ会社に問い合わせて固定IPオプション（有料）を検討
- またはVPS（外部サーバー）を中継する方法も可能

#### 動的IPか固定IPか

- **固定IP**: そのまま使用可能
- **動的IP**: ダイナミックDNS（DDNS）が必要

### 2. ネットワーク構成の確認

```
インターネット
    |
[ケーブルモデム/ルーター]
    |
    +-- Raspberry Pi Zero (VPNサーバー)
    +-- その他デバイス
```

### 3. 必要な情報

- [ ] ルーター管理画面のアクセス方法
- [ ] ルーターのログイン情報
- [ ] Raspberry Pi ZeroのローカルIPアドレス

```bash
# Raspberry Pi ZeroのIPアドレス確認
ip addr show eth0
# または
ifconfig eth0
```

---

## WireGuard VPN セットアップ

### ステップ1: サーバーセットアップ

```bash
# Raspberry Pi Zeroにログイン
ssh root@raspizero-vpn.local

# セットアップスクリプトを実行
/opt/vpn-scripts/setup-wireguard.sh
```

**対話的に入力:**

```
VPNサーバーのIPアドレス範囲 [10.0.0.1/24]:
→ そのままEnter（デフォルト使用）

リッスンポート [51820]:
→ そのままEnter（デフォルト使用）

外部に接続するインターフェース名 [eth0]:
→ そのままEnter（eth0使用）
```

**出力例:**
```
サーバー公開鍵: AbCd1234EfGh5678IjKl9012MnOp3456QrSt7890UvWx=
設定ファイル: /etc/wireguard/wg0.conf
```

### ステップ2: WireGuard起動

```bash
# WireGuardインターフェースを起動
wg-quick up wg0

# 自動起動を有効化
systemctl enable wg-quick@wg0

# ステータス確認
wg show
```

### ステップ3: IP転送の確認

```bash
# IP転送が有効か確認
sysctl net.ipv4.ip_forward
# → net.ipv4.ip_forward = 1 であればOK

# 無効の場合
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

---

## ダイナミックDNS 設定

固定IPでない場合、ダイナミックDNSが必要です。

### ステップ1: DDNSサービスに登録

#### DuckDNS（推奨・無料）

1. https://www.duckdns.org/ にアクセス
2. GitHubアカウントなどでログイン
3. ドメイン名を作成（例: `myhome`）
   - 完全なドメイン: `myhome.duckdns.org`
4. トークンをコピー（例: `a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6`）

### ステップ2: DDNSセットアップ

```bash
# Raspberry Pi Zero上で実行
/opt/vpn-scripts/setup-ddns.sh

# 選択肢: 1 (DuckDNS)
# ドメイン名を入力: myhome
# トークンを入力: a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6
```

### ステップ3: DDNS動作確認

```bash
# 5分待ってから確認
nslookup myhome.duckdns.org

# 自分のグローバルIPアドレスが返ってくればOK
```

---

## ルーター設定

### ポート転送（ポートフォワーディング）

ルーター管理画面でポート転送を設定します。

#### 一般的な手順

1. **ルーター管理画面にアクセス**
   - ブラウザで `http://192.168.1.1` など
   - ルーターメーカーによって異なる

2. **ポート転送/仮想サーバー設定を開く**
   - 「ポート転送」「Port Forwarding」
   - 「仮想サーバー」「Virtual Server」
   - 「NAT設定」などの名前

3. **以下の情報を入力**
   ```
   サービス名: WireGuard
   外部ポート: 51820
   内部ポート: 51820
   プロトコル: UDP
   内部IPアドレス: 192.168.1.xxx (Raspberry Pi ZeroのIP)
   ```

4. **保存して有効化**

#### メーカー別ガイド

**Buffalo:**
- 詳細設定 → セキュリティ → ポート変換

**NEC:**
- 詳細設定 → ポートマッピング設定

**TP-Link:**
- 転送 → 仮想サーバー

**ASUS:**
- WAN → 仮想サーバー/ポート転送

### DMZ設定（代替方法・非推奨）

ポート転送が難しい場合、DMZも可能ですがセキュリティリスクあり：

```
DMZホスト: 192.168.1.xxx (Raspberry Pi ZeroのIP)
```

---

## クライアント接続

### クライアント追加

```bash
# Raspberry Pi Zero上で実行
/opt/vpn-scripts/wireguard-add-client.sh

# 入力例:
クライアント名: laptop
クライアントのVPN IPアドレス [10.0.0.2]: （Enter）
サーバーの外部IPアドレスまたはホスト名: myhome.duckdns.org
```

**出力:**
```
クライアント設定ファイル:
  /etc/wireguard/clients/laptop/laptop.conf

QRコード画像:
  /etc/wireguard/clients/laptop/laptop.png
```

### クライアント設定ファイルのダウンロード

#### PCから取得（SCP使用）

```bash
# Windows PowerShell / Mac Terminal / Linux
scp root@raspizero-vpn.local:/etc/wireguard/clients/laptop/laptop.conf .
```

#### Webブラウザで取得

```bash
# Raspberry Pi Zero上で一時的にWebサーバー起動
cd /etc/wireguard/clients
python3 -m http.server 8000

# PCのブラウザで http://raspizero-vpn.local:8000/ にアクセス
# ファイルをダウンロード後、Ctrl+Cで停止
```

### クライアントソフトウェアのインストール

#### Windows / Mac / Linux

1. https://www.wireguard.com/install/ からダウンロード
2. インストール
3. 「トンネルをファイルからインポート」
4. ダウンロードした `laptop.conf` を選択
5. 「接続」をクリック

#### iOS / Android

1. App Store / Google Playで「WireGuard」を検索
2. インストール
3. 「+」→「QRコードからスキャン」
4. Raspberry Pi Zero上でQRコードを表示:
   ```bash
   qrencode -t ansiutf8 < /etc/wireguard/clients/phone/phone.conf
   ```
5. スキャンして接続

### 接続テスト

#### VPN接続確認

```bash
# クライアント側で実行（VPN接続後）

# VPN IPアドレスを確認
ip addr show wg0  # Linux
# または Get-NetIPAddress -InterfaceAlias "WireGuard" # Windows PowerShell

# VPNサーバーにPing
ping 10.0.0.1

# 自宅ネットワークのデバイスにアクセス
ping 192.168.1.10  # 例: 自宅PC
```

#### 外部からのアクセステスト

```bash
# スマホのモバイル回線などから接続テスト
# VPN接続して、自宅のRaspberry Piにアクセス
ssh root@10.0.0.1
```

---

## トラブルシューティング

### 接続できない

#### 1. ポート転送の確認

```bash
# 外部から確認（別のネットワークから）
nc -vuz myhome.duckdns.org 51820
# または
nmap -sU -p 51820 myhome.duckdns.org
```

#### 2. Raspberry Pi側のファイアウォール確認

```bash
# Raspberry Pi Zero上で
iptables -L -n -v
# FORWARD チェーンにACCEPTルールがあるか確認

# WireGuardが起動しているか
systemctl status wg-quick@wg0
wg show
```

#### 3. ログ確認

```bash
# システムログ
journalctl -u wg-quick@wg0 -f

# dmesg
dmesg | tail -n 50
```

### 速度が遅い

#### MTU設定の調整

```bash
# /etc/wireguard/wg0.conf に追加
[Interface]
MTU = 1420  # または 1380

# 再起動
wg-quick down wg0
wg-quick up wg0
```

### DDNS更新されない

```bash
# ログ確認
tail -f /var/log/duckdns.log

# 手動更新
/usr/local/bin/duckdns-update.sh

# cronジョブ確認
crontab -l
```

### CGNAT環境での対処法

CGNAT（共有グローバルIP）環境では、直接VPNサーバーとして使えません。

#### 解決策1: ISPに固定IPオプションを申し込む

多くのケーブルテレビ会社で月額500〜1000円程度。

#### 解決策2: VPS中継方式

```
[自宅 Raspberry Pi] --VPN--> [VPS] <--VPN-- [外出先]
```

1. 安価なVPS（月500円程度）を契約
2. VPS上にWireGuardサーバー構築
3. 自宅のRaspberry PiをVPSに常時接続
4. 外出先からVPS経由で自宅アクセス

#### 解決策3: Tailscale / ZeroTier（簡単）

P2P VPNサービスを利用（無料プランあり）：

```bash
# opkgでインストール
opkg update
opkg install tailscale

# セットアップ
tailscale up
```

---

## セキュリティのベストプラクティス

### 1. 定期的な更新

```bash
# 月1回程度
opkg update
opkg upgrade

# 再起動
reboot
```

### 2. SSH鍵認証の設定

```bash
# パスワード認証を無効化
# /etc/ssh/sshd_config を編集
PasswordAuthentication no
```

### 3. ファイアウォールルールの最小化

```bash
# 不要なポートを閉じる
iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
iptables -A INPUT -p udp --dport 51820 -j ACCEPT  # WireGuard
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j DROP
```

### 4. ログ監視

```bash
# 定期的にログ確認
journalctl -f
tail -f /var/log/messages
```

---

## よくある質問

### Q: ケーブルテレビ回線で使える？

**A:** 以下の条件を満たせば可能：
- グローバルIPアドレスが割り当てられている
- ポート転送が可能なルーター

確認方法は「前提条件の確認」を参照。

### Q: スマホから接続できる？

**A:** はい、iOS/AndroidともにWireGuardアプリがあります。QRコードで簡単に設定可能。

### Q: 複数デバイスから同時接続できる？

**A:** はい。デバイスごとにクライアント設定を作成してください。

```bash
/opt/vpn-scripts/wireguard-add-client.sh  # 繰り返し実行
```

### Q: 通信は暗号化される？

**A:** はい、WireGuardは最新の暗号技術（ChaCha20, Poly1305）で暗号化されます。

### Q: WireGuardとOpenVPNどちらを使うべき？

**A:** WireGuard を推奨：
- **高速** （OpenVPNの約2〜3倍）
- **設定が簡単**
- **バッテリー消費が少ない**（モバイル向け）
- **最新の暗号技術**

OpenVPNは古いデバイスとの互換性が必要な場合のみ。

---

## 参考リソース

- [WireGuard公式サイト](https://www.wireguard.com/)
- [DuckDNS公式サイト](https://www.duckdns.org/)
- [WireGuard設定ガイド](https://www.wireguard.com/quickstart/)
- [Raspberry Pi公式フォーラム](https://forums.raspberrypi.com/)

---

## サポート

問題が解決しない場合：
- GitHub Issues: https://github.com/your-repo/yocto-pizero/issues
- トラブルシューティングセクションを参照
- ログを添付して報告
