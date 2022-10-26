---
layout: default
title: MISC
nav_order: 5
has_children: false
---

## Max File Size Uploads
- A single object in AWS Glacier can be a few terabytes in size. However, the size of an object that can be uploaded **in a single upload/PUT operation** is restricted to a maximum of 5 GB (4 GB with AWS Glacier API-Only)
- The upload scripts available in this repo also enforce this max upload size limitation
- To upload larger objects, there are at least a couple of ways to do it

### Use Multipart Upload
- This process involves initiating a multipart upload operation, uploading the large file in multiple parts, and then the multiple parts get assembled on AWS as one object
- The upload scripts in this repo do not perform multipart uploads to AWS and therefore the user would have to do them manually
- Multipart Uploads to S3 Buckets, including AWS S3 Glacier Deep Archive, is documented [here](https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html)
- Mutlipart Uploads to AWS Glacier API-Only Vaults is documented [here](https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html)


### Splittig the Object into Smaller Parts
- A big file can be split into smaller pieces with the built-in Linux/Unix command `split`
- The smaller pieces can later be assembled into the original file with `cat`
- The scripts in this repo can be used to encrypt the smaller pieces and upload them to AWS following the instructions in previous sections
- Alternatively, the big file can be encrypted with `encrypt_and_save.sh` first. Split into smaller pieces with `split` which are then uploaded *manually* to AWS
