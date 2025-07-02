#terraform code to point python source code zip code
data "archive_file" "python_source" {
    type        = "zip"
    source_dir = "${path.module}/py/code"
    output_path = "${path.module}/.terraform/py/src.zip"
    }

#basic role for lambda function

resource "aws_iam_role" "lambda_role" {
  name = "lambda_basic_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#attach to basic lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#aws lambda function
#add layer version to lambda function
resource "aws_lambda_function" "message_lambda" {
  function_name = "message_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"
  runtime       = "python3.9"
  filename      = data.archive_file.python_source.output_path
  source_code_hash = data.archive_file.python_source.output_base64sha256
  #layered version for python dependencies
  #this will be used to install python dependencies
  layers        = [aws_lambda_layer_version.python_layer.arn]

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.messages.id
    }
  }

  tags = {
    Name        = "Message Lambda Function"
    Environment = "Production"
  }
}

#layer version for python dependencies

resource "aws_lambda_layer_version" "python_layer" {
  layer_name  = "python_dependencies-py-message-lambda-layer"
  compatible_runtimes = ["python3.9"]
  filename    = data.archive_file.layer_archive.output_path
  source_code_hash = data.archive_file.layer_archive.output_base64sha256
}
#to make archive from pip install
#this will create a zip file of the python dependencies
#deployment of this layer_archive should happen everytime this laye.zip changes
data "archive_file" "layer_archive" {
  type        = "zip"
  source_dir  = "${path.module}/py/layer"
  output_path = "${path.module}/.terraform/layer.zip"
  depends_on = [ null_resource.pip_install ]
}

#null resource to trigger if there is change in requirements.txt file
#everytime there is a change in requirements.txt, it will trigger pip_install
resource "null_resource" "pip_install" {
  triggers = {
    requirements_hash = filebase64sha256("${path.module}/py/requirements.txt")
  }

  depends_on = [
    aws_lambda_function.message_lambda
  ]
  #${path.module}/py/layer/python this is the path where pip will install the dependencies
  provisioner "local-exec" {
    command = "pip install -r ${path.module}/py/requirements.txt -t ${path.module}/py/layer/python"
  }
}