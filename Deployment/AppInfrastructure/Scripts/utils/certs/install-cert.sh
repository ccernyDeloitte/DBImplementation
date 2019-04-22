#!/bin/bash
# 
# creates a .PEM file from pfx
# 
# 1. Use openssl to dump out the cert and key in the same file
# 2. Move combined file to a config path
############################################# 

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="install-cert.sh.log"
#Initialize variables to default values
pathtocert=c
password=p
outfilename=f
usage=false
argsnum=$#

## helper function
#######################
function usage {
    echo -e "Usage: $scriptname -c <pathtocert> -p <password> -f <outfilename>"
}

## Logger function
#######################
function logit {
    echo -e "$*"
    echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" >> $logdir/$logfile
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
## ## Export PFX to combined PEM format
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
while getopts :c:p:f:h FLAG; do
    case $FLAG in 
        c) pathtocert=$OPTARG ;;
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
if [[ -f "$pathtocert" && "$password" ]]; then
    logit "$scriptname: Attempting export operation"
    logit "$scriptname:    PFX: $pathtocert"
    logit "$scriptname:    OUT: $outfilename"
    # export it
    /bin/openssl pkcs12 -in $pathtocert -out $outfilename -nodes -password pass:$password
fi