# MJPG-Streamer - Streaming application for USB webcams
#
# MJPG-Streamer is a command line application that can be used to
# stream JPEG files over an IP-based network from a webcam to various types of viewers.

SUMMARY = "Streaming application for USB webcams"
DESCRIPTION = "MJPG-Streamer is a command line application that can stream \
JPEG files over an IP-based network from a webcam to various types of viewers."
HOMEPAGE = "https://github.com/jacksonliam/mjpg-streamer"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

DEPENDS = "jpeg v4l-utils"

SRC_URI = "git://github.com/jacksonliam/mjpg-streamer.git;protocol=https;branch=master"
SRCREV = "310b29f4a94c46652b20c4b7b6e5cf24e532af39"

S = "${WORKDIR}/git/mjpg-streamer-experimental"

inherit cmake

EXTRA_OECMAKE = " \
    -DENABLE_HTTP_MANAGEMENT=ON \
    -DPLUGIN_INPUT_UVC=ON \
    -DPLUGIN_INPUT_FILE=ON \
    -DPLUGIN_OUTPUT_HTTP=ON \
    -DPLUGIN_OUTPUT_FILE=ON \
"

do_install:append() {
    # Install start script
    install -d ${D}${bindir}

    # Create wrapper script for easier usage
    cat > ${D}${bindir}/mjpg_streamer << 'EOF'
#!/bin/sh
# MJPG-Streamer wrapper script

MJPG_STREAMER_DIR=/usr/local/lib/mjpg-streamer
export LD_LIBRARY_PATH=${MJPG_STREAMER_DIR}

exec ${MJPG_STREAMER_DIR}/mjpg_streamer "$@"
EOF
    chmod +x ${D}${bindir}/mjpg_streamer
}

FILES:${PN} += " \
    ${libdir}/mjpg-streamer/*.so \
    ${datadir}/mjpg-streamer/* \
"

RDEPENDS:${PN} += "jpeg v4l-utils"
