#!/bin/bash -xv

MYIP=`env LC_ALL=C /sbin/ifconfig | \
  grep "inet addr" | \
  awk -F\: '{print $2}' | \
  sed s/" [A-z]*"//g | \
  grep -v 127.0 | \
  head -1`

SFWLOG=/var/log/iptables.log
SFWREP=/var/log/sfwreport.log
SFWMAIL=root@`hostname -f`

grep "iptables.* IN" "$SFWLOG" | \
  sed s/"^\(.*\)\( iptables-[a-z]* IN=\)"/"\2"/g | \
  sed s/" "/"\n"/g | \
  grep "IN=\|OUT=\|SRC=\|DST=\|PROTO=\|SPT=\|DPT=\|TYPE=\|iptables" | \
  sed s/'iptables-in'/' INPUT '/g | \
  sed s/'iptables-ou'/' OUTPUT '/g | \
  sed s/'iptables-fw'/' FORWARD '/g | \
  sed s/'iptables-npr'/' PREROUTING '/g | \
  sed s/'iptables-npo'/' POSTROUTING '/g | \
  sed s/'iptables-nou'/' OUTPUT '/g | \
  sed s/"IN=\$"//g | \
  sed s/"IN="/' -i '/g | \
  sed s/"OUT=\$"//g | \
  sed s/"OUT="/' -i '/g | \
  sed s/"SRC="/' -s '/ | \
  sed s/"DST="/' -d '/g | \
  sed s/"PROTO="/' -p '/g | \
  sed s/"SPT="/' --sport '/g | \
  sed s/"DPT="/' --dport '/g | \
  sed s/"TYPE="/' --icmp-type '/g | \
  sed s/"-[sd] $MYIP"//g | \
  sed s/"TCP"/'tcp -m tcp'/g | \
  sed s/"UDP"/'udp -m udp'/g | \
  sed s/"ICMP"/'icmp -m icmp'/g | \
  xargs echo -n | \
  sed s/"dport [0-9]*"/"&\n"/g | \
  sed s/"^"/"\[0:0\] -A "/g | \
  sed s/'\(--icmp-type [0-9]*\) \[.*'/" \1 "/g | \
  sed s/"  *"/" "/g | \
  sort -k 4 -u > "$SFWREP"



