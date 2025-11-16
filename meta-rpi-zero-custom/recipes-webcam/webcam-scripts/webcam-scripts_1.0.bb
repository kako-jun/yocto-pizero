# USB Webカメラ セットアップスクリプト
#
# USB Webカメラ、Cloudflare Tunnel、タイムラプスのセットアップヘルパースクリプト

SUMMARY = "USB webcam setup helper scripts"
DESCRIPTION = "Scripts to help setup USB webcam streaming, Cloudflare Tunnel, and timelapse recording"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
    file://setup-webcam.sh \
    file://setup-cloudflare-tunnel.sh \
    file://setup-timelapse.sh \
    file://webcam-start.sh \
    "

S = "${WORKDIR}"

do_install() {
    install -d ${D}/opt/webcam-scripts

    install -m 0755 ${WORKDIR}/setup-webcam.sh ${D}/opt/webcam-scripts/
    install -m 0755 ${WORKDIR}/setup-cloudflare-tunnel.sh ${D}/opt/webcam-scripts/
    install -m 0755 ${WORKDIR}/setup-timelapse.sh ${D}/opt/webcam-scripts/
    install -m 0755 ${WORKDIR}/webcam-start.sh ${D}/opt/webcam-scripts/
}

FILES:${PN} = "/opt/webcam-scripts/*"

RDEPENDS:${PN} = "bash"
