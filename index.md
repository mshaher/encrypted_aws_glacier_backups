---
layout: default
title: Introduction
nav_order: 1
has_children: false
---

## Goal
Basically, the goal here is to encrypt and save backups locally and inexpensively to the cloud, specifically to AWS 

## Backup Strategy and Encryption
For anyone with internet access, cloud storage can help with performing backups using the 3-2-1 rule.
First coined by Peter Krogh in 2005[^backuprule], the 3-2-1 rule is a great strategy for digital data backups, that it is recommended by the [Cybersecurity and Infrastructure Security Agency](https://www.cisa.gov/uscert/sites/default/files/publications/data_backup_options.pdf) (CISA) for use by individuals and businesses to reduce the chance of data loss. 
The 3-2-1 rule involves the following:  

- **3**:  Keep **3** copies of any important data: 1 primary and 2 backups.
- **2**:  Keep the data on **2** different media types
- **1**:  Store **1** copy offsite

[^backuprule]: Krogh, Peter. *The DAM Book: Digital Asset Management for Photographers, 2nd Edition*, p. 207. O'Reilly Media, 2009.

However, saving data on shared media (Cloud storage or shared desktop/laptops/servers/mobile devices), and important data in general, should be encrypted to further reduce the risk in case of a breach or unwanted access to the storage device.  
The scripts in this repo are based on the "[Cheap Personal Backup using AWS Glacier](https://klaus.hohenpoelz.de/cheap-personal-backup-using-aws-glacier.html)" by Klaus Eisentraut.
Klaus' work has the added benefit of saving the backups as encrypted archives before uploading them to what is now known as "**AWS Glacier API Only**".
There are now AWS and non-AWS cloud storage solutions that may make more sense depending on personal preferences/needs and how much these solutions cost.   
Personally, I started with uploading encrypted backups to "**AWS Glacier API Only**" using these modified versions of Klaus' scripts. 
But, soon after I switched to uploading to "**AWS S3 Glacier Deep Archive**". 
The scripts and documentation here are for setting up and uploading encrypted archives to both AWS solutions

## Assumptions and Functionality
[The scripts in this repo](https://github.com/mshaher/encrypted_aws_glacier_backups) are performing the following tasks, which are explained in this documentation:
- Files, folders or the contents of folders are made into archives first before encryption
- Archive files are encrypted with GPG using symmetric encryption. With symmetric encryption, a passphrase instead of certificates is used. This way, the user only has to worry about remembering or securely saving the passphrase, instead of the storage and management of the gpg private certificate
- Encrypted archives of less than 5GB in size each can then be uploaded to AWS Glacier (4GB with AWS Glacier API-Only). Support for uploading larger size files will be explained later in the documentation
- The same encrypted archives (same sha512 sum hash) aren't re-uploaded
- A detailed text metadata file is kept as an index of all the archives uploaded to AWS Glacier. This is an important file that should perhaps be saved to another cloud storage provider service, and can be encrypted before doing so if necessary.

## Requirements
- OS: Linux, Mac OS X, or a UNIX-like OS with standard tools and programs in the user's PATH, specifically the following:
	- bash shell
	- `basename`
	- `command`
	- `dirname`
	- `sha256sum` and `sha512sum` ( or just `shasum` on some systems)
	- `tar`
- AWS Account 
- AWS CLI tools 
- GnuGP/GPG 
- Not a requirement, but using a password management software or service is highly recommended. The scripts here rely on one strong passphrase to encrypt the backups, but you'll also need to create an AWS account and at least one user there, and both require their own credentials. Personally, I use [KeePass](https://keepass.info), but there are plenty of other free and paid solutions out there to choose from
