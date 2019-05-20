#!/bin/bash
#####################################################
##            Deluge BitTorrent Daemon             ##
##                    v.1.3.15                     ##
##                                                 ##
#####################################################
## setup variables ##
latest="http://download.deluge-torrent.org/source/deluge-1.3.15.tar.gz"
#geoip="http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz"
geoip="https://github.com/maulvi/Deluge-WebUI-Installer/raw/master/GeoIP.zip"
packages="curl unzip python python-twisted python-twisted-web python-openssl python-simplejson python-setuptools intltool python-xdg python-chardet geoip-database python-libtorrent python-notify python-pygame python-glade2 librsvg2-common xdg-utils python-mako"
ip=$(hostname -I | awk -F ' ' '{print $2}')
# Check if we're root
if [ $(whoami) != "root" ]; then
        echo "You need to run this script as root."
        echo "Use 'sudo ./deluge_web.sh' then enter your password when prompted."
        exit 1
fi
clear
## get packages required to build deluge ##
echo "Installing Dependencies....."
	apt-get update -qq
	apt-get upgrade -qqy
	apt-get install -qqy $packages

## setup install dir ##
	mkdir deluge_install
	cd deluge_install
## get deluge
	wget $latest
	tar -xf deluge-*
	cd deluge-*

## install deluge ##
	echo " Installing Deluge...."
	python setup.py clean -a
	python setup.py build
	python setup.py install  --install-layout=deb

## cleanup install directory ##
	cd ../..
	rm -rf deluge_install
	clear
## install geoip database to resolve ips ##
	echo " Installing GeoIP Database...."
	wget $geoip
	unzip GeoIP.zip
	mkdir -p /usr/share/geoip
	mv GeoIP/GeoIP.dat /usr/share/geoip/

## setup deluge user
	echo "Now we will setup a user for Deluge"
	read -p "What would you like the username to be?   " USERNAME
             adduser --gecos "" $USERNAME

####################### BEGIN INIT SETUP ###############################				
## setup defaults ##

cat > /etc/default/deluge-daemon << EOF
# Configuration for /etc/init.d/deluge-daemon

# The init.d script will only run if this variable non-empty.
DELUGED_USER="$USERNAME"             # !!!CHANGE THIS!!!!

# Should we run at startup?
RUN_AT_STARTUP="YES"
EOF

## setup init script ##
## original script from http://apocryph.org/archives/601 ##
cat > /etc/init.d/deluge-daemon << "EOF"
#!/bin/sh
### BEGIN INIT INFO
# Provides:          deluge-daemon
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $network
# Should-Stop:       $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Daemonized version of deluge and webui.
# Description:       Starts the deluge daemon with the user specified in
#                    /etc/default/deluge-daemon.
### END INIT INFO

# Author: Adolfo R. Brandes
# Updated by: Jean-Philippe "Orax" Roemer

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="Deluge Daemon"
NAME1="deluged"
NAME2="deluge"
DAEMON1=/usr/bin/deluged
DAEMON1_ARGS="-d"             # Consult `man deluged` for more options
DAEMON2=/usr/bin/deluge-web
DAEMON2_ARGS=""               # Consult `man deluge-web` for more options
PIDFILE1=/var/run/$NAME1.pid
PIDFILE2=/var/run/$NAME2.pid
UMASK=022                     # Change this to 0 if running deluged as its own user
PKGNAME=deluge-daemon
SCRIPTNAME=/etc/init.d/$PKGNAME

# Exit if the package is not installed
[ -x "$DAEMON1" -a -x "$DAEMON2" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$PKGNAME ] && . /etc/default/$PKGNAME

# Load the VERBOSE setting and other rcS variables
[ -f /etc/default/rcS ] && . /etc/default/rcS

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

if [ -z "$RUN_AT_STARTUP" -o "$RUN_AT_STARTUP" != "YES" ]
then
   log_warning_msg "Not starting $PKGNAME, edit /etc/default/$PKGNAME to start it."
   exit 0
fi

if [ -z "$DELUGED_USER" ]
then
    log_warning_msg "Not starting $PKGNAME, DELUGED_USER not set in /etc/default/$PKGNAME."
    exit 0
fi

#
# Function to verify if a pid is alive
#
is_alive()
{
   pid=`cat $1` > /dev/null 2>&1
   kill -0 $pid > /dev/null 2>&1
   return $?
}

#
# Function that starts the daemon/service
#
do_start()
{
   # Return
   #   0 if daemon has been started
   #   1 if daemon was already running
   #   2 if daemon could not be started

   is_alive $PIDFILE1
   RETVAL1="$?"

   if [ $RETVAL1 != 0 ]; then
       rm -f $PIDFILE1
       start-stop-daemon --start --background --quiet --pidfile $PIDFILE1 --make-pidfile \
       --exec $DAEMON1 --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK -- $DAEMON1_ARGS
       RETVAL1="$?"
   else
       is_alive $PIDFILE2
       RETVAL2="$?"
       [ "$RETVAL2" = "0" -a "$RETVAL1" = "0" ] && return 1
   fi

   is_alive $PIDFILE2
   RETVAL2="$?"

   if [ $RETVAL2 != 0 ]; then
        sleep 2
        rm -f $PIDFILE2
        start-stop-daemon --start --background --quiet --pidfile $PIDFILE2 --make-pidfile \
        --exec $DAEMON2 --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK -- $DAEMON2_ARGS
        RETVAL2="$?"
   fi
   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
   # Return
   #   0 if daemon has been stopped
   #   1 if daemon was already stopped
   #   2 if daemon could not be stopped
   #   other if a failure occurred

   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user $DELUGED_USER --pidfile $PIDFILE2
   RETVAL2="$?"
   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user $DELUGED_USER --pidfile $PIDFILE1
   RETVAL1="$?"
   [ "$RETVAL1" = "2" -o "$RETVAL2" = "2" ] && return 2

   rm -f $PIDFILE1 $PIDFILE2

   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] && return 0 || return 1
}

case "$1" in
  start)
   [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME1"
   do_start
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  stop)
   [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME1"
   do_stop
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  restart|force-reload)
   log_daemon_msg "Restarting $DESC" "$NAME1"
   do_stop
   case "$?" in
     0|1)
      do_start
      case "$?" in
         0) log_end_msg 0 ;;
         1) log_end_msg 1 ;; # Old process is still running
         *) log_end_msg 1 ;; # Failed to start
      esac
      ;;
     *)
        # Failed to stop
      log_end_msg 1
      ;;
   esac
   ;;
  *)
   echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
   exit 3
   ;;
esac

:
EOF
########################## END INIT SETUP ##################################

## setup daemon ##
chmod 755 /etc/init.d/deluge-daemon
update-rc.d deluge-daemon defaults
## start deluge ##
invoke-rc.d deluge-daemon start

## Finish ## 
clear
echo "#####################################################"
echo "##########        Install Complete         ##########"
echo "#####################################################"
echo "If all went as planned you should be able to access"
echo "the deluge web-ui at http://$ip:8112/ "
echo "         Default password = deluge"
echo "#####################################################"
echo "##  Installer by SonicBoxes.com modified by maulvi ##"
echo "#####################################################"
echo "For FAQ and configuration options please see:"
echo "http://sonicboxes.com/bittorrent-deluge-webui-install-script/"
