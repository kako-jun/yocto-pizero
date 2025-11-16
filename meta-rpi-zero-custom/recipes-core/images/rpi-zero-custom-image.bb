# Raspberry Pi Zero 軽量Webサーバーイメージ
#
# このイメージは core-image-minimal をベースに、
# 軽量Webサーバー（nginx）として動作するよう最適化されています

SUMMARY = "Lightweight web server image for Raspberry Pi Zero"
DESCRIPTION = "Minimal Linux image optimized for Raspberry Pi Zero as a lightweight web server with nginx"

LICENSE = "MIT"

# ベースイメージ
require recipes-core/images/core-image-minimal.bb

# イメージの機能
IMAGE_FEATURES += "\
    ssh-server-openssh \
    package-management \
    "

# WiFi サポート（注: Raspberry Pi Zero 初代はWiFiなし、USB WiFiアダプタ使用時のみ）
IMAGE_INSTALL:append = " \
    linux-firmware-rpidistro-bcm43430 \
    "

# ネットワーク管理ツール
IMAGE_INSTALL:append = " \
    iw \
    wpa-supplicant \
    dhcpcd \
    "

# Webサーバー (nginx)
IMAGE_INSTALL:append = " \
    nginx \
    "

# 必要最小限のシステムユーティリティ
IMAGE_INSTALL:append = " \
    nano \
    htop \
    "

# パッケージマネージャー（opkg）でランタイムにパッケージ追加可能
# 例: opkg update && opkg install <パッケージ名>

# イメージのルートファイルシステム設定
# より小さいサイズに最適化
IMAGE_ROOTFS_SIZE ?= "512000"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# イメージ後処理
ROOTFS_POSTPROCESS_COMMAND += "custom_postprocess; "

custom_postprocess() {
    # ホスト名の設定
    echo "raspizero-web" > ${IMAGE_ROOTFS}/etc/hostname

    # nginx デフォルトページの設定
    if [ -d ${IMAGE_ROOTFS}/var/www/localhost/html ]; then
        cat > ${IMAGE_ROOTFS}/var/www/localhost/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Raspberry Pi Zero Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #c51a4a; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Raspberry Pi Zero Web Server</h1>
        <p>Welcome to your lightweight Yocto-based web server!</p>
        <p>Built with nginx on Yocto Project</p>
    </div>
</body>
</html>
EOF
    fi
}
