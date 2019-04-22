#!/bin/bash
# 
# pg_archive_xlog
# 
# This script creates a uploads pg_xlogs
# Usage: pg_archive_xlog.sh <path_to_pg_xlog> <pg_xlog_name> 
#######################
## Script vars
#######################
logdir="/var/pg_base/pg_utils/logs"
dtstamp=$(date +"%Y%m%d")
logfile="pg_xlog_backup.log"
pgid="postgres"
pgxlogdir=/var/pg_base/PostgreSQL/9.6/data/pg_xlog
pg_xlog_name=$1
############ Azure Hooks #################
AZ_CONTAINER_NAME="#{var_az_storage_acct_container}#"
AZ_STORAGE_ACCOUNT="#{var_az_storage_acct_name}#"
AZ_KV_MSI_URI="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net"
AZ_KV_URI="https://#{var_az_kv_name}#.vault.azure.net/secrets/#{var_sasstd_secret_name}#?api-version=2016-10-01"
#### Place holders #### 
AZ_STORAGE_KEY=""

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | tee -a $logdir/$logfile 
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
            logit "    getStorageAcctKeyMSI:  API Call to $AZ_KV_URI for Storage Account Key failed."
            # bail out
            exit 1 
        fi
    else
        logit "    getStorageAcctKeyMSI:  Error! API Call to $AZ_KV_MSI_URI for Access Token failed."
        exit 1 
    fi 
    logit "    getStorageAcctKeyMSI: Exit Code: ${?}"
}

## upload pg_xlog to Az
#######################
function upload_pg_xlog {
    
    if [ -f $pgxlogdir/$pg_xlog_name ]; then
        logit "    upload_pg_xlog:  Uploading the pg_xlog...$pgxlogdir/$pg_xlog_name"
        az storage blob upload \
            --account-name $AZ_STORAGE_ACCOUNT \
            --container-name $AZ_CONTAINER_NAME/log/$dtstamp \
            --account-key $AZ_STORAGE_KEY \
            --file $pgxlogdir/$pg_xlog_name --name $pg_xlog_name
        if [ ${?} -eq 1 ]; then
            logit "    upload_pg_xlog:  File upload failed."
            # bail out
            exit 1
        fi
    else
        logit "    upload_pg_xlog:  ERROR Uploading backup. File $bkpdir/$pg_bkp_name doesn't exist."
        exit 1
    fi 
    logit "    upload_pg_xlog: Exit Code: ${?}"
} 

## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$LOGFILE ***"
echo

getStorageAcctKeyMSI    # retrieve SA Key via MSI
upload_pg_xlog          # upload back-up file to storage account

logit "Final Return Code: $?"

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
