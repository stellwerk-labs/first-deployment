moved {
  from = aws_iam_role.humanitec_runner
  to   = aws_iam_role.platform_orchestrator_runner
}

moved {
  from = aws_iam_role_policy.humanitec_runner
  to   = aws_iam_role_policy.platform_orchestrator_runner
}

moved {
  from = aws_iam_policy.humanitec_runner_user
  to   = aws_iam_policy.platform_orchestrator_runner_user
}
