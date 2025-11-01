--------First create a trail in CloudTrail--------------
aws cloudtrail create-trail \
  --name RootLoginTrail \
  --no-s3-bucket-name \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --is-organization-trail false

aws cloudtrail update-trail \
  --name RootLoginTrail \
  --is-organization-trail false \
  --event-selectors '[{"ReadWriteType":"All","IncludeManagementEvents":true}]'

aws cloudtrail start-logging --name RootLoginTrail
---------------- create Event --------------------
aws events put-rule \
  --name RootSignInEvent \
  --event-bus-name "default" \
  --event-pattern '{
    "detail": {
      "eventSource": ["signin.amazonaws.com"],
      "eventName": ["ConsoleLogin"],
      "userIdentity": {"type": ["Root"]},
      "responseElements": {"ConsoleLogin": ["Success"]}
    }
  }'

  aws events put-targets \
  --rule RootSignInEvent \
  --targets '[
    {
      "Id": "SendEmail",
      "Arn": "arn:aws:sns:eu-west-1:111122223333:RootSignInAlerts"
    }
  ]'

