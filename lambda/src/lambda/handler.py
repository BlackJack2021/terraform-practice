def lambda_handler(event, context):
    """引数で渡された input_string を出力するだけの関数"""
    input_string = event.get("input_string")
    if not input_string:
        return {"error": "No input_string provided"}
    
    result = f"Processed: {input_string}"
    return {"input": input_string, "result": result}