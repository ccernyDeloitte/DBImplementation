#!/bin/bash
# 
# pg_backup
# 
# This script creates a full back_up of Postgres
# Usage: pg_backup.sh 
#######################
## Script vars
#######################
udir="/var/pg_base/pg_utils"
logdir="$udir/logs"
me=$(basename $0)
dtstamp=$(date +"%Y%m%d")
logfile="pg_backup.log"
pgid="postgres"
user=$(id -un)
PIDFILE=${logdir}/scrip.flock.tmp.$me.pid
TMPFILE=${logdir}/scrip.tmp.$me.$$.log
bkpdirBase="/var/pgads/pg_archive/full"
fsToCheck=$(realpath $(df $bkpdirBase | grep '^/' | cut -d' ' -f1))
prevday=$(date -d '1 day ago' +"%Y%m%d")
bkpdir="$bkpdirBase/${dtstamp}"
pgdatadir="/var/pg_base/PostgreSQL/9.6/data"
pg_bkp_name="base.tar.gz"
gpg_file_name="base.tar.gz.gpg"
host=$HOSTNAME
GPG_PHRASE="#{var_gpg_pass}#"
############ Azure Hooks #################
AZ_CONTAINER_NAME="#{var_az_storage_acct_container}#"
AZ_STORAGE_ACCOUNT="#{var_az_storage_acct_name}#"
AZ_KV_MSI_URI="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net"
AZ_KV_URI="https://#{var_az_kv_name}#.vault.azure.net/secrets/#{var_sasstd_secret_name}#?api-version=2016-10-01"
################ EMAIL ####################
IP=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
smtp_addr="smtp.us.deloitte.com:25"
dba_team_adr="#{var_dba_mail_addr}#"
#### Place holders #### 
AZ_STORAGE_KEY=""
ERR=1
SUCCESS=""
# Number of days to keep daily backups
# following variable can be used to have it more flexible: DAYS_TO_KEEP="#{var_bkp_days2keep}#"
DAYS_TO_KEEP="0" # to address current backup policy
# cleanup pattern for old base backups
regexBackupRemoval=${bkpdirBase}'/[0-9]{8}$'

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | tee -a $logdir/$logfile $TMPFILE
}

## send mail
#######################
function send_mail {
    subj=$1
    message=$2
    (echo "${message}:"; cat $TMPFILE;) | mailx -S smtp=$smtp_addr -s "$subj" $dba_team_adr
}

## exits on failure
#######################
function fatal {
        SUCCESS=1
        logit "$*" 
        summary
        exit $ERR
} 

## cleans backup files out of local storage for today before proceeding with today's backup again
#######################
function clean_up {
    # remove files
    logit "     clean_up: Removing backup files: $bkpdir"
    rm -rf $bkpdir || logit "     cannot remove $bkpdir. Exit code: $?"
}

## cleans backup files out of local storage older than DAYS_TO_KEEP
#######################
function clean_up_old_backups {
    # sanity check for the presents of bkpdirBase=/var/pgads/pg_archive/full before starting cleaning process
    [ -d "$bkpdirBase" ] || fatal "   bkpdirBase=[$bkpdirBase] is not found"
    # do clean_up of current base backup folder:
    clean_up
    # remove files
    logit "     clean_up_old_backups: Removing backup files older than $DAYS_TO_KEEP days from $bkpdirBase"
    find $bkpdirBase -type d -daystart -regextype posix-egrep -regex $regexBackupRemoval -mtime +${DAYS_TO_KEEP} -prune -print0 |
                while IFS= read -r -d '' file_p; do logit "     Directory $file_p will be removed"; done
    find $bkpdirBase -type d -daystart -regextype posix-egrep -regex $regexBackupRemoval -mtime +${DAYS_TO_KEEP} -prune -exec rm -rf {} \+ -print || 
                logit "     cannot remove $bkpdirBase files older than $DAYS_TO_KEEP. Exit code: $?"
}

