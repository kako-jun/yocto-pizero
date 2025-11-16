#!/bin/bash
# WireGuard VPN セットアップスクリプト

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

echo_info "======================================"
echo_info "WireGuard VPN セットアップ"
echo_info "======================================"
echo ""

# WireGuardの確認
if ! command -v wg &> /dev/null; then
    echo_error "WireGuardがインストールされていません"
    exit 1
fi

# 設定ディレクトリ
WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/wg0.conf"

# 既存設定の確認
if [ -f "${WG_CONF}" ]; then
    echo_warn "既存の設定が見つかりました: ${WG_CONF}"
    read -p "上書きしますか? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "セットアップを中止しました"
        exit 0
    fi
fi

# サーバー設定
echo_info "サーバー設定を入力してください"
echo ""

read -p "VPNサーバーのIPアドレス範囲 [10.0.0.1/24]: " VPN_SUBNET
VPN_SUBNET=${VPN_SUBNET:-10.0.0.1/24}

read -p "リッスンポート [51820]: " LISTEN_PORT
LISTEN_PORT=${LISTEN_PORT:-51820}

read -p "外部に接続するインターフェース名 [eth0]: " WAN_INTERFACE
WAN_INTERFACE=${WAN_INTERFACE:-eth0}

echo_info "鍵ペアを生成しています..."
cd ${WG_DIR}

# サーバー鍵の生成
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key

SERVER_PRIVATE_KEY=$(cat server_private.key)
SERVER_PUBLIC_KEY=$(cat server_public.key)

echo_info "サーバー公開鍵: ${SERVER_PUBLIC_KEY}"

# 設定ファイルの作成
cat > ${WG_CONF} << EOF
[Interface]
# サーバー設定
Address = ${VPN_SUBNET}
ListenPort = ${LISTEN_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

# IP転送とNATマスカレード
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WAN_INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WAN_INTERFACE} -j MASQUERADE

# クライアント設定はここに追加
# [Peer]
# PublicKey = クライアントの公開鍵
# AllowedIPs = 10.0.0.2/32
EOF

chmod 600 ${WG_CONF}

echo_info ""
echo_info "======================================"
echo_info "セットアップ完了！"
echo_info "======================================"
echo_info ""
echo_info "設定ファイル: ${WG_CONF}"
echo_info "サーバー公開鍵: ${SERVER_PUBLIC_KEY}"
echo_info ""
echo_info "次のステップ:"
echo_info "1. ルーターでポート転送を設定"
echo_info "   ${LISTEN_PORT}/UDP → このRaspberry PiのIPアドレス"
echo_info ""
echo_info "2. クライアントを追加"
echo_info "   /opt/vpn-scripts/wireguard-add-client.sh"
echo_info ""
echo_info "3. WireGuardを起動"
echo_info "   wg-quick up wg0"
echo_info "   systemctl enable wg-quick@wg0  # 自動起動"
echo_info ""
echo_info "4. ステータス確認"
echo_info "   wg show"
echo_info ""
