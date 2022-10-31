#!/usr/bin/env bash
#
# Uploads the encrypted .tar.gpg files in ${ENC_BACKUP_DIR} to an AWS Glacier API Vault
# TODO: does not work for files > 4GB ...
#

##############################################################################################
## Begin: TODO - Adjust you config variables here
#---------------------------------------------------------------------------------------------

#--- Begin: Settings used by both scripts ----
# This is where the encrypted .tar.gpg files are/will be saved to
# This variable should have the same value in both scripts
ENC_BACKUP_DIR="/scratch/backup/glacier"
#--- End: Settings used by both scripts ----

#--- Begin: Settings used only by the script that creates, encrypts and saves the archives locally----
# adjust your (shortened) passphrase SHA512 checksum hash here,
# this acts as a safeguard (a backup encrypted with the wrong key is unusable and dangerous)
# This is not used in the upload_to_aws script
PASS512SUM="0123456789abcdefghijklm0123456789abc"
#--- End: Settings used only by the script that creates, encrypts and saves the archives locally----

#--- Begin: Settings used only by the script that uploads to AWS Glacier ----
# METADATA_DIR & METADATA_FILE are only used in the upload_to_aws script.
# These are safe to comment out or delete in the encrypt_and_save_locally script
METADATA_DIR="${ENC_BACKUP_DIR}/metadata"
METADATA_FILE="${METADATA_DIR}/details.txt"

# Name of your AWS Glacier vault
VAULT="backup"

# Extra privacy setting. By default, the AWS archive-description is set to the archive name
# without the ".tar.gz" extension. Change the following to true if you want the 
# AWS archive-description instead to be the sha256sum value of archive name
# e.g: For the archive "myfilename.tar.gz" , the AWS archive-description value
# with HASH_DESC=false is "myfilename"
# with HASH_DESC=true is "02d8ef8071b418bbc2375df5ab6bc917b1751af25ded56bda71ce8a5a86a0ba5"
HASH_DESC=false
#--- End: Settings used only by the script that uploads to AWS Glacier ----

# All or some of the above variables and their values can be placed in a file.
# Variables and values set in the PERSONAL_CONFIG_FILE take precedence
PERSONAL_CONFIG_FILE="${HOME}/.aws/enc_backups.config"

#---------------------------------------------------------------------------------------------
## End: TODO - Adjust you config variables here
##############################################################################################

##############################################################################################
## Begin: Read the above varaiables from the PERSONAL_CONFIG_FILE if it exists
#---------------------------------------------------------------------------------------------
if [ -r "${PERSONAL_CONFIG_FILE}" ]; then
	. "${PERSONAL_CONFIG_FILE}"
fi
#---------------------------------------------------------------------------------------------
## End: Read the above varaiables from the PERSONAL_CONFIG_FILE if it exists
##############################################################################################

DATE=`date +%F`

# 4GB is the maximum file upload size in a single operation per the documentation at
# https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-an-archive.html
# Archives larger than 4GB must use the Multi Upload Process instead
MAX_ARCHIVE_SIZE=4294967296


##############################################################################################
## Begin: Check for sha512sum, sha256sum or shasum
#---------------------------------------------------------------------------------------------
if $(! command -v sha512sum &> /dev/null) || $(! command -v sha256sum &> /dev/null) ; then
	if ! command -v shasum &> /dev/null; then
		echo "Could not find 'shasum'. Please make sure it is installed somwhere in your PATH"
		exit 1
	else
		shopt -s expand_aliases
		alias sha512sum='shasum -a  512'
		alias sha256sum='shasum -a  256'
	fi
fi
#---------------------------------------------------------------------------------------------
## End: Check for sha512sum, sha256sum or shasum
##############################################################################################

##############################################################################################
## Begin: Attempt to create METADATA_DIR or check that it is writeable
#---------------------------------------------------------------------------------------------
mkdir -p "${METADATA_DIR}" 2>/tmp/foobar123 && touch "${METADATA_DIR}/foobar123" 2>/tmp/foobar123 && rm -f "${METADATA_DIR}/foobar123"
if [ -s /tmp/foobar123 ]; then
	cat /tmp/foobar123 | sed "s|.*|Metadata directory $METADATA_DIR is not writable|" && rm -f /tmp/foobar123; exit 1
else
	rm -f /tmp/foobar123
fi
#---------------------------------------------------------------------------------------------
## End: Attempt to create METADATA_DIR or check that it is writeable
##############################################################################################

##############################################################################################
## Begin: Checking that METADATA_FILE exists and is writable
#---------------------------------------------------------------------------------------------
if [ ! -f "${METADATA_FILE}" ]; then
	echo ""
	echo "Metadata file ${METADATA_FILE} doesn't exist."
	echo "You can either, "
	echo "  - Answer 'y' to have one created. Or"
	echo "  - Answer 'n' and change the METADATA_FILE variable value in ${0}"
	echo ""
	echo -n "Do you want the Metadata file created? (y/n) : "
	read ANSWER
	CREATE=`echo ${ANSWER} | tr [A-Z] [a-z]`
	if [ "${CREATE}" = "y" ]; then
		touch "${METADATA_FILE}"
	elif [ "${CREATE}" = "n" ]; then
		echo "Please edit ${0} and change the value of the variable METADATA_FILE to your desired file"
		exit 1
	else
		echo ""
		echo "Please answer with either 'y' or 'n' "
		${0}
	fi
