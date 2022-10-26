---
layout: default
title: Uploading to AWS Glacier API-Only Vault
parent: AWS Upload Scripts
grand_parent: The Scripts
nav_order: 2
---

**NOTE: The documentation here should be followed ONLY if you created an AWS Glacier API-Only Vault**

## upload_to_aws_vault.sh
- Uploads the .tar.gpg encrypted archives in the **ENC_BACKUP_DIR** directory to the the AWS Glacier API-Only Vault defined by the **VAULT** variable
- The script is run without any command options
- Relies on the following variables to be defined by the user either in the script or in the file defined by the PERSONAL_CONFIG_FILE variable  
	- `ENC_BACKUP_DIR`: The local directory where the encrypted archives are saved to. Usually this value would match the value in the encrypt_and_save.sh script  
	- `VAULT`: The name of the AWS Glacier API-Only Vault
	- `METADATA_DIR` and `METADATA_FILE`: the location and name of the metadata file. By default it's `${ENC_BACKUP_DIR}/metadata/details.txt`
	- `HASH_DESC`: by default set to false. Extra privacy setting if you want the names of the files to be saved as their sha 256 sum in AWS instead of just __filename.tar.gpg__
	- `PERSONAL_CONFIG_FILE`: All or some of the above variables can be set in a file defined by this variable. By default, it's `${HOME}/.aws/enc_backups.config`

## The Metadata File
- The upload_to_aws_vault.sh script generates a metadata file as an index that keeps track of uploaded objects
- The metadata file can be uploaded to somewhere like Google Drive or DropBox for fast retrieval from anywhere and to keep a backup copy. It can be encrypted before uploading it, but that's not necessary
- Each line in the metadata file contains colon-separated fields of the following information
OBJECT::::::DATE:VAULT:HASH_DESC:SHA256SUM:SHA512SUM:AWSLOCATION:AWSCHECKSUM:AWSARCHIVEID
- Fields Description:
	- Field 1 (OJBECT) - name of the encrypted archive file, without the .tar.gpg extension
	- Fields 2-6 (User Defined) - These are left blank by the script. The user is free to enter any information here. For example, if the object contains photos, these fields can be used to keep information about the who, what, where, when contents of the photos
	- Field 7 (DATE) - The date the object was uploaded to AWS in YYYY-MM-DD format
	- Field 8 (VAULT): The Glacier Vault name where the object was uploaded to
	- Field 9 (HASH_DESC): A true or false value. Indicates whether files are to saved as their sha 256 sum in AWS instead of the default of just __filename.tar.gpg__ .
	- Field 10 (SHA256SUM): The sha 256 sum of the file name, without the .tar.gpg extension
	- Field 12 (SHA512SUM): The sha 512 sum of the encrypted archive. This is useful in determining if the same object has already been uploaded
	- Field 13 (AWSLOCATION): This is the value of the "location" attribute in the json output which gets generated with a successful upload to the vault
	- Field 14 (AWSCHECKSUM): This is the value of the "checksum" attribute in the json output which gets generated with a successful upload to the vault
	- Field 15 (AWSARCHIVEID): This is the "archiveId" of the object. This is very important to have and is needed for object retrieval. This also gets generated with a successful upload to the vault

- After a file is successfully uploaded, an entry similar to the following will be appended to the metadata file
```
a_sample_file.jpg::::::2022-10-04:MYVAULT:false:756d81daf8ead809e3095dcd0460e536565397b953422e513debf537d4e65970:d7717f2c2601a4672e47613af864fcd5ef1abdb5922e1a48bb1ed7ecc215acfbdb1401d28d6c78455fad8d1bc6ee27b881a8c218756c1e47ffd31a98a8a71ca2:/301234567890/vaults/MYVAULT/archives/3cfWzYywh9s4Cinbl9lsF__k137VUyY5yZ1tcQiEQxjLdCMyd23uEhRx042owcSqyjDamFhwnWfa3nb51T0G6c1sIJCEv-5_VAuL1WNpIcV-ADmA-VDdzu-dOqKbraIIqt1-eVo8zQ:e0cae35f0279dcaca95dfb265a7b01107afee9b08416575611a62d404ac49c13:3cfWzYywh9s4Cinbl9lsF__k137VUyY5yZ1tcQiEQxjLdCMyd23uEhRx042owcSqyjDamFhwnWfa3nb51T0G6c1sIJCEv-5_VAuL1WNpIcV-ADmA-VDdzu-dOqKbraIIqt1-eVo8zQ
```
- This is an example of the same entry after editing the user defined fields 2-6
```
a_sample_file.jpg:John Doe, Jane Doe, Alex, Bob:Boulder, CO, USA - Denver, CO, USA:01 August 2018 - 05 August 2018:Chautauqua Park, Flatirons, Rocky Mountains, Boulder, Colorado::2022-10-04:MYVAULT:false:756d81daf8ead809e3095dcd0460e536565397b953422e513debf537d4e65970:d7717f2c2601a4672e47613af864fcd5ef1abdb5922e1a48bb1ed7ecc215acfbdb1401d28d6c78455fad8d1bc6ee27b881a8c218756c1e47ffd31a98a8a71ca2:/301234567890/vaults/MYVAULT/archives/3cfWzYywh9s4Cinbl9lsF__k137VUyY5yZ1tcQiEQxjLdCMyd23uEhRx042owcSqyjDamFhwnWfa3nb51T0G6c1sIJCEv-5_VAuL1WNpIcV-ADmA-VDdzu-dOqKbraIIqt1-eVo8zQ:e0cae35f0279dcaca95dfb265a7b01107afee9b08416575611a62d404ac49c13:3cfWzYywh9s4Cinbl9lsF__k137VUyY5yZ1tcQiEQxjLdCMyd23uEhRx042owcSqyjDamFhwnWfa3nb51T0G6c1sIJCEv-5_VAuL1WNpIcV-ADmA-VDdzu-dOqKbraIIqt1-eVo8zQ
```

