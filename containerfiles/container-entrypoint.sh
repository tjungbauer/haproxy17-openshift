#!/bin/bash

export TZ=${TZ:-UTC}
export LOGLEVEL=${LOGLEVEL:-notice}
export SYSLOG_ADDRESS=${SYSLOG_ADDRESS:-/tmp/haproxy_syslog}

if [[ -n "${DEBUG}" ]]; then

 set -x

echo "Current ENV Values"
echo "==================="
echo "SERVICE_NAME        :"${SERVICE_NAME}
echo "SERVICE_DEST        :"${SERVICE_DEST}
echo "SERVICE_DEST_PORT   :"${SERVICE_DEST_PORT}
echo "TZ                  :"${TZ}
echo "SYSLOG_ADDRESS      :"${SYSLOG_ADDRESS}
echo "CONFIG_FILE         :"${CONFIG_FILE}
echo "given DNS_SRV001    :"${DNS_SRV001}
echo "given DNS_SRV002    :"${DNS_SRV002}

echo "HAProxy Version:"

/usr/local/sbin/haproxy -vv

fi

if [[ -z "${SERVICE_DEST}" ]];
then
  echo "Error the SERVICE_DEST MUST be defined"
  exit 1
fi

if [[ -z "${SERVICE_NAME}" ]];
then
  echo "Error the SERVICE_NAME MUST be defined"
  exit 1
fi

if [[ -z "${SERVICE_DEST_PORT}" ]];
then
  echo "Error the SERVICE_DEST_PORT MUST be defined"
  exit 1
fi

if [[ -z "${SYSLOG_ADDRESS}" ]];
then
  echo "Error the SYSLOG_ADDRESS MUST be defined"
  exit 1
fi

if [[ -z  "${DNS_SRV001}" ]];
then
  dns_counter=1
  for i in $( egrep ^nameserver /etc/resolv.conf|awk '{print $2}' ) ; do
    export DNS_SRV00${dns_counter}=$i
    let "dns_counter++"
  done
fi

if [[ -z "${DNS_SRV001}" ]];
then
  echo "Error the DNS_SRV001 MUST be defined"
  exit 1
fi

if [[ -z "${DNS_SRV002}" ]];
then
  export DNS_SRV002=${DNS_SRV001}
fi

if [[ -n "${DEBUG}" ]]; then
  echo "==================="
  echo "compute DNS_SRV001  :"${DNS_SRV001}
  echo "compute DNS_SRV002  :"${DNS_SRV002}
fi

if [[ -z "${CONFIG_FILE}" ]];
then
  counter=0
  for i in $( echo ${SERVICE_DEST}| sed -e 's/;/ /g') ; do
    if [[ $SERVICE_DEST == *":"* ]]; then
      SERVICE_PORT="" 
    else 
      SERVICE_PORT=":"${SERVICE_DEST_PORT}
    fi
    #server_lines=${server_lines}$(echo -e server "${SERVICE_NAME}_"$(printf "%03i" "$counter") ${i}:${SERVICE_DEST_PORT} check \\\\\n)
    server_lines=${server_lines}$(echo -e server "${SERVICE_NAME}_"$(printf "%03i" "$counter") ${i}${SERVICE_PORT} check \\\\\n)
    let "counter++"
  done
  CONFIG_FILE=/tmp/haproxy.conf
  # ${server_lines}
  sed -e "s/server_lines/${server_lines}/" /usr/local/etc/haproxy/haproxy.conf.template > ${CONFIG_FILE}

  if [[ $MOD_HEADERS != "" ]]; then
    counter=0
    for i in $( echo ${MOD_HEADERS}| sed -e 's/;/ /g') ; do

      add_headers=${add_header}$(echo -e "${i}" \\\\\n)
      let "counter++"
    done
  else
    add_headers=""
  fi
  sed -i -e "s/add_headers/${add_headers}/" ${CONFIG_FILE}
fi

echo "using CONFIG_FILE   :"${CONFIG_FILE}

echo "Loaded env:"
echo `env`

echo "Loaded configuration"
LOAD=`cat ${CONFIG_FILE}`
echo $LOAD

echo "starting socklog"
/usr/local/bin/socklog unix /tmp/haproxy_syslog &

echo "wait for socklog to come up"
sleep 5

if [[ -n "${DEBUG}" ]]; then
  exec /usr/local/sbin/haproxy -f ${CONFIG_FILE} -d
else
  exec /usr/local/sbin/haproxy -f ${CONFIG_FILE} -db
fi