fi

if [ ! -w "${METADATA_FILE}" ]; then
	echo "Metadata file ${METADATA_FILE} isn't writable."
	echo "Please change the permissions on the file and try again."
	exit 1
fi
#---------------------------------------------------------------------------------------------
## End: Checking that METADATA_FILE exists and is writable
##############################################################################################

cd "$ENC_BACKUP_DIR"

ls *.tar.gpg | sort -R | while read -r FILENAME; do

	echo -n "Checking ${FILENAME} ..."
	SHA512SUM=`sha512sum "${FILENAME}" | awk '{print $1}'`
	JSON_FILE="${METADATA_DIR}/${FILENAME}.json"
	GPGFILENAME=`basename "${FILENAME}"`
	OBJECT=`echo "${GPGFILENAME%%\.tar\.gpg}"`
	SHA256SUM=`echo -n "${OBJECT}" | sha256sum | awk '{print $1}'`
	ARCHIVE_SIZE=$(wc -c "${FILENAME}" | awk '{print $1}')

	########################################################################################################
	## Begin: When a match is found in the metadata file 
	#-------------------------------------------------------------------------------------------------------
	if grep -q ":${SHA512SUM}:" ${METADATA_FILE}; then # check for the sha512sum of the gpg file to be backed up
		ARCHIVEID=`grep ":${SHA512SUM}:" ${METADATA_FILE} | awk -F":" '{if ($NF)print $NF}'`
		if [ "${ARCHIVEID}" = "" ]; then
			# strange file
			echo "WARNING: ${FILENAME} seems corrupt or wasn't uploaded correctly to AWS Glacier. Please fix manually"
			echo "Relevant metadata information :"
			echo "-------------------------------"
			grep ":${SHA512SUM}:" ${METADATA_FILE}
			echo "-------------------------------"
		elif [ -s ${JSON_FILE} ]; then # check for non empty json file
			AWSARCHIVEID=`grep '"archiveId":' ${JSON_FILE} | awk -F: '{print $2}' | awk -F\" '{print $2}'`
			if [ ${ARCHIVEID} != ${AWSARCHIVEID} ]; then
				echo "-------------------------------"
				echo "WARNING: ${FILENAME} may be corrupt or wasn't uploaded correctly to AWS Glacier."
				echo "WARNING: The archiveId values in the metadata file and the JSON file do not match"
				echo "archiveId value from metadata file : ${ARCHIVEID} "
				echo "archiveId value from json file     : ${AWSARCHIVEID} "
				echo "-------------------------------"
			else 
				# The archiveId values in the JSON_FILE and METADATA_FILE match
				# already successfully uploaded
				echo "${FILENAME} was already uploaded to glacier."
			fi
		else
			# already successfully uploaded
			echo "${FILENAME} was already uploaded to glacier."
		fi
	#-------------------------------------------------------------------------------------------------------
	## End: When a match is found in the metadata file 
	########################################################################################################

	########################################################################################################
	## Begin: new file to be uploaded
	#-------------------------------------------------------------------------------------------------------
	else	
		if [ ${ARCHIVE_SIZE} -lt ${MAX_ARCHIVE_SIZE} ];then
			if [ ${HASH_DESC} = true ]; then
				DESC=${SHA256SUM}
			else
				DESC=${OBJECT}
			fi

			echo "Uploading ${FILENAME}"
			date
			aws glacier upload-archive --cli-connect-timeout 6000 --vault-name "$VAULT" --account-id - --body "${FILENAME}" --archive-description "${DESC}" 2>&1 | tee ${JSON_FILE}
			date
			AWSLOCATION=`grep '"location":' ${JSON_FILE} | awk -F: '{print $2}' | awk -F\" '{print $2}'`
			AWSCHECKSUM=`grep '"checksum":' ${JSON_FILE} | awk -F: '{print $2}' | awk -F\" '{print $2}'`
			AWSARCHIVEID=`grep '"archiveId":' ${JSON_FILE} | awk -F: '{print $2}' | awk -F\" '{print $2}'`

			echo "${OBJECT}::::::${DATE}:${VAULT}:${HASH_DESC}:${SHA256SUM}:${SHA512SUM}:${AWSLOCATION}:${AWSCHECKSUM}:${AWSARCHIVEID}" >> "${METADATA_FILE}"
		else
			echo "${FILENAME} is more than 4GB in size. It will not be uploaded to AWS at this time"
		fi
	fi
	#-------------------------------------------------------------------------------------------------------
	## End: new file to be uploaded
	########################################################################################################
done
