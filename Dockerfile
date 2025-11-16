# Yocto Project ビルド環境 for Raspberry Pi Zero
# Ubuntu 22.04 LTS ベース

FROM ubuntu:22.04

# 非対話モード設定
ENV DEBIAN_FRONTEND=noninteractive

# タイムゾーン設定
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Yocto Project 必須パッケージのインストール
RUN apt-get update && apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool file locales sudo vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ロケール設定
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ビルド用ユーザーの作成（rootでビルドしない）
ARG USER_NAME=yoctouser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USER_NAME} && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 作業ディレクトリ
WORKDIR /home/${USER_NAME}/yocto-pizero

# ユーザー切り替え
USER ${USER_NAME}

# Git設定（ビルド時に必要）
RUN git config --global user.name "Yocto Builder" && \
    git config --global user.email "builder@yocto.local"

# エントリーポイント
CMD ["/bin/bash"]
