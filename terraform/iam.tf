data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
  }
}

# Grant the GitHub Actions deploy role permission to create the AgentCore
# service linked role (required by CreateAgentRuntime on first use).
resource "aws_iam_role_policy" "github_actions_slr" {
  name = "allow-create-agentcore-slr"
  role = "github-actions-agentcore"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iam:CreateServiceLinkedRole"
      Resource = "arn:aws:iam::*:role/aws-service-role/bedrock-agentcore.amazonaws.com/*"
    }]
  })
}

resource "aws_iam_role" "agentcore_execution" {
  name               = "agentcore-hello-world-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "agentcore_execution" {
  role = aws_iam_role.agentcore_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = "arn:aws:bedrock:*::foundation-model/anthropic.claude*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::bedrock-agentcore-code-*/*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.region}:*:log-group:/aws/bedrock/agentcore/*"
      }
    ]
  })
}
