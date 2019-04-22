#!/bin/bash
# 
# Upgrade extracted models to r43, sdk-api
# 
# Target NODE: Web-API
# input<required> -i <modelsToUpgradeDirectory> 
# input<required> -o <upgradedModelsDirectory> 
# ex: /opt/kira/fields/upgrade-models.sh -i /opt/kira/fields/perm_text_and_value_models -o /opt/kira/fields/upgraded-fields 
############################################# 

#######################
## Script vars
#######################
today=`date +%m%d%Y`
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="."
logfile="$scriptname-$today.log"
#  kira command jar
kiracmdjar="/opt/kira/jars/kira.cmd.jar"
#  kira conf jar
kiraconfjar="/opt/kira/jars/kira.configuration.jar"
# Initialize variables to default values
modelsToUpgrade=i
upgradedModels=o
usage=false
argsnum=$#

## helper function
#######################
function usage {
    /usr/bin/sudo echo -e "Usage: $scriptname -i <modelsToUpgrade> -o <upgradedModels>"
}

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

## Check number of arguments; 2 pairs expected
#######################
function checkargs {
    if [ $argsnum -ne 4 ]; then
        echo -e \\n"Invalid Number of arguments"\\n
        usage 
        exit 2;
    fi
}

#######################
## Main processing
## upgrade models
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

checkargs     # args must be 4
umask 022     # set umask

## getopts
while getopts :i:o:h FLAG; do
    case $FLAG in 
        i) modelsToUpgrade=$OPTARG ;;
        o) upgradedModels=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            help
            break
            ;;
    esac
done

shift "$((OPTIND-1))"

## Upgrade models 
if [[ -d "$modelsToUpgrade" && "$upgradedModels" ]]; then
    # export it
    modelsToUpgradeCount=$(/bin/ls $modelsToUpgrade | xargs -n1 basename | wc -l) 

    logit " $scriptname: op.modelsToUpgrade: Path to models: $modelsToUpgrade"
    logit " $scriptname: op.modelsToUpgrade: Path to upgraded models: $upgradedModels"
    logit " $scriptname: op.modelsToUpgrade: Found $modelsToUpgradeCount models to upgrade."
     
    # upgradedModels -- needs to land in /opt/kira/fields/upgraded-fields  
    /bin/ls $modelsToUpgrade | xargs -n1 basename | xargs -n1 -I% -t java -cp ${kiraconfjar}:${kiracmdjar} kira.cmd.core upgrade-field ${modelsToUpgrade}/% ${upgradedModels}/%

    logit " $scriptname: op.upgradedModels: Sueccessfully updated $/bin/ls $modelsToUpgradeCount  models."
else
    logit "$scriptname:    ERROR! Directories $modelsToUpgrade doesn't exist. Nothing to do."
fi

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
