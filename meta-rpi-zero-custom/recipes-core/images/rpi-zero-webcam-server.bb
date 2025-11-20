# Raspberry Pi Zero USB Webカメラサーバーイメージ
#
# このイメージは core-image-minimal をベースに、
# USB Webカメラによるストリーミング・タイムラプス撮影サーバーとして動作します

SUMMARY = "USB webcam streaming and timelapse server for Raspberry Pi Zero"
DESCRIPTION = "Minimal Linux image optimized for USB webcam streaming, timelapse recording with Cloudflare Tunnel support"

LICENSE = "MIT"

# ベースイメージ
require recipes-core/images/core-image-minimal.bb

# イメージの機能
IMAGE_FEATURES += "\
    ssh-server-openssh \
    package-management \
    "

# WiFi サポート（USB WiFiアダプタ使用時）
IMAGE_INSTALL:append = " \
    linux-firmware-rpidistro-bcm43430 \
    "

# ネットワーク管理ツール
IMAGE_INSTALL:append = " \
    iw \
    wpa-supplicant \
    dhcpcd \
    "

# USB Webカメラサポート（V4L2）
IMAGE_INSTALL:append = " \
    v4l-utils \
    "

# ビデオストリーミング
IMAGE_INSTALL:append = " \
    mjpg-streamer \
    "

# 画像・動画処理
IMAGE_INSTALL:append = " \
    ffmpeg \
    "

# Webサーバー（静的ファイル配信・ギャラリー）
IMAGE_INSTALL:append = " \
    nginx \
    "

# ファイルシステム・ストレージ
IMAGE_INSTALL:append = " \
    e2fsprogs \
    dosfstools \
    "

# システムユーティリティ
IMAGE_INSTALL:append = " \
    nano \
    htop \
    rsync \
    cron \
    logrotate \
    "

# Cloudflare Tunnel用パッケージ（手動インストール用のツール）
IMAGE_INSTALL:append = " \
    curl \
    wget \
    ca-certificates \
    "

# カメラセットアップスクリプト
IMAGE_INSTALL:append = " \
    webcam-scripts \
    "

# パッケージマネージャー（opkg）でランタイムにパッケージ追加可能
# 例: opkg update && opkg install <パッケージ名>

# イメージのルートファイルシステム設定
# カメラ画像保存用に余裕を持たせる
IMAGE_ROOTFS_SIZE ?= "1048576"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# イメージ後処理
ROOTFS_POSTPROCESS_COMMAND += "custom_postprocess; "

custom_postprocess() {
    # ホスト名の設定
    echo "raspizero-webcam" > ${IMAGE_ROOTFS}/etc/hostname

    # カメラ画像保存ディレクトリ
    install -d ${IMAGE_ROOTFS}/var/webcam
    install -d ${IMAGE_ROOTFS}/var/webcam/stream
    install -d ${IMAGE_ROOTFS}/var/webcam/timelapse
    install -d ${IMAGE_ROOTFS}/var/webcam/snapshots
    install -d ${IMAGE_ROOTFS}/var/webcam/videos

    # nginx Webギャラリー用ディレクトリ
    install -d ${IMAGE_ROOTFS}/var/www/html
    install -d ${IMAGE_ROOTFS}/var/www/html/gallery

    # シンボリックリンク作成（Webからアクセス可能に）
    ln -sf /var/webcam/snapshots ${IMAGE_ROOTFS}/var/www/html/gallery/snapshots
    ln -sf /var/webcam/videos ${IMAGE_ROOTFS}/var/www/html/gallery/videos

    # nginx デフォルトページの設定
    cat > ${IMAGE_ROOTFS}/var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Raspberry Pi Zero Webcam Server</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #2c3e50; }
        .stream-container {
            margin: 20px 0;
            text-align: center;
        }
        .stream-container img {
            max-width: 100%;
            height: auto;
            border: 2px solid #ddd;
            border-radius: 4px;
        }
        .button {
            display: inline-block;
            padding: 10px 20px;
            margin: 5px;
            background: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .button:hover {
            background: #2980b9;
        }
        .info {
            background: #ecf0f1;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎥 Raspberry Pi Zero Webcam Server</h1>

        <div class="stream-container">
            <h2>ライブストリーム</h2>
            <img src="http://localhost:8080/?action=stream" alt="Live Stream" id="stream">
            <p><small>mjpg-streamer が起動していない場合は表示されません</small></p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
            <a href="gallery/snapshots/" class="button">📷 スナップショット</a>
            <a href="gallery/videos/" class="button">🎬 タイムラプス動画</a>
            <a href="http://localhost:8080/?action=snapshot" class="button" target="_blank">📸 今すぐ撮影</a>
        </div>

        <div class="info">
            <h3>セットアップ手順</h3>
            <ol>
                <li>USB Webカメラを接続</li>
                <li><code>/opt/webcam-scripts/setup-webcam.sh</code> を実行</li>
                <li>Cloudflare Tunnel: <code>/opt/webcam-scripts/setup-cloudflare-tunnel.sh</code></li>
                <li>タイムラプス: <code>/opt/webcam-scripts/setup-timelapse.sh</code></li>
            </ol>
        </div>
    </div>

    <script>
        // ストリームエラー時の処理
        document.getElementById('stream').onerror = function() {
            this.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQwIiBoZWlnaHQ9IjQ4MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iNjQwIiBoZWlnaHQ9IjQ4MCIgZmlsbD0iI2VjZjBmMSIvPjx0ZXh0IHg9IjUwJSIgeT0iNTAlIiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMjAiIGZpbGw9IiM5NWE1YTYiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGR5PSIuM2VtIj5TdHJlYW0gbm90IGF2YWlsYWJsZTwvdGV4dD48L3N2Zz4=';
            this.alt = 'Stream not available';
        };
    </script>
</body>
</html>
EOF

    # セットアップヘルプファイルを作成
    cat > ${IMAGE_ROOTFS}/root/README-WEBCAM.txt << 'EOF'
==================================================
Raspberry Pi Zero USB Webcam Server
==================================================

このイメージには以下が含まれています：

1. USB Webカメラサポート（V4L2）
2. mjpg-streamer（ライブストリーミング）
3. ffmpeg（動画変換・タイムラプス作成）
4. nginx（Webギャラリー）
5. Cloudflare Tunnel（外部公開）

セットアップ方法:
-----------------

1. USB Webカメラのセットアップ
   /opt/webcam-scripts/setup-webcam.sh

2. Cloudflare Tunnelのセットアップ（外部公開）
   /opt/webcam-scripts/setup-cloudflare-tunnel.sh

3. タイムラプス撮影のセットアップ
   /opt/webcam-scripts/setup-timelapse.sh

4. Webインターフェースにアクセス
   http://raspizero-webcam.local/

詳細なドキュメント:
  https://github.com/your-repo/yocto-pizero/docs/WEBCAM_SETUP.md

==================================================
EOF

    # スクリプトディレクトリを作成
    install -d ${IMAGE_ROOTFS}/opt/webcam-scripts
}
