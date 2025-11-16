# Docker を使ったビルドガイド

Dockerを使用してYocto Projectをビルドする方法

## メリット

- ホストシステムを汚さない
- 依存パッケージのインストールが不要
- 再現性のあるビルド環境
- 複数のプロジェクトで環境を分離できる

## 前提条件

### Docker のインストール

#### Ubuntu/Debian
```bash
# Docker公式リポジトリから最新版をインストール
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 現在のユーザーをdockerグループに追加（sudoなしで実行可能に）
sudo usermod -aG docker $USER

# ログアウト＆ログインして反映
```

#### macOS
```bash
# Docker Desktop for Macをインストール
# https://docs.docker.com/desktop/install/mac-install/
```

#### Windows
```bash
# Docker Desktop for Windowsをインストール
# https://docs.docker.com/desktop/install/windows-install/
# WSL2バックエンドを使用することを推奨
```

### システム要件

- **ディスク容量**: 最小 60GB（推奨: 100GB以上）
- **メモリ**: 最小 8GB（推奨: 16GB以上）
- **CPU**: 4コア以上推奨

Docker Desktopのリソース設定を確認：
- Settings → Resources → Advanced
- Memory: 8GB以上に設定
- Disk: 60GB以上に設定

## クイックスタート

### 1. 簡単なビルド（推奨）

```bash
# フルビルド（セットアップ → ビルド）
./docker-build.sh

# カスタムイメージを指定
./docker-build.sh rpi-zero-custom-image

# 最小イメージをビルド
./docker-build.sh core-image-minimal
```

### 2. ステップバイステップ

```bash
# セットアップのみ実行
./docker-build.sh --setup

# ビルドのみ実行（セットアップ済みの場合）
./docker-build.sh --build-only
```

## Docker Compose を使った手動操作

### コンテナの起動

```bash
# コンテナをビルド
docker-compose build

# コンテナをバックグラウンドで起動
docker-compose up -d

# コンテナ内でシェルを起動
docker-compose exec yocto-builder bash
```

### コンテナ内での作業

```bash
# コンテナシェルに入る
docker-compose exec yocto-builder bash

# セットアップ
./setup.sh

# ビルド環境をソース
source poky/oe-init-build-env build

# イメージをビルド
bitbake rpi-zero-custom-image

# 終了
exit
```

### コンテナの停止と削除

```bash
# コンテナを停止
docker-compose down

# ボリュームも削除（キャッシュをクリア）
docker-compose down -v
```

## ビルド成果物の取得

ビルドが完了すると、イメージファイルは以下の場所に生成されます：

```bash
# ホストシステムから確認
ls -lh build/tmp/deploy/images/raspberrypi0/

# .wicファイルを探す
find build/tmp/deploy/images/raspberrypi0/ -name "*.wic"
```

イメージファイルは自動的にホストシステムにマウントされます。

## ボリューム管理

### 永続化されるデータ

Docker Composeは以下のディレクトリを永続化します：

- `downloads/` - ダウンロードしたソースコード（再利用可能）
- `sstate-cache/` - ビルドキャッシュ（ビルド高速化）

### ボリュームの確認

```bash
# Docker ボリューム一覧
docker volume ls | grep yocto

# ボリュームの詳細情報
docker volume inspect yocto-pizero_yocto-downloads
docker volume inspect yocto-pizero_yocto-sstate
```

### ボリュームのクリーンアップ

```bash
# 全てのボリュームを削除（ビルドキャッシュもクリア）
docker-compose down -v

# 手動でボリュームを削除
docker volume rm yocto-pizero_yocto-downloads
docker volume rm yocto-pizero_yocto-sstate
```

## トラブルシューティング

### ディスク容量不足

```bash
# Dockerのディスク使用量を確認
docker system df

# 不要なイメージ・コンテナ・ボリュームを削除
docker system prune -a --volumes

# ビルドディレクトリをクリーンアップ
./docker-build.sh --clean
```

### メモリ不足

Docker Desktopの場合：
1. Settings → Resources → Advanced
2. Memory を 8GB 以上に増やす
3. Docker Desktop を再起動

Linux の場合：
```bash
# スワップを確認
free -h

# スワップが少ない場合は増やすことを検討
```

### ビルドが遅い

```bash
# CPUコア数を確認
nproc

# local.conf の並列設定を調整
# build/conf/local.conf を編集:
BB_NUMBER_THREADS = "8"  # CPUコア数
PARALLEL_MAKE = "-j 8"   # CPUコア数
```

### パーミッションエラー

```bash
# ホストとコンテナのUID/GIDを合わせる
# Dockerfileのビルド引数を調整:
docker-compose build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)
```

## 開発用Tips

### インタラクティブシェル

```bash
# コンテナ内でシェルを起動
./docker-build.sh --shell

# または
docker-compose run --rm yocto-builder bash
```

### ビルドログの確認

```bash
# コンテナ内でログを確認
docker-compose exec yocto-builder bash
tail -f build/tmp/log/cooker/raspberrypi0/*.log
```

### devtool の使用

```bash
# コンテナシェルに入る
./docker-build.sh --shell

# Yocto環境をソース
source poky/oe-init-build-env build

# devtoolを使用
devtool add myapp https://github.com/username/myapp.git
devtool build myapp
```

## CI/CD での使用

GitHub Actionsなどで使用する場合：

```yaml
# .github/workflows/build.yml の例
- name: Build with Docker
  run: |
    docker-compose build
    docker-compose run --rm yocto-builder bash -c "
      ./setup.sh
      source poky/oe-init-build-env build
      bitbake rpi-zero-custom-image
    "
```

詳細は `.github/workflows/build-image.yml` を参照してください。

## Dockerfile のカスタマイズ

### ベースイメージの変更

```dockerfile
# Ubuntu 22.04以外を使用する場合
FROM ubuntu:20.04
```

### 追加パッケージのインストール

```dockerfile
# Dockerfileに追加
RUN apt-get update && apt-get install -y \
    your-package-here \
    && apt-get clean
```

### ビルド後にイメージを再ビルド

```bash
docker-compose build --no-cache
```

## まとめ

### よく使うコマンド

```bash
# フルビルド
./docker-build.sh

# セットアップのみ
./docker-build.sh --setup

# シェル起動
./docker-build.sh --shell

# クリーンアップ
./docker-build.sh --clean

# 特定のイメージをビルド
./docker-build.sh core-image-minimal
```

## 参考リソース

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Yocto Project in Docker](https://wiki.yoctoproject.org/wiki/TipsAndTricks/DockerImageYoctoCaching)
