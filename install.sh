#!/bin/bash
#
# Last Update:	2012/02/18
# Author:	labunix@linux.jp
# for Squeeze eth0 
#
# Environment
# PATH=/sbin:/usr/sbin:/bin:/usr/bin
set -e
echo ${PATH} | sed s/":"/"\n"/g | grep "^/usr/sbin\$" || \
  export PATH=/usr/sbin:${PATH}
echo ${PATH} | sed s/":"/"\n"/g | grep "^/sbin\$" || \
  export PATH=/sbin:${PATH}


if [ `id -u` -ne "0" ];then
  echo "Sorry,Permit User!"
  exit 1
fi

# for error

sfwerr() {
  echo "$@"
  exit 255
}

# environment

SFWLOG=/var/sfw/
test -d ${SFWLOG} || mkdir ${SFWLOG}
test -d ${SFWLOG} || sfwerr "ERROR:Can't Create ${SFWLOG}"
touch ${SFWLOG}/uninstall.info || exit 2

function subinstall() {
  echo $1 >> ${SFWLOG}/uninstall.info
  echo $1 >> ${SFWLOG}/uninstall.info
}

function sfwfirst() {
  cp smallfirewall /etc/smallfirewall
  chown root:root /etc/smallfirewall
  chmod 755 /etc/smallfirewall
  /bin/bash -x /etc/smallfirewall || \
    sfwerr "ERROR:/bin/bash -x /etc/smallfirewall"
}

function sfwinit() {
  test -f /etc/init.d/iptables
  cp iptables /etc/init.d/iptables
  chown root:root /etc/init.d/iptables
  chmod 755 /etc/init.d/iptables
  insserv -v iptables
  chkconfig --list iptables | grep "2\:on" || \
    sfwerr "ERROR:chkconfig --list iptables"
  /etc/init.d/iptables start || sfwerr "ERROR:/etc/init.d/iptables start"
}


case $1 in
-u)
  echo "Uninstall..."
  /etc/init.d/iptables stop || sfwerr "ERROR:/etc/init.d/iptables stop"
  chkconfig --list iptables | grep iptables && insserv -r iptables || \
    sfwerr "ERROR:insserv -r iptables"
  rm -f /etc/init.d/iptables || sfwerr "ERROR:rm -f /etc/init.d/iptables"
  rm -f /etc/smallfirewall || sfwerr "ERROR:rm -f /etc/smallfirewall"
  rm -fr ${SFWLOG} || sfwerr "ERROR:rm -fr ${SFWLOG}"
  ;;
*)
  echo "Install..."
  
  dpkg -l chkconfig | grep ^ii || subinstall chkconfig
  dpkg -l insserv | grep ^ii || subinstall insserv
  test -s ${SFWLOG}/uninstall.info && sort ${SFWLOG}/uninstall.info | uniq | \
    for list in `xargs`;do
      apt-get install "$list" || sfwerr "ERROR:apt-get install $list"
    done
  echo "done."
  echo ""
  echo "if you want to uninstall,run : $0 -u"
  sfwfirst >> ${SFWLOG}/install.log 2>&1 || sfwerr "sfwfirst"
  sfwinit >> ${SFWLOG}/install.log 2>&1 || sfwerr "sfwinit"
  ;;
esac
exit 0
