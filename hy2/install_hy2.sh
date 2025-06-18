#!/bin/bash
clear
cd ~
PASSWORD=$1
USERNAME=$(whoami)
CRONJOB="*/2 * * * * ~/hysteria2/check_process.sh"

download() {
  if [ -d ~/hysteria2 ]; then
    rm -rf ~/hysteria2
  fi

  mkdir -p ~/hysteria2
  cd ~/hysteria2

  if fetch -o hysteria2 https://github.com/Meokj/MyServ00/releases/download/1.0.0/hysteria-freebsd-amd64 >/dev/null 2>&1; then
    echo "下载 hysteria2 成功"
  else
    echo "下载 hysteria2 失败"
    exit 1
  fi

  chmod +x hysteria2
}

get_ports() {
  UDP_PORT=""
  TCP_PORT=""
  udp_ports=($(devil port list | awk '$2=="udp"{print $1}'))
  tcp_ports=($(devil port list | awk '$2=="tcp"{print $1}'))

  if [[ ${#udp_ports[@]} -gt 1 ]]; then
    UDP_PORT=${udp_ports[0]}
    for ((i=1; i<${#udp_ports[@]}; i++)); do
      devil port del udp "${udp_ports[i]}"
    done
  elif [[ ${#udp_ports[@]} -eq 1 ]]; then
    UDP_PORT=${udp_ports[0]}  
  else
    while true; do
      rand_udp_port=$(shuf -i 10000-65535 -n 1)
      result=$(devil port add udp "$rand_udp_port" hy2 2>&1)
      if [[ $result == *"Ok"* ]]; then
        UDP_PORT=$rand_udp_port
        break
      fi
    done
  fi

  if [[ ${#tcp_ports[@]} -gt 1 ]]; then
    TCP_PORT=${tcp_ports[0]}
    for ((i=1; i<${#tcp_ports[@]}; i++)); do
      devil port del tcp "${tcp_ports[i]}"
    done
  elif [[ ${#tcp_ports[@]} -eq 1 ]]; then
    TCP_PORT=${tcp_ports[0]}  
  else
    while true; do
      rand_tcp_port=$(shuf -i 10000-65535 -n 1)
      result=$(devil port add tcp "$rand_tcp_port" traffic 2>&1)
      if [[ $result == *"Ok"* ]]; then
        TCP_PORT=$rand_tcp_port
        break
      fi
    done
  fi
}

generate_configuration() {
  openssl ecparam -genkey -name prime256v1 -out "private.key"
  openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=${USERNAME}.serv00.net"

  cat >config.yaml <<EOF
listen: ${IP}:${UDP_PORT}
tls:
  cert: cert.pem
  key: private.key
  alpn:
    - h3
speedTest: true
auth:
  type: userpass
  userpass:
    ${USERNAME}: ${PASSWORD}
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
    insecure: true
trafficStats:
  listen: 127.0.0.1:${TCP_PORT}
  secret: ${PASSWORD}
outbounds:
  - name: only_ipv4
    type: direct
    direct:
      mode: 4             
      fast_open: false    
rules:
  - type: field
    outbound: only_ipv4   
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
          IP="$THIRD_IP"
          return  
      fi
      sleep 1
  done

  for ((RETRIES=0; RETRIES<$MAX_RETRIES; RETRIES++)); do
      RESPONSE=$(curl -s --max-time 2 "${API_URL}/${FIRST_IP}")
      if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
          IP="$FIRST_IP"
          return  
      fi
      sleep 1
  done
  IP="$SECOND_IP"
}

run_hysteria2() {
  if [ -e "hysteria2" ]; then
    nohup ./hysteria2 server -c config.yaml >/dev/null 2>&1 &
    sleep 2
    echo
    pgrep -x "hysteria2" >/dev/null && echo "hysteria2 正在运行" || {
      echo "hysteria2 未运行, 正在重启"
      pkill -x "hysteria2"
      nohup ./hysteria2 server -c config.yaml >/dev/null 2>&1 &
      sleep 2
      echo "hysteria2 已经重新启动"
    }
    pgrep -x "hysteria2" >/dev/null || {
      echo "hysteria2 启动失败，退出脚本"
      ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk '{print $2}' | xargs -r kill -9 >/dev/null 2>&1
      rm -rf ~/hysteria2
      exit 1
    }
  fi
  sleep 1
}

get_links() {
 ISP=$(curl -s --max-time 2 https://speed.cloudflare.com/meta | awk -F\" '{print $26}' | sed -e 's/ /_/g' || echo "0")
 NUMBER=$(hostname | cut -d '.' -f1)
    cat >list.txt <<EOF
hysteria2://***@$IP:$UDP_PORT/?sni=www.bing.com&alpn=h3&insecure=1#${ISP}-${NUMBER}-${USERNAME}
EOF
  echo
  echo "复制以下节点信息并修改密码，格式：username:password"
  cat list.txt
  echo

  sleep 3
}

scheduled_task() {
  cat <<'EOF' >"check_process.sh"
#!/bin/bash
if ! pgrep -f hysteria2 > /dev/null; then
  cd ~/hysteria2
  nohup ./hysteria2 server -c config.yaml >/dev/null 2>&1 &
fi
EOF

  chmod +x "check_process.sh"
  (
    crontab -l 2>/dev/null | grep -v -F "$CRONJOB"
    echo "$CRONJOB"
  ) | crontab -
  echo "已添加定时任务每2分钟检测一次该进程，如果不存在则后台启动"
}

download
get_ip
get_ports
generate_configuration
run_hysteria2
scheduled_task
get_links
