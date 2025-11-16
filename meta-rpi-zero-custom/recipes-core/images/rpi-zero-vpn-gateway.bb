# Raspberry Pi Zero VPNゲートウェイイメージ
#
# このイメージは core-image-minimal をベースに、
# VPNゲートウェイとして動作するよう最適化されています

SUMMARY = "VPN gateway image for Raspberry Pi Zero"
DESCRIPTION = "Minimal Linux image optimized for Raspberry Pi Zero as a VPN gateway with WireGuard and OpenVPN"

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

# VPN関連パッケージ
IMAGE_INSTALL:append = " \
    wireguard-tools \
    openvpn \
    easy-rsa \
    "

# ネットワーク・ファイアウォールツール
IMAGE_INSTALL:append = " \
    iptables \
    iptables-modules \
    iproute2 \
    iputils \
    bind-utils \
    "

# ダイナミックDNS クライアント
IMAGE_INSTALL:append = " \
    ddclient \
    curl \
    "

# システムユーティリティ
IMAGE_INSTALL:append = " \
    nano \
    htop \
    tcpdump \
    rsyslog \
    "

# VPN セットアップスクリプト
IMAGE_INSTALL:append = " \
    vpn-scripts \
    "

# パッケージマネージャー（opkg）でランタイムにパッケージ追加可能
# 例: opkg update && opkg install <パッケージ名>

# IP転送を有効化（VPNゲートウェイに必須）
KERNEL_MODULE_AUTOLOAD += "iptable_nat ip_tables iptable_filter"

# イメージのルートファイルシステム設定
IMAGE_ROOTFS_SIZE ?= "512000"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# イメージ後処理
ROOTFS_POSTPROCESS_COMMAND += "custom_postprocess; "

custom_postprocess() {
    # ホスト名の設定
    echo "raspizero-vpn" > ${IMAGE_ROOTFS}/etc/hostname

    # IP転送を有効化
    if [ ! -f ${IMAGE_ROOTFS}/etc/sysctl.conf ]; then
        touch ${IMAGE_ROOTFS}/etc/sysctl.conf
    fi

    # IPv4転送を有効化
    echo "net.ipv4.ip_forward=1" >> ${IMAGE_ROOTFS}/etc/sysctl.conf

    # IPv6転送を有効化（オプション）
    echo "net.ipv6.conf.all.forwarding=1" >> ${IMAGE_ROOTFS}/etc/sysctl.conf

    # WireGuard設定ディレクトリを作成
    install -d ${IMAGE_ROOTFS}/etc/wireguard
    chmod 700 ${IMAGE_ROOTFS}/etc/wireguard

    # OpenVPN設定ディレクトリを作成
    install -d ${IMAGE_ROOTFS}/etc/openvpn
    install -d ${IMAGE_ROOTFS}/etc/openvpn/server
    install -d ${IMAGE_ROOTFS}/etc/openvpn/client

    # セットアップヘルプファイルを作成
    cat > ${IMAGE_ROOTFS}/root/README-VPN.txt << 'EOF'
==================================================
Raspberry Pi Zero VPN Gateway
==================================================

このイメージには以下が含まれています：

1. WireGuard VPN（推奨・高速）
2. OpenVPN（互換性重視）
3. iptables（ファイアウォール）
4. DDクライアント（動的DNS更新）

セットアップ方法:
-----------------

1. WireGuardのセットアップ
   /opt/vpn-scripts/setup-wireguard.sh

2. OpenVPNのセットアップ
   /opt/vpn-scripts/setup-openvpn.sh

3. ダイナミックDNSのセットアップ
   /opt/vpn-scripts/setup-ddns.sh

詳細なドキュメント:
  https://github.com/your-repo/yocto-pizero/docs/VPN_SETUP.md

==================================================
EOF

    # スクリプトディレクトリを作成
    install -d ${IMAGE_ROOTFS}/opt/vpn-scripts
}
