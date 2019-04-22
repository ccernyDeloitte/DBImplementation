#!/bin/bash
# 
# pg_backup
# 
# This script creates a full back_up of Postgres
# Usage: pg_install_wale.sh -k <AZ-STORAGE-ACCT-KEY> -a <STORAGE-ACCT-NAME> -p <STORAGE-ACCT-PREFIX>"
#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
LOGDIR="/var/pg_base/pg_utils/logs"
TIMESTAMP=$(date +%Y_%m_%d)
LOGFILE="$scriptname_${TIMESTAMP}.log"
PG_ID="postgres"
PGDATA="/var/pg_base/PostgreSQL/9.6/data"
WALTMP_DIR="/var/pgads/waltmp"
CRONLOG_LOCATION="/var/pg_base/pg_cron_logs"
HN=$HOSTNAME
################ EMAIL ####################
IP=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
SMTP_ADDR="smtp.us.deloitte.com:25"
#DBA_TEAM_EMAIL="#{var_dba_mail_addr}#"
DBA_TEAM_EMAIL="jlagman@deloitte.com"
SUCCESS=""

## Logger function
#######################
function createlogdir {
    # create working dir if not exists
    if [ ! -d "$WORKING_DIR" ]; then
        logit "     createlogdir:  Creating $WORKING_DIR"
        createDir $WORKING_DIR 
    fi

    # create cronlog location if not exists
    if [ ! -d "$LOGDIR" ]; then
        logit "     createlogdir:  Creating $LOGDIR"
        createDir $LOGDIR
    fi
}

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | tee -a $LOGDIR/$LOGFILE 
}

## used to create directory
## usage: createDir /thedirectorytocreate
#########################
function createDir {
    logit "     createDir: Creating $1"
    dir=$1      # the directory to create
    # create dir
    if /usr/bin/sudo [ ! -d $dir ]; then
        /usr/bin/sudo  mkdir -p $dir
        # Set permissions
        /usr/bin/sudo chown -R $PG_ID:$PG_ID $dir
    fi
    logit "     createDir: Done. Exit code: $?"
}

## exception handler
#######################
function exit_unless_success {
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        send_mail "BASEBACKUP FAILED on ${HN} ${IP}"  "BASEBACKUP FAILED on ${HN} ${IP} - [$BACKUP_NAME] An unknown error occurred while creating backup. Exit code: $exit_code"
        exit $exit_code
    fi
}

## send mail
#######################
function send_mail {
    subj=$1
    message=$2
    echo "$1" | mailx -S smtp=$SMTP_ADDR -s "$message" $DBA_TEAM_EMAIL
}

#TO DO Implement wal-e clean-up here
## cleans old backpup files
## find files older than 2 days and delete them
#######################
function clean_up {
    logit "     clean_up: Removing files older than 1 days..."
    #TO DO Implement wal-e clean-up here
    exit_unless_success
}

## Create pg_base backup
#######################
function pg_fullbackup {
    START=$(date +%s)
    
    #not sure if needed
    logit "     pg_fullbackup: Prep: Looking for label $PGDATA/backup_label.old "
    if [ -f $PGDATA/backup_label.old ]; then
        logit "     pg_fullbackup: Prep: moving label $PGDATA/backup_label.old to $PGDATA/backup_label.old_$START"
        mv $PGDATA/backup_label.old $PGDATA/backup_label.old_$START
    fi
    
    #not sure if needed
    logit "     pg_fullbackup: Prep: Looking for label $PGDATA/backup_label "
    if [ -f $PGDATA/backup_label ] ; then
        logit "     pg_fullbackup: Prep: Found $PGDATA/backup_label. Database in BACKUP MODE."
        send_mail "BACKUP FAILED on ${HN} ${IP}". "BACKUP FAILED on ${HN} ${IP} REASON: Database already in BACKUP MODE." 
        exit 0
    fi

    logit "     pg_fullbackup: Creating pg_basebackup on '${HN} ${IP} ' with name: $WORKING_DIR/$BACKUP_NAME"
    #relcate TMPDIR
    TMPDIR='/var/pgads/waltmp'; export TMPDIR
    /opt/wal-e/bin/envdir /etc/wal-e.d/env env /opt/wal-e/bin/wal-e backup-push /var/pg_base/PostgreSQL/9.6/data >> "$LOGDIR/$BACKUP_NAME.log"   

    result=${?}
    
    if [ ${result} -eq 1 ]; then
        SUCCESS=1
        send_mail "BASEBACKUP FAILED on '${HN} ${IP}"  "Basebackup failed on '${HN} ${IP}. Please connect to server ASAP! "
    else
        SUCCESS=0
        logit "     pg_fullbackup: SUCCESS=0. Sending success email"
        send_mail "BASEBACKUP COMPLETED Successfully on ${HN} ${IP}". "Basebackup completed successfully on ${HN} ${IP}. Enjoy your day."
    fi
}

## summary   
#######################
function summary {
    if [ $SUCCESS -eq 0 ]; then
        echo -e "************** Base Backup Details  **************\n"
        echo -e "BASE BKP LOG.........:  $LOGDIR/$BACKUP_NAME.log"
        echo    "DATA DIRECTORY.......:  $PGDATA"
        echo    "BACKUP LOCATION......:  $WORKING_DIR"
        echo    "AZ STORAGE ACCT......:  $AZ_STORAGE_ACCOUNT"
        echo    "AZ CONTAINER_ROOT....:  $AZ_CONTAINER_ROOT_NAME"
        echo    "AZ CONTAINER NAME....:  $AZ_CONTAINER_NAME"
        echo    "FULL BKP FILE........:  $WORKING_DIR/$ARCHIVE_NAME"

        logit "     summary:     BASE BKP LOG.........:  $LOGDIR/$BACKUP_NAME.log"
        logit "     summary:     DATA DIRECTORY.......:  $PGDATA"
        logit "     summary:     BACKUP LOCATION......:  $WORKING_DIR"
        logit "     summary:     AZ STORAGE ACCT......:  $AZ_STORAGE_ACCOUNT"
        logit "     summary:     AZ CONTAINER_ROOT....:  $AZ_CONTAINER_ROOT_NAME"
        logit "     summary:     AZ CONTAINER NAME....:  $AZ_CONTAINER_NAME"
        logit "     summary:     FULL BKP FILE........:  $WORKING_DIR/$ARCHIVE_NAME"
        echo "`date`|`hostname`|${HN} ${IP}|`basename $0`|true|Backup successfull" >>$LOGDIR/cronjobs.csv 
   else
      logit "`date`|`hostname`|${HN} ${IP} |`basename $0`|false|Backup was not successful" >>$LOGDIR/cronjobs.csv
      logit "     summary:    Backup was not successful!"
      send_mail "Backup failed on ${HN} ${IP}" "Backup failed on ${HN} ${IP}" < $LOGDIR/cronjobs.csv
   fi
}

## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $LOGDIR/$LOGFILE ***"
echo

while getopts :k:a:p FLAG; do
    case $FLAG in 
        k) AZKEY=$OPTARG ;;
        a) AZACCT=$OPTARG ;;
        p) PRFX=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            usage 
            break
            ;;
    esac
done

createlogdir
pg_fullbackup
summary
clean_up

logit "Final Return Code: $?"

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
