---
layout: default
title: Setting Up Glacier Vaults
parent: Buckets vs. Vaults
grand_parent: Setup
nav_order: 2
---

**NOTE: The steps here should not be done unless there is a need to create an AWS Glacier API-Only Vault.**

## Create an AWS Glacier API-Only Vault
- While logged in to AWS as the root user, type "**Glacier**" in the main search field, or Under the "**Storage**" section of "**Services**" in the console, select "**S3 Glacier**", then select "**Create Vault**"
- Make sure the "**Region**" is set to the same one where the SNS service was created
- Enter a value for the Vault Name. e.g: "**backup**"
- Since an SNS topic was created before, it needs to be linked to the Glacier vault. So, choose "**Enable notifications and use an existing SNS topic**"
- **NOTE: If you have an SNS linked to an S3 Glacier Deep Archive bucket, then you should create a different SNS topic and link it to the Glacier Vault. This is because changes are made to the SNS Topic that would ONLY send notifications when there are changes made to the S3 Glacier Deep Archive bucket.**
- The Amazon SNS Topic ARN needs to be provided. This is in the confirmation email sent when the SNS topic was created and it usually starts with "**arn:aws:sns:......**"
- Enable the check boxes next to "**Archive Retrieval Job Complete**" and "**Vault Inventory Retrieval Job Complete**" to be notified about these events by email
- Review your setup and confirm the creation of the vault. Other vaults can be created if necessary for different purposes (e.g: vaults named "photos", "music", etc..)

### Add Access Policy to the AWS Glacier Vault
- The following grants the "**backup**" user upload and read privileges on the "**backup**" vault
	- Navigate back to the "**S3 Glacier**" service
	- Click the name of the vault created earlier. This should display more information about the vault in a few tabs. Select the "**Vault policies**" tab
	- Select "**Edit vault access policy**" button and paste the following json definition in the provided text area
	- Keep the "**Version**" value as "**2012-10-17**". This is a schema definition version.
	- Grab and Edit the following values below:  
	`"AWS": "arn:aws:iam::XXXXXXXXXXXX:user/backup"`  -  This is the User ARN of the "**backup**" user. Found by going to **IAM**, then selecting "**Users" -- "backup**"   
	`"Resource": "arn:aws:glacier:eu-west-1:XXXXXXXXXXXX:vaults/backup"`  - This is the ARN of the "**backup**" vault. This should be displayed and can be copied from the line just above line number 1 in the text area. This is also found by going to "**S3 Glacier**", then selecting "**backup**". The ARN is displayed in the "**Details**" area
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::XXXXXXXXXXXX:user/backup"
            },
            "Action": [
                "glacier:ListVaults",
                "glacier:InitiateJob",
                "glacier:GetJobOutput",
                "glacier:DescribeJob",
                "glacier:InitiateMultipartUpload",
                "glacier:ListParts",
                "glacier:UploadArchive",
                "glacier:UploadMultipartPart",
                "glacier:AbortMultipartUpload",
                "glacier:CompleteMultipartUpload"
            ],
            "Resource": "arn:aws:glacier:us-XXXX-X:XXXXXXXXXXXX:vaults/backup"
        }
    ]
}
```
	
	
- Click "**Save**"