# cleans up of backup files from local storage in case of INT TERM signals received earlier then planned
trap "[ -d \"${bkpdir}\" ] && clean_up" INT SIGINT TERM
# cleans up tmp file in case of earlier exit than expected
trap "[ -f \"${TMPFILE}\" ] && rm $TMPFILE" EXIT

## used to create directory
## usage: createDir /thedirectorytocreate
#########################
function createDir {
    logit "     createDir: Creating $1"
    dir=$1      # the directory to create
    # create dir
    if  [ ! -d $dir ]; then
        mkdir -p $dir || fatal "     createDir: can't create $dir"
        # Set permissions
        chown -R $pgid:$pgid $dir || fatal "     createDir: can't set permissions ${pgid}:${pgid} on $dir"
    fi
    logit "     createDir: Done. Exit code: $?"
}

## create dirs
#######################
function createbkpdir {
    # create working dir if not exists
    if [ ! -d "$bkpdir" ]; then
        logit "     createbackupdir:  Creating $bkpdir"
        createDir $bkpdir
    fi
}

## create cronlog location if not exists
#######################
function createlogdir {
    if [ ! -d "$logdir" ]; then
        logit "     createlogdir:  Creating $logdir"
        createDir $logdir
    fi
}

## create a lock to eliminate multiple instances of the same program running
#########################
function flock {
    if [ -f $PIDFILE ]; then
        PID=$(cat $PIDFILE)
        ps -p $PID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            fatal "Another instance is already running!!!"
        else
            ## Process not found assume not running
            echo $$ > $PIDFILE
            if [ $? -ne 0 ]; then
                fatal "Could not create PID file for $me program"
            fi
        fi
    else
        echo $$ > $PIDFILE
        if [ ${?} -ne 0 ]; then
            fatal "Could not create PID file for $me program"
        fi
    fi
}

## This function checks that we're running as a correct user
#######################
function checkUser {
    id=$1
    currentId=$(id -un)
    if [ "$id" != "$currentId" ]; then 
        fatal "$me program should be launched as $id and not $currentId user"
    fi
}

## This function:
## 1. locks running instance of the script per user 
## 2. checks that we're running as a $pgid user
#######################
function checkNlock { 
    checkUser $pgid 
    flock 
}

## This function:
## store previous size of backup in vars before deleting it
#######################
function recordbackupsize {
    if [[ -d "${bkpdirBase}/${prevday}" ]]; then
        prevday_size=$(du -skx ${bkpdirBase}/${prevday} | awk '{print $1}')
        prevday_sizeH=$(du -shx ${bkpdirBase}/${prevday} | awk '{print $1}')
    fi
}

## This function:
## checks if we have enough space to proceed with backup
#######################
function checkdiskspace {
    if [[ -n "${prevday_size}" ]]; then
        available_size=$(df -kP $fsToCheck | awk '!/^Filesystem/ {print $4}')
        if [[ "${prevday_size}" -gt "${available_size}" ]]; then
            available_sizeH=$(df -hP $fsToCheck | awk '!/^Filesystem/ {print $4}')
            logit "Add more disk space before proceeding with backup."
            logit "Yesterdays backup took  $prevday_sizeH."
            logit "But available space in $bkpdirBase on filesystem $fsToCheck is $available_sizeH only."
            fatal "Insufficient disc space for backup. Please address it before restarting $me again."
        fi
    fi
}

