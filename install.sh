#!/bin/bash
#
# Last Update:	2012/03/01
# Author:	labunix@linux.jp
# for Squeeze eth0 
#
# Environment
# PATH=/sbin:/usr/sbin:/bin:/usr/bin
set -e
# for CentOS
echo $PATH | sed s/":"/"\n"/g | grep "^/sbin\$" || export PATH=/sbin:${PATH}

if [ `id -u` -ne "0" ];then
  echo "Sorry,Permit User!"
  exit 1
fi

SFWLOG='/var/log'
SFWDIR='/etc/sfw'
test -d ${SFWLOG} || mkdir ${SFWLOG} || exit 2
test -d ${SFWDIR} || mkdir ${SFWDIR} || exit 2
touch ${SFWLOG}/uninstall.info || exit 2

# functions

sfwerr() {
  echo "$@"
  exit 255
}

function subinstall() {
  echo $1 >> ${SFWLOG}/uninstall.info
}

function sfwfirst() {
  cp smallfirewall ${SFWDIR}/smallfirewall
  chown root:root ${SFWDIR}/smallfirewall
  chmod 755 ${SFWDIR}/smallfirewall
  /bin/bash -x ${SFWDIR}/smallfirewall || \
    sfwerr "ERROR:/bin/bash -x ${SFWDIR}/smallfirewall"
}

function sfwinit() {
  test -f /etc/init.d/iptables && \
    mv /etc/init.d/iptables /etc/init.d/iptables.org
  cp -f iptables /etc/init.d/iptables
  chown root:root /etc/init.d/iptables
  chmod 755 /etc/init.d/iptables
  # for debian
  test -f /etc/debian_version && insserv -v iptables
  test -f /etc/redhat_release && echo "Redhat or CentOS"
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
  test -f /etc/redhat_release && test -f /etc/init.d/iptables.org && \
    mv /etc/init.d/iptables.org /etc/init.d/iptables
  rm -f ${SFWDIR}/smallfirewall || sfwerr "ERROR:rm -f ${SFWDIR}/smallfirewall"
  rm -fr ${SFWLOG} || sfwerr "ERROR: rm -fr ${SFWLOG}"
  ;;
--repackage)
  SFWWORK="/tmp/sfw-`date '+%Y%m%d'`"
  test -d ${SFWWORK} || mkdir ${SFWWORK} || sfwerr "ERROR: mkdir ${SFWWORK}"
  for list in README install.sh iptables sfwreport smallfirewall ;do
    test -f ${list} && cp ${list} ${SFWWORK}/${list} || \
      sfwerr "ERROR: cp ${list}"
    cp -f ${SFWDIR}/smallfirewall ${SFWWORK}/${list}
  done
  cp -f /etc/init.d/iptables ${SFWWORK}/iptables
  chown -R 65534:65534 ${SFWWORK}
  cd /tmp
  tar zcvf ${SFWWORK}-user.tar.gz "`echo ${SFWWORK} | sed s%/tmp/%%`"
  chown -R 65534:65534 ${SFWWORK}-user.tar.gz
  ;;
*)
  echo "Install..."
  
  dpkg -l chkconfig | grep ^ii || subinstall chkconfig
  dpkg -l insserv | grep ^ii || subinstall insserv
  test -s uninstall.info && sort uninstall.info | uniq | \
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
