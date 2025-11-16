#!/bin/bash
# USB Webカメラ セットアップスクリプト

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
echo_info "USB Webカメラ セットアップ"
echo_info "======================================"
echo ""

# USB Webカメラの検出
echo_info "USB Webカメラを検出しています..."
if ! ls /dev/video* > /dev/null 2>&1; then
    echo_error "USB Webカメラが検出されませんでした"
    echo_error "USB Webカメラを接続してから再度実行してください"
    exit 1
fi

# 検出されたカメラを表示
echo_info "検出されたカメラ:"
for dev in /dev/video*; do
    if [ -c "$dev" ]; then
        echo "  $dev"
        v4l2-ctl --device=$dev --info 2>/dev/null || true
    fi
done

echo ""
read -p "使用するカメラデバイス [/dev/video0]: " VIDEO_DEVICE
VIDEO_DEVICE=${VIDEO_DEVICE:-/dev/video0}

if [ ! -c "$VIDEO_DEVICE" ]; then
    echo_error "デバイス $VIDEO_DEVICE が見つかりません"
    exit 1
fi

# カメラの対応フォーマットを確認
echo_info ""
echo_info "カメラの対応フォーマット:"
v4l2-ctl --device=$VIDEO_DEVICE --list-formats-ext

echo ""
echo_info "推奨設定:"
echo_info "  解像度: 640x480 または 1280x720"
echo_info "  FPS: 15〜30"
echo ""

read -p "解像度（幅） [640]: " WIDTH
WIDTH=${WIDTH:-640}

read -p "解像度（高さ） [480]: " HEIGHT
HEIGHT=${HEIGHT:-480}

read -p "フレームレート [15]: " FPS
FPS=${FPS:-15}

read -p "ポート番号 [8080]: " PORT
PORT=${PORT:-8080}

# mjpg-streamerの確認
if ! command -v mjpg_streamer &> /dev/null; then
    echo_error "mjpg-streamer がインストールされていません"
    echo_info "opkg install mjpg-streamer でインストールしてください"
    exit 1
fi

# 起動スクリプトの作成
cat > /opt/webcam-scripts/webcam-start.sh << EOF
#!/bin/bash
# mjpg-streamer 起動スクリプト

DEVICE="${VIDEO_DEVICE}"
WIDTH=${WIDTH}
HEIGHT=${HEIGHT}
FPS=${FPS}
PORT=${PORT}

# 既存プロセスを停止
pkill -f mjpg_streamer || true
sleep 1

# mjpg-streamer 起動
mjpg_streamer \\
    -i "input_uvc.so -d \$DEVICE -r \${WIDTH}x\${HEIGHT} -f \$FPS" \\
    -o "output_http.so -p \$PORT -w /usr/share/mjpg-streamer/www" &

echo "mjpg-streamer started on port \$PORT"
echo "Stream URL: http://\$(hostname -I | awk '{print \$1}'):\$PORT/?action=stream"
echo "Snapshot URL: http://\$(hostname -I | awk '{print \$1}'):\$PORT/?action=snapshot"
EOF

chmod +x /opt/webcam-scripts/webcam-start.sh

# systemdサービスの作成
cat > /etc/systemd/system/webcam.service << EOF
[Unit]
Description=USB Webcam Streaming Service
After=network.target

[Service]
Type=forking
ExecStart=/opt/webcam-scripts/webcam-start.sh
ExecStop=/usr/bin/pkill -f mjpg_streamer
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# サービスの有効化
systemctl daemon-reload
systemctl enable webcam.service
systemctl start webcam.service

# 起動確認
sleep 2
if systemctl is-active --quiet webcam.service; then
    echo_info ""
    echo_info "======================================"
    echo_info "セットアップ完了！"
    echo_info "======================================"
    echo_info ""
    echo_info "ストリーミングが開始されました"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo_info ""
    echo_info "アクセスURL:"
    echo_info "  ライブストリーム: http://${IP_ADDR}:${PORT}/?action=stream"
    echo_info "  スナップショット: http://${IP_ADDR}:${PORT}/?action=snapshot"
    echo_info "  Webギャラリー: http://${IP_ADDR}/"
    echo_info ""
    echo_info "サービス管理:"
    echo_info "  停止: systemctl stop webcam"
    echo_info "  開始: systemctl start webcam"
    echo_info "  状態確認: systemctl status webcam"
    echo_info ""
else
    echo_error "サービスの起動に失敗しました"
    echo_error "journalctl -u webcam でログを確認してください"
    exit 1
fi