## Create pg_full backup
#######################
function pg_fullbackup {
    START=$(date +%s)
    logit "     pg_fullbackup: Prep: Looking for label $pgdatadir/backup_label.old "
    
    # backup label
    if [ -f $pgdatadir/backup_label.old ]; then
        logit "     pg_fullbackup: Prep: moving label $pgdatadir/backup_label.old to $pgdatadir/backup_label.old_$START"
        mv $pgdatadir/backup_label.old $pgdatadir/backup_label.old_$START
    fi
    
    logit "     pg_fullbackup: Prep: Looking for label $pgdatadir/backup_label "
    if [ -f $pgdatadir/backup_label ] ; then
        logit "     pg_fullbackup: Prep: Found $pgdatadir/backup_label. Database in BACKUP MODE."
        send_mail "BACKUP FAILED on ${host} ${IP}". "BACKUP FAILED on ${host} ${IP} REASON: Database already in BACKUP MODE." 
        exit $ERR
    fi

    logit "     pg_fullbackup: Creating pg_basebackup on '${host} ${IP} ' with name: $bkpdir/$pg_bkp_name"
    
    # run the backup
    pg_basebackup -h localhost -U $pgid -D $bkpdir -Ft -z -v -P -x
    if [[ ${?} -ne 0 ]]; then
        fatal "     pg_fullbackup: ERROR! pg_basebackup Failed."
    else
        logit "     pg_fullbackup: pg_basebackup Succeeded."
    fi
    logit "     pg_fullbackup: Exit Code: ${?}"
}

## encrypt backup
#######################
function encrypt_backup {
    logit "     encrypt_backup: Encrypting PG_Backup"
    if [ -f $bkpdir/$pg_bkp_name ]; then
        logit "     encrypt_backup: Encrypting backup file: $bkpdir/$pg_bkp_name"
        # encrypt
        logit "     gpg --yes --batch --passphrase=<GPG_PHRASE> --symmetric --cipher-algo aes256 --compress-algo 2 -o $bkpdir/$gpg_file_name $bkpdir/$pg_bkp_name"
        gpg --yes --batch --passphrase=$GPG_PHRASE --symmetric --cipher-algo aes256 --compress-algo 2 -o $bkpdir/$gpg_file_name $bkpdir/$pg_bkp_name
        if [ ${?} -ne 0 ]; then
            fatal "     encrypt_backup: GPG Operation failed with code: ${?}"
        else
            logit "     encrypt_backup: GPG Operation succeeded."
        fi
    else
        fatal "     encrypt_backup: File: $bkpdir/$pg_bkp_name does not exist."
    fi
    logit "     encrypt_backup: Exit Code: ${?}"
}

## Get storage account key
#######################
function getStorageAcctKeyMSI {
    logit "    getStorageAcctKeyMSI:  Getting Storage Account Key from KeyVault"
    # getAccessToken
    token=`curl $AZ_KV_MSI_URI -H Metadata:true | grep \"access_token\" | cut -d':' -f 2 | cut -d"\"" -f 2`
    if [[ ! -z "$token" ]]; then
        logit "    getStorageAcctKeyMSI:  Successfully obtained Access Token."
        logit "    getStorageAcctKeyMSI:  Calling $AZ_KV_URI for Storage Account Key"
        # get secret
        AZ_STORAGE_KEY=`curl -H 'Authorization: Bearer '$token -X GET $AZ_KV_URI | grep \"value\" | cut -d':' -f 2 | cut -d',' -f 1 | cut -d"\"" -f 2`
        if [[ -z "$AZ_STORAGE_KEY" ]]; then
            # bail out
            fatal "    getStorageAcctKeyMSI:  API Call to $AZ_KV_URI for Storage Account Key failed."
        fi
    else
        fatal "    getStorageAcctKeyMSI:  Error! API Call to $AZ_KV_MSI_URI for Access Token failed."
    fi 
    logit "    getStorageAcctKeyMSI: Exit Code: ${?}"
}

## upload pg_full_backup to Az
#######################
function upload_pg_fullbackup {
    
    if [ -f $bkpdir/$gpg_file_name ]; then
        logit "     upload_pg_fullbackup:  Uploading the file...$bkpdir/$gpg_file_name"
        az storage blob upload \
            --account-name $AZ_STORAGE_ACCOUNT \
            --container-name $AZ_CONTAINER_NAME/full/$dtstamp \
            --account-key $AZ_STORAGE_KEY \
            --file $bkpdir/$gpg_file_name --name $gpg_file_name
        if [ ${?} -eq 1 ]; then
            # bail out
            fatal "    upload_pg_fullbackup:  File upload failed."
        fi
    else
        fatal "upload_pg_fullbackup:  ERROR Uploading backup. File $bkpdir/$gpg_file_name doesn't exist."
    fi 
    logit "     upload_pg_fullbackup: Exit Code: ${?}"
} 

