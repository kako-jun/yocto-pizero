# パッケージ管理ガイド

Yocto OS起動後のパッケージ管理方法

## パッケージマネージャー: opkg

Yocto Projectでは、デフォルトで **opkg** という軽量なパッケージマネージャーを使用します。
これは組み込みLinux向けに最適化されており、aptやyumと同様の機能を提供します。

### 前提条件

イメージに `package-management` 機能が含まれている必要があります：

```bitbake
# イメージレシピに以下が含まれていること
IMAGE_FEATURES += "package-management"
```

このプロジェクトの `rpi-zero-custom-image.bb` には既に含まれています。

## 基本的な使い方

### 1. パッケージリストの更新

```bash
# パッケージリストを更新（初回必須）
opkg update
```

### 2. パッケージの検索

```bash
# パッケージを検索
opkg list | grep <パッケージ名>

# 例: gitを検索
opkg list | grep git

# インストール可能な全パッケージを表示
opkg list
```

### 3. パッケージのインストール

```bash
# パッケージをインストール
opkg install <パッケージ名>

# 例: gitをインストール
opkg install git

# 複数のパッケージを同時にインストール
opkg install curl wget vim
```

### 4. パッケージの削除

```bash
# パッケージを削除
opkg remove <パッケージ名>

# 例: vimを削除
opkg remove vim
```

### 5. インストール済みパッケージの確認

```bash
# インストール済みパッケージ一覧
opkg list-installed

# 特定のパッケージがインストールされているか確認
opkg list-installed | grep <パッケージ名>
```

### 6. パッケージ情報の表示

```bash
# パッケージの詳細情報を表示
opkg info <パッケージ名>

# 例: nginxの情報を表示
opkg info nginx
```

## 実用例

### Webサーバー関連

```bash
# PHP のインストール
opkg update
opkg install php php-cli php-fpm

# 静的サイトジェネレーターツール
opkg install python3 python3-pip
pip3 install pelican
```

### 開発ツール

```bash
# Git とエディタ
opkg install git vim nano

# コンパイラ（必要な場合）
opkg install gcc g++ make
```

### ネットワークツール

```bash
# ネットワーク診断ツール
opkg install tcpdump nmap curl wget

# HTTPクライアント
opkg install curl wget
```

### データベース

```bash
# SQLite（軽量DB）
opkg install sqlite3

# MariaDB クライアント
opkg install mariadb-client
```

## パッケージフィードの設定

### デフォルトのフィード

opkgは `/etc/opkg/` にある設定ファイルからパッケージフィードのURLを取得します：

```bash
# フィード設定を確認
cat /etc/opkg/opkg.conf
cat /etc/opkg/*.conf
```

### カスタムフィードの追加

独自のパッケージリポジトリを追加する場合：

```bash
# カスタムフィード設定ファイルを作成
echo "src/gz custom-feed http://example.com/packages" > /etc/opkg/custom-feed.conf

# パッケージリストを更新
opkg update
```

## ビルド時のパッケージフィード設定

ビルド時にパッケージフィードを設定するには、`local.conf` に以下を追加：

```bitbake
# パッケージフィードのベースURL
PACKAGE_FEED_URIS = "http://your-server.com/ipk"
PACKAGE_FEED_BASE_PATHS = "rpm deb ipk"
PACKAGE_FEED_ARCHS = "all armv6 raspberrypi0"
```

## Webサーバー上でのパッケージ配信

ビルドしたパッケージをWebサーバーで配信する方法：

### 1. パッケージの場所

ビルド後、パッケージは以下に生成されます：

```bash
build/tmp/deploy/ipk/
├── all/
├── armv6/
└── raspberrypi0/
```

### 2. Webサーバーに配置

```bash
# パッケージをWebサーバーのディレクトリにコピー
rsync -av build/tmp/deploy/ipk/ /var/www/html/packages/

# または、nginxで直接配信
# nginx.conf に以下を追加:
location /packages {
    alias /path/to/build/tmp/deploy/ipk;
    autoindex on;
}
```

### 3. デバイス側でフィード設定

```bash
# Raspberry Pi Zero上で
echo "src/gz local-ipk http://<ビルドマシンIP>/packages/raspberrypi0" > /etc/opkg/local.conf
opkg update
```

## トラブルシューティング

### パッケージが見つからない

```bash
# パッケージリストを更新
opkg update

# フィード設定を確認
cat /etc/opkg/*.conf
```

### ディスク容量不足

```bash
# ディスク使用量を確認
df -h

# 不要なパッケージを削除
opkg remove <不要なパッケージ>

# キャッシュをクリア
rm -rf /var/cache/opkg
```

### 依存関係エラー

```bash
# 依存関係を含めて強制インストール
opkg install --force-depends <パッケージ名>

# ただし、これは推奨されません。依存関係を満たすパッケージを先にインストールしてください
```

### ネットワーク接続エラー

```bash
# ネットワーク接続を確認
ping -c 3 8.8.8.8

# DNSを確認
cat /etc/resolv.conf

# フィードURLに手動でアクセスしてみる
wget http://<フィードURL>/Packages
```

## 代替: ビルド時にパッケージを含める

ランタイムではなく、ビルド時にパッケージを含めたい場合：

```bitbake
# meta-rpi-zero-custom/recipes-core/images/rpi-zero-custom-image.bb
# に以下を追加:

IMAGE_INSTALL:append = " \
    git \
    curl \
    vim \
    "
```

この方法の利点：
- イメージサイズは大きくなるが、起動後すぐに使用可能
- ネットワーク接続不要
- パッケージバージョンがビルド時に固定される

## opkg vs apt

| 機能 | opkg | apt |
|------|------|-----|
| サイズ | 軽量（100KB程度） | 大きい（数MB） |
| 速度 | 高速 | やや遅い |
| 依存解決 | 基本的 | 高度 |
| 組み込み向け | ◎ | △ |
| パッケージ数 | Yoctoビルド分のみ | Debian全体 |

Yoctoでは **opkg** の使用が推奨されます。

## まとめ

### よく使うコマンド一覧

```bash
# パッケージリスト更新
opkg update

# パッケージ検索
opkg list | grep <名前>

# インストール
opkg install <パッケージ名>

# 削除
opkg remove <パッケージ名>

# インストール済み一覧
opkg list-installed

# パッケージ情報
opkg info <パッケージ名>
```

## 参考リソース

- [opkg Documentation](https://openwrt.org/docs/guide-user/additional-software/opkg)
- [Yocto Project Package Management](https://docs.yoctoproject.org/dev-manual/packages.html)
- [OpenEmbedded Package Feeds](https://www.openembedded.org/)
