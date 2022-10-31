#!/usr/bin/env bash

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
# This is not used in the by the script that uploads to AWS
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

ALL_ARCHIVES=()
IFS=$'\n'
OVERWRITE=false
PROMPT=false
THISSCRIPT=`basename ${0}`
TMPDIR="/tmp/enc_local_backup"

##############################################################################################
## Begin: Check for necessary programs. Emulate realpath function, if realpath isn't installed
#---------------------------------------------------------------------------------------------

for COMMAND in tar gpg dirname basename; do
	if ! command -v ${COMMAND}  &> /dev/null; then
		echo "Could not find '${COMMAND}'. Please make sure it is installed somewhere in your PATH"
		exit 1
	fi
done

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

if ! command -v realpath &> /dev/null; then
	realpath(){
		if [ -f $1 ]; then
			cd $(dirname $1) >/dev/null
			REAL_PATH="$(pwd)/$(basename $1)"
		elif [ -d $1 ]; then
			cd $1 >/dev/null
			REAL_PATH=$(pwd)
		else
			echo "Unknown file or directory: $1"
			exit 1
		fi
		cd - >/dev/null
		echo ${REAL_PATH}
	}
fi
#---------------------------------------------------------------------------------------------
## End: Check for necessary programs. Emulate realpath function, if realpath isn't installed
##############################################################################################

##############################################################################################
## Begin: Usage Information
#---------------------------------------------------------------------------------------------
display_usage() { 
	echo -e "\nDescription: Creates gpg-encrypted tar archives and saves them to a local directory\n"
	echo -e "Usage: ${THISSCRIPT} [-f | -p] (-s <path> | -m <path>) ... \n"
	echo -e "Options:"
	echo -e " By default, archive isn't overwritten if one with the same name exists in the local save directory."
	echo -e " The '-f' and '-p' options change the default behavior"
	echo -e "   -f   Overwrite archive file if one with the same name already exists. "
	echo -e "        This option doesn't prompt for confirmation if archive already exists "
	echo -e "        This option also takes precedence over the '-p' option "
	echo -e "   -p   Prompt for confirmation to overwrite when an archive with the same name already exists. "
	echo -e ""
	echo -e "One or more '-s' and/or '-m' and their argument <path> MUST be specified"
	echo -e "<path> can either be an absolute path, relative to the current directory, or something like ~/somefile "
	echo -e "   -s   For single archive. "
	echo -e "        The outcome is one .tar.gpg archive of the file or directory specified by <path> "
	echo -e "        <path> can be a directory or a file with this option.  "
	echo -e "   -m   For multiple archives".
	echo -e "        The outcome is x number of .tar.gpg archives, where x is the number of 'unhidden' files or directories in <path>"
	echo -e "        <path> must be a directory with this option.  "
}
#---------------------------------------------------------------------------------------------
## End: Usage Information
##############################################################################################

##############################################################################################
## Begin: Parse command line options
#---------------------------------------------------------------------------------------------
while getopts ":m:s:fp" optname; do
	case "$optname" in
		"f")
			OVERWRITE=true
			;;
		"m")
			if [ ! -d "${OPTARG}" ]; then
				echo "${OPTARG} isn't a directory or doesn't exist"
				exit 1
			else
				for content in `ls ${OPTARG}`; do
					FULLPATH=$(realpath "${OPTARG}/${content}")
					if [[ ! "${ALL_ARCHIVES[@]}" =~ "${FULLPATH}" ]]; then
						ALL_ARCHIVES+=("${FULLPATH}")
					fi
				done
			fi
			;;
		"p")
			PROMPT=true
			;;
		"s")
			if [[ -e "${OPTARG}" ]]; then
				FULLPATH=$(realpath "${OPTARG}")
				if [[ ! "${ALL_ARCHIVES[@]}" =~ "${FULLPATH}" ]]; then
					ALL_ARCHIVES+=("${FULLPATH}")
				fi
			else
				echo "${OPTARG} doesn't exist!"
				exit 1
			fi
			;;
		"?")
			echo "Unknown option $OPTARG"
			display_usage
			exit 1
			;;
		":")
			echo "No argument value for option $OPTARG"
			display_usage
			exit 1
			;;
		*)
			# Should not occur
			echo "Unknown error while processing options"
			;;
	esac
done
#---------------------------------------------------------------------------------------------
## End: Parse command line options
##############################################################################################

if  [ "$#" -eq "0" ] || [ "${OPTIND}" -eq "1" ]; then
	display_usage
	exit 1