## summary   
#######################
function summary {
    echo -e "************** Base Backup Details  **************\n"
    echo -e "BASE BKP LOG.........:  $logdir/$pg_bkp_name.log"
    echo    "DATA DIRECTORY.......:  $pgdatadir"
    echo    "BACKUP LOCATION......:  $bkpdir"
    echo    "AZ STORAGE ACCT......:  $AZ_STORAGE_ACCOUNT"
    echo    "AZ CONTAINER_ROOT....:  $AZ_CONTAINER_ROOT_NAME"
    echo    "AZ CONTAINER NAME....:  $AZ_CONTAINER_NAME"
    echo    "FULL BKP FILE........:  $bkpdir/$pg_bkp_name"
    echo    "ENC FULL BKP FILE....:  $bkpdir/$gpg_file_name"

    logit "     summary:     BASE BKP LOG.........:  $logdir/$pg_bkp_name.log"
    logit "     summary:     DATA DIRECTORY.......:  $pgdatadir"
    logit "     summary:     BACKUP LOCATION......:  $bkpdir"
    logit "     summary:     AZ STORAGE ACCT......:  $AZ_STORAGE_ACCOUNT"
    logit "     summary:     AZ CONTAINER_ROOT....:  $AZ_CONTAINER_ROOT_NAME"
    logit "     summary:     AZ CONTAINER NAME....:  $AZ_CONTAINER_NAME"
    logit "     summary:     FULL BKP FILE........:  $bkpdir/$pg_bkp_name"
    logit "     summary:     ENC FULL BKP FILE....:  $bkpdir/$gpg_file_name"
    if [[ $SUCCESS -eq 0 ]]; then
        echo "`date`|`hostname`|${host} ${IP}|`basename $0`|true|Backup successfully" >> $logdir/$logfile 
    else
        logit "`date`|`hostname`|${host} ${IP} |`basename $0`|false|Backup was not successful" >> $logdir/$logfile 
        logit "     summary:    ERROR! Backup FAILED!"
        send_mail "BASEBACKUP FAILED on '${host} ${IP}"  "Basebackup failed on '${host} ${IP}. Please connect to server ASAP!"
    fi
    logit "     summary: Exit Code: ${?}"
}

## add cron-entry
#######################
function add_cron {
    # this entry only gets added once. ignored on subsequent runs
    if [[ $(crontab -l | grep "$me" 2>/dev/null |  wc -l) = "0" ]];  then
        (crontab -l; echo "0 4 * * * ${udir}/${me}") | crontab -
        if [ ${?} -ne 0 ]; then
            logit "  add_cron  :  Failed to add cron entry for $pgid to execute $me once a day"
        fi
    else
        crontab -l
    fi
    logit "     add_cron: Exit Code: ${?}"
}

## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$LOGFILE ***"
echo

createlogdir            # create log dir
checkNlock              # checking user and creating PID file
recordbackupsize        # recording how much space took previous day backup before deleting it
clean_up_old_backups    # cleaning old backup files older than DAYS_TO_KEEP
checkdiskspace          # checking if we have enough space to proceed with backup
createbkpdir            # backup directory
pg_fullbackup           # take full back-up
encrypt_backup          # encrypt full back-up
getStorageAcctKeyMSI    # retrieve SA Key via MSI
upload_pg_fullbackup    # upload back-up to storage account
summary                 # log a summary
add_cron                # add to cron


logit "Final Return Code: $?"

# return exit code
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

[ -f $PIDFILE ] && rm $PIDFILE
[ -f $TMPFILE ] && rm $TMPFILE

exit $?
