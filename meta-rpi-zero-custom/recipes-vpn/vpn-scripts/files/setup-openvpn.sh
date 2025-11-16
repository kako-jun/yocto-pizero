#!/bin/bash
# OpenVPN セットアップスクリプト（簡易版）

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
echo_info "OpenVPN セットアップ"
echo_info "======================================"
echo ""

echo_warn "OpenVPNのセットアップは複雑です"
echo_warn "WireGuardの使用を推奨します（より簡単・高速）"
echo ""

read -p "続行しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# OpenVPNの確認
if ! command -v openvpn &> /dev/null; then
    echo_error "OpenVPNがインストールされていません"
    exit 1
fi

OVPN_DIR="/etc/openvpn"
EASY_RSA_DIR="/usr/share/easy-rsa"

if [ ! -d "${EASY_RSA_DIR}" ]; then
    echo_error "easy-rsaがインストールされていません"
    exit 1
fi

echo_info "PKI（公開鍵基盤）をセットアップしています..."
cd ${OVPN_DIR}

# Easy-RSAのコピー
cp -r ${EASY_RSA_DIR} ${OVPN_DIR}/easy-rsa
cd ${OVPN_DIR}/easy-rsa

# PKIの初期化
./easyrsa init-pki

echo_info ""
echo_info "======================================"
echo_info "次のステップ（手動設定が必要）"
echo_info "======================================"
echo_info ""
echo_info "OpenVPNのフルセットアップは以下のコマンドを実行:"
echo ""
echo_info "cd /etc/openvpn/easy-rsa"
echo_info "./easyrsa build-ca nopass"
echo_info "./easyrsa gen-req server nopass"
echo_info "./easyrsa sign-req server server"
echo_info "./easyrsa gen-dh"
echo_info "openvpn --genkey secret ta.key"
echo ""
echo_info "詳細な手順:"
echo_info "  https://openvpn.net/community-resources/how-to/"
echo ""
echo_warn "初心者の方はWireGuardの使用を強く推奨します"
echo_warn "  /opt/vpn-scripts/setup-wireguard.sh"
echo ""
