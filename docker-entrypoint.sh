#!/bin/bash

# Wait before postfix is really started.

echo "my docker-entrypoint.sh"

MYHOSTNAME=${SMTP_HOSTNAME:-imran.com}

function get_state {
    echo $(script -c 'postfix status' | grep postfix/postfix-script)
}

function modify_main_cf() {
    # Configuration changes needed in main.cf
    echo "Changing postfix configuration"
    postconf -e inet_interfaces=all
    postconf -e myorigin=/etc/mailname
    postconf -e mynetworks='127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8'
    postconf -e smtpd_relay_restrictions='permit_mynetworks permit_sasl_authenticated defer_unauth_destination'
    postconf -e mydomain=${MYHOSTNAME}
    postconf -e myhostname=mail.${MYHOSTNAME}
    postconf -e mydestination=${MYHOSTNAME}
    postconf -e debug_peer_level=3
}

modify_main_cf

postfix -D -v start
echo $(get_state)

while true; do
    state=$(get_state)
    if [[ "$state" != "${state/is running/}" ]]; then
        PID=${state//[^0-9]/}
        if [[ -z $PID ]]; then
            continue
        fi
        if [[ ! -d "/proc/$PID" ]]; then
            echo "Postfix proces $PID does not exist."
            break
        fi
    else
        echo "Postfix is not running."
        break
    fi
done