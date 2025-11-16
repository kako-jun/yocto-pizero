#!/bin/bash
# Cloudflare Tunnel セットアップスクリプト

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
echo_info "Cloudflare Tunnel セットアップ"
echo_info "======================================"
echo ""

echo_info "Cloudflare Tunnelを使用すると、CGNAT環境でも"
echo_info "Webカメラストリームを外部公開できます。"
echo ""

# cloudflaredのインストール確認
if ! command -v cloudflared &> /dev/null; then
    echo_info "cloudflared をインストールしています..."

    # アーキテクチャを検出
    ARCH=$(uname -m)
    case $ARCH in
        armv6l|armv7l)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
            ;;
        aarch64)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
            ;;
        *)
            echo_error "サポートされていないアーキテクチャ: $ARCH"
            exit 1
            ;;
    esac

    wget -O /usr/local/bin/cloudflared $CLOUDFLARED_URL
    chmod +x /usr/local/bin/cloudflared

    echo_info "cloudflared のインストールが完了しました"
fi

echo ""
echo_info "======================================"
echo_info "セットアップ手順"
echo_info "======================================"
echo ""
echo_info "1. Cloudflareアカウントにログイン"
echo ""
echo_info "次のコマンドを実行してください:"
echo_info "  cloudflared tunnel login"
echo ""
echo_info "ブラウザが開くので、Cloudflareにログインして認証してください"
echo ""

read -p "ログインが完了したら Enter を押してください..."

echo ""
echo_info "2. トンネルの作成"
echo ""

read -p "トンネル名を入力 [raspizero-webcam]: " TUNNEL_NAME
TUNNEL_NAME=${TUNNEL_NAME:-raspizero-webcam}

echo_info "トンネルを作成しています..."
cloudflared tunnel create ${TUNNEL_NAME}

TUNNEL_ID=$(cloudflared tunnel list | grep ${TUNNEL_NAME} | awk '{print $1}')
echo_info "トンネルID: ${TUNNEL_ID}"

echo ""
echo_info "3. DNSレコードの設定"
echo ""
echo_info "Cloudflareで管理しているドメインを入力してください"
echo_info "（例: example.com）"
read -p "ドメイン名: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo_error "ドメイン名を入力してください"
    exit 1
fi

read -p "サブドメイン [webcam]: " SUBDOMAIN
SUBDOMAIN=${SUBDOMAIN:-webcam}

FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"

echo_info "DNSレコードを作成しています..."
cloudflared tunnel route dns ${TUNNEL_NAME} ${FULL_DOMAIN}

echo ""
echo_info "4. トンネル設定ファイルの作成"
echo ""

# 設定ファイルディレクトリ
mkdir -p /root/.cloudflared

# ローカルサービス（nginx + mjpg-streamer）
read -p "nginxポート [80]: " NGINX_PORT
NGINX_PORT=${NGINX_PORT:-80}

read -p "mjpg-streamerポート [8080]: " MJPG_PORT
MJPG_PORT=${MJPG_PORT:-8080}

# 設定ファイルの作成
cat > /root/.cloudflared/config.yml << EOF
tunnel: ${TUNNEL_ID}
credentials-file: /root/.cloudflared/${TUNNEL_ID}.json

ingress:
  # Webギャラリー（nginx）
  - hostname: ${FULL_DOMAIN}
    service: http://localhost:${NGINX_PORT}

  # ライブストリーム（mjpg-streamer）
  - hostname: stream.${DOMAIN}
    service: http://localhost:${MJPG_PORT}

  # その他すべて（404）
  - service: http_status:404
EOF

echo ""
echo_info "5. トンネルの起動"
echo ""

# systemdサービスの作成
cat > /etc/systemd/system/cloudflared.service << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config /root/.cloudflared/config.yml run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# サービスの有効化と起動
systemctl daemon-reload
systemctl enable cloudflared.service
systemctl start cloudflared.service

# 起動確認
sleep 3
if systemctl is-active --quiet cloudflared.service; then
    echo_info ""
    echo_info "======================================"
    echo_info "セットアップ完了！"
    echo_info "======================================"
    echo_info ""
    echo_info "外部アクセスURL:"
    echo_info "  Webギャラリー: https://${FULL_DOMAIN}"
    echo_info "  ライブストリーム: https://stream.${DOMAIN}/?action=stream"
    echo_info ""
    echo_info "トンネル管理:"
    echo_info "  停止: systemctl stop cloudflared"
    echo_info "  開始: systemctl start cloudflared"
    echo_info "  状態確認: systemctl status cloudflared"
    echo_info ""
    echo_info "Cloudflareダッシュボード:"
    echo_info "  https://dash.cloudflare.com/"
    echo_info ""
else
    echo_error "トンネルの起動に失敗しました"
    echo_error "journalctl -u cloudflared でログを確認してください"
    exit 1
fi
