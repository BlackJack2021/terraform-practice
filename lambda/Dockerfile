
# マルチステージビルド1: 依存関係のインストールまで
FROM public.ecr.aws/lambda/python:3.12 as builder

COPY requirements.lock ${LAMBDA_TASK_ROOT}

# requirements.lock から不要な行を削除し、 requirements.txtを作成
RUN sed '/-e/d' ${LAMBDA_TASK_ROOT}/requirements.lock \
    > ${LAMBDA_TASK_ROOT}/requirements.txt

# 依存関係のインストール
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt


# マルチステージビルド2: 必要最小限のイメージを構築
FROM public.ecr.aws/lambda/python:3.12

# builderステージからインストールされたパッケージをコピー
COPY --from=builder \
    /var/lang/lib/python3.12/site-packages \
    /var/lang/lib/python3.12/site-packages

COPY src/lambda ${LAMBDA_TASK_ROOT}/
CMD ["handler.lambda_handler"]