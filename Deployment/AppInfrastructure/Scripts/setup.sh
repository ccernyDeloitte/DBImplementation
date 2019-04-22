#!/bin/bash

function HELP {
      echo -e "Example:  $SCRIPT -s <STGACCT> -k <STGKEY> -f <FILESHARE>"
}

function cloudscript {
   curl -s "https://rahuldisks102.blob.core.windows.net/test/cloudscriptfinal.sh?sv=2017-04-17&ss=b&srt=sco&sp=r&se=2018-12-19T00:29:12Z&st=2017-12-18T16:29:12Z&spr=https&sig=YMAxAWLDJzOOUqhmNUz%2FFdMLUteRPmyw%2FvfYLN%2Fn6E4%3D" | bash -s  install usclouddev.us.deloitte.com root
}

function setconfigs {
  local iphost=$1
  cp /mnt/kirashare/pkgs/createkira/devops/templates/*.conf /var/tmp
  cd /var/tmp
  chown kira:kira common.conf
  chown kira:kira node.conf
  chown postgres:postgres pg_hba.conf
  chown postgres:postgres postgresql.conf
  sed -i "s/XXX\.XXX\.XXX\.XXX/$iphost/g" *.conf
  cp /var/tmp/common.conf /opt/kira/config/
  cp /var/tmp/node.conf   /opt/kira/config/
  cp /var/tmp/pg_hba.conf /opt/kira/PostgreSQL/9.6/data/
  cp /var/tmp/postgresql.conf /opt/kira/PostgreSQL/9.6/data/
}

function startservices {
  #Iptables flush
  iptables --flush
  #Check the DB Start/Stop --- Commented temporarily
  #su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl start -D /opt/kira/PostgreSQL/9.6/data && /usr/pgsql-9.6/bin/pg_ctl stop -m fast -D /opt/kira/PostgreSQL/9.6/data"
  #sleep 300
  #Stage DB & Application
  service postgresql-9.6 start 
  #Update table in database with the current host IP - TBC
  #Start the docker services - TBC
}


function setupssl {
  cp /mnt/kirashare/pkgs/createkira/devops/ssl/* /opt/kira/ssl/
  chown kira:kira /opt/kira/ssl -R
}

function addvolume {
  #Elimanate /dev/sda and /dev/sdb for volume creation
  local devstr=`lsscsi -d |grep /dev/sd|grep -v '/dev/sd[ab]' |awk '{print $7}' ORS=' '`
  local cnt=$(echo $devstr | wc -w)
  echo $cnt
  echo $devstr
  mkdir -p /mnt/argus
  pvcreate $devstr
  vgcreate data-vg01 $devstr
  lvcreate --extents 100%FREE --stripes $cnt --name data-lv01 data-vg01
  mkfs -t ext4 /dev/data-vg01/data-lv01
  cp /etc/fstab /etc/dist.fstab
  echo  "/dev/data-vg01/data-lv01  /mnt/argus  ext4  defaults  0  2" >> /etc/fstab
  mount -a 
  if [ $? -ne 0 ] ; then
      echo "unable to create and mount the Volume ...error in volume creation command"
      exit 2
  fi
  mkdir -p /mnt/argus/kira
  mkdir -p /mnt/argus/docker
  echo  "/mnt/argus/kira  /opt/kira                       none    bind            0 0"  >> /etc/fstab
  echo  "/mnt/argus/docker /var/lib/docker                none    bind            0 0"  >> /etc/fstab
  lvdisplay
}

function mountfs {
   local stga="$1"
   local stgkey="$2"
   local fileshare="$3"
   local stguser=${stga%%\.*}
   local mntcmd="//$stga/$fileshare /mnt/kirashare  cifs vers=3.0,username=$stguser,password=$stgkey,dir_mode=0777,file_mode=0777,sec=ntlmssp"
   echo $stguser
   echo $mntcmd
   echo "$mntcmd" >> /etc/fstab
   mount -a
   if [ $? -ne 0 ] ; then 
      echo "unable to mount ...error in mount command"
      exit 2
   fi
   lvdisplay
}

function setupprereq {
    yum install -y samba-client samba-common cifs-utils
    yum install -y telnet
    yum install -y java-1.8.0-openjdk.x86_64
    yum install -y lvm2
    mkdir -p /mnt/kirashare
    mkdir -p /opt/kira
    mkdir -p /var/lib/docker
}

function kirasetup {
   groupadd -g 500 kira
   useradd -d /opt/kira -u 500 kira -g 500
   usermod -aG wheel kira
#Set the password 
/usr/bin/passwd kira <<EOF
changemenow!
changemenow!
EOF
#Create a library structure
  cd /opt/kira
  mkdir config
  mkdir jars
  mkdir log
  mkdir ssl
  mkdir mdr
  mkdir tmp
  mkdir docker-images
  mkdir model-cache
  mkdir custom-models
  mkdir rabbitmq
  mkdir rabbitmq/mnesia
  mkdir rabbitmq/etc
  mkdir rabbitmq/log
  mkdir zookeeper
  mkdir zookeeper/conf
  mkdir zookeeper/data
  mkdir zookeeper/log
  mkdir omnipage 
  chown -R kira:kira /opt/kira
  chmod 777 /tmp
  cd /mnt/kirashare/pkgs/createkira/docker
  yum install -y docker-engine-1.8.2-1.el7.centos.x86_64.rpm
  yum install -y docker-engine-selinux-1.11.2-1.el7.centos.noarch.rpm
  wget https://bootstrap.pypa.io/get-pip.py -P /tmp
  python /tmp/get-pip.py
  pip install docker.py
  #Copy Docker files from share
  cp /mnt/kirashare/pkgs/createkira/kira/images/*.tar.gz /opt/kira/docker-images
  cd /opt/kira/docker-images
  chown -R kira:kira /opt/kira/docker-images 
  #Copy Jar files from share
  cp /mnt/kirashare/pkgs/createkira/kira/jars/*.jar /opt/kira/jars
  cd /opt/kira/jars
  cp kira.configuration.jar kira.configuration-1.0.jar
  chown -R kira:kira /opt/kira/jars 
  chmod 755 /opt/kira/jars/*.jar
  # Copy  Omnipage
  cp /mnt/kirashare/pkgs/createkira/kira/omnipage/bin /opt/kira/omnipage/ -R
  chown kira:kira /opt/kira/omnipage -R
  chmod 755 /opt/kira/omnipage/bin -R
  # Copy Config Files
  cp /mnt/kirashare/pkgs/createkira/kira/config/* /opt/kira/config -R
  chown kira:kira /opt/kira/config -R
  chmod 755 /opt/kira/config/* -R
  #Copy Zookeeper Files
  cp /mnt/kirashare/pkgs/createkira/kira/zookeeper/* /opt/kira/zookeeper -R
  chown kira:kira /opt/kira/zookeeper -R
  chmod 755 /opt/kira/zookeeper/* -R
}

function loaddckimgs {
   local imgpth=$1
   cd $imgpth
   echo $PWD
   #Start the docker daemon and include it in AutoStart
   systemctl enable docker.service
   service docker start
   #Load Dockers
   docker load -i doc-converter.tar.gz
   tagdoc=`docker images|grep -E 'doc-converter|none' |awk  '{print $3}'`
   docker tag -f $tagdoc doc-converter:latest
   docker load -i jamie.tar.gz
   tagjm=`docker images|grep -E 'jamie|none' |awk  '{print $3}'`
   docker tag -f $tagjm jamie:latest
   docker load -i nginx.tar.gz
   tagnginx=`docker images|grep -E 'nginx|none'|awk  '{print $3}'`
   docker tag -f $tagnginx nginx:latest
   docker load -i web.tar.gz
   tagweb=`docker images|grep -E 'web|none'|awk  '{print $3}'`
   docker tag -f $tagweb web:latest
   docker load -i scheduler.tar.gz
   tagsch=`docker images|grep -E 'scheduler|none'|awk  '{print $3}'`
   docker tag -f $tagsch scheduler:latest
   docker load -i rabbitmq.tar.gz
   tagrabbi=`docker images|grep -E 'rabbitmq|none'|awk  '{print $3}'`
   docker tag -f $tagrabbi rabbitmq:latest
   docker load -i zookeeper.tar.gz
   tagzoo=`docker images|grep -E 'zookeeper|none'|awk  '{print $3}'`
   docker tag -f $tagzoo zookeeper:latest
   docker images
}

# moved to vm-provisioning/SetUp-postgres.sh
function pgsqlsetup {
  yum install -y /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-9.6.5-1PGDG.rhel7.x86_64.rpm /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-contrib-9.6.5-1PGDG.rhel7.x86_64.rpm  /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-debuginfo-9.6.5-1PGDG.rhel7.x86_64.rpm /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-devel-9.6.5-1PGDG.rhel7.x86_64.rpm /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-docs-9.6.5-1PGDG.rhel7.x86_64.rpm /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-libs-9.6.5-1PGDG.rhel7.x86_64.rpm /mnt/kirashare/pkgs/createkira/PG9.6/postgresql96-server-9.6.5-1PGDG.rhel7.x86_64.rpm 
  cp /usr/lib/systemd/system/postgresql-9.6.service /etc/systemd/system/postgresql-9.6.service
  sed -i "s/PGDATA=.*/PGDATA=\/opt\/kira\/PostgreSQL\/9.6\/data/g" /etc/systemd/system/postgresql-9.6.service
  systemctl daemon-reload
  systemctl enable postgresql-9.6.service
  mkdir -p /opt/kira/PostgreSQL/9.6/data
  chmod 700 /opt/kira/PostgreSQL/9.6/data
  chown postgres:postgres /opt/kira/PostgreSQL/9.6/data
  cp  /mnt/kirashare/pkgs/createkira/PG9.6/R35/* /opt/kira/PostgreSQL/9.6/data/ -R
  chmod 600 /opt/kira/PostgreSQL/9.6/data -R
  chown postgres:postgres /opt/kira/PostgreSQL/9.6/data -R
  cd /opt/kira/PostgreSQL/9.6/data/
  mkdir pg_log
  chown postgres:postgres pg_log -R 
  find /opt/kira/PostgreSQL/9.6/data/ -type d -exec chmod 700 {} \;
}

 
SCRIPT=`basename ${BASH_SOURCE[0]}`
#Initialize variables to default values
STGACCT=S
KEYSTG=K
FILESHARE=F
HELP=false

#Check the number of arguments. If none are passed print help and exit
NUMARGS=$#

if [ $NUMARGS -ne 6 ]; then
  echo -e \\n"Invalid Number of arguments"\\n
  HELP
  exit 2;
fi

while getopts :s:k:f:h FLAG; do
  case $FLAG in 
    s) STGACCT=$OPTARG ;;
    k) KEYSTG=$OPTARG ;;
    f) FILESHARE=$OPTARG ;;
    h) HELP ;;
    \?) echo -e \\n"Invalid Option"
        HELP
        break
        ;;
   esac
done

shift $((OPTIND-1))

echo $STGACCT
echo $FILESHARE
echo $HELP

HOSTIP=`ifconfig eth0 |grep 'inet '|awk '{print $2}'`

echo "Running cloud script"
#cloudscript
echo "Setting up pre-requisites"
#setupprereq
echo "Setting up LVM Drive"
#addvolume
echo "Mounting the fileshare"
#mountfs $STGACCT $KEYSTG $FILESHARE
echo "Setting up Kira"
#kirasetup
echo "Setting up postgreSQL"
#pgsqlsetup
echo "Change configs"
#setconfigs $HOSTIP
echo "Copying SSL Certs "
#setupssl
echo "Loading Docker Images"
#loaddckimgs "/opt/kira/docker-images"
echo "Start services"
#startservices
