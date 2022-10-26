---
layout: default
title: Uploading to S3 Glacier Deep Archive Bucket
parent: AWS Upload Scripts
grand_parent: The Scripts
nav_order: 1
---

## upload_to_aws_bucket.sh
- Uploads the .tar.gpg encrypted archives in the **ENC_BACKUP_DIR** directory to the the AWS S3 Glacier Deep Archive Bucket defined by the **BUCKET** variable
- The script is run without any command options
- Relies on the following variables to be defined by the user either in the script or in the file defined by the **PERSONAL_CONFIG_FILE** variable  
	- `ENC_BACKUP_DIR`: The local directory where the encrypted archives are saved to. Usually this value would match the value in the encrypt_and_save.sh script  
	- `BUCKET`: The name of the AWS S3 Glacier Deep Archive Bucket   
	- `PREFIX`: OPTIONAL . Behind the scenes, ALL uploads are saved to the root of the AWS S3 Bucket, so there is NO directory hierarchy in S3 buckets.  However, a prefix can be assigned  when uploading data, which will show up as a directory in the Bucket when viewed using the AWS Web Console    
	- `USE_LOCAL_METADATA`: by default set to true. If true, generates a metadata file to keep track of uploaded data. More information about the contents of this metadata is provided in the next section   
	- `METADATA_DIR` and `METADATA_FILE`: the location and name of the metadata file. By default it's `${ENC_BACKUP_DIR}/metadata/details.txt`    
	- `HASH_DESC`: by default set to false. Extra privacy setting if you want the names of the files to be saved as their sha 256 sum in AWS instead of just __filename.tar.gpg__    
	- `PERSONAL_CONFIG_FILE`: All or some of the above variables can be set in a file defined by this variable. By default, it's `${HOME}/.aws/enc_backups.config`    

## Retrieving Files from the S3 Glacier Deep Archive Bucket
- First, I hope that you never "have to" get to this point, since as mentioned earlier, AWS Glacier should be treated as a last resort offsite backup solution
- Before a file can be downloaded from an S3 Glacier Deep Archive Bucket, a request to Initiate Restore for the file has to be issued
- The "Initiate Restore" request starts the process of moving the file temporarirly to an S3 node from which it can be downloaded
- After the "Restore" process completes, the user has the number of days specified in the "Initiate Restore" request to download the file
- One of the following data access tier options can be specified during the "Inititate Restore" process for objects stored in the S3 Glacier Deep Archive storage class:
	- Standard : 
		- This is the default option for retrieval requests that do not specify the retrieval option. 
		- They typically finish within 12 hours for objects stored in the S3 Glacier Deep Archive storage class

	- Bulk : 
		- Bulk retrievals are the lowest-cost retrieval option in S3 Glacier, enabling you to retrieve large amounts, even petabytes, of data inexpensively. 
		- They typically finish within 48 hours for objects stored in the S3 Glacier Deep Archive storage class
- Refer to [this AWS Documentation](https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html) for more information

### Example: Initiating Restore and Downloading an Object Using the AWS CLI
- The following would initiate a restore request of the file `a_sample_file.jpg.tar.gpg`   
  that was saved with the prefix `photos/2018_Colorado_Trip/`  
   to the `my-bucket` bucket   
   using the `Bulk` tier    
   and to have the file be available for download for `2` Days    
```    
aws s3api restore-object --bucket my-bucket --key photos/2018_Colorado_Trip/a_sample_file.jpg.tar.gpg --restore-request '{"Days":2,"GlacierJobParameters":{"Tier":"Bulk"}}'
```
- If the S3 Bucket was setup to subscribe to the SNS Topic as explained in a previous section, then an email similiar to the following will be sent to the user when the restore process is complete. The __key__ value (ie, PREFIX/OBJECT_NAME) should be included in the message
```
{"Records":[{"eventVersion":"2.1","eventSource":"aws:s3","awsRegion":"us-west-2","eventTime":"2022-10-06T17:26:46.768Z","eventName":"ObjectRestore:Completed",
..................."configurationId":"AWS-S3-Bucket-SNS-Events","bucket":{"name":"my-bucket",
................... "object":{"key":"photos/2018_Colorado_Trip/a_sample_file.jpg.tar.gpg",
................... "lifecycleRestoreStorageClass":"DEEP_ARCHIVE"}}}]}
```
- After the restore process is complete, using the AWS CLI, the object can be downloaded using the following syntax (replace MY-BUCKET-NAME, MY_PREFIX/MY_OBJECT and MY_OUTFILE with your values. MY_OUTFILE is what you want to save the file locally as)
```
aws s3api get-object --bucket MY-BUCKET-NAME --key MY_PREFIX/MY_OBJECT MY_LOCAL_OBJECT_NAME
```

