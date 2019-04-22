#!/bin/bash
# 

# Creates and imports updated extracted fiels to be used in Kira SDK 
# 
# Uses the SDK endpoints to create and import each field to be used in the SDK:
# 1. Create an empty field using the POST /fields method (note that name and description will be overwritten by import)
# 2. Import your extracted fields one at a time using the PUT /fields/${id}/models method, specifying the ${id} returned by the previous step.
# 
# input<required> -m <pathtomodels-list> 
# input<required> -t <token> 
# input<required> -e <sdkendpoint>
# ex: /opt/kira/fields/delete-custom-models.sh -m /opt/kira/fields/pathtomodels-list.lst -t <TOKEN> -e dargusai-ame-api.aaps.deloitte.com

############################################# 

#######################
## Script vars
#######################
today=`date +%m%d%Y`
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="."
logfile="$scriptname-$today.log"

## Kira system paths
proto="https://"
api_field_method="/sdk-api/v1/fields"

## Initialize variables to default values
pathtomodels=m
token=t
sdk_end_point=e
argsnum=$#

## helper function
#######################
function usage {
    echo -e "Usage: $scriptname -m <pathtomodels> -t <accestoken> -e <sdkendpoint>"
}

## Logger function
#######################
function logit {
    echo -e "$*"
    echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

## Check number of arguments; 3 pairs expected
#######################
function checkargs {
    if [ $argsnum -ne 6 ]; then
        echo -e \\n"Invalid Number of arguments"\\n
        usage 
        exit 2;
    fi
}

## Create an empty field record to SDK
## Given a path to extracted models
## Get each file and post/put to SDK
## input: field_id - the id of the model to delete 
## input: token - the token
## input: endpoint - the url
#######################
function deleteModel {
    field_id=$1
    token=$2
    sdk_end_point=$3

    field_url=$proto$sdk_end_point$api_field_method

    # Send DELETE command to remove models
    if [[ !  -z  $sdk_end_point  ]] || [[ !  -z  $token  ]]; then
        logit " $scriptname: op.deleteModel:    Removing field $field_id on $sdk_end_point"
        # make the call
        resp=$(/usr/bin/curl -k -sw "%{http_code}" -X DELETE --header "Accept: application/json"  "$field_url?field_id=$field_id&access_token= $token")
        # get the reponse code
        http_code="${resp:${#resp}-3}"
        body="${resp:0:${#resp}-3}"
        # log the response
        logit " $scriptname: op.deleteModel:    DELETE_RESPONSE: $resp"
        # log the response code
        logit " $scriptname: op.deleteModel:    DELETE_RESPONSE_CODE: $http_code"
        # if OK continue processing
        if [ ! $http_code = 204 ]; then
            logit " $scriptname: op.deleteModel:     ERROR! Unable to DELETE $field_id."
            logit " $scriptname: op.deleteModel:     ERROR! DELETE Response body: $body."
        fi
    fi
}

#######################
## Main processing
## Uploaded updated fields
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

checkargs     # args must be 6
 
## getopts
while getopts :m:t:e:h FLAG; do
    case $FLAG in 
        m) pathtomodels=$OPTARG ;;
        t) token=$OPTARG ;;
        e) sdk_end_point=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            help
            break
            ;;
    esac
done

shift "$((OPTIND-1))"

## Getfile and post/put to SDK
if  [ -f "$pathtomodels" ]; then

    logit " $scriptname:  Found list of models to delete: $pathtomodels."

    for fid in `cat $file`; do
        logit " $scriptname: Sending delete command to Kira SDK for field: $fid."
        deleteModel $fid $token $sdk_end_point
        sleep 2 # add delay
    done
else
   logit " $scriptname: No list of models to delete $pathtomodels. Exiting."
fi

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
