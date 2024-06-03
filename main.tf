provider "aws" {
  region = "ap-south-1"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM Policy for S3 Access
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    }
  ]
}
EOF
}

# Lambda Function
resource "aws_lambda_function" "list_buckets_terraform" {
  filename      = "C:\\Users\\SHIVAMBEMBEY\\Desktop\\awsLambda_terraform\\lambda_function_payload.zip"  # Path to your Lambda function code
  function_name = "list-buckets-lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "list_buckets_api" {
  name = "list-buckets-api"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "list_buckets_resource" {
  rest_api_id = aws_api_gateway_rest_api.list_buckets_api.id
  parent_id   = aws_api_gateway_rest_api.list_buckets_api.root_resource_id
  path_part   = "list-buckets"
}

# API Gateway Method
resource "aws_api_gateway_method" "list_buckets_method" {
  rest_api_id   = aws_api_gateway_rest_api.list_buckets_api.id
  resource_id   = aws_api_gateway_resource.list_buckets_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration with Lambda
resource "aws_api_gateway_integration" "list_buckets_integration" {
  rest_api_id             = aws_api_gateway_rest_api.list_buckets_api.id
  resource_id             = aws_api_gateway_resource.list_buckets_resource.id
  http_method             = aws_api_gateway_method.list_buckets_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:ap-south-1:lambda:path/2015-03-31/functions/${aws_lambda_function.list_buckets_terraform.arn}/invocations"
}

# Lambda Permission to allow API Gateway invocation
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_buckets_terraform.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.list_buckets_api.execution_arn}/*/*"
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "list_buckets_deployment" {
  depends_on = [aws_api_gateway_integration.list_buckets_integration]
  rest_api_id = aws_api_gateway_rest_api.list_buckets_api.id
  stage_name  = "prod"
}