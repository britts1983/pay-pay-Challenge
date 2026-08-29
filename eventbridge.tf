resource "aws_cloudwatch_event_rule" "start" {
  count    = var.enable_schedules ? 1 : 0
  provider = aws.management

  name                = "EnvControl-Start"
  description         = "Optional schedule to start EnvControl=True EC2 instances."
  schedule_expression = var.start_schedule_expression

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "start" {
  count    = var.enable_schedules ? 1 : 0
  provider = aws.management

  rule      = aws_cloudwatch_event_rule.start[0].name
  target_id = "EnvControlLambdaStart"
  arn       = aws_lambda_function.env_control.arn

  input = jsonencode({
    action = "start"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  count    = var.enable_schedules ? 1 : 0
  provider = aws.management

  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.env_control.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start[0].arn
}

resource "aws_cloudwatch_event_rule" "stop" {
  count    = var.enable_schedules ? 1 : 0
  provider = aws.management

  name                = "EnvControl-Stop"
  description         = "Optional schedule to stop EnvControl=True EC2 instances."
  schedule_expression = var.stop_schedule_expression

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "stop" {
  count    = var.enable_schedules ? 1 : 0
  provider = aws.management

  rule      = aws_cloudwatch_event_rule.stop[0].name
  target_id = "EnvControlLambdaStop"
  arn       = aws_lambda_function.env_control.arn

  input = jsonencode({
    action = "stop"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  count    = var.enable_schedules ? 1 : 0
  provider = aws.management

  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.env_control.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop[0].arn
}
