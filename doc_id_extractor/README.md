# doc-id-extractor

## 機能

s3 にアクセスして、前日の処理で取得されたドキュメントの一覧 (`doc_ids`) を取得します。

## デプロイの方法

ルートディレクトリの main.tf により terraform によるデプロイを行いますが、デプロイ前においては予めこのプロジェクトを zip 化しておく必要があります。

`package.sh` に Zip 化の処理が全て実行されていますので、`./package.sh` などのコマンドをターミナルに打ち込み、実行してください。
