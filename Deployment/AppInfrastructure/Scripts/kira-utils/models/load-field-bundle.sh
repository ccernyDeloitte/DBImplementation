# Target NODE: POSTGRES
# Run this postgresql node
################################################################
# KIRA PROVIDED SOFTWARE
################################################################
# adapted from load-provs.sh 1.2
version=1.0
lck_file=".r45_11"
bundle_path="/var/pg_base/pg_utils/"

################################################################
# Edit these values only

# FIRM_ID must match the value of the firm_id column from the de_firms.firms table, for the row corresponding to the firm you wish to load provisions into.
export TARGET_FIRM_ID=1

# BUNDLE_PATH must be either the current directory (if this script is run in the same directory as the bundle jar), or the directory part of the full path to the bundle jar, without tailing /
export BUNDLE_PATH=.

# BUNDLE_JAR is the filename of the provided bundle of fields
#export BUNDLE_JAR='2018-10-24-r50.7-new-file-version/provisions.csv'
export BUNDLE_JAR='2018-10-24-r50.7-new-file-version'

################################################################
# Edit nothing below here

BASE_PATH=/opt/kira
FIELD_GROUPS=':dp :cfa :de :gc :re :isda :ma-dp :cltrs :nda :corg :re-en'
awk_scr=$(cat <<EOF
BEGIN { pgflag=0; rmqflag=0; zkflag=0; }
/^\[/ { pgflag=0; rmqflag=0; zkflag=0; }
! pgflag && /^\[postgresql\]/ { pgflag=1; }
! rmqflag && /^\[rabbitmq\]/ { rmqflag=1; }
! zkflag && /^\[zookeeper\]/ { zkflag=1; }
pgflag && /^uri/ { uri = substr(\$0, 1+index(\$0, "="), 100); print "export DB_SERVER='" uri "'"; }
pgflag && /^password=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_PWD='" pwd "'"; }
pgflag && /^password_enc=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_PWD_ENC='" pwd "'"; }
pgflag && /^admin_password=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_WEB_TEMPLATE_PWD='" pwd "'"; }
pgflag && /^admin_password_enc=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export DB_WEB_TEMPLATE_PWD_ENC='" pwd "'"; }
rmqflag && /^nodes=/ { nodes = substr(\$0, 1+index(\$0, "="), 100); print "export RMQ_SERVER='" nodes "'"; }
rmqflag && /^password=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export RMQ_PWD='" pwd "'"; }
rmqflag && /^password_enc=/ { pwd = substr(\$0, 1+index(\$0, "="), 100); print "export RMQ_PWD_ENC='" pwd "'"; }
zkflag && /^nodes=/ { nodes = substr(\$0, 1+index(\$0, "="), 100); print "export ZOOKEEPER='" nodes "'"; }
EOF
)
eval $(/usr/bin/sudo awk "${awk_scr}" ${BASE_PATH}/config/common.conf)

if [ ! -f $bundle_path/$lck_file ] ; then
    /usr/bin/sudo java -cp ${BUNDLE_PATH}/${BUNDLE_JAR}:${BASE_PATH}/jars/kira.configuration.jar:${BASE_PATH}/jars/kira.cmd.jar kira.cmd.core provision --db-server 127.0.0.1:5432 --mode import --firm-id ${TARGET_FIRM_ID} ${FIELD_GROUPS}
    /bin/touch $bundle_path/$lck_file
fi