output "execution_role_arn" {
  value = aws_iam_role.agentcore_execution.arn
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
