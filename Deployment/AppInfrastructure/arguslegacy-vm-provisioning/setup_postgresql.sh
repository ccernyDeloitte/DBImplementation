#!/bin/bash
#
#  Ssetup_postgresql.sh
#
# postgresql install and configure script
#
# $1 = DOMAIN=uscloudprod.us.deloitte.com
# $2 = ENVIRONMENTID=USAZUAUDDE
# $3 = STARSLIFECYCLE=Quality Assurance
# $4 = STARSPOD=POD
# ex: sh setup_postgresql.sh 'uscloudprod.us.deloitte.com' 'USAZUAUDDE' 'Quality Assurance' 'POD'
##########################################################################
 
#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="setup_postgresql.log"
puppetinstalllogfile="puppet_install.log"
lckfile=".setup_postgresql.lck"
vgname="vgdata"
vgpgads="vgpgads"
vgpgxlog="vgpgxlog"
vgpgdb="vgpgdb"
pgdatalv="pgdatalv"
pgxloglv="pgxloglv"
pgadslv="pgadslv"
pgdblv="pgbdblv"
pgbasemnt="/var/pg_base"                 # pg bits - disk 1; 2048GB 
pgdbmnt="/var/pgdatabases"				# pg_databases - disk 2; 512GB
pgxlogmnt="/var/pg_xlog"				# pg_xlog - disk 3; 512GB
pgadsmnt="/var/pgads"					# pg_bkp - disk 4; 2048GB
stripescnt="1"

## Initialize variables to default values
domain=$1                                      # ex: usclouddev.us.deloitte.com
envid=$2                                       # ex: USAZUAUDDE
environment=$3                                     # ex: Quality Assurance
pod=$4                                         # ex: POD
rootdomain=$(echo $domain | cut -d'.' -f 2-4)  # ex: us.deloitte.com
subdomain=$(echo $domain | cut -d'.' -f 1)     # ex: usclouddev
os="Linux - Red Hat"
contact="CSD-CLIENTSOLUTIONS-AUDIT-DEVOPS"
facility="MS Azure Cloud (AZU)"
model="Virtual Machine"
osowner="STEAM"
description="LinuxVM"
shortdescription="VM for Argus"

# handle prod vs non-prd
if [[ $environment -eq "Production" ]]; then 
	pod="POD1" 
else # Set POD to POD2
	pod="POD2" 
fi

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" >> $logdir/$logfile
}

#######################
## Check script setup
#######################
function checksetup {
  ## Verify User 
  if [[ $EUID -ne 0 ]]; then
    logit "checksetup: Error: This script must be run as root" 1>&2
    exit $?
  fi
}

function updateProfile {
	logit "updateProfile: Update bash profile for user: $1."
	echo "# Add .NET Core 2.0 to my login environment \n source scl_source enable rh-dotnet20" >> /home/$1/.bash_profile
	logit "updateProfile: Done. Exit code: $?"
}

#######################
## cloudscript domain join
#######################
function cloudscript {
	logit "cloudscript: Incoming script Params:"
	logit "cloudscript: script input;pos1:  '$domain'"
	logit "cloudscript: script input;pos3:  '$environment'"
	logit "cloudscript: script input;pos4:  '$pod'"
	logit "cloudscript: "
	logit "cloudscript: Cloudscript Input Params:"
	logit "cloudscript: rootdomain........'$rootdomain'"
	logit "cloudscript: OS Verion.........'$os'"
	logit "cloudscript: Contact...........'$contact'"
	logit "cloudscript: Patch.............'$pod'"
	logit "cloudscript: Environment.......'$environment'"
	logit "cloudscript: Description.......'$description'"
	logit "cloudscript: ShortDescription..'$shortdescription'"

	logit "cloudscript: Running cloudscript."
	curl -sS -k "https://usstocrmitsbx.blob.core.windows.net/cloudtemplates/scripts/prodcloudscript.sh?sp=r&st=2018-07-20T22:48:31Z&se=2021-07-21T06:48:31Z&spr=https&sv=2017-11-09&sig=QZ8IDDJ9V%2BP2baqE1vyfq77qJOe12A%2FLAkms4a4JWCw%3D&sr=b" | bash -s install "$domain" root "$contact" "$contact" "$environment" "$contact" "$pod"  "$os" "$description" "$shortdescription" >> $logdir/$puppetinstalllogfile
	logit "cloudscript: Done. Exit code: $?"
}

#######################
## install prereqs
#######################
 function installPreReqs {
   logit "installPreReqs: Installing base packages"
   yum install -y samba-client 
   yum install -y samba-common 
   yum install -y cifs-utils
   yum install -y telnet
   yum install -y java-1.8.0-openjdk.x86_64 
   yum install -y lvm2 
   yum install -y tree
   yum install -y psmisc
   yum install -y screen.x86_64
   yum install -y icu
   yum install -y deltarpm
   yum install -y curl-devel 
   yum install -y expat-devel 
   yum install -y gettext-devel
   yum install -y openssl-devel
   yum install -y zlib-devel
   yum install -y gcc
   yum install -y perl-ExtUtils-MakeMaker
   
   logit "installPreReqs: Done. Exit code: $?"
}

#######################
## Set deltarpm flag
#######################
function setdeltarpmflag {
	logit "setdeltarpmflag: Setting deltarpm config flag to -1."
	echo "deltarpm=-1" >> /etc/yum.conf
	logit "setdeltarpmflag: Done. Exit code: $?"
}

