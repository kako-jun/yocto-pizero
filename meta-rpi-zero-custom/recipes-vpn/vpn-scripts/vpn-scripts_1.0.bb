# VPN セットアップスクリプト
#
# WireGuard、OpenVPN、DDNS のセットアップヘルパースクリプト

SUMMARY = "VPN setup helper scripts"
DESCRIPTION = "Scripts to help setup WireGuard, OpenVPN, and Dynamic DNS"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://setup-wireguard.sh \
    file://setup-openvpn.sh \
    file://setup-ddns.sh \
    file://wireguard-add-client.sh \
    "

S = "${WORKDIR}"

do_install() {
    install -d ${D}/opt/vpn-scripts

    install -m 0755 ${WORKDIR}/setup-wireguard.sh ${D}/opt/vpn-scripts/
    install -m 0755 ${WORKDIR}/setup-openvpn.sh ${D}/opt/vpn-scripts/
    install -m 0755 ${WORKDIR}/setup-ddns.sh ${D}/opt/vpn-scripts/
    install -m 0755 ${WORKDIR}/wireguard-add-client.sh ${D}/opt/vpn-scripts/
}

FILES:${PN} = "/opt/vpn-scripts/*"

RDEPENDS:${PN} = "bash"
