# カスタマイズガイド

Yocto Projectでイメージをカスタマイズする方法

## カスタムレイヤーの構成

```
meta-rpi-zero-custom/
├── conf/
│   └── layer.conf              # レイヤー設定
├── recipes-core/
│   └── images/
│       └── rpi-zero-custom-image.bb  # カスタムイメージ定義
├── recipes-example/
│   └── hello/
│       ├── hello_1.0.bb       # レシピ
│       └── files/
│           └── hello.c         # ソースファイル
└── recipes-connectivity/
    └── wifi/
        └── wifi-config_1.0.bb # WiFi設定
```

## イメージのカスタマイズ

### 1. パッケージの追加

`meta-rpi-zero-custom/recipes-core/images/rpi-zero-custom-image.bb` を編集：

```bitbake
# パッケージを追加
IMAGE_INSTALL:append = " \
    git \
    curl \
    nginx \
    "
```

### 2. カーネルモジュールの追加

```bitbake
# カーネルモジュールを含める
IMAGE_INSTALL:append = " \
    kernel-modules \
    "
```

### 3. Python パッケージの追加

```bitbake
# Python パッケージ
IMAGE_INSTALL:append = " \
    python3-numpy \
    python3-flask \
    python3-requests \
    "
```

## カスタムレシピの作成

### 基本的なレシピ構造

```bitbake
# recipes-myapp/myapp/myapp_1.0.bb

SUMMARY = "My Custom Application"
DESCRIPTION = "Description of my application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://myapp.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} myapp.c -o myapp
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 myapp ${D}${bindir}
}

FILES:${PN} = "${bindir}/myapp"
```

### Gitリポジトリからのビルド

```bitbake
SRC_URI = "git://github.com/username/project.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit cmake  # または autotools, meson など

do_install() {
    oe_runmake install DESTDIR=${D}
}
```

## systemd サービスの追加

### 1. サービスファイルの作成

`recipes-myapp/myapp/files/myapp.service`:

```ini
[Unit]
Description=My Custom Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/myapp
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

### 2. レシピに追加

```bitbake
inherit systemd

SYSTEMD_SERVICE:${PN} = "myapp.service"
SYSTEMD_AUTO_ENABLE = "enable"

SRC_URI += "file://myapp.service"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/myapp.service ${D}${systemd_system_unitdir}
}

FILES:${PN} += "${systemd_system_unitdir}/myapp.service"
```

## 設定ファイルのカスタマイズ

### 既存レシピの設定を上書き（bbappend）

`recipes-core/base-files/base-files_%.bbappend`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://custom-hostname"

do_install:append() {
    install -m 0644 ${WORKDIR}/custom-hostname ${D}${sysconfdir}/hostname
}
```

## カーネル設定のカスタマイズ

### カーネルフラグメントの追加

`recipes-kernel/linux/linux-raspberrypi_%.bbappend`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://custom.cfg"
```

`files/custom.cfg`:
```
CONFIG_I2C=y
CONFIG_SPI=y
CONFIG_USB_SERIAL=y
```

## デバイスツリーのカスタマイズ

### デバイスツリーオーバーレイの追加

```bitbake
# local.conf または イメージレシピに追加
ENABLE_I2C = "1"
ENABLE_SPI = "1"
ENABLE_UART = "1"

# カスタムオーバーレイ
RPI_EXTRA_CONFIG += '\n dtoverlay=i2c-rtc,ds3231'
```

## ルートファイルシステムの後処理

### イメージ作成後のカスタマイズ

```bitbake
# イメージレシピに追加
ROOTFS_POSTPROCESS_COMMAND += "custom_postprocess; "

custom_postprocess() {
    # ホスト名の設定
    echo "raspizero" > ${IMAGE_ROOTFS}/etc/hostname

    # タイムゾーンの設定
    ln -sf /usr/share/zoneinfo/Asia/Tokyo ${IMAGE_ROOTFS}/etc/localtime

    # カスタムファイルのコピー
    install -d ${IMAGE_ROOTFS}/opt/myapp
    install -m 0755 ${WORKDIR}/myapp.sh ${IMAGE_ROOTFS}/opt/myapp/
}
```

## 依存関係の管理

### ランタイム依存関係

```bitbake
# パッケージの実行に必要な依存関係
RDEPENDS:${PN} = "python3 bash"
```

### ビルド時依存関係

```bitbake
# ビルドに必要な依存関係
DEPENDS = "openssl zlib"
```

## イメージサイズの最適化

### 不要なパッケージの削除

```bitbake
# local.conf に追加
IMAGE_INSTALL:remove = "packagegroup-core-boot"

# 最小限の機能のみ
DISTRO_FEATURES = "ext2 usbhost wifi bluetooth"
```

### 作業ディレクトリの自動削除

```bitbake
# local.conf に追加
INHERIT += "rm_work"

# 特定のレシピは保持
RM_WORK_EXCLUDE += "myapp"
```

## 開発用カスタマイズ

### SDK の生成

```bash
# クロス開発環境を生成
bitbake -c populate_sdk rpi-zero-custom-image

# SDKのインストール
./tmp/deploy/sdk/poky-glibc-x86_64-rpi-zero-custom-image-cortexa7t2hf-neon-vfpv4-raspberrypi0-toolchain-*.sh
```

### devtool の使用

```bash
# 新しいレシピを作成
devtool add myapp https://github.com/username/myapp.git

# 開発
devtool edit-recipe myapp

# ビルドとデプロイ
devtool build myapp
devtool deploy-target myapp root@raspizero.local
```

## カスタマイズ例

### IoTセンサーノード向け

```bitbake
IMAGE_INSTALL:append = " \
    python3-smbus \
    i2c-tools \
    python3-gpiozero \
    python3-rpi-gpio \
    python3-paho-mqtt \
    "
```

### Webサーバー向け

```bitbake
IMAGE_INSTALL:append = " \
    nginx \
    php \
    sqlite3 \
    "
```

### カメラストリーミング向け

```bitbake
IMAGE_INSTALL:append = " \
    v4l-utils \
    ffmpeg \
    python3-picamera \
    "
```

## トラブルシューティング

### レシピのクリーンビルド

```bash
bitbake -c cleanall myapp
bitbake myapp
```

### 依存関係の確認

```bash
bitbake -g rpi-zero-custom-image
cat task-depends.dot | grep myapp
```

### デバッグ情報の出力

```bash
bitbake -v myapp
bitbake -e myapp | grep ^SRC_URI=
```

## 参考リソース

- [Yocto Project Manual](https://docs.yoctoproject.org/)
- [BitBake User Manual](https://docs.yoctoproject.org/bitbake/)
- [meta-raspberrypi Layer](https://meta-raspberrypi.readthedocs.io/)
