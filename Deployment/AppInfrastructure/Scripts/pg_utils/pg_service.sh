#!/bin/bash
#
#  pg_service.sh
#
# start, stop, retstart, status postgresql
#
##########################################################################
pg_service="postgresql-9.6.service"

case "$1" in 
  start)
    /usr/bin/sudo /usr/bin/systemctl start $pg_service
    ;;
  stop)
    /usr/bin/sudo /usr/bin/systemctl stop $pg_service
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  status)
    /usr/bin/sudo /usr/bin/systemctl status $pg_service
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0