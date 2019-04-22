#!/bin/bash
#
# wrapper around kira.cmd to load the classifier
# Target NODE: COORD
################################################################
# KIRA PROVIDED SOFTWARE
################################################################

version=1.0

base_path=/opt/kira
export FIELD_PATH="${base_path}/fields"

awk_scr=$(cat <<EOF
BEGIN { pgflag=0; rmqflag=0; zkflag=0; esflag=0; aflag=0; }
/^\[/ { pgflag=0; rmqflag=0; zkflag=0; esflag=0; aflag=0; }
! pgflag && /^\[postgresql\]/ { pgflag=1; }
! rmqflag && /^\[rabbitmq\]/ { rmqflag=1; }
! zkflag && /^\[zookeeper\]/ { zkflag=1; }
! esflag && /^\[elasticsearch\]/ { esflag=1; }
! aflag && /^\[analytics\]/ { aflag=1; }
pgflag && /^uri/ { uri = substr(\$0, 1+index(\$0, "="), 100); print "export DB_SERVER='" uri "'"; }
pgflag && /^password=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_PWD='" pwd "'"; }
pgflag && /^password_enc=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_PWD_ENC='" pwd "'"; }
pgflag && /^admin_password=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_WEB_TEMPLATE_PWD='" pwd "'"; }
pgflag && /^admin_password_enc=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_WEB_TEMPLATE_PWD_ENC='" pwd "'"; }
rmqflag && /^nodes=/ { nodes = substr(\$0, 1+index(\$0, "="), 100); print "export RMQ_SERVER='" nodes "'"; }
rmqflag && /^password=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export RMQ_PWD='" pwd "'"; }
rmqflag && /^password_enc=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export RMQ_PWD_ENC='" pwd "'"; }
zkflag && /^nodes=/ { nodes = substr(\$0, 1+index(\$0, "="), 100); print "export ZOOKEEPER='" nodes "'"; }
esflag && /^host=/ { host = substr(\$0, 1+index(\$0, "="), 100); print "export ES_HOST='" host "'"; }
esflag && /^cluster_name=/ { name = substr(\$0, 1+index(\$0, "="), 100); print "export ES_CLUSTER_NAME='" name "'"; }
aflag && /^deployment_id/ { id = substr(\$0, 1+index(\$0, "="), 100); print "export APC_DEPLOYMENT_ID='" id "'"; }
EOF
)

# the AWK script above reads common.conf and finds the DB URI and passwords; the eval below sticks them in to the current environment
eval $(awk "${awk_scr}" ${base_path}/config/common.conf)

mode=info
firm_id=""

while [ -n "$1" ]
do
    n=1
    case "$1" in
        info|load|clean)
            mode=$1
            ;;
        --firm-id)
            shift
            firm_id=$1
            ;;
        *)
            echo Error: parameter ${n} not understood: ${1}
            ;;
    esac
    shift
    n=$(( n + 1 ))
done

if [ -z "${firm_id}" ]
then
    echo Error: missing '--firm-id' option
    exit 1
fi

kira_cmd="java -cp ${FIELD_PATH}:${base_path}/jars/kira.configuration.jar:${base_path}/jars/kira.cmd.jar kira.cmd.core"

case "${mode}" in
    info)
        ${kira_cmd} classifier -m info --firm-id ${firm_id}
        ;;
    clean)
        ${kira_cmd} classifier --firm-id ${firm_id} -m remove --id 1
        ;;
    load)
        ${kira_cmd} classifier --firm-id ${firm_id} -m add --id kira-coarse   --spec ${base_path}/classifier/coarse-classifer-1.edn   --model ${base_path}/classifier/coarse-1.0.reg
        ${kira_cmd} classifier --firm-id ${firm_id} -m add --id kira-contract --spec ${base_path}/classifier/contract-classifer-1.edn --model ${base_path}/classifier/contract-1.0.reg
        export FIRM_DB="$( psql -At -U de -h localhost -d de_firms -c 'SELECT database_name FROM firms WHERE firm_id='${firm_id} )"
        export PGPASSWORD="$( psql -At -U de -h localhost -d de_firms -c 'SELECT database_pwd FROM firms WHERE firm_id='${firm_id} )"
        psql -U ${FIRM_DB} -h localhost -d ${FIRM_DB} -c "INSERT INTO firm_config VALUES (':new-document-classifier?',true) ON CONFLICT DO NOTHING"
        ${kira_cmd} classifier -m info --firm-id ${firm_id}
        ;;
    *)
esac
