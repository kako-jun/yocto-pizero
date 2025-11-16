#!/bin/bash
# Docker を使った Yocto イメージビルドスクリプト

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
    echo "使用方法: $0 [オプション] [イメージ名]"
    echo ""
    echo "オプション:"
    echo "  --setup        セットアップのみ実行（ビルドしない）"
    echo "  --build-only   ビルドのみ実行（セットアップスキップ）"
    echo "  --shell        コンテナ内でシェルを起動"
    echo "  --clean        ビルドディレクトリをクリーンアップ"
    echo "  -h, --help     このヘルプを表示"
    echo ""
    echo "イメージ名:"
    echo "  rpi-zero-custom-image  - カスタムイメージ（デフォルト）"
    echo "  core-image-minimal     - 最小限のイメージ"
    echo ""
    echo "例:"
    echo "  $0                              # フルビルド（デフォルトイメージ）"
    echo "  $0 core-image-minimal           # core-image-minimalをビルド"
    echo "  $0 --setup                      # セットアップのみ"
    echo "  $0 --shell                      # コンテナシェルを起動"
    exit 1
}

# Docker と docker-compose の確認
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo_error "Docker がインストールされていません"
        echo_error "https://docs.docker.com/get-docker/ を参照してください"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo_error "docker-compose がインストールされていません"
        exit 1
    fi

    # docker-compose または docker compose のどちらを使うか判定
    if docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
    else
        DOCKER_COMPOSE="docker-compose"
    fi
}

# Dockerイメージのビルド
build_docker_image() {
    echo_info "Docker イメージをビルドしています..."
    $DOCKER_COMPOSE build
    echo_info "Docker イメージのビルドが完了しました"
}

# セットアップ実行
run_setup() {
    echo_info "Yocto 環境のセットアップを実行しています..."
    $DOCKER_COMPOSE run --rm yocto-builder bash -c "./setup.sh"
    echo_info "セットアップが完了しました"
}

# ビルド実行
run_build() {
    local IMAGE_NAME=${1:-rpi-zero-custom-image}
    echo_info "イメージ ${IMAGE_NAME} をビルドしています..."
    echo_warn "ビルドには数時間かかる場合があります"

    $DOCKER_COMPOSE run --rm yocto-builder bash -c "
        source poky/oe-init-build-env build
        bitbake ${IMAGE_NAME}
    "

    echo_info "ビルドが完了しました！"
    echo_info "イメージファイル: build/tmp/deploy/images/raspberrypi0/"
}

# シェル起動
run_shell() {
    echo_info "コンテナシェルを起動します..."
    $DOCKER_COMPOSE run --rm yocto-builder bash
}

# クリーンアップ
run_clean() {
    echo_warn "ビルドディレクトリをクリーンアップします"
    read -p "続行しますか? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi

    $DOCKER_COMPOSE run --rm yocto-builder bash -c "
        rm -rf build/tmp
        echo 'クリーンアップ完了'
    "
}

# メイン処理
main() {
    check_docker

    local SETUP_ONLY=false
    local BUILD_ONLY=false
    local SHELL_MODE=false
    local CLEAN_MODE=false
    local IMAGE_NAME="rpi-zero-custom-image"

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --setup)
                SETUP_ONLY=true
                shift
                ;;
            --build-only)
                BUILD_ONLY=true
                shift
                ;;
            --shell)
                SHELL_MODE=true
                shift
                ;;
            --clean)
                CLEAN_MODE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                IMAGE_NAME=$1
                shift
                ;;
        esac
    done

    # Dockerイメージをビルド
    build_docker_image

    # モード別処理
    if $SHELL_MODE; then
        run_shell
    elif $CLEAN_MODE; then
        run_clean
    elif $SETUP_ONLY; then
        run_setup
    elif $BUILD_ONLY; then
        run_build "$IMAGE_NAME"
    else
        # フルビルド
        run_setup
        run_build "$IMAGE_NAME"
    fi

    echo_info ""
    echo_info "============================================"
    echo_info "完了しました！"
    echo_info "============================================"
}

main "$@"
