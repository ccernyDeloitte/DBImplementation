#!/bin/bash
# 
#  az_getazblobs.sh
#
# 1. Get a blob from Azure Storage
# 2. Move combined file to a config path
############################################# 

#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="/mnt/resource"
logfile="$scriptname.log"

#Initialize variables to default values
usage=false
shareName=s
path=p
accountName=n
key=k
outpathfilename=f
argsnum=$#

## helper function
#######################
function usage {
    echo -e "Usage: $scriptname -rg <resourcegroup>"
}

## Logger function
#######################
function logit {
    echo -e "$*"
    echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" >> $logdir/$logfile
}

## Check number of arguments; 1 pair expected
#######################
function checkargs {
    if [ $argsnum -ne 2 ]; then
        echo -e \\n"Invalid Number of arguments"\\n
        usage 
        exit 2;
    fi
}

## Check script setup
#######################
function checksetup {
    ## Verify User Executing Script is root
    if [[ $EUID -ne 0 ]]; then
        logit "checksetup: Error: This script must be run as root" 1>&2
        exit $?
    fi
}

##  download file
#######################
function getFile {
    $1     # shareName
    $2     # path
    $3     # accountName
    $4     # key
    $5     # outPath
    az storage file download -s $1 -p $2 --account-name $3 --account-key $4 --dest $5
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

checksetup          # run as root
checkargs           # args must be 6
umask 022           # set umask

## getopts
wwhile getopts :s:k:f:h FLAG; do
    case $FLAG in 
        s) shareName=$OPTARG ;;
        p) path=$OPTARG ;;
        n) accountName=$OPTARG ;;
        k) key==$OPTARG ;;
        f) outpathfilename=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            help
            break
            ;;
    esac
done

shift "$((OPTIND-1))"

checkargs             # check args
# az storage file download -s arguspkgs -p pkgs/createkira/kira-r43/fields-R44-2018-04-09.jar --account-name ameargusrpmrepo --account-key #KEY --dest fields-R44-2018-04-09.jar 
getFile $shareName $path $accountName $key $outpathfilename

