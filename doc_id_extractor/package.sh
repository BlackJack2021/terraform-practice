# エラーが発生した場合、スクリプトの実行を即座に停止することを指示
set -e

# BASH_SOURCE[0] でこのファイルのパスを取得
# dirname でそのファイルのディレクトリを取得
# cd で移動して、パスを pwd で取得
# この処理により、まずはスクリプトのある場所を特定するし、定義
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$SCRIPT_DIR

# その他のディレクトリ場所を定義
BUILD_DIR="$PROJECT_ROOT/build"
SRC_DIR="$PROJECT_ROOT/src/doc_id_extractor"
ZIP_FILE="$PROJECT_ROOT/doc_id_extractor.zip"

# 現在のビルドディレクトリとzipファイルを削除
rm -rf "$BUILD_DIR" "$ZIP_FILE"
mkdir -p "$BUILD_DIR"

# 依存ライブラリを BUILD_DIRにインストール
cd "$PROJECT_ROOT"
rye run pip install --target "$BUILD_DIR" -r requirements.lock

# ソースコードを BUILD_DIR にコピー
cp -r "$SRC_DIR" "$BUILD_DIR/"

# ZIPファイルを作成
cd "$BUILD_DIR"
zip -r9 "$ZIP_FILE" .

echo "Lambda package created: $ZIP_FILE"
