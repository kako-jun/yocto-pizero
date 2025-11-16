#!/bin/bash
# WireGuard クライアント追加スクリプト

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# rootチェック
if [ "$EUID" -ne 0 ]; then
    echo_error "このスクリプトはroot権限で実行してください"
    exit 1
fi

WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/wg0.conf"

if [ ! -f "${WG_CONF}" ]; then
    echo_error "WireGuardサーバーが設定されていません"
    echo_error "先に /opt/vpn-scripts/setup-wireguard.sh を実行してください"
    exit 1
fi

echo_info "======================================"
echo_info "WireGuard クライアント追加"
echo_info "======================================"
echo ""

# クライアント情報の入力
read -p "クライアント名 (例: laptop, phone): " CLIENT_NAME
if [ -z "${CLIENT_NAME}" ]; then
    echo_error "クライアント名を入力してください"
    exit 1
fi

# 既存クライアント数をカウント（次のIPアドレス用）
CLIENT_COUNT=$(grep -c "^\[Peer\]" ${WG_CONF} || true)
NEXT_IP=$((CLIENT_COUNT + 2))  # 10.0.0.2 から開始

read -p "クライアントのVPN IPアドレス [10.0.0.${NEXT_IP}]: " CLIENT_IP
CLIENT_IP=${CLIENT_IP:-10.0.0.${NEXT_IP}}

# サーバー情報の取得
SERVER_PUBLIC_KEY=$(cat ${WG_DIR}/server_public.key)
SERVER_PORT=$(grep "ListenPort" ${WG_CONF} | awk '{print $3}')

# サーバーの外部IPアドレス/ホスト名を取得
echo ""
read -p "サーバーの外部IPアドレスまたはホスト名: " SERVER_ENDPOINT
if [ -z "${SERVER_ENDPOINT}" ]; then
    echo_error "サーバーのアドレスを入力してください"
    exit 1
fi

# クライアント鍵の生成
echo_info "クライアント用の鍵を生成しています..."
cd ${WG_DIR}

CLIENT_DIR="${WG_DIR}/clients/${CLIENT_NAME}"
mkdir -p ${CLIENT_DIR}
cd ${CLIENT_DIR}

umask 077
wg genkey | tee privatekey | wg pubkey > publickey

CLIENT_PRIVATE_KEY=$(cat privatekey)
CLIENT_PUBLIC_KEY=$(cat publickey)

# クライアント設定ファイルの生成
cat > ${CLIENT_NAME}.conf << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_ENDPOINT}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# QRコード生成（スマホ用）
if command -v qrencode &> /dev/null; then
    echo_info "QRコードを生成しています..."
    qrencode -t ansiutf8 < ${CLIENT_NAME}.conf
    qrencode -t png -o ${CLIENT_NAME}.png < ${CLIENT_NAME}.conf
    echo_info "QRコード画像: ${CLIENT_DIR}/${CLIENT_NAME}.png"
else
    echo_warn "qrencode がインストールされていません（QRコード生成スキップ）"
fi

# サーバー設定にPeerを追加
echo_info "サーバー設定にクライアントを追加しています..."
cat >> ${WG_CONF} << EOF

# Client: ${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_IP}/32
EOF

# WireGuardを再起動（既に起動している場合）
if systemctl is-active --quiet wg-quick@wg0; then
    echo_info "WireGuardを再起動しています..."
    wg syncconf wg0 <(wg-quick strip wg0)
fi

echo_info ""
echo_info "======================================"
echo_info "クライアント追加完了！"
echo_info "======================================"
echo_info ""
echo_info "クライアント設定ファイル:"
echo_info "  ${CLIENT_DIR}/${CLIENT_NAME}.conf"
echo_info ""
echo_info "クライアント設定内容:"
cat ${CLIENT_DIR}/${CLIENT_NAME}.conf
echo ""
echo_info "次のステップ:"
echo_info "1. クライアント設定ファイルをダウンロード"
echo_info "   scp root@raspizero-vpn:${CLIENT_DIR}/${CLIENT_NAME}.conf ."
echo_info ""
echo_info "2. クライアントにWireGuardをインストール"
echo_info "   - Windows/Mac: https://www.wireguard.com/install/"
echo_info "   - Linux: apt install wireguard"
echo_info "   - iOS/Android: App Storeから「WireGuard」"
echo_info ""
echo_info "3. 設定をインポート"
echo_info "   - ファイルをインポート、またはQRコードをスキャン"
echo_info ""
