#!/bin/bash

pkill -f supervisord
sleep 10
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
