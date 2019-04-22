#!/bin/bash
#
# Init-kira from baseline
#
# Target NODE: POSTGRESQL
#
# $1 = -u <de_passwd>
# $2 = -a <de_firmadm_passwd>
################################################################
# KIRA PROVIDED SOFTWARE
################################################################

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="init-kira-baseline.sh.log"
lckfile="/opt/kira/.init-kira.lck"
# Initialize variables to default values
#######################
usage=false
argsnum=$#
# note that the passwords must _not_ be encrypted
########################
DE_USER=de
DE_PASS=u
DE_FIRMADM_USER="de_firmadm"
DE_FIRMADM_PASS=a
pg_id="postgres"
TODAY=$( date +%d-%m-%Y )
FLYWAY="/opt/kira/flyway/flyway-4.2.0/flyway"
DRIVER="org.postgresql.Driver"
HOST="localhost"
URL="jdbc:postgresql://$HOST:5432"
MIGRATIONS="filesystem:/opt/kira/migrations/sql"
OPTS='-cleanOnValidationError=false -cleanDisabled=true -outOfOrder=false'

## Logger function
#######################
function logit {
    echo -e "$*"
    echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

## Check number of arguments; 3 pairs expected
#######################
function checkargs {
    if [ $argsnum -ne 4 ]; then
        echo -e \\n"Invalid Number of arguments"\\n
        usage 
        exit 2;
    fi
}

## helper function
#######################
function usage {
    /usr/bin/sudo echo -e "Usage: $init-kira-baseline.sh -d <DE_PASS> -a <DE_FIRMADM_PASS>"
}

#######################
## Main processing
## Initialize Kira
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

umask 022                                   # set umask

checkargs     # args must be 4
 
## getopts
#######################
while getopts :u:a:h FLAG; do
    case $FLAG in 
        u) DE_PASS=$OPTARG ;;
        a) DE_FIRMADM_PASS=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            usage 
            break
            ;;
    esac
done

shift "$((OPTIND-1))"

## Retry logic
if [[ ! -f $lckfile ]] ; then
    ################################################################################################################################
    set -e

    #logit "    : Check Version: "
    #/bin/sudo su - $pg_id -c "psql -U $pg_id -c     ' "

    logit "    : Creating ROLE:${DE_USER} "
    /bin/sudo su - $pg_id -c "psql -U  $pg_id -c 'CREATE ROLE ${DE_USER} LOGIN ENCRYPTED PASSWORD '\''${DE_PASS}'\'';' "

    logit "    : Creating ROLE: ${DE_FIRMADM_USER} "
    /bin/sudo su - $pg_id -c "psql -U  $pg_id -c 'CREATE ROLE ${DE_FIRMADM_USER} LOGIN CREATEDB CREATEROLE ENCRYPTED PASSWORD '\''${DE_FIRMADM_PASS}'\'';' "

    logit "    : Creating DB=DE_FIRMS with OWNER ${DE_FIRMADM_USER} "
    /bin/sudo su - $pg_id -c "psql -U  $pg_id -c 'CREATE DATABASE de_firms OWNER ${DE_FIRMADM_USER};'"

    logit "    : Creating EXT=pg_trgm On DB=DE_FIRMS "
    /bin/sudo su - $pg_id -c "psql -d de_firms -U  $pg_id -c 'CREATE EXTENSION pg_trgm;'"

    logit "    : Creating DB: de_web_template with OWNER=${DE_FIRMADM_USER} "
    /bin/sudo su - $pg_id -c "psql -U postgres -c 'CREATE DATABASE de_web_template OWNER ${DE_FIRMADM_USER};'"

    logit "    : Creating EXT=ltree On DB=de_web_template "
    /bin/sudo su - $pg_id -c "psql -d de_web_template -U  $pg_id -c 'CREATE EXTENSION ltree;'"

    logit "    : Creating EXT=pg_trgm On DB=de_web_template "
    /bin/sudo su - $pg_id -c "psql -d de_web_template -U  $pg_id -c 'CREATE EXTENSION pg_trgm;'"

    logit "    : Creating EXT=pgcrypto On DB=de_web_template."
    /bin/sudo su - $pg_id -c "psql -d de_web_template -U  $pg_id -c 'CREATE EXTENSION pgcrypto;'"

    logit "    : Creating EXT=btree_gin On DB=de_web_template"
    /bin/sudo su - $pg_id -c "psql -d de_web_template -U  $pg_id -c 'CREATE EXTENSION btree_gin;'"

    logit "    : Creating EXT=pg_repack On DB=de_web_template."
    /bin/sudo su - $pg_id -c "psql -d de_web_template -U  $pg_id -c 'CREATE EXTENSION pg_repack;'"

    logit "    : Updating DB=pg_database; Setting datistemplate=true WHERE datname=de_web_template "
    /bin/sudo su - $pg_id -c "psql -d de_web_template -U  $pg_id -c 'UPDATE pg_database SET datistemplate=true WHERE datname='\''de_web_template'\'';'"

    logit "    : Adding COMMENT ON DB:de_firms "
    /bin/sudo su - $pg_id -c "psql -c 'COMMENT ON DATABASE de_firms IS '\''CREATED on ${TODAY}'\'';' "

    logit "    : Running FLYWAY migrate on de_firms "
    /bin/bash $FLYWAY migrate $OPTS -driver=$DRIVER -url=$URL/de_firms -user=$DE_FIRMADM_USER -password=$DE_FIRMADM_PASS -locations=$MIGRATIONS/de_firms  -placeholders.db_user=${DE_FIRMADM_USER} 

    logit "    : Running FLYWAY migrate on de_web_template "
    /bin/bash $FLYWAY migrate $OPTS -driver=$DRIVER -url=$URL/de_web_template -user=$DE_FIRMADM_USER -password=$DE_FIRMADM_PASS -locations=$MIGRATIONS/de_web_template -placeholders.db_user=${DE_FIRMADM_USER}

    logit "    : Applying GRANT SELECT ON firms TO $DE_USER "
    /bin/sudo su - $pg_id -c "psql -d de_firms -U  $pg_id -c 'GRANT SELECT ON firms TO $DE_USER;'"

    logit "    : Applying GRANT INSERT ON transactions TO $DE_USER "
    /bin/sudo su - $pg_id -c "psql -d de_firms -U  $pg_id -c 'GRANT INSERT ON transactions TO $DE_USER;'"

    logit "    : Applying USAGE ON transactions_transaction_id_seq TO $DE_USER "
    /bin/sudo su - $pg_id -c "psql -d de_firms -U  $pg_id -c 'GRANT USAGE ON transactions_transaction_id_seq TO $DE_USER;'"

    touch $lckfile
fi

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?