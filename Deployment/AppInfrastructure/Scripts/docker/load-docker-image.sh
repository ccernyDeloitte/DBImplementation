#!/bin/bash
#
#  load-docker-image.sh
#
# This script is used to tag and load Kira docker images 
##########################################################################

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="install-haproxy.sh.log"
dckrimgpath="/opt/kira/docker-images"

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

#######################
## Load Docker Image
#######################
function loadimage {
  imagetoload=$1
	logit "loadimage: Attempting to load: $imagetoload"
  /bin/docker load -i $imagetoload
  logit "loadimage: Done."
}

#######################
## Tag Docker Image
#######################
function tagimage {
  logit "tagimage: Attempting to tag images."

  #tag zookeeper
  if [[ `docker images | grep -E 'zookeeper|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging zookeeper image."
    /bin/docker tag kira/zookeeper:2017-11-10_build-157 zookeeper:latest
  fi

  #tag rabbit
  if [[ `docker images | grep -E 'rabbitmq|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging rabbitmq image."
    /bin/docker tag kira/rabbitmq:2017-11-10_build-157 rabbitmq:latest
  fi

  #tag scheduler
  if [[ `docker images | grep -E 'scheduler|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging scheduler image."
    /bin/docker tag kira/scheduler:2017-11-10_build-157 scheduler:latest
  fi

  #tag web
  if [[ `docker images | grep -E 'web|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging web image."
    /bin/docker tag kira/web:2017-11-10_build-157 web:latest
  fi

  #tag doc-converter
  if [[ `docker images | grep -E 'doc-converter|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging doc-converter image."
   /bin/docker tag kira/doc-converter:2017-11-24_build-170 doc-converter:latest
  fi

  # tag kira-ml
  if [[ `docker images | grep -E 'ml|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging kira-ml image."

    /bin/docker tag kira-ml:2018-02-27-gamma-binaries kira-ml:latest
  fi

  # tag jamie
  if [[ `docker images | grep -E 'jamie|none' | awk '{print $3}' | wc -l` != 0 ]] ; then
    logit "tagimage: Tagging jamie image."
    /bin/docker tag kira/jamie:2017-11-10_build-157 jamie:latest
  fi

  logit "tagimage: Done."
}


## validate directory and images
  if [[ -d "$dckrimgpath" ]]; then
    for fn in `/bin/ls $dckrimgpath | xargs -n1 basename`; do
      echo "Image to load: $fn"
      loadimage $dckrimgpath/$fn
    done
    #tag images to latest
    tagimage 
  else
      logit "ERROR! Directories $dckrimgpath doesn't exist. Nothing to do."
  fi