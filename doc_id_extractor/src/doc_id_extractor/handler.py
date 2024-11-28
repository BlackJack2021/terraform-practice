import boto3
import json
from datetime import datetime, timedelta
import os

def lambda_handler(event, context):
    """
    S3 から昨日の JSONファイルを取得し、docIDリストを生成
    """
    
    # ファイル名を特定
    yesterday = (datetime.utcnow() - timedelta(days=1)).strftime('%Y-%m-%d')
    bucket_name = os.getenv("BUCKET_NAME", "default-bucket-name")
    prefix = os.getenv("PREFIX", "default-prefix")
    object_key = f"{prefix}/{yesterday}.json"
    
    s3_client = boto3.client('s3')
    
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        doc_infos = json.loads(
            response["Body"].read().decode('utf-8')
        )
        doc_ids = [doc_info["docID"] for doc_info in doc_infos if doc_info.get("docID")]
        return {"doc_ids": doc_ids}
    
    except Exception:
        raise
    