#!/bin/bash
# regen-apikey.sh
# script that generates the API Key
#
# Rotates the KIRA API-Token
# $1 = the database host
############################################# 

#######################
## Script vars
#######################
logfile="regen-apikey.sh.log"

#######################
# Initialize variables to default values
#######################
usage=false
argsnum=$#
DBHOST=d

#######################
## helper function
#######################
function usage {
    /usr/bin/sudo echo -e "Usage: regen-apikey.sh -d <DATABASE_HOST_IP>"
    echo ""
}

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logfile
  chomd 600 $logfile
}

## Check number of arguments; 3 pairs expected
#######################
function checkargs {
    if [ $argsnum -ne 2 ]; then
        echo -e \\n"Invalid Number of arguments"\\n
        echo ""
        usage 
        exit 1;
    fi
}

#######################
# create user kira with id of 500
#######################
function regenkey {
  logit "regenkey: Generating new API Key"
  echo ""
  cd /opt/kira/jars/
  echo "Current directory is:    `pwd`"
  java -cp kira.configuration.jar:kira.cmd.jar kira.cmd.core sdk-update-token --db-server $DBHOST:5432 --firm-id 1
  echo ""
  logit "regenkey:  Done. Exit code: $?"
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

#######################
## getopts
#######################
while getopts :d:h FLAG; do
    case $FLAG in 
        d) DBHOST=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            usage 
            break
            ;;
    esac
done

shift "$((OPTIND-1))"

checkargs
regenkey
 
logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?