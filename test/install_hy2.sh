#!/bin/bash
clear

PASSWORD=$1

if [ -d ~/hysteria2 ]; then
  rm -rf ~/hysteria2
fi

mkdir -p ~/hysteria2
cd ~/hysteria2

fetch https://github.com/apernet/hysteria/releases/latest/download/hysteria-freebsd-amd64
chmod +x hysteria-freebsd-amd64
mv hysteria-freebsd-amd64 hysteria2

USERNAME=$(whoami)

get_udp_port() {
  local udp_port
  udp_port=$(devil port list | awk '$2=="udp"{print $1; exit}')

  if [[ -n "$udp_port" ]]; then
    :
  else
    local port_lines port_count random_port result rand_port
    port_lines=$(devil port list | awk 'NR>1')
    port_count=$(echo "$port_lines" | wc -l)

    if [[ $port_count -ge 3 ]]; then
      random_port=$(echo "$port_lines" | shuf -n 1 | awk '{print $1}')
      devil port remove "$random_port"
    fi

    while true; do
      rand_port=$(shuf -i 10000-65535 -n 1)
      result=$(devil port add udp "$rand_port" 2>&1)
      if [[ $result == *"Ok"* ]]; then
        udp_port=$rand_port
        break
      fi
    done
  fi
  echo "$udp_port"
}

UDP_PORT=$(get_udp_port)

generate_configuration() {
  openssl ecparam -genkey -name prime256v1 -out "private.key"
  openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=${USERNAME}.serv00.net"

  cat >config.yaml <<EOF
listen: 0.0.0.0:${UDP_PORT}
tls:
  cert: cert.pem
  key: private.key
  insecure: true
speedTest: true
auth:
  type: password
  password: ${PASSWORD}
EOF
}

get_ip() {
  IP_LIST=($(devil vhost list | awk '/^[0-9]+/ {print $1}'))
  API_URL="https://status.eooce.com/api"
  IP=""
  MAX_RETRIES=3
  THIRD_IP=${IP_LIST[2]}
  SECOND_IP=${IP_LIST[1]}
  FIRST_IP=${IP_LIST[0]}

  for ((RETRIES=0; RETRIES<$MAX_RETRIES; RETRIES++)); do
      RESPONSE=$(curl -s --max-time 2 "${API_URL}/${THIRD_IP}")
      if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
          IP=$THIRD_IP
          return  
      fi
      sleep 1
  done

  for ((RETRIES=0; RETRIES<$MAX_RETRIES; RETRIES++)); do
      RESPONSE=$(curl -s --max-time 2 "${API_URL}/${FIRST_IP}")
      if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
          IP=$FIRST_IP
          return  
      fi
      sleep 1
  done
  IP=$SECOND_IP
  echo "$IP"
}

IP=$(get_ip)

get_links() {
    cat >list.txt <<EOF
hysteria2://${PASSWORD}@$IP:$UDP_PORT/?sni=www.bing.com&alpn=h3&insecure=1#${USERNAME}
EOF
  echo
  echo "$hysteria2节点信息如下："
  cat list.txt
  echo

  sleep 3
}

generate_configuration
get_links
