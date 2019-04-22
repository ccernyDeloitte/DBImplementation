#!/bin/bash
#
#  docker_service.sh
#
# start, stop, retstart, status postgresql
##########################################################################
dcksvc="docker.service"

case "$1" in 
  start)
    /usr/bin/sudo /usr/bin/systemctl start $dcksvc
    ;;
  stop)
    /usr/bin/sudo /usr/bin/systemctl stop $dcksvc
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  status)
    /usr/bin/sudo /usr/bin/systemctl status $dcksvc
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0