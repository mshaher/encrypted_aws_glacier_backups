---
layout: default
title: encrypt_and_save.sh
parent: The Scripts
nav_order: 1
---

## encrypt_and_save.sh
- Converts files or directories into tar archives, encrypts the archives with gpg using symmetric encryption, and then saves the encrypted files to the **ENC_BACKUP_DIR** directory
- Prints a usage and help message if the script is run without any options or arguments 
- Relies on the following variables to be defined by the user either in the script or in the file defined by the **PERSONAL_CONFIG_FILE** variable  
	**ENC_BACKUP_DIR**	:  The local directory to which the encrypted archives will be saved to  
	**PASS512SUM**	:  This the first 25 to 35 characters of the sha 512 sum of the secret passphrase used to encrypt and decrypt the archive. See below for information on how to set this value  
- The script **MUST** have at least one '**-s**' or '**-m**' option specified . Two other optional parameters can be specified, '-f' and '-p'
- Multiple '-s' and '-m' options can be specified
```
	-s : The outcome is one .tar.gpg archive of the file or directory specified immediately after the option
	-m : The outcome is x number of .tar.gpg archives, where x is the number of 'unhidden' files or directories in the directory specified immediately after the option
	-f : Optional. Overwrites the encrypted archive in the ENC_BACKUP_DIR directory if one with the same name already exists. If this option isn't specified, the default is to NOT overwrite
	-p : Optional. Prompt for confirmation to overwrite when an encrypted archive in the ENC_BACKUP_DIR directory with the same name already exists
```
## Usage Examples
- Let's assume the following example directory structure 
```
     topDir
      |
      |--- dir1
               |--- file1.txt
               |--- file2.txt
               |--- .hiddenfile1
               |--- subDir1
                      |--- file3.txt
                      |--- file4.txt
                      |--- .hiddenfile2
```

### Example 1
```
encrypt_and_save.sh -s topDir/dir1
``` 
would result in one .tar.gpg file getting created:   
- **dir1.tar.gpg** : this will contain ALL of the files and subdirectories under dir1, including subDir1 and its content and the hidden files in dir1 and subDir1


### Example 2
```
encrypt_and_save.sh -m topDir/dir1/subDir1
```` 
would result in two .tar.gpg files getting created:     
- **file3.txt.tar.gpg** and **file4.txt.tar.gpg** 
- this is the same as running 
```
encrypt_and_save.sh -s topDir/dir1/subDir1/file3.txt -s topDir/dir1/subDir1/file4.txt
```



### Example 3
```
encrypt_and_save.sh -s topDir/dir1 -m topDir/dir1/subDir1
``` 
would result in three .tar.gpg files getting created    
- this is the same as running the "Example 1" and "Example 2" commands above separately, so the output files are **dir1.tar.gpg**, **file3.txt.tar.gpg** and **file4.txt.tar.gpg**  

## Setting the value of PASS512SUM
- First, pick a strong password or passphrase that is at least 16 characters long. Use dashes or underscores instead of spaces.
- **DO NOT LOSE THIS SECRET!!!** Everything from encrypting your archives to the ability to decrypt them relies on this secret.
- Temporarily save this secret to a file. Make sure there are no trailing spaces or any lines before or after the secret
- Generate the sha 512 sum of the secret by echo'ing it with trailing newlines, and piping it to "shasum -a 512" or "sha512sum"
- Copy the first 25 to 35 characters of the sha 512 value and paste it as the value of the PASS512SUM variable
- Delete the temporary file where the password was saved to

### Example
- Let's assume that the secret is My_Sup3r-secret-p@ssword
- Save it to a file named temppass.txt
- Generate the sha 512 sum of the password by running something like the following:
```
  echo -n $(cat temppass.txt) | shasum -a 512
```
or
```
 echo -n $(cat temppass.txt) | sha512sum
```
- The output of the above command for the secret  My_Sup3r-secret-p@ssword  is   
**c44de0496d695c503d941a1ede5bf52b0e1293466184d0177b3b312be217e110df5a8eaa81ba00217bdb80170ab744cbc66fb7ae8d6e21a1931a65ee0e3abb8b  -**
- copy the first 25 to 35 characters, so **c44de0496d695c503d941a1ede5bf52b0e12934661**  and paste it to the value of **PASS512SUM** variable
- Delete temppass.txt


## IMPORTANT !! IMPORTANT !! IMPORTANT !!
- Before proceeding with encrypting and uploading important files to AWS, make sure you are able to decrypt content that was encrypted using the encrypt_and_save.sh script and your secret
- Pick or create a file and a small directory that has some content
- Run the encrypt_and_save.sh on the file and directory. e.g:   
`$ encrypt_and_save.sh -s /path/to/test_file -s /path/to/test_directory`
- After the .tar.gz files are saved to the ENC_BACKUP_DIR directory, create and cd to a temporary directory   
`$ mkdir /tmp/my_test_dir ; cd /tmp/my_test_dir`
- Decrypt the encrypted archives with the following commands. Provide your secret when prompted  
	- assuming ENC_BACKUP_DIR is /mnt/backups
```
	$ gpg --output decrypted_file.tar --decrypt /mnt/backups/test_file.tar.gpg
	$ gpg --output decrypted_directory.tar --decrypt /mnt/backups/my_test_dir.tar.gpg
```
- untar the archives and verify that the file and content of the directory match the originals
```
	$ tar -xvf decrypted_file.tar
	$ tar -xvf decrypted_directory.tar
```
