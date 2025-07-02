
#terraform code to integrate lambda with api gateway
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.messages_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.message_lambda.invoke_arn
  integration_method = "POST"

  timeout_milliseconds = 29000

  depends_on = [aws_lambda_function.message_lambda]
}
#get route
resource "aws_apigatewayv2_route" "get_route" {
  api_id    = aws_apigatewayv2_api.messages_api
  route_key = "GET /messages"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  depends_on = [aws_apigatewayv2_integration.lambda_integration]
}
#post route
resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.messages_api
  route_key = "POST /messages"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  depends_on = [aws_apigatewayv2_integration.lambda_integration]
}

#persmission for api gateway to invoke lambda function
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.message_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN is the API Gateway's ARN
  source_arn = "${aws_apigatewayv2_api.messages_api.execution_arn}/*/*"

  depends_on = [aws_apigatewayv2_route.get_route, aws_apigatewayv2_route.post_route]
}

#output the API endpoint
output "api_endpoint" {
  value = "${aws_apigatewayv2_api.messages_api.api_endpoint}/dev/messages"
#   value = aws_apigatewayv2_stage.dev_stage.invoke_url
  description = "The endpoint for the API Gateway to access the Lambda function"
}