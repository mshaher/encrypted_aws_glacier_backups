---
layout: default
title: Cloud Storage
nav_order: 2
has_children: false
---

# Cloud Storage and AWS Glacier

## Cloud Storage Types
Cloud storage services can be grouped into two categories, depending on how they are billed: **Pre-Paid** and **Pay-Per-Use**

### Pre-Paid Storage
- Think DropBox, Apple iCloud, Google Drive, Sync, MEGA, etc..
- Designed for instant access to stored data and often allows for sharing and collboration with others
- Users are billed for pre-allocated storage space whether that space is used partially or in full
- Usually has a free-tier offering
- In general, there are no costs associated with the data transfer or downloads

### Pay-Per-Use Storage
- Think AWS Glacier, BackBlaze B2 Storage, Google Archive Storage
- Desgined as an alternative to tape backups. So, primarily for data archiving and long-term backups and not for sharing or instantenous colloboration with others. In fact, it can take anywhere from several hours to a day to retreive and download the data
- Billed on a per use basis, usually in GB and sometimes MB increments
- Usually has additional costs associated with the transfer and download of the data
- In general, they are cheap to store and upload the data, but the cost is more for data retrieval and downloads

## What is AWS Glacier?
- Amazon’s S3 pay-per-use storage class for data archiving and long-term backup
- Initially, AWS Glacier was just one storage option. Throughout this document, unless otherwise specified, “AWS Glacier” or “Glacier” refers to all of the following:
    - **Glacier API-Only** : This is the initial AWS Glacier option. Saved data is stored into **Vaults**. Uploads and retrieval of data from vaults can only be done through the AWS CLI. Browsing of the stored data is not possible through the AWS web console or CLI[^inventoryFile], so keeping a separate metadata file outside of AWS is recommended for tracking what data is in the vaults. The scripts here also generate this metadata file.

    - **S3 Glacier** or **S3 Glacier Flexible Retrieval** : This is basically Glacier API-Only “improved”. Data is stored into S3 **Buckets** . Browsing, uploads and retrievals can be done through the AWS CLI or the web GUI console. Pricing is similar to Glacier API-Only, except there is additional data overhead storage cost, explained below.

    - **S3 Glacier Deep Archive** : This is the same as S3 Glacier Flexible Retrieval but at a much cheaper storage cost

[^inventoryFile]: Although Glacier API-Only doesn't have a way to browse the stored data in real-time, there is an inventory file that gets stored in every Vault. Accessing this inventory file is explained in a later section  

- For each object that is stored in **S3 Glacier Flexible Retrieval** or **S3 Glacier Deep Archive**, Amazon S3 adds 40 KB of chargeable overhead for metadata, with 8 KB charged at S3 Standard rates and 32 KB charged at S3 Glacier Flexible Retrieval or S3 Deep Archive rates. For example, storing 1,000,000 files or objects in the US West (Oregon) region, would be about $0.28/month with S3 Glacier Flexible Retrieval and $0.21/month with S3 Glacier Deep Archive in overhead storage costs. The overhead storage cost is significantly less and may be negligible if the same files could be grouped into archives before uploading, resulting in fewer bigger files and hence fewer overhead metadata files. The tradeoff there is that retrieving and downloading bigger files would cost more.


## Why AWS Glacier?
- **Cheap to "Store"**: Cost is the biggest selling point for AWS Glacier.  It **CAN** be a cheaper option compared to other Pay-Per-Use and Pre-Paid cloud storage services, depending on how much data is stored and the number of files stored. For example,  saving 200GB of data at an average file size of 100MB costs about $0.20/month to store with AWS Glacier Deep Archive and $0.72/month with Glacier Flexible Retrieval. The same amount of data costs $2.99/month to store on the Pre-Paid Apple iCloud and Google One ($2.50/month with Google One, if paid annually). However, just like other Pay-Per-Use storage options,  there are costs for data retrieval and transfer out of AWS, but not with the other cloud providers, as is shown below.

## BUT .......
- **Objects Availability**: Unlike other cloud storage solutions, objects uploaded to the AWS Glacier **may** not be immediately available to view or retrieve. With AWS Glacier API-Only for example, it can take up to 24 hours for uploaded objects to be "available" and about the same time to retrieve stored items, depending on the retrieval tier chosen by the user. So, it is best used as a last resort offsite backup
- **Browsing**: *(Applies only to the Glacier API-only option)*. There is no way to view the details about the content of the stored items in AWS Glacier with the API-only option. Retrieval of stored items is done through the AWS CLI and by knowing the ArchiveId of the stored items. 
- **Privacy/Security**: This is not unique to AWS, but like every cloud storage offering, your data is stored on someone else's hardware. This is where the need to encrypt the data before uploading matters, and this why the scripts available here are divided into two: one that encrypts the data and saves it locally, and another that takes that encrypted data and uploads it to AWS Glacier
- **Cost to Retrieve and Transfer Out**: In general, the cost to upload or transfer data IN to AWS Glacier is free or very cheap.  However, downloading or transferring data OUT can get expensive depending on the size of the data. An example breakdown of the cost compared to other Pay-Per-Use cloud storage services is provided below.


## How does it compare to other cloud storage services?
- Some general differences between Pay-Per-Use and Pre-Paid storage solutions are provided above. 
- When compared to other Pay-Per-Use storage solutions, cost, maximum file sizes, transfer speeds, storage replication, availability of the stored data, utilities and APIs, personal preferences, and few other factors need to be considered to determine if the storage solution is right for you. For me personally, cost was the biggest selling point, and I could make any shortcomings and available features in AWS Glacier Deep Archive work for my need to have a cheap long-term last-resort offsite backup solution.
- The following is a link to cost comparison spreadsheet of storing, retrieving, and downloading different size data with AWS Glacier in the US West (Oregon) region, and other popular pay-per-use cloud storage services. The cheapest options are highlighted in green, while the expensive options are in red
- [Pay-Per-Use Storage Cost](https://docs.google.com/spreadsheets/d/1QDpAGJROl3kIamxAMyv1b9NII7se4w-dGTxm35yb-zE/edit?usp=sharing) [^storagecost]     




[^storagecost]: Figures are as of October 2022 . Sources and for the most recent figures, please refer to the following sites:    
     [AWS Glacier API-Only Pricing](https://aws.amazon.com/s3/glacier/pricing/)    
     [AWS S3 Pricing](https://aws.amazon.com/s3/pricing/)    
     [BackBlaze Pricing](https://www.backblaze.com/b2/cloud-storage-pricing.html)    
     [Google Pricing](https://cloud.google.com/storage/pricing)    
