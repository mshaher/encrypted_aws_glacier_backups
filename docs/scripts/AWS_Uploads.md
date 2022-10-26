---
layout: default
title: AWS Upload Scripts
parent: The Scripts
nav_order: 2
has_children: true
---

## Overview
- There are two distinct upload_to_AWS.sh scripts that both perform two main functions:
	- As their names indicate, upload the encrypted archives to an AWS S3 Glacier Deep Archive Bucket (upload_to_aws_bucket.sh) or to an AWS Glacier API-Only Vault (upload_to_aws_vault.sh)
	- Generate a local metadata file to keep track of uploaded content
	- [Follow this documentation](upload_to_aws_bucket.md) if you created an AWS S3 Bucket to be used with AWS S3 Glacier Deep Archive (Recommended)
	- [Follow this documentation](upload_to_aws_vault.md) if you decided to go with and created an AWS Glacier API-Only Vault