## Retrieving Files from the Glacier API-Only Vault
- First, I hope that you never "have to" get to this point, since as mentioned earlier, AWS Glacier should be treated as a last resort offsite backup solution
- Objects won't show up instantly in the vault. In fact, it will take at least 12 to 24 hours after upload for them to be there
- Before a file can be downloaded from an AWS Glacier API-Only Vault, a job is initiated to request the retrieval of the file
- This request for retrieval starts the process of moving the file temporarirly to an S3 node from which it can be downloaded
- After the "Restore" process completes, the user has between 12 and 24 hours to retrieve the item from the S3 storage node
- One of the following data access tier options can be specified when initiating the request to retrieve the file. 
	- Expedited : 
		- Expedited retrievals allow you to quickly access your data 
		- For all but the largest archives (more than 250 MB), data accessed by using Expedited retrievals is typically made available within 1–5 minutes

	- Standard : 
		- This is the default option for retrieval requests that do not specify the retrieval option.
		- allows you to access any of your archives within several hours.
		- Standard retrievals are typically completed within 3–5 hours. 

	- Bulk : 
		- are the lowest-cost Glacier retrieval option, which you can use to retrieve large amounts, even petabytes, of data inexpensively in a day. 
		- Bulk retrievals are typically completed within 5–12 hours.
- Refer to the [Glacier Pricing](https://aws.amazon.com/s3/glacier/pricing/) for the how much each retrieval tier costs for your AWS region
- The ArchiveId of the archive is needed to retrieve it from the vault. Having a description of the archive is also useful in identifying the archive to be retrieved. This is why both information are saved to the detailed metadata file explained below
- A Simple Notification Service (SNS) can be set up to send a notification when an item is ready for retrieval. This prevents from having to check often whether the item is ready to be retrieved.
- Setting up SNS is explained in a previous section

### Example: Initiating Retrieval and Downloading an Object Using the AWS CLI
- The command syntax to initiate a retrieval request for a file/archive from the AWS Glacier vault is as follows (Replace MYVAULT and MY_FILE_ARCHIVE_ID, with the name of the vault and the file's ArchiveId values, respectively):
```
aws glacier initiate-job --account-id - --vault-name MYVAULT --job-parameters '{"Type": "archive-retrieval", "Tier": "Bulk","ArchiveId": "MY_FILE_ARCHIVE_ID"}'
```

- It is also recommended to include a description with this command. This is useful when trying to retrieve more than one file
```
aws glacier initiate-job --account-id - --vault-name MYVAULT --job-parameters '{"Type": "archive-retrieval", "Tier": "Bulk", "ArchiveId": "MY_FILE_ARCHIVE_ID", "Description": "MY_FILE_DESCRIPTION"}'
```

- If you setup SNS to notify you as explained in an earlier section, you should get an email notification when the file is available for download
- Once the file is available for download, the following command is used to download the file. Again, replace MYVAULT, JOB_ID_FROM_THE_NOTIFICATION_EMAIL, and FILENAME_TO_SAVE_THE_FILE_TO with the appropriate values

```
aws glacier get-job-output --account-id - --vault-name MYVAULT --job-id JOB_ID_FROM_THE_NOTIFICATION_EMAIL FILENAME_TO_SAVE_THE_FILE_TO
```

- A successful download should result in a json message with a "status": 200


## But, what if I don't have the metadata file
- Every non-empty AWS Glacier vault has an inventory file that contains information about every file in the vault, including the files' ArchiveIds
- This inventory file can be retrieved from the vault, but that also can take a few hours, depending on the tier specified, possibly adding a few more hours compared to when the ArchiveId is already known
- Retrieving the inventory file is a two step process, just like retrieving any other file:
- First, a job is initiated to request the retrieval of the inventory file. Behind the scenes, the inventory file is moved from AWS Glacier to an S3 temporary storage location and the user has about 24 hours to download it once it is on there
- The command syntax to initiate a retrieval of the inventory file from the AWS Glacier vault is as follows (Replace MYVAULT with the name of the vault):

```
aws glacier initiate-job --account-id - --vault-name MYVAULT --job-parameters '{"Type": "inventory-retrieval"}'
```

- If you setup SNS to notify you as explained in an earlier section, you should get an email notification when the file is available for download
- Once the file is available for download, the following command is used to download the file. Again, replace MYVAULT and JOB_ID_FROM_THE_NOTIFICATION_EMAIL  with the appropriate values

```
aws glacier get-job-output --account-id - --vault-name MYVAULT --job-id JOB_ID_FROM_THE_NOTIFICATION_EMAIL my_inventory_file.json
```

- A successful download should result in a json message with a `"status": 200`
- The inventory file is in json format and will contain information about every file's ArchiveId, Description, CreationDate, Size, and SHA256TreeHash

## The "--archive-description" Argument when Uploading to AWS Glacier
- When uploading files to an AWS Glacier vault, it is highly recommended to include a description of the file with the "--archive-description" option
- The "--archive-description" value becomes critical if retrieval is done without knowing the ArchiveId of the file
- By default, the upload_to_aws.sh script uses the name of the encrypted archive, minus the .tar.gpg extension as the value of "--archive-description"
- The HASH_DESC variable can be set to "true", in which case the archive-description value is set to the sha256sum value of encrypted archive name, minus the .tar.gpg extension
- Changing HASH_DESC to true is done for extra privacy/security. However, not having the metadata file or the json files then makes it almost impossible to identify which files exist in the vault when a retrieval is needed