- so, using the same sample file above, the command would look like this
```
aws s3api get-object --bucket my-bucket --key photos/2018_Colorado_Trip/a_sample_file.jpg.tar.gpg a_sample_file.jpg.tar.gpg
```

- A successful download should generate a JSON message similar to the followng:
```
{
    "AcceptRanges": "bytes",
    "Restore": "ongoing-request=\"false\", expiry-date=\"Sun, 09 Oct 2022 00:00:00 GMT\"",
    "LastModified": "2022-10-04T23:11:28+00:00",
    "ContentLength": 286,
    "ETag": "\"fe73b155c511fa9a6a9dc5349c76b670\"",
    "ContentType": "binary/octet-stream",
    "Metadata": {},
    "StorageClass": "DEEP_ARCHIVE"
}
```

### Example: Initiating Restore and Downloading an Object Using the AWS Web Console
- Sign in to the [AWS S3 Web console](https://console.aws.amazon.com/s3/)
- Select the bucket that contains the objects that you want to restore
- Select the checkbox next to the object that you want to restore. Choose __Actions__, and then __Initiate restore__
- Enter the number of days that you want your archived data to be accessible in the __Initiate restore__ dialog box
- Choose __Bulk retrieval__ or __Standard retrieval__ for __Retrieval tier__ and then choose __Initiate restore__
- If the S3 Bucket was setup to subscribe to the SNS Topic as explained in a previous section, then an email will be sent to the user when the restore process is complete
- When the restore process is complete, selecting the object where it is located in the bucket and selecting the "Download" option should download it to your local machine

## The Metadata File
- Although this is not required, by default the upload_to_aws_bucket.sh script generates a metadata file as an index that keeps track of uploaded objects
- This feature can be turned off by setting the value of `USE_LOCAL_METADATA` to `false` but I would higly recommend keeping this feature
- The metadata file can be uploaded to somewhere like Google Drive or DropBox for fast retrieval from anywhere and to keep a backup copy. It can be encrypted before uploading it, but that's not necessary
- Each line in the metadata file contains colon-separated fields of the following information
OBJECT::::::DATE:BUCKET:PREFIX:HASH_DESC:SHA256SUM:SHA512SUM:
- Fields Description:
	- Field 1 (OJBECT) - name of the encrypted archive file, without the .tar.gpg extension
	- Fields 2-6 (User Defined) - These are left blank by the script. The user is free to enter any information here. For example, if the object contains photos, these fields can be used to keep information about the who, what, where, when contents of the photos
	- Field 7 (DATE) - The date the object was uploaded to AWS in YYYY-MM-DD format
	- Field 8 (BUCKET): The S3 Glacier Bucket name where the object was uploaded to
	- Field 9 (PREFIX): The path in the bucket where the object was uploaded to
	- Field 10 (HASH_DESC): A true or false value. Indicates whether files are to saved as their sha 256 sum in AWS instead of just __filename.tar.gpg__ . The default is false
	- Field 11 (SHA256SUM): The sha 256 sum of the file name, without the .tar.gpg extension
	- Field 12 (SHA512SUM): The sha 512 sum of the encrypted archive. This is useful in determining if the same object has already been uploaded

- After the file is uploaded, the following entry will be appended to the metadata file
```
a_sample_file.jpg::::::2022-10-04:my-bucket:photos/2018_Colorado_Trip/:false:756d81daf8ead809e3095dcd0460e536565397b953422e513debf537d4e65970:d7717f2c2601a4672e47613af864fcd5ef1abdb5922e1a48bb1ed7ecc215acfbdb1401d28d6c78455fad8d1bc6ee27b881a8c218756c1e47ffd31a98a8a71ca2:
```
- This is an example of the same entry after editing the user defined fields 2-6
```
a_sample_file.jpg:John Doe, Jane Doe, Alex, Bob:Boulder, CO, USA - Denver, CO, USA:01 August 2018 - 05 August 2018:Chautauqua Park, Flatirons, Rocky Mountains, Boulder, Colorado::2022-10-04:my-bucket:photos/2018_Colorado_Trip/:false:756d81daf8ead809e3095dcd0460e536565397b953422e513debf537d4e65970:d7717f2c2601a4672e47613af864fcd5ef1abdb5922e1a48bb1ed7ecc215acfbdb1401d28d6c78455fad8d1bc6ee27b881a8c218756c1e47ffd31a98a8a71ca2:
```

