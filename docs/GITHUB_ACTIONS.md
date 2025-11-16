# GitHub Actions によるビルド自動化

GitHub Actionsを使ってYoctoイメージを自動ビルドし、リリースに添付する方法

## 概要

このプロジェクトには、GitHub Actionsでビルドを自動化するワークフローが含まれています。

### 自動化される処理

1. Yocto環境のセットアップ
2. 依存パッケージのインストール
3. イメージのビルド
4. ビルド成果物のアップロード
5. リリースへの自動添付（タグプッシュ時）

### ビルド時間

- **初回ビルド**: 3〜6時間
- **キャッシュ利用時**: 1〜3時間
- **タイムアウト**: 6時間（GitHub Actions最大値）

## ワークフローのトリガー

### 1. タグプッシュ時（自動リリース）

```bash
# タグを作成してプッシュ
git tag v1.0.0
git push origin v1.0.0

# または、タグ作成とプッシュを同時に
git tag v1.0.1 -m "Release version 1.0.1"
git push origin v1.0.1
```

タグは `v` で始まる必要があります（例: `v1.0.0`, `v2.1.0`, `v1.0.0-beta`）

### 2. 手動実行

GitHub のウェブUIから手動で実行できます：

1. リポジトリページに移動
2. **Actions** タブをクリック
3. **Build Yocto Image for Raspberry Pi Zero** を選択
4. **Run workflow** をクリック
5. ブランチとビルドするイメージを選択
6. **Run workflow** を実行

手動実行時に選択できるイメージ：
- `rpi-zero-custom-image`（デフォルト）
- `core-image-minimal`

## ビルドプロセスの詳細

### 1. 環境準備

```yaml
- ディスク容量の確保（不要ファイルの削除）
- Yocto必須パッケージのインストール
- Git設定
```

### 2. キャッシュの利用

ビルド時間を短縮するため、以下をキャッシュします：

