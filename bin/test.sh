#!/bin/sh
./pssh-exe A  "sed -i -e s#SYSLOGD_OPTIONS=\"\"#SYSLOGD_OPTIONS=\"-c 2 -r -m 0\"#g /etc/sysconfig/rsyslog"
