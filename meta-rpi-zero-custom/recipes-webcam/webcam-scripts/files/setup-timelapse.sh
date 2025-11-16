#!/bin/bash
# タイムラプス撮影 セットアップスクリプト

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
echo_info "タイムラプス撮影 セットアップ"
echo_info "======================================"
echo ""

# 必要なツールの確認
if ! command -v ffmpeg &> /dev/null; then
    echo_error "ffmpeg がインストールされていません"
    exit 1
fi

if ! command -v v4l2-ctl &> /dev/null; then
    echo_error "v4l-utils がインストールされていません"
    exit 1
fi

# カメラデバイスの確認
if ! ls /dev/video* > /dev/null 2>&1; then
    echo_error "USB Webカメラが検出されませんでした"
    exit 1
fi

read -p "使用するカメラデバイス [/dev/video0]: " VIDEO_DEVICE
VIDEO_DEVICE=${VIDEO_DEVICE:-/dev/video0}

echo ""
echo_info "タイムラプス設定"
echo ""

read -p "撮影間隔（分） [5]: " INTERVAL_MIN
INTERVAL_MIN=${INTERVAL_MIN:-5}

read -p "解像度（幅） [1280]: " WIDTH
WIDTH=${WIDTH:-1280}

read -p "解像度（高さ） [720]: " HEIGHT
HEIGHT=${HEIGHT:-720}

read -p "1日何回動画を生成しますか [1]: " VIDEO_PER_DAY
VIDEO_PER_DAY=${VIDEO_PER_DAY:-1}

# 保存先ディレクトリ
SNAPSHOT_DIR="/var/webcam/timelapse"
VIDEO_DIR="/var/webcam/videos"

mkdir -p ${SNAPSHOT_DIR}
mkdir -p ${VIDEO_DIR}

# スナップショット撮影スクリプト
cat > /usr/local/bin/timelapse-capture.sh << EOF
#!/bin/bash
# タイムラプス用スナップショット撮影

DEVICE="${VIDEO_DEVICE}"
SNAPSHOT_DIR="${SNAPSHOT_DIR}"
WIDTH=${WIDTH}
HEIGHT=${HEIGHT}

# ファイル名（日時付き）
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
FILENAME="\${SNAPSHOT_DIR}/\${TIMESTAMP}.jpg"

# スナップショット撮影
ffmpeg -f v4l2 -video_size \${WIDTH}x\${HEIGHT} -i \${DEVICE} -frames:v 1 \${FILENAME} -y 2>/dev/null

# ログ
echo "\$(date): Captured \${FILENAME}" >> /var/log/timelapse.log
EOF

chmod +x /usr/local/bin/timelapse-capture.sh

# 動画生成スクリプト
cat > /usr/local/bin/timelapse-video.sh << 'EOF'
#!/bin/bash
# タイムラプス動画生成

SNAPSHOT_DIR="/var/webcam/timelapse"
VIDEO_DIR="/var/webcam/videos"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VIDEO_FILE="${VIDEO_DIR}/timelapse_${TIMESTAMP}.mp4"

# スナップショットが存在するか確認
if [ ! "$(ls -A $SNAPSHOT_DIR/*.jpg 2>/dev/null)" ]; then
    echo "No snapshots found"
    exit 0
fi

# 動画生成（30fps）
ffmpeg -framerate 30 -pattern_type glob -i "${SNAPSHOT_DIR}/*.jpg" \
    -c:v libx264 -pix_fmt yuv420p -preset medium \
    "${VIDEO_FILE}" 2>/dev/null

# 生成成功したらスナップショットを削除
if [ -f "${VIDEO_FILE}" ]; then
    echo "$(date): Video created: ${VIDEO_FILE}" >> /var/log/timelapse.log

    # スナップショットをアーカイブディレクトリに移動（オプション）
    # mkdir -p ${SNAPSHOT_DIR}/archive
    # mv ${SNAPSHOT_DIR}/*.jpg ${SNAPSHOT_DIR}/archive/

    # またはシンプルに削除
    rm -f ${SNAPSHOT_DIR}/*.jpg

    echo "Timelapse video created: ${VIDEO_FILE}"
else
    echo "Failed to create video" >> /var/log/timelapse.log
fi
EOF

chmod +x /usr/local/bin/timelapse-video.sh

# cronジョブの追加
echo ""
echo_info "cronジョブを設定しています..."

# スナップショット撮影（指定間隔）
CRON_CAPTURE="*/${INTERVAL_MIN} * * * * /usr/local/bin/timelapse-capture.sh"

# 動画生成（1日に指定回数）
if [ "$VIDEO_PER_DAY" -eq 1 ]; then
    # 1日1回（23:59）
    CRON_VIDEO="59 23 * * * /usr/local/bin/timelapse-video.sh"
elif [ "$VIDEO_PER_DAY" -eq 2 ]; then
    # 1日2回（11:59, 23:59）
    CRON_VIDEO="59 11,23 * * * /usr/local/bin/timelapse-video.sh"
elif [ "$VIDEO_PER_DAY" -eq 4 ]; then
    # 1日4回（5:59, 11:59, 17:59, 23:59）
    CRON_VIDEO="59 5,11,17,23 * * * /usr/local/bin/timelapse-video.sh"
else
    # デフォルト: 1日1回
    CRON_VIDEO="59 23 * * * /usr/local/bin/timelapse-video.sh"
fi

# cronに追加
(crontab -l 2>/dev/null | grep -v timelapse; echo "$CRON_CAPTURE"; echo "$CRON_VIDEO") | crontab -

# logrotateの設定
cat > /etc/logrotate.d/timelapse << EOF
/var/log/timelapse.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF

# 初回テスト撮影
echo ""
echo_info "テスト撮影を実行しています..."
/usr/local/bin/timelapse-capture.sh

if ls ${SNAPSHOT_DIR}/*.jpg > /dev/null 2>&1; then
    echo_info "テスト撮影成功！"
else
    echo_error "テスト撮影に失敗しました"
    exit 1
fi

echo ""
echo_info "======================================"
echo_info "セットアップ完了！"
echo_info "======================================"
echo_info ""
echo_info "タイムラプス設定:"
echo_info "  撮影間隔: ${INTERVAL_MIN}分ごと"
echo_info "  動画生成: 1日${VIDEO_PER_DAY}回"
echo_info "  解像度: ${WIDTH}x${HEIGHT}"
echo_info ""
echo_info "ファイル保存先:"
echo_info "  スナップショット: ${SNAPSHOT_DIR}/"
echo_info "  動画: ${VIDEO_DIR}/"
echo_info ""
echo_info "手動操作:"
echo_info "  今すぐ撮影: /usr/local/bin/timelapse-capture.sh"
echo_info "  今すぐ動画生成: /usr/local/bin/timelapse-video.sh"
echo_info ""
echo_info "cron設定確認:"
echo_info "  crontab -l"
echo_info ""
echo_info "ログ確認:"
echo_info "  tail -f /var/log/timelapse.log"
echo_info ""
echo_info "Webアクセス:"
echo_info "  http://$(hostname -I | awk '{print $1}')/gallery/videos/"
echo_info ""
