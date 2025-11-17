#!/bin/bash
# Yocto ビルド実行スクリプト
#
# このスクリプトはYocto環境をソースしてビルドを実行します

set -e

# 色付き出力
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 使用方法
usage() {
    echo "使用方法: $0 [イメージ名]"
    echo ""
    echo "イメージ名:"
    echo "  rpi-zero-custom-image   - nginx Webサーバー（デフォルト）"
    echo "  rpi-zero-vpn-gateway    - VPNゲートウェイ（WireGuard/OpenVPN）"
    echo "  rpi-zero-webcam-server  - USB Webカメラサーバー"
    echo "  core-image-minimal      - 最小限のイメージ"
    echo ""
    echo "例:"
    echo "  $0                          # Webサーバーイメージ（デフォルト）"
    echo "  $0 rpi-zero-vpn-gateway     # VPNゲートウェイ"
    echo "  $0 rpi-zero-webcam-server   # Webカメラサーバー"
    exit 1
}

# Yocto環境の確認
if [ ! -d "poky" ]; then
    echo_error "poky ディレクトリが見つかりません"
    echo_error "まず setup.sh を実行してください"
    exit 1
fi

# イメージ名の指定（デフォルト: rpi-zero-custom-image）
IMAGE_NAME=${1:-rpi-zero-custom-image}

echo_info "========================================="
echo_info "Yocto Project ビルド開始"
echo_info "========================================="
echo_info "イメージ: ${IMAGE_NAME}"
echo_info ""

# ディスク容量確認
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 50 ]; then
    echo_warn "ディスク空き容量が少なくなっています: ${AVAILABLE_SPACE}GB"
    echo_warn "ビルドには最低50GB以上の空き容量を推奨します"
    read -p "続行しますか? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ビルド開始時刻
START_TIME=$(date +%s)

# Yocto環境をソースしてビルド実行
echo_info "Yocto環境をソースしています..."
source poky/oe-init-build-env build

echo_info "ビルドを開始します（数時間かかる場合があります）..."
echo_info ""

# bitbake 実行
bitbake ${IMAGE_NAME}

# ビルド終了時刻
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
ELAPSED_HOURS=$((ELAPSED_TIME / 3600))
ELAPSED_MINUTES=$(((ELAPSED_TIME % 3600) / 60))
ELAPSED_SECONDS=$((ELAPSED_TIME % 60))

echo_info ""
echo_info "========================================="
echo_info "ビルドが完了しました！"
echo_info "========================================="
echo_info "経過時間: ${ELAPSED_HOURS}時間 ${ELAPSED_MINUTES}分 ${ELAPSED_SECONDS}秒"
echo_info ""
echo_info "生成されたイメージ:"
ls -lh tmp/deploy/images/raspberrypi0/*.wic 2>/dev/null || echo "  イメージファイルが見つかりませんでした"
echo_info ""
echo_info "SDカードへの書き込み例:"
echo_info "  sudo dd if=tmp/deploy/images/raspberrypi0/${IMAGE_NAME}-raspberrypi0.wic of=/dev/sdX bs=4M status=progress"
echo_info "  sudo sync"
echo_info ""