- **downloads/** - ソースコードのダウンロードキャッシュ（約2〜5GB）
- **sstate-cache/** - ビルドステートキャッシュ（約5〜15GB）

キャッシュは自動的に保存・復元されます。

### 3. ビルド最適化

CI環境でのビルドを最適化するため、以下の設定が自動適用されます：

```bash
# ディスク容量節約
INHERIT += "rm_work"

# CPUコア数に応じた並列ビルド
BB_NUMBER_THREADS = "自動検出"
PARALLEL_MAKE = "自動検出"

# イメージフォーマット
IMAGE_FSTYPES = "wic wic.gz"
```

### 4. 成果物の生成

ビルド完了後、以下のファイルが生成されます：

- `*.wic` - SDカード書き込み用イメージ
- `*.wic.gz` - 圧縮イメージ（ダウンロード用）
- `*.manifest` - インストールされたパッケージ一覧
- `build-info.txt` - ビルド情報

## リリースの作成

### タグプッシュによる自動リリース

タグをプッシュすると、自動的にGitHub Releaseが作成されます：

```bash
# 例: v1.0.0 リリースを作成
git tag v1.0.0 -m "Initial release with nginx web server"
git push origin v1.0.0
```

リリースには以下が含まれます：

- ビルドされたイメージファイル（.wic, .wic.gz）
- パッケージマニフェスト
- ビルド情報
- インストール手順

### リリースの確認

1. リポジトリの **Releases** タブを開く
2. 最新のリリースを確認
3. **Assets** からイメージファイルをダウンロード

## ビルドステータスの確認

### GitHub Actionsページ

1. リポジトリの **Actions** タブを開く
2. 実行中/完了したワークフローを確認
3. ワークフローをクリックして詳細を表示

### ビルドログの確認

1. ワークフロー実行ページを開く
2. **build** ジョブをクリック
3. 各ステップのログを展開して確認

### ビルド失敗時

ビルドが失敗した場合：

1. エラーログを確認
2. ディスク容量不足が原因の場合が多い
3. ワークフローを再実行（Re-run jobsボタン）

## アーティファクトのダウンロード

手動実行またはタグなしビルドの場合、アーティファクトから取得：

1. ワークフロー実行ページを開く
2. **Artifacts** セクションにスクロール
3. `yocto-raspberrypi0-image` をダウンロード（30日間保存）

## ワークフローのカスタマイズ

### タイムアウトの変更

デフォルト: 360分（6時間）

```yaml
# .github/workflows/build-image.yml
jobs:
  build:
    timeout-minutes: 360  # 変更可能（最大360分）
```

### ビルドするイメージの変更

```yaml
# .github/workflows/build-image.yml
- name: Build Yocto image
  run: |
    IMAGE_NAME="${{ github.event.inputs.image_name || 'rpi-zero-custom-image' }}"
    # ここでデフォルトイメージを変更可能
```

### キャッシュの無効化

キャッシュを無効にする場合（クリーンビルド）：

1. `.github/workflows/build-image.yml` を編集
2. `actions/cache@v4` ステップをコメントアウト
3. コミット＆プッシュ

## トラブルシューティング

### ディスク容量不足エラー

```
ERROR: No space left on device
```

**対処法**:
- ワークフローは自動的に不要ファイルを削除済み
- `INHERIT += "rm_work"` が有効化されているか確認
- イメージサイズを小さくする（不要なパッケージを削除）

### タイムアウトエラー

```
Error: The operation was canceled.
```

**対処法**:
- キャッシュが正しく機能しているか確認
- 並列ビルド数を増やす（自動設定されているはず）
- ビルドするパッケージを減らす

### キャッシュが効かない

**対処法**:
- `setup.sh` ファイルが変更されていないか確認
- キャッシュキーが適切か確認
- 手動でキャッシュをクリア（Settings → Actions → Caches）

### ビルドが途中で止まる

**対処法**:
- ログで最後のステップを確認
- ネットワークエラーの可能性（自動リトライされる）
- ワークフローを再実行

## ベストプラクティス

### 1. タグの命名規則

セマンティックバージョニングを推奨：

```
v1.0.0   - メジャーリリース
v1.1.0   - マイナーリリース
v1.1.1   - パッチリリース
v2.0.0-beta.1  - プレリリース
```

### 2. リリースノートの記載

タグ作成時にメッセージを含める：

```bash
git tag v1.0.0 -m "
Release v1.0.0

- Added nginx web server
- Optimized for minimal footprint
- Added opkg package manager
"
git push origin v1.0.0
```

### 3. テストビルド

リリース前に手動実行でテスト：

1. GitHub Actionsページで手動実行
2. ビルド成功を確認
3. アーティファクトをダウンロードしてテスト
4. 問題なければタグをプッシュ

### 4. ディスク容量の監視

ワークフローにはディスク使用量の監視が含まれています：

```yaml
- name: Check build artifacts
  run: |
    df -h  # ビルド後のディスク使用量を表示
```

## コスト管理

### GitHub Actions 無料枠

- **パブリックリポジトリ**: 無制限
- **プライベートリポジトリ**: 月2,000分まで無料

### ビルド時間の目安

- 初回ビルド: 約4時間 = 240分
- 2回目以降（キャッシュ利用）: 約1.5時間 = 90分

### コスト削減のヒント

1. 不要なビルドを避ける（タグは慎重に）
2. キャッシュを有効活用
3. 開発中はローカルまたはDockerでビルド
4. リリース時のみGitHub Actionsを使用

## セキュリティ

### シークレットの管理

イメージに含めるべきでない情報：

- パスワード
- APIキー
- 証明書

これらはGitHub Secretsを使用：

```yaml
# .github/workflows/build-image.yml
env:
  API_KEY: ${{ secrets.MY_API_KEY }}
```

Settings → Secrets and variables → Actions から設定

## まとめ

### よく使う操作

```bash
# リリースビルド（自動）
git tag v1.0.0
git push origin v1.0.0

# テストビルド（手動）
# GitHub Actions UI から実行

# リリースの確認
# Releases タブから確認・ダウンロード
```

## 参考リソース

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Caching Dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
