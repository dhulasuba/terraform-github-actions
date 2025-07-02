
#create api gateway v2
resource "aws_apigatewayv2_api" "messages_api" {
    name          = "message-api"
    protocol_type = "HTTP"
    
    tags = {
        Name        = "Message API Gateway"
        Environment = "Development"
    }
  
}
#create Development stage for api gateway
resource "aws_apigatewayv2_stage" "dev_stage" {
    api_id = aws_apigatewayv2_api.messages_api.id
    name   = "dev"
    
    auto_deploy = true
  
    tags = {
        Name        = "Development Stage"
        Environment = "Development"
    }
  
}


