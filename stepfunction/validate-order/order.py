def lambda_handler(event, context):
    required = ["orderId", "customerEmail", "amount"]
    missing = [field for field in required if field not in event]

    is_valid = not missing and event["amount"] > 0

    return {
        "isValid": is_valid,
        "reason": None if is_valid else f"Missing/invalid fields: {missing}"
    }