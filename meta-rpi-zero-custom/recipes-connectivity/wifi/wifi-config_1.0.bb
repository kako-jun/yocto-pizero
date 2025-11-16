# WiFi 設定ファイル
#
# このレシピは wpa_supplicant の設定テンプレートをインストールします
# 実際のSSIDとパスワードは起動後に設定してください

SUMMARY = "WiFi configuration template for Raspberry Pi Zero"
DESCRIPTION = "Installs wpa_supplicant configuration template"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wpa_supplicant.conf.template"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 0600 wpa_supplicant.conf.template ${D}${sysconfdir}/wpa_supplicant/
}

FILES:${PN} = "${sysconfdir}/wpa_supplicant/wpa_supplicant.conf.template"
