#!/bin/bash

# Wait before postfix is really started.

echo "my docker-entrypoint.sh"

MYHOSTNAME=${SMTP_HOSTNAME:-imran.com}

if [[ -z "${SMTP_RELAY_USERNAME:-}" ]]
then
    echo "SMTP_RELAY_USERNAME must be set"
    exit 1
fi
if [[ -z "${SMTP_RELAY_PASSWORD:-}" ]]
then
    echo "SMTP_RELAY_PASSWORD must be set"
    exit 1
fi
if [[ -z "${SMTP_RELAY_SERVER:-}" ]]
then
    echo "SMTP_RELAY_SERVER must be set"
    exit 1
fi
if [[ -z "${SMTP_RELAY_PORT:-}" ]]
then
    echo "SMTP_RELAY_PORT must be set"
    exit 1
fi


function get_state {
    echo $(script -c 'postfix status' | grep postfix/postfix-script)
}

function modify_main_cf() {
    # Configuration changes needed in main.cf
    echo "Changing postfix configuration"
    postconf -e inet_interfaces=all
    
    postconf -e inet_protocols=ipv4
    newaliases
    
    #postconf -e mynetworks='127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8'

    #enable all IPs since we'll restrict this to the docker swarm
    postconf -e mynetworks='0.0.0.0/0'
    # postconf -e smtpd_relay_restrictions='permit_sasl_authenticated'
    # postconf -e mydomain=${MYHOSTNAME}
    # postconf -e myorigin=${MYHOSTNAME}
    # postconf -e myhostname=mail.${MYHOSTNAME}
    # postconf -e mydestination=${MYHOSTNAME}
    # postconf -e debug_peer_list=smtp.sendgrid.net
    # postconf -e debug_peer_level=3

    # from https://sendgrid.com/docs/Integrate/Mail_Servers/postfix.html
    echo "[${SMTP_RELAY_SERVER}]:${SMTP_RELAY_PORT} ${SMTP_RELAY_USERNAME}:${SMTP_RELAY_PASSWORD}" > /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd

    postconf -e smtp_sasl_auth_enable=yes
    postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
    postconf -e smtp_sasl_security_options=noanonymous
    postconf -e smtp_sasl_tls_security_options=noanonymous
    postconf -e smtp_tls_security_level=encrypt
    postconf -e header_size_limit=4096000
    postconf -e relayhost=[${SMTP_RELAY_SERVER}]:${SMTP_RELAY_PORT}
}

# https://sendgrid.com/docs/Integrate/Mail_Servers/postfix.html

rsyslogd

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