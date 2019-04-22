#!/bin/bash
# encrypt-kira-cred.sh
# script that creates encrypted kira config passwords
# Must run on a Kira node. 
# 1. Go the zookeeper 165
# 2. cd /opt/kira/jars
# 3. run command: java -cp kira.configuration-1.0.jar:de.pwd-2.0.0-standalone.jar de.pwd.core
# 4. Enter a password that is easy
# 5. Encrypted password provided.
# $1 = the string to encrypt
############################################# 
## Script vars
#######################
logfile="encrypt-kira-cred.log"

# Initialize variables to default values
#######################
usage=false
argsnum=$#
CRED=c

## helper function
#######################
function usage {
    /usr/bin/sudo echo -e "Usage: encrypt-kira-cred.sh -c <STRING_TO_ENCRYPT>"
    echo ""
}

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logfile
  chmod 600 $logfile
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

# Encrypt passed-in string
# run manually for now.
# java app doesn't appear to accept in-coming args from bash
# or I don't yet know how to do it properly
#######################
function encrypt {
  logit "encrypt: Encrypting $CRED"
  echo ""
  cd /opt/kira/jars/
  echo "Current directory is:    `pwd`"
  java -cp kira.configuration.jar:de.pwd-2.0.0-standalone.jar de.pwd.core
  echo ""
  logit "encrypt:  Done. Exit code: $?"
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
        c) CRED=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            usage 
            break
            ;;
    esac
done

shift "$((OPTIND-1))"

checkargs
encrypt
 
logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?