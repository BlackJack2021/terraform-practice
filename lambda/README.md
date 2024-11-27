# lambda-practice

本プロジェクトは練習用です。ただし、要件を要約すると以下です。

## 1. 開発環境

Rye を使って仮想環境の構築を行います。

## 2. 本番用環境

Lambda で実行するための Python コンテナを用いて構築します。
依存関係はローカルで作成された requirements.lock ファイルを用いて`pip` を用いてインストールします。

## 3. デプロイ

Terraform を用いて IaC による Lambda 関数の定義を行います。ただし、利用するコンテナについてはあらかじめ ECR にプッシュしておく必要があります。具体的なデプロイの手順は以下です。

### 1. Terraform で ECR の構築、及びリポジトリ URL の取得

### 2. Docker イメージのビルド及びプッシュ

具体的な手順は以下です。

1. ECR にログインする

```
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <取得されたリポジトリURL>
```

元々の認証トークンの有効期限が切れている場合はこのコードだけだとだめな場合がある。明示的にログアウトしてから上記のコードを実施することを推奨。

```
docker logout public.ecr.aws
```

2. イメージをビルドする。

ここでは、 practice-docker-lambda というコンテナ名であると仮定します

```
docker build -t practice-docker-lambda .
```

3. ビルドされたイメージにタグ付けを実施

```
docker tag practice-docker-lambda:latest <取得されたリポジトリURL>:latest
```

4. イメージをプッシュ

```
docker push <取得されたリポジトリURL>:latest
```

### 3. Terraform で Lambda 関数の定義を実施
