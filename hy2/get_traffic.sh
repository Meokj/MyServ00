#!/bin/bash
clear
PASSWORD=$1
USERNAME=$(whoami)

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

get_traffic_data() {
    response=$(curl -s -w "%{http_code}" -H "Authorization: ${PASSWORD}" http://127.0.0.1:${TCP_PORT}/traffic)
    http_code="${response: -3}"  
    json_data="${response:0:${#response}-3}" 

    if [[ "$http_code" -ne 200 ]]; then
        echo "获取流量信息失败，状态码: $http_code"
        echo
        return 1
    fi

    tx=$(echo "$json_data" | jq ".\"$USERNAME\".tx")
    rx=$(echo "$json_data" | jq ".\"$USERNAME\".rx")

    tx_gb=$(echo "scale=2; $tx / 1024 / 1024 / 1024" | bc)
    rx_gb=$(echo "scale=2; $rx / 1024 / 1024 / 1024" | bc)

    output=""

    if (( $(echo "$tx_gb < 1" | bc -l) )); then
        tx_mb=$(echo "scale=2; $tx / 1024 / 1024" | bc)
        output+="上传: $(printf "%.2f" "$tx_mb") MB "
    else
        output+="上传: $(printf "%.2f" "$tx_gb") GB "
    fi

    if (( $(echo "$rx_gb < 1" | bc -l) )); then
        rx_mb=$(echo "scale=2; $rx / 1024 / 1024" | bc)
        output+="下载: $(printf "%.2f" "$rx_mb") MB"
    else
        output+="下载: $(printf "%.2f" "$rx_gb") GB"
    fi
    echo "$output"
    echo "账号：$USERNAME"
    echo
}

get_ports
get_traffic_data
