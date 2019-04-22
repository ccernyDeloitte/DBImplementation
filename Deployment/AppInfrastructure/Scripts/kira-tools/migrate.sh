#!/bin/bash
# Target NODE: POSTGRESQL
################################################################
# KIRA PROVIDED SOFTWARE
################################################################

FLYWAY=flyway/flyway
DRIVER=org.postgresql.Driver
HOST=localhost
URL=jdbc:postgresql://$HOST:5432
MIGRATIONS=filesystem:/opt/kira/migrations/sql
#OPTS='-validateOnMigrate=false -ignoreMissingMigrations=true -cleanDisabled=true -outOfOrder=false'
OPTS='-cleanOnValidationError=false -cleanDisabled=true -outOfOrder=false'

# try to discover the de_firmadmin user password from the common.conf file
base_path=/opt/kira
common_conf_admin_pass="$( awk -F= '/admin_password/{print $2}' ${base_path}/config/common.conf )"
ADMIN_USER="de_firmadm"
ADMIN_PASS="${common_conf_admin_pass:-de_firmadm_password}"

# Migrate de_firms 
echo "de_firms:"
sh $FLYWAY migrate $OPTS -driver=$DRIVER -url=$URL/de_firms -user=$ADMIN_USER -password=$ADMIN_PASS -locations=$MIGRATIONS/de_firms  -placeholders.db_user=de_firmadm

if [[ "${rc}" -gt 0 ]]
then
    echo "===="
    echo "ERROR: de_firms migration failed, exiting..."
    exit 1
fi

# Migrate de_web_template
echo -e "\nde_web_template:"
sh $FLYWAY migrate $OPTS -driver=$DRIVER -url=$URL/de_web_template -user=$ADMIN_USER -password=$ADMIN_PASS -locations=$MIGRATIONS/de_web_template -placeholders.db_user=de_firmadm

if [[ "$?" -gt 0 ]]
then
    echo "===="
    echo "ERROR: de_web_template migration failed, exiting..."
    exit 1
fi

# Migrate each firm. DB user is the same as the name.
rc=0
error_firms=''
for DB in $( psql de_firms -h $HOST -U de -At -c "SELECT database_name FROM firms ORDER BY 1" )
do
    echo -e "\n$DB:"
    sh $FLYWAY migrate $OPTS -driver=$DRIVER -url=$URL/$DB -user=$ADMIN_USER -password=$ADMIN_PASS -locations=$MIGRATIONS/de_web_template -placeholders.db_user=$DB
    if [[ "$?" -gt 0 ]]
    then
        error_firms+="${DB} "
        rc=$(( rc + 1 ))
    fi
done

if [[ "${rc}" -gt 0 ]]
then
    echo "===="
    echo "ERROR: ${rc} failed migrations"
    echo "       Check" ${error_firms} "for errors"
fi

exit ${rc}
