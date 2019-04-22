#!/bin/bash
# 
# pg_restore.sh
# 
# This script downloads a backup file and applies it
# Usage: pg_restore.sh  
#######################
## Script vars
#######################
logdir="/var/pg_base/pg_utils/logs"
dtstamp=$(date +"%Y%m%d")
logfile="pg_restore${dtstamp}.log"
pgid="postgres"
pgdatadir="/var/pg_base/PostgreSQL/9.6/data"
pgxlogdir=$pgdatadir/pg_xlog
bkpdir="/var/pgads/pg_archive/${dtstamp}/full"
pgdatadir="/var/pg_base/PostgreSQL/9.6/data"
pglocaltmpdir="/var/pgads/pg_archive/full/emergency/${dtstamp}"
pgrestoredir="/var/pgads/pg_archive/full/${dtstamp}"
pg_restore_name="base.tar.gz"
gpg_file_name="base.tar.gz.gpg"
GPG_PHRASE="#{var_gpg_pass}#"
############ Azure Hooks #################
AZ_CONTAINER_NAME="#{var_az_storage_acct_container}#"
AZ_STORAGE_ACCOUNT="#{var_az_storage_acct_name}#"
AZ_KV_MSI_URI="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net"
AZ_KV_URI="https://#{var_az_kv_name}#.vault.azure.net/secrets/#{var_sasstd_secret_name}#?api-version=2016-10-01"
#### Place holders #### 
AZ_STORAGE_KEY=""
SUCCESS=""

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | tee -a $logdir/$logfile 
}

## create dirs
#######################
function createworkdir {
    # create working dir if not exists
    if [ ! -d "$pgrestoredir" ]; then
        logit "     createlogdir:  Creating $pgrestoredir"
        createDir $pgrestoredir 
    fi

    if [ ! -d "$pglocaltmpdir" ]; then
        logit "     createlogdir:  Creating $pglocaltmpdir"
        createDir $pglocaltmpdir 
    fi
}

## used to create directory
## usage: createDir /thedirectorytocreate
#########################
function createDir {
    logit "     createDir: Creating $1"
    dir=$1      # the directory to create
    # create dir
    if  [ ! -d $dir ]; then
        mkdir -p $dir
        # Set permissions
        chown -R $pgid:$pgid $dir
    fi
    logit "     createDir: Done. Exit code: $?"
}

## Get storage account key
#######################
function getStorageAcctKeyMSI {
    logit "    getStorageAcctKeyMSI:  Getting Storage Account Key from KeyVault"
    # getAccessToken
    token=`curl $AZ_KV_MSI_URI -H Metadata:true | grep \"access_token\" | cut -d':' -f 2 | cut -d"\"" -f 2`
    if [[ ! -z $token ]]; then
        logit "    getStorageAcctKeyMSI:  Got token."
        logit "    getStorageAcctKeyMSI:  Calling $AZ_KV_URI"
        # get secret
        AZ_STORAGE_KEY=`curl -H 'Authorization: Bearer '$token -X GET $AZ_KV_URI | grep \"value\" | cut -d':' -f 2 | cut -d',' -f 1 | cut -d"\"" -f 2`
        if [ ${?} -eq 1 ]; then
            logit "    getStorageAcctKeyMSI:  API Call to $AZ_KV_URI failed."
            # bail out
            exit 1 
    else
        logit "    getStorageAcctKeyMSI:  Error! API Call to $AZ_KV_MSI_URI failed."
        exit 1 
    fi 
    logit "     getStorageAcctKeyMSI: Exit Code: ${?}"
}

## download pg_xlog to Az
#######################
function downlog_pg_xlog {
    
    if [ -d $pgxlogdir ]; then
        logit "     downlog_pg_xlog:  Download pg_xlog...$pgxlogdir/$pg_xlog_name"
        az storage blob download \
            --account-name $AZ_STORAGE_ACCOUNT \
            --container-name $AZ_CONTAINER_NAME/log/$dtstamp \
            --account-key $AZ_STORAGE_KEY \
            --file $pgxlogdir/$pg_xlog_name --name $pg_xlog_name
        if [ ${?} -eq 1 ]; then
            logit "    downlog_pg_xlog:  File download failed."
            SUCCESS=1
            # bail out
            exit 1
        fi
    else
        logit "downlog_pg_xlog:  ERROR downloading backup. File $bkpdir/$pg_bkp_name doesn't exist."
        SUCCESS=1
        exit 1
    fi 
    logit "     downlog_pg_xlog: Exit Code: ${?}"
} 

