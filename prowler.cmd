Prowler is a tool for AWS Security & Compliance Assessment
----------------------------------------------------------
pip install prowler
prowler --version
prowler aws
prowler aws -M html,json -o output/
prowler aws -c check_mfa_enabled,check_iam_password_policy


--------------------------
C:\Users\Administrateur>prowler aws
                         _
 _ __  _ __ _____      _| | ___ _ __
| '_ \| '__/ _ \ \ /\ / / |/ _ \ '__|
| |_) | | | (_) \ V  V /| |  __/ |
| .__/|_|  \___/ \_/\_/ |_|\___|_|v3.11.3
|_| the handy cloud security tool

Date: 2025-10-23 10:23:47


This report is being generated using credentials below:

AWS-CLI Profile: [default] AWS Filter Region: [all]
AWS Account: [11111111111111] UserId: [XXXXXXXXXXXXXXXXX]
Caller Identity ARN: [arn:aws:iam::11111111111111:user/testuser]

Executing 301 checks, please wait...

-> Scanning cloudwatch service |▉▉▉▉▉▉▉▏                                | \ 54/301 [18%] in 4:36

  
