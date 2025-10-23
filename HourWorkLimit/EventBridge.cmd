--------------- Start at 8 Oclock-------------------
aws scheduler create-schedule \
  --name office-hours-start-detach \
  --schedule-expression "cron(0 8 ? * MON-FRI *)" \
  --schedule-expression-timezone "Europe/Paris" \
  --target "Arn=arn:aws:lambda:<REGION>:<MGMT_ACCOUNT_ID>:function:orgs-office-hours-toggle,RoleArn=arn:aws:iam::<MGMT_ACCOUNT_ID>:role/<EventBridgeInvokeRole>,Input={\"action\":\"detach\"}"


  ----------------Stop at 18:30 ------------------

  aws scheduler create-schedule \
  --name office-hours-end-attach \
  --schedule-expression "cron(30 18 ? * MON-FRI *)" \
  --schedule-expression-timezone "Europe/Paris" \
  --target "Arn=arn:aws:lambda:<REGION>:<MGMT_ACCOUNT_ID>:function:orgs-office-hours-toggle,RoleArn=arn:aws:iam::<MGMT_ACCOUNT_ID>:role/<EventBridgeInvokeRole>,Input={\"action\":\"attach\"}"

  ----------------Policy------------------

  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "InvokeLambda",
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:<REGION>:<MGMT_ACCOUNT_ID>:function:orgs-office-hours-toggle"
    }
  ]
}
