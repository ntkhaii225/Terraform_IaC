# IAM Role for Lambda
resource "aws_iam_role" "lambda_autostart" {
  name = "${var.project_name}-${var.environment}-lambda-autostart-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda (EC2 and ASG permissions)
resource "aws_iam_policy" "lambda_autostart_policy" {
  name        = "${var.project_name}-${var.environment}-lambda-autostart-policy"
  description = "Permissions for Lambda to start EC2 and ASG"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_autostart_attach" {
  role       = aws_iam_role.lambda_autostart.name
  policy_arn = aws_iam_policy.lambda_autostart_policy.arn
}

# Archive the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "autostart" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-autostart"
  role             = aws_iam_role.lambda_autostart.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 120

  environment {
    variables = {
      BASTION_INSTANCE_ID  = var.bastion_instance_id
      NAT_INSTANCE_ID      = var.nat_instance_id
      FRONTEND_INSTANCE_ID = var.frontend_instance_id
      BACKEND_INSTANCE_ID  = var.backend_instance_id
      SQS_QUEUE_URL        = aws_sqs_queue.autostart_queue.url
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-autostart"
    Environment = var.environment
  }
}

# Allow Function URL (No Auth for simple webhook)
resource "aws_lambda_function_url" "autostart_url" {
  function_name      = aws_lambda_function.autostart.function_name
  authorization_type = "NONE" # Public for GitHub Webhook
}

# --- Auto-Stop Scheduler (12:00 AM Daily VN Time / 17:00 UTC) ---

resource "aws_cloudwatch_event_rule" "daily_stop" {
  name                = "${var.project_name}-${var.environment}-daily-stop"
  description         = "Stops instances every day at 12:00 AM VN time"
  schedule_expression = "cron(0 17 * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_stop.name
  target_id = "TriggerAutoStopLambda"
  arn       = aws_lambda_function.autostart.arn
  input     = jsonencode({ "action" : "STOP" })
}

resource "aws_lambda_permission" "allow_public_url" {
  statement_id           = "AllowFunctionUrlPublic"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.autostart.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autostart.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_stop.arn
}


# --- SQS Infrastructure ---

resource "aws_sqs_queue" "autostart_dlq" {
  name                      = "${var.project_name}-${var.environment}-autostart-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "autostart_queue" {
  name                       = "${var.project_name}-${var.environment}-autostart-queue"
  visibility_timeout_seconds = 60 # Retry every 1 minute
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.autostart_dlq.arn
    maxReceiveCount     = 10 # Allow ~10 minutes of retries
  })
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.autostart_queue.arn
  function_name    = aws_lambda_function.autostart.arn
  batch_size       = 1
}

# Broader permission for testing (will be refined)
resource "aws_lambda_permission" "allow_public_invoke" {
  statement_id  = "AllowPublicInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autostart.function_name
  principal     = "*"
}