## stop pg
#######################
function stop_pg {
    systemctl stop postgresql-9.6
}

## start pg
#######################
function start_pg {
    systemctl start postgresql-9.6
}

## download pg_full_backup from AZ
#######################
function download_pg_fullbackup {
    logit "     download_pg_fullbackup:  Downloading file $gpg_file_name from Storage"
    az storage blob download \
        --account-name $AZ_STORAGE_ACCOUNT \
        --container-name $AZ_CONTAINER_NAME/full/$dtstamp \
        --account-key $AZ_STORAGE_KEY \
        --file $pgrestoredir/$gpg_file_name --name $gpg_file_name
    if [ ${?} -eq 1 ]; then
        SUCCESS=1
        logit "    download_pg_fullbackup:  File downloading failed."
        # bail out
        exit 1
    else
        #check for the file
        if [ ! -f $pgrestoredir/$gpg_file_name ]; then
            logit "    download_pg_fullbackup: Expected File $pgrestoredir/$gpg_file_name doesn't exist!"
        fi
    fi
    logit "     download_pg_fullbackup: Exit Code: ${?}"
} 

## decrypt
#######################
function decrypt_backup {
    logit "     decrypt: Decrypting PG_Backup"
    if [ -f $pgrestoredir/$pg_restore_name ]; then
        logit "     decrypt: Encrypting backup file: $pgrestoredir/$pg_restore_name to $pgrestoredir/$gpg_file_name"
        # decrypt
        gpg --yes --batch --passphrase=$GPG_PHRASE -o $pgrestoredir/$pg_restore_name -d $pgrestoredir/$gpg_file_name
        if [ ${?} -eq 1 ]; then
            SUCCESS=1
            logit "     decrypt: GPG Operation failed with code: ${?}"
            exit 1
        else
            SUCCESS=0
            logit "     decrypt: GPG Operation succeeded."
        fi
    else
        logit "     decrypt: File: $pgrestoredir/$pg_restore_name does not exist."
        SUCCESS=1
        exit 1
    fi
    logit "     decrypt: Exit Code: ${?}"
}

## Restore DB
#######################
function restore_db {
     if [ -d "$pglocaltmpdir" ]; then
        logit "     restore_db:  Creating LOCAL backup of configs from $pgdatadir prior to restore"
        
        #copy configs
        logit "     restore_db:  Copying $pgdatadir/pg_hba.conf to $pglocaltmpdir"
        cp -p $pgdatadir/pg_hba.conf $pglocaltmpdir/.
        logit "     restore_db:  $pgdatadir/postgresql.conf to $pglocaltmpdir"
        cp -p $pgdatadir/postgresql.conf $pglocaltmpdir/.

        if [ ${?} -eq 0 ]; then
            # empty out current datadir
            logit "     restore_db:  removing pg cluster data ($pgdatadir)"
            rm -rf $pgdatadir/*
        else
            logit "     restore_db:  LOCAL backup failed."
            SUCCESS=1
            exit 1
        fi
    fi

    # extract archive
    if [[ -f "$pgrestoredir/$pg_restore_name" ]]; then
        logit "     restore_db:  Extract archive: $pgrestoredir/$pg_restore_name to $pgdatadir"
        tar -xvf $pgrestoredir/$pg_restore_name -C $pgdatadir
        if [ ${?} -eq 0 ]; then
            logit "     restore_db:  Extract complete."

            sleep 10
            #copy configs
            logit "     restore_db:  Copying conf:  $pglocaltmpdir/pg_hba.conf to $pgdatadir"
            cp -p $pglocaltmpdir/pg_hba.conf $pgdatadir/.
            logit "     restore_db:  Copying conf:  $pglocaltmpdir/postgresql.conf to $pgdatadir"
            cp -p $pglocaltmpdir/postgresql.conf $pgdatadir/.

            # set perms
            logit "     restore_db:  Setting perms on $pgdatadir "
            chown -R $pgid: $pgdatadir
            chmod -R 700 $pgdatadir
        fi 
    else
        logit "     restore_db: Error! File $pgrestoredir/$pg_restore_name not found."
        exit 1
    fi
}

## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$LOGFILE ***"
echo

createworkdir                # create work dirs
getStorageAcctKeyMSI         # retrieve SA Key via MSI
download_pg_fullbackup       # download bkp
decrypt_backup               # decrypt bkp

if [[ $SUCCESS -eq 0 ]]; then
    stop_pg                  # stop Postgres
    restore_db               # restore Postgres
    start_pg                 # start Postgres
fi 

logit "Final Return Code: $?"

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?