else

	if [ -r "${PERSONAL_CONFIG_FILE}" ]; then
		. "${PERSONAL_CONFIG_FILE}"
	fi

	##############################################################################################
	## Begin: Attempt to create ENC_BACKUP_DIR or check that it is writeable
	#---------------------------------------------------------------------------------------------
	mkdir -p "${ENC_BACKUP_DIR}" 2>/tmp/foobar123 && touch "${ENC_BACKUP_DIR}/foobar123" 2>/tmp/foobar123 && rm -f "${ENC_BACKUP_DIR}/foobar123"
	if [ -s /tmp/foobar123 ]; then
		cat /tmp/foobar123 | sed "s|.*|Backup directory $ENC_BACKUP_DIR is not writable|" && rm -f /tmp/foobar123; exit 1
	else
		rm -f /tmp/foobar123
	fi
	#---------------------------------------------------------------------------------------------
	## End: Attempt to create ENC_BACKUP_DIR or check that it is writeable
	##############################################################################################

	##############################################################################################
	## Begin: Prompt for passphrase and check its sha512sum 
	#---------------------------------------------------------------------------------------------
	stty -echo
	printf "Enter Encryption Passphrase: "
	read MYPP
	stty echo
	printf "\n"
	if [[ ! $(echo -n "$MYPP" | sha512sum) =~ ^${PASS512SUM}.*$ ]]; then
		echo "Wrong Passphrase"
		exit 1
	fi
	#---------------------------------------------------------------------------------------------
	## End: Prompt for passphrase and check its sha512sum 
	##############################################################################################

	# ensure that TMPDIR folder exists and remove previous files
	mkdir -p "${TMPDIR}"
	cd "${TMPDIR}" >/dev/null

	for ((i = 0; i < ${#ALL_ARCHIVES[@]}; i++)); do
		ARCHIVE="${ALL_ARCHIVES[${i}]}"
		BASENAME=`basename "${ARCHIVE}"`
		# make sure a symlink in TMPDIR doesn't exist already. This could happen if the user interrupts the process at some point
		# which can cause an infinite loop
		rm -f "${TMPDIR}/${BASENAME}"
	
		if [ ! -e "${ENC_BACKUP_DIR}/${BASENAME}.tar.gpg" ] || [ ${OVERWRITE} = true ]; then
			PROCEED="y"
		else
			if [ ${PROMPT} = true ]; then
				printf "${ENC_BACKUP_DIR}/${BASENAME}.tar.gpg already exists. Overwrite it with new archive? (y/n) : "
				read PROCEED
			else
				PROCEED="n"
				echo "Not overwriting ${ENC_BACKUP_DIR}/${BASENAME}.tar.gpg"
			fi
		fi

		if [ "${PROCEED}" = "y" ]; then
			# encrypt everything, note that GnuPG does compression already!
			echo "Creating encrypted archive \"${BASENAME}.tar.gpg\" in ${ENC_BACKUP_DIR} ..."
			ln -s "${ARCHIVE}" "${TMPDIR}/${BASENAME}"

			# Un-comment the following line for some debugging output
			# echo "ARCHIVE is ${ARCHIVE} and symlink is ${TMPDIR}/${BASENAME}"

			if command -v gtar &> /dev/null; then
				# use 'gtar' if available, otherwise just 'tar'
				gtar cvh "${BASENAME}" | gpg --s2k-mode=3 --s2k-cipher-algo=AES256 --s2k-digest-algo=SHA512 --s2k-count=65011712 --symmetric --cipher-algo=AES256 --digest-algo=SHA512 --compress-algo=zlib --batch --passphrase-fd 3 3<<< "$MYPP" > "${ENC_BACKUP_DIR}/${BASENAME}.tar.gpg"
			else
				tar cvh "${BASENAME}" | gpg --s2k-mode=3 --s2k-cipher-algo=AES256 --s2k-digest-algo=SHA512 --s2k-count=65011712 --symmetric --cipher-algo=AES256 --digest-algo=SHA512 --compress-algo=zlib --batch --passphrase-fd 3 3<<< "$MYPP" > "${ENC_BACKUP_DIR}/${BASENAME}.tar.gpg"
			fi

			echo -n "Encryption of ${ARCHIVE} done! Removing symlink ${TMPDIR}/${BASENAME} ..."
			rm -f "${TMPDIR}/${BASENAME}"
			echo " Done"
			echo ""
		fi
	done
	cd - >/dev/null
	# we don't need it anymore, so we overwrite our passphrase
	MYPP=0123456789012345678901234567890123456789
fi
