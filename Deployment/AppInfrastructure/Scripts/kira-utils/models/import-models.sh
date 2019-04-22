#!/bin/bash
# 

# Creates and imports updated extracted fiels to be used in Kira SDK 
# 
# Uses the SDK endpoints to create and import each field to be used in the SDK:
# 1. Create an empty field using the POST /fields method (note that name and description will be overwritten by import)
# 2. Import your extracted fields one at a time using the PUT /fields/${id}/models method, specifying the ${id} returned by the previous step.
# 
# input<required> -m <pathtomodels> 
# input<required> -t <token> 
# input<required> -e <sdkendpoint>
# ex: /opt/kira/fields/import-models.sh -m /opt/kira/fields/upgraded-fields/ -t <TOKEN> -e dargusai-ame-api.aaps.deloitte.com

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
## input: filename - the modelfilename
## input: filepath - parent folder of the filename
#######################
function uploadModel {
    filename=$1
    filepath=$2
    token=$3
    sdk_end_point=$4

    field_url=$proto$sdk_end_point$api_field_method

    # Sequential operation, POST then PUT
    # Failure results in orphaned records - Field Records with no models
    # POST to create an empty field for a given model
    if [ !  -z  $sdk_end_point  ] || [ !  -z  $token  ]; then
        logit " $scriptname: op.uploadModel:    Creating field at on $sdk_end_point"
        # make the call
        resp=$(/usr/bin/sudo /usr/bin/curl -k -sw "%{http_code}" -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: Bearer $token" --data '{"field_name":"string","description":"string"}' $field_url)
        # get the reponse code
        http_code="${resp:${#resp}-3}"
        # log the response code
        logit " $scriptname: op.uploadModel:    POST_RESPONSE_CODE: $http_code"

        # if OK continue processing
        if [ $http_code = 201 ]; then
            # assign response body to variable
            body="${resp:0:${#resp}-3}"
            # parse out the "field_id" from the body
            fid=$(echo $body | /usr/bin/sudo /bin/sed -e 's,},,g'| /usr/bin/sudo /bin/awk -F':' '{ print $2 }')   
            logit " $scriptname: op.uploadModel:    POST_RESPONSE field_id: $fid"
            
            # check for null
            if [ ! -z $fid ]; then
                # assemble the PUT url
                put_url=$field_url"/"$fid"/models"
                # adding sleep to not overwhelm the system.
                sleep 3
                logit " $scriptname: op.uploadModel:      Uploading file: $filename to $put_url" 
                #putresp=$(/usr/bin/curl -k -sw "%{http_code}" -X PUT -d @$filepath$filename $puturl)
                putresp=$(/usr/bin/sudo /bin/curl -k -sw "%{http_code}" -X PUT --header "Accept: application/json" --header "Content-Type: multipart/form-data" --header "Authorization: Bearer $token" --form "file=@$filepath$filename" $put_url)
                # get the reponse code
                putresp_http_code="${putresp:${#putresp}-3}"
                # check response code
                if [[ $putresp_http_code = 204 ]]; then
                    logit " $scriptname: op.uploadModel:    Upload Successful"
                    logit " $scriptname: op.uploadModel:      PUT_RESPONSE_CODE: $putresp_http_code."
                else
                    # request to import the field's model failed.
                    logit " $scriptname: op.uploadModel:    Upload FAILED!"
                    logit " $scriptname: op.uploadModel:      PUT_RESPONSE_CODE: $putresp_http_code."
                    logit " $scriptname: op.uploadModel:      PUT_RESPONSE_BODY: ${putresp}."
                fi
            fi
        else
            logit " $scriptname: op.uploadModel:     ERROR! Unable to get field_id."
            logit " $scriptname: op.uploadModel:     ERROR! POST Response body: $body."
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

## Given a path to extracted models
## Get each file and post/put to SDK
if /usr/bin/sudo [ -d "$pathtomodels" ]; then
    # get count
    fileCount=$(/usr/bin/sudo /bin/ls $pathtomodels | /usr/bin/sudo xargs -n1 basename | wc -l)

    logit " $scriptname:  Found $fileCount file to upload."
    
    # get a list of fields from $pathtomodels and POST/PUT the model to SDK
    for fn in `/usr/bin/sudo /bin/ls $pathtomodels | /usr/bin/sudo xargs -n1 basename`; do
        uploadModel $fn $pathtomodels $token $sdk_end_point
    done
else
   logit " $scriptname: No extracted fields found in path $pathtomodels. Exiting."
fi

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
