---
layout: default
title: The Scripts
nav_order: 4
has_children: true
---

## Overview
- [The scripts in this repo](https://github.com/mshaher/encrypted_aws_glacier_backups) perform two main functions: 
	- converting files or directories into encrypted archives and saving them locally. This is done by the encrypt_and_save.sh script
	- uploading the saved encrypted archives to AWS. This is done by the *AWS Upload Scripts*
- The scripts rely on a few user-defined variables. These are defined at the top of the scripts, or can be put in a config file defined by the **PERSONAL_CONFIG_FILE** variable
- A variable defined in the **PERSONAL_CONFIG_FILE** takes precedence over the same user-defined variable in the scripts themselves
- The script that encrypts and saves archives locally is not dependent on the script(s) that upload(s) its output to AWS. In fact, the user can choose not to upload the encrypted archives to anywhere, or to upload them to any storage service of their choice.
- As written, the scripts that upload to AWS are dependent on the output of the encryption script. But, the user is free to modify the scripts to make them upload ANY files to AWS
- More information about the scripts is provided in the next sections

## Download Location
- The latest versions of the scripts are available from [this link](https://github.com/mshaher/encrypted_aws_glacier_backups)
