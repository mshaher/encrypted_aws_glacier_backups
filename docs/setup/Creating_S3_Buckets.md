---
layout: default
title: Setting Up AWS S3 Buckets
parent: Buckets vs. Vaults
grand_parent: Setup
nav_order: 1
---

## Create an AWS S3 Glacier Bucket
- While logged in to AWS as the root user, type "**S3**" in the main search field, or Under the "**Storage**" section of "**Services**" in the console, select "**S3**"
- Click the “**Create Bucket**” option
- Enter a name for the Bucket
- Make sure to set the "**Region**" to same one where the SNS service was created
- Leave the Object Ownership at the default “**ACLs disabled (recommended)**” option
- Make sure the option to “**Block all public access**” is selected
- Disable **Bucket Versioning**
- Disable **Server-side encryption** . The provided scripts will encrypt the data before uploading it
- Disable “**Object Lock**” under “**Advanced settings**”, and then click the “**Create Bucket**” button.
- Once the bucket is created, in the S3 main menu, select the radio button next to the bucket that was just created and choose the “**copy ARN**” option.
- Paste the value to a temporary file on your local machine. This value would be something like `arn:aws:s3:::BUCKET-NAME`
- Get the ARN of the backup user. This should have been noted down when the account was created in an earlier step
- Go back to the S3 main menu and click the name of the newly created bucket
- Select the “**Permissions**” tab for the bucket and click the “**Edit**” button in the “**Bucket policy**” section
- The Bucket ARN is listed at the top, followed by a section where a JSON policy statement can be edited.
- Copy and paste the following text to assign permissions to the "**backup**" user on the bucket. This allows the "**backup**" user to query, upload and restore/download the bucket objects.

```json
{
    "Version": "2012-10-17",
    "Id": "Policy1646895724505",
    "Statement": [
        {
            "Sid": "AllowObjectManagementExceptDeletions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID_GOES_HERE:user/backup"
            },
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:RestoreObject",
                "s3:GetObjectAcl",
                "s3:GetObjectAttributes",
                "s3:PutObjectAcl"
            ],
            "Resource": "YOUR_S3_BUCKET_ARN_VALUE_GOES_HERE/*"
        },
        {
            "Sid": "AllowRootLevelListingOfBucket",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID_GOES_HERE:user/backup"
            },
            "Action": "s3:ListBucket",
            "Resource": "YOUR_S3_BUCKET_ARN_VALUE_GOES_HERE"
        }
    ]
}

```

- Replace `YOUR_AWS_ACCOUNT_ID_GOES_HERE`, `YOUR_AWS_ACCOUNT_ID_GOES_HERE`, and `YOUR_S3_BUCKET_ARN_VALUE_GOES_HERE` above with your correct AWS values

## Link the SNS Topic to the S3 Bucket
- The S3 Bucket has to be given permissions first to access the SNS Topic that was created in a previous step.
- Make sure to have two different browser tabs or windows with both displaying the AWS web console
- In the first AWS browser tab/window, Type "**SNS**" in the AWS main search field and select "**Simple Notification Service**" from the results
- The SNS Dashboard menu should be displayed. Click either the number below "**Topics**" or, if the left navigation menu is expanded, click on "**Topics**"
- Click the name of the Topic that was created in a previous step
- Click the "**Edit**" button at the top of the topic screen to present the "**Edit YOUR_TOPIC_NAME**" screen
- Scroll down and expand the "**Access Policy -** ***optional***" section
- Towards the bottom of the JSON editor, there should be something like the following:

```json
        "SNS:Publish"
      ],
      "Resource": "arn:aws:sns:YOUR_REGION:YOUR_AWS_ACCOUNT_NUMBER:YOUR_TOPIC_NAME",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "YOUR_AWS_ACCOUNT_NUMBER"
        }
      }
    }
  ]
}
```

- First, change `SourceOwner` in  the line that reads
```json
          "AWS:SourceOwner": "YOUR_AWS_ACCOUNT_NUMBER"
```
to `SourceAccount` so that line is instead
```json
          "AWS:SourceAccount": "YOUR_AWS_ACCOUNT_NUMBER"
```


- Next, edit the line immediately below it with the closing curly brace so that it reads like the following (**Don't forget the comma after the first closing curly brace**):
```json
        }, "ArnLike": { "AWS:SourceArn": "YOUR_S3_BUCKET_ARN"}
```
- the last part in the JSON editor should now read something like the following. Again, don't forget the comma before `"ArnLike"`
```json
        "SNS:Publish"
      ],
      "Resource": "arn:aws:sns:YOUR_REGION:YOUR_AWS_ACCOUNT_NUMBER:YOUR_TOPIC_NAME",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "YOUR_AWS_ACCOUNT_NUMBER"
        }, "ArnLike": { "AWS:SourceArn": "YOUR_S3_BUCKET_ARN" }
      }
    }
  ]
}
```
- In the 2nd browser tab/window, type **S3** in the AWS main search field, and select "**S3**" from the results.
- In the Buckets page, click the S3 bucket created in the previous step and then select the "**Properties**" tab .
- Under the "**Bucket Overview**" section, locate the Amazon Resource Name (ARN) of the bucket and copy its value
- Paste the value to replace `YOUR_S3_BUCKET_ARN` in the browser window/tab displaying the SNS JSON Editor, so the full line reads something like
```
        }, "ArnLike": { "AWS:SourceArn": "arn:aws:s3:::your_bucket_name"}
```
- Save the changes to the SNS Topic Access Policy
- On the browser window/tab with the S3 bucket information, and while still in the "**Properties**" tab, scroll down to the "**Event notifications**" section
- Choose the "**Create Event notifications**" option
- Enter a value for "**Event name**" e.g: *YOUR_BUCKET_NAME*-Events
- Under the "**Event types**" section, enable the "**Restore completed**" option. The "Restore initiated", "Restored object expired", or the "All restore object events" can be enabled if you want to be notified about other restore events
- Under the "**Destination**" section, select the "**SNS topic**" and then the "**Choose from your SNS topics**" options
- Select the name of the SNS topic when you created the SNS service from the drop-down menu
- Save your changes
- If you run into any or all of the following error messages when tyring to save these settings, make sure to go back and verify that there are no typos or errors in the SNS Topic Access Policy
```
An unexpected error occurred.
API response
Unable to validate the following destination configurations
```
- A test message from the SNS Topic will be sent to the email address configured as the subscriber after the changes to the S3 Bucket are saved successfully