#######################
## Setup default partitions
#######################
function partitionDisk {
	logit "partitionDisk: Partioning disk."
	# Eliminate /dev/sda and /dev/sdb for volume creation
	local disks=`lsscsi -d | grep /dev/sd | grep -v 'dev/sd[ab]' | awk '{print $7}' ORS=' '`
	logit "partitionDisk: Found: $disks. Strpes count: $stripescnt."
	
	# Init /dev/sb[cdef] as a LVM physical volume
	logit "partitionDisk: Creating Physical volume group for disks /dev/sd[cdef] ."
	pvcreate /dev/sd[cdef]
	pvscan >> $logdir/$logfile

	# create volume group
	logit "partitionDisk: Creating volume group for $disks."
	vgcreate $vgname /dev/sdc
	vgcreate $vgpgads /dev/sdd
	vgcreate $vgpgxlog /dev/sde
	vgcreate $vgpgdb /dev/sdf
	vgscan
	
	# creating mount dir
	logit "partitionDisk: Creating mount directory."
	mkdir -p $pgbasemnt $pgxlogmnt $pgadsmnt $pgdbmnt

	# create logical Volumes
	logit "partitionDisk: Creating $pgdatalv $vgname logical volume."
	lvcreate --extents 100%FREE --stripes $stripescnt --name $pgdatalv $vgname -y
	# pg_xlog
	logit "partitionDisk: Creating $pgxloglv $vgname logical volume."
	lvcreate --extents 100%FREE --stripes $stripescnt --name $pgxloglv $vgpgxlog -y
    #pg_ads - backup
	logit "partitionDisk: Creating $pgadslv $vgname logical volume."
	lvcreate --extents 100%FREE --stripes $stripescnt --name $pgadslv $vgpgads -y
	# pg_data
	logit "partitionDisk: Creating $pgdblv $vgname logical volume."
	lvcreate --extents 100%FREE --stripes $stripescnt --name $pgdblv $vgpgdb -y

	lvscan >> $logdir/$logfile
	
	# create filesys
	logit "partitionDisk: Creating filesystems."
	mkfs -t ext4 /dev/$vgname/$pgdatalv >> $logdir/$logfile
	mkfs -t ext4 /dev/$vgpgxlog/$pgxloglv >> $logdir/$logfile
	mkfs -t ext4 /dev/$vgpgads/$pgadslv >> $logdir/$logfile
	mkfs -t ext4 /dev/$vgpgdb/$pgdblv >> $logdir/$logfile
	
	#update fstab
	logit "partitionDisk: Update fstab."
	cp -p /etc/fstab /etc/fstab.bkp
	echo "/dev/$vgname/$pgdatalv                $pgbasemnt          ext4    defaults          1 2" >> /etc/fstab
	echo "/dev/$vgpgxlog/$pgxloglv              $pgxlogmnt          ext4    defaults          1 2" >> /etc/fstab
	echo "/dev/$vgpgads/$pgadslv                $pgadsmnt           ext4    defaults          1 2" >> /etc/fstab
	echo "/dev/$vgpgdb/$pgdblv                  $pgdbmnt            ext4    defaults          1 2" >> /etc/fstab
	
	#mount fs
	logit "partitionDisk: Mount filesystems."
	mount /dev/$vgname/$pgdatalv $pgbasemnt
	mount /dev/$vgpgxlog/$pgxloglv $pgxlogmnt
	mount /dev/$vgpgads/$pgadslv $pgadsmnt
	mount /dev/$vgpgdb/$pgdblv $pgdbmnt
  
	if [ $? -ne 0 ] ; then
		logit  "partitionDisk: ERROR: Unable to create and mount the Volume ...error in volume creation command."
		exit 1
	else
		touch "$logdir/.partioned"
		logit "partitionDisk: Done. Exit code: $?"
	fi
}


#######################
## DotNetCore
## https://www.microsoft.com/net/download/linux-package-manager/rhel/sdk-current
#######################
function enableDotNetCore {
	logit "enableDotNetCore: Enabling dotnet core packages."
	# https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x
	# https://github.com/dotnet/core-setup
	# packages
	yum install rh-dotnet21 -y                           
	scl enable rh-dotnet21 bash

	logit "enableDotNetCore: Done. Exit code: $?"
}

#######################
## Install AZCopy
## depends on dotnet-core
https://www.microsoft.com/net/download/linux-package-manager/rhel/sdk-current
#######################
function installAZCopy {
	logit "installAZCopy: Installing AZCopy."
	wget -O azcopy.tar.gz https://aka.ms/downloadazcopyprlinux
	mkdir -p /opt/azcopy
	tar -xzvf azcopy.tar.gz -C /opt/azcopy
	logit "installAZCopy: Done. Exit code: $?"
}

#######################
## DotNetCore
## https://www.microsoft.com/net/download/linux-package-manager/rhel/sdk-current
#######################
function enableDotNetCore {
	logit "enableDotNetCore: Enabling dotnet core packages."
	# https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x
	# https://github.com/dotnet/core-setup
	# packages
	yum install rh-dotnet21 -y                           
	scl enable rh-dotnet21 bash
	
	logit "enableDotNetCore: Done. Exit code: $?"
}

#######################
## install azure-cli
## https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum?view=azure-cli-latest
#######################
function installAzureCLI {
	# Import the Microsoft repository key
	/usr/bin/rpm --import https://packages.microsoft.com/keys/microsoft.asc
	# Create local azure-cli repository information
	/usr/bin/sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
	/usr/bin/yum install -y azure-cli
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

umask 022                                   # set umask
installPreReqs                              # install prereq packages
setdeltarpmflag                             # set deltarpm config
enableDotNetCore                            # install dotnet
installAZCopy                               # install AzCopy
installAzureCLI                             # install Azure CLI

## partion datadisk w/ retry
if [ ! -f "$logdir/.partioned" ] ; then
	partitionDisk                           # partition disk
fi

sleep 15
cloudscript                                # domain join       

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?