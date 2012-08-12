#!/bin/bash

SFWLOG=/var/log/iptables.log
SFWREP=/var/log/sfwreport.log
SFWMAIL=root@`hostname -f`

grep "iptables.* IN" "$SFWLOG" | sed s/"^.*iptables"/"iptables"/g | sed s/" "/"\n"/g
  grep "IN=\|OUT=\|SRC=\|DST=\|PROTO=\|SPT\|DPT" | \
  sed s/"iptables-in"/"-A -t filter INPUT "/g
  sed s/"iptables-ou"/"-A -t filter OUTPUT "/g
  sed s/"iptables-fw"/"-A -t filter FORWARD "/g
  sed s/"iptables-npr"/"-A -t nat PREROUTING "/g
  sed s/"iptables-npo"/"-A -t nat POSTROUTING "/g
  sed s/"iptables-nou"/"-A -t nat OUTPUT "/g
  sed s/"IN=\$"//g | \
  sed s/"IN="/'-i '/g | \
  sed s/"OUT=\$"//g | \
  sed s/"OUT="/'-i '/g | \
  sed s/"SRC="/'-s '/g | \
  sed s/"DST="/'-d '/g | \
  sed s/"PROTO="/'-p '//g | \
  sed s/"SPT="/'--sport '/g | \
  sed s/"DPT="/'--dport '/g | \
  sed s/"^"/"\[0:0\] "//g | tee "$SFWREP"



