#!/usr/bin/env bash
#
# Uploads the encrypted .tar.gpg files in ${ENC_BACKUP_DIR} to an AWS Deep Archive bucket
# Limited to file size < 5GB ...
#

##############################################################################################
## Begin: TODO - Adjust your config variables here
#---------------------------------------------------------------------------------------------

#--- Begin: Settings used by both scripts ----
# This is where the encrypted .tar.gpg files are/will be saved to
# This variable should have the same value in both scripts
ENC_BACKUP_DIR="/scratch/backup/glacier"
#--- End: Settings used by both scripts ----

#--- Begin: Settings used only by the script that creates, encrypts and saves the archives locally----
# adjust your (shortened) passphrase SHA512 checksum hash here,
# this acts as a safeguard (a backup encrypted with the wrong key is unusable and dangerous)
# This is not used by the upload_to_aws script
PASS512SUM="0123456789abcdefghijklm0123456789abc"
#--- End: Settings used only by the script that creates, encrypts and saves the archives locally----

#--- Begin: Settings used only by the script that uploads to AWS ----
# METADATA_DIR & METADATA_FILE are only used by the script that uploads to AWS.
# These are safe to comment out or delete in the encrypt_and_save.sh script
# Make sure to set USE_LOCAL_METADATA to true if HASH_DESC is true
# Name of your AWS S3 Bucket
BUCKET="mybucketname"

# All uploads are saved to the root of the AWS S3 Bucket. There is NO directory hierarchy in S3 buckets 
# However, a prefix can be assigned  when uploading data, which will show up as a directory in the 
# Bucket when viewed using the AWS Web Console. This is an optional parameter but make sure to append 
# the trailing "/" backslash to the value, if it's not empty 
#PREFIX=""
PREFIX="myprefix/myprefix2_with_trailing_backslash/"

# Optional: Whether to use a local metadata file to keep track of various information like
# name of the files uploaded, date of the upload, prefix used, shasum of the file being
# uploaded, etc... The advantage of using a local metadata file is that it prevents uploading the same file
# to AWS. The downside is, compared to not using a metadata file, it's a bit slower, because the sha512 sum
# needs to be calculated for the file before it is uploaded. 
USE_LOCAL_METADATA=true
METADATA_DIR="${ENC_BACKUP_DIR}/metadata"
METADATA_FILE="${METADATA_DIR}/details.txt"

# Extra privacy setting if you want to the names of the files to be saved as their sha 256 sum in AWS.
# Change the following to true if you want the 
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
## End: TODO - Adjust your config variables here
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

# 5GB is the maximum file upload size in a put operation to S3 Buckets
# Archives larger than 5GB must use the Multi Upload Process instead
MAX_ARCHIVE_SIZE=5368709120


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

if [ ${USE_LOCAL_METADATA} = true ]; then
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
			touch ${METADATA_FILE}
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
fi

cd "$ENC_BACKUP_DIR"

find ./ -name "*.tar.gpg" | grep -iv '^\./uploaded' | sed "s/^\.\///" | while read -r FILENAME; do

	echo -n "Checking ${FILENAME} ..."
	GPGFILENAME=`basename "${FILENAME}"`
	OBJECT=`echo "${GPGFILENAME%%\.tar\.gpg}"`
	SHA256SUM=`echo -n "${OBJECT}" | sha256sum | awk '{print $1}'`
	ARCHIVE_SIZE=$(wc -c "${FILENAME}" | awk '{print $1}')
	NEWFILE=true

	########################################################################################################
	## Begin: When a match is found in the metadata file 
	#-------------------------------------------------------------------------------------------------------
	if [ ${USE_LOCAL_METADATA} = true ]; then
		SHA512SUM=`sha512sum "${FILENAME}" | awk '{print $1}'`
		if grep -q ":${SHA512SUM}:" ${METADATA_FILE}; then # check for the sha512sum of the gpg file to be backed up
			# already successfully uploaded
			echo "${FILENAME} was already uploaded to glacier."
			NEWFILE=false
		fi
	fi
	#-------------------------------------------------------------------------------------------------------
	## End: When a match is found in the metadata file 
	########################################################################################################

	########################################################################################################
	## Begin: new file to be uploaded
	#-------------------------------------------------------------------------------------------------------
	if [ ${USE_LOCAL_METADATA} = false ] || [ ${NEWFILE} = true ]; then
		if [ ${ARCHIVE_SIZE} -lt ${MAX_ARCHIVE_SIZE} ];then
			echo "Uploading ${FILENAME}"
			if [ ${HASH_DESC} = true ]; then
				OUTPUT_FILENAME="${SHA256SUM}"
			else
				OUTPUT_FILENAME="${FILENAME}"
			fi
			# date
			aws s3 cp "${FILENAME}" "s3://${BUCKET}/${PREFIX}${OUTPUT_FILENAME}" --cli-connect-timeout 6000 --storage-class DEEP_ARCHIVE 2>&1
			# date
			if [ ${USE_LOCAL_METADATA} = true ]; then
				FILEDIR=`dirname "${FILENAME}" | sed "s/^\.//"`
				echo "${OBJECT}::::::${DATE}:${BUCKET}:${PREFIX}${FILEDIR}:${HASH_DESC}:${SHA256SUM}:${SHA512SUM}:" >> "${METADATA_FILE}"
			fi
		else
			echo "${FILENAME} is more than 5GB in size. It will not be uploaded to AWS at this time"
		fi
	fi
	#-------------------------------------------------------------------------------------------------------
	## End: new file to be uploaded
	########################################################################################################
done
