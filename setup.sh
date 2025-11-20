#!/bin/bash
# Yocto Project セットアップスクリプト for Raspberry Pi Zero
# このスクリプトは必要なレイヤーをクローンし、ビルド環境を準備します

set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Yocto Project バージョン（LTS版のKirkstoneを使用）
YOCTO_BRANCH="kirkstone"

echo_info "Yocto Project セットアップを開始します（ブランチ: ${YOCTO_BRANCH}）"

# 現在のディレクトリ
WORK_DIR=$(pwd)

# 1. Poky（Yocto Projectリファレンス）のクローン
if [ ! -d "poky" ]; then
    echo_info "Poky をクローンしています..."
    git clone -b ${YOCTO_BRANCH} git://git.yoctoproject.org/poky.git
    echo_info "Poky のクローンが完了しました"
else
    echo_warn "poky ディレクトリが既に存在します。スキップします"
fi

# 2. meta-raspberrypi レイヤーのクローン
if [ ! -d "meta-raspberrypi" ]; then
    echo_info "meta-raspberrypi をクローンしています..."
    git clone -b ${YOCTO_BRANCH} git://git.yoctoproject.org/meta-raspberrypi
    echo_info "meta-raspberrypi のクローンが完了しました"
else
    echo_warn "meta-raspberrypi ディレクトリが既に存在します。スキップします"
fi

# 3. meta-openembedded レイヤーのクローン（依存関係）
if [ ! -d "meta-openembedded" ]; then
    echo_info "meta-openembedded をクローンしています..."
    git clone -b ${YOCTO_BRANCH} git://git.openembedded.org/meta-openembedded
    echo_info "meta-openembedded のクローンが完了しました"
else
    echo_warn "meta-openembedded ディレクトリが既に存在します。スキップします"
fi

# 4. カスタムレイヤーの作成
CUSTOM_LAYER="meta-rpi-zero-custom"
if [ ! -d "${CUSTOM_LAYER}" ]; then
    echo_info "カスタムレイヤー ${CUSTOM_LAYER} を作成しています..."
    mkdir -p ${CUSTOM_LAYER}/conf
    mkdir -p ${CUSTOM_LAYER}/recipes-core/images
    mkdir -p ${CUSTOM_LAYER}/recipes-example/hello
    mkdir -p ${CUSTOM_LAYER}/recipes-connectivity/wifi
    echo_info "カスタムレイヤーディレクトリの作成が完了しました"
else
    echo_warn "${CUSTOM_LAYER} ディレクトリが既に存在します"
fi

# layer.conf の作成（存在しない場合のみ）
if [ ! -f "${CUSTOM_LAYER}/conf/layer.conf" ]; then
    echo_info "layer.conf を作成しています..."
    mkdir -p ${CUSTOM_LAYER}/conf
    cat > ${CUSTOM_LAYER}/conf/layer.conf << 'EOF'
# Custom layer for Raspberry Pi Zero

BBPATH .= ":${LAYERDIR}"

BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "rpi-zero-custom"
BBFILE_PATTERN_rpi-zero-custom = "^${LAYERDIR}/"
BBFILE_PRIORITY_rpi-zero-custom = "10"

LAYERDEPENDS_rpi-zero-custom = "core raspberrypi"
LAYERSERIES_COMPAT_rpi-zero-custom = "kirkstone"
EOF
    echo_info "layer.conf の作成が完了しました"
else
    echo_warn "${CUSTOM_LAYER}/conf/layer.conf が既に存在します。スキップします"
fi

# 5. ビルドディレクトリの準備
echo_info "ビルドディレクトリを準備しています..."
mkdir -p build/conf

# 6. 設定ファイルのコピー（存在しない場合のみ）
if [ ! -f "build/conf/local.conf" ]; then
    if [ -f "conf-templates/local.conf.sample" ]; then
        echo_info "local.conf をコピーしています..."
        cp conf-templates/local.conf.sample build/conf/local.conf
    else
        echo_warn "conf-templates/local.conf.sample が見つかりません"
    fi
else
    echo_warn "build/conf/local.conf が既に存在します。スキップします"
fi

if [ ! -f "build/conf/bblayers.conf" ]; then
    if [ -f "conf-templates/bblayers.conf.sample" ]; then
        echo_info "bblayers.conf をコピーしています..."
        cp conf-templates/bblayers.conf.sample build/conf/bblayers.conf
        # ##OEROOT## を実際のパスに置換
        sed -i "s|##OEROOT##|${WORK_DIR}/poky|g" build/conf/bblayers.conf
    else
        echo_warn "conf-templates/bblayers.conf.sample が見つかりません"
    fi
else
    echo_warn "build/conf/bblayers.conf が既に存在します。スキップします"
fi

echo_info ""
echo_info "============================================"
echo_info "セットアップが完了しました！"
echo_info "============================================"
echo_info ""
echo_info "次のステップ:"
echo_info "1. 設定ファイルを必要に応じて編集:"
echo_info "   build/conf/local.conf"
echo_info "   build/conf/bblayers.conf"
echo_info ""
echo_info "2. Yocto環境をソース:"
echo_info "   source poky/oe-init-build-env build"
echo_info ""
echo_info "3. イメージをビルド:"
echo_info "   bitbake core-image-minimal"
echo_info "   または"
echo_info "   bitbake rpi-zero-custom-image"
echo_info ""
echo_info "詳細は README.md を参照してください"
