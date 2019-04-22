#!/bin/bash
# 
#  az_getazvms.sh
#
# 1. gets a list of vms for a given RG
# 2. Move combined file to a config path
############################################# 

#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="/mnt/resource"
logfile="$scriptname.log"

#Initialize variables to default values
resourcegroup=rg
outfilename=f
usage=false
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

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

checksetup    # run as root
checkargs     # args must be 6
umask 022     # set umask

## getopts
wwhile getopts :s:k:f:h FLAG; do
    case $FLAG in 
        rg) resourcegroup=$OPTARG ;;
        p) password=$OPTARG ;;
        f) outfilename=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            help
            break
            ;;
    esac
done

shift "$((OPTIND-1))"


## Export PFX to combined PEM
#if [[ -f "$pathtocert" && "$password" ]]; then
#    logit "$scriptname: Attempting export operation"
#    logit "$scriptname:    PFX: $pathtocert"
#    logit "$scriptname:    OUT: $outfilename"
    # export it
#    /bin/openssl pkcs12 -in $pathtocert -out $outfilename -nodes -password pass:$password
#fi