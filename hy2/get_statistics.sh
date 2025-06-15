#!/bin/bash
clear
PASSWORD=$1
USERNAME=$(whoami)
CONFIG_FILE=~/hysteria2/config.yaml
echo "账号：$USERNAME"

check_process(){
  if ! pgrep -f hysteria2 > /dev/null; then
    echo "hysteria2 未运行"
    exit 0
  fi
}

get_tcp_port() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "配置文件不存在：$CONFIG_FILE"
    exit 0
  fi
  TCP_PORT=$(yq e '.trafficStats.listen' "$CONFIG_FILE" | grep -oE '[0-9]+$')
  if [[ -z "$TCP_PORT" ]]; then
    echo "未能从配置文件中解析出端口号"
    exit 0
  fi
}

get_traffic() {
    response=$(curl -s -w "%{http_code}" -H "Authorization: ${PASSWORD}" http://127.0.0.1:${TCP_PORT}/traffic)
    http_code="${response: -3}"  
    json_data="${response:0:${#response}-3}" 

    if [[ "$http_code" -ne 200 ]]; then
        echo "获取已使用流量信息失败，状态码: $http_code"
        return 1
    fi

    tx=$(echo "$json_data" | jq ".\"$USERNAME\".tx")
    rx=$(echo "$json_data" | jq ".\"$USERNAME\".rx")

    tx_gb=$(echo "scale=2; $tx / 1024 / 1024 / 1024" | bc)
    rx_gb=$(echo "scale=2; $rx / 1024 / 1024 / 1024" | bc)

    if (( $(echo "$tx_gb < 1" | bc -l) )); then
        tx_mb=$(echo "scale=2; $tx / 1024 / 1024" | bc)
        echo "上传: $(printf "%.2f" "$tx_mb") MB"
    else
        echo "上传: $(printf "%.2f" "$tx_gb") GB"
    fi

    if (( $(echo "$rx_gb < 1" | bc -l) )); then
        rx_mb=$(echo "scale=2; $rx / 1024 / 1024" | bc)
        echo "下载: $(printf "%.2f" "$rx_mb") MB"
    else
        echo "下载: $(printf "%.2f" "$rx_gb") GB"
    fi
}

get_online_num(){
    response=$(curl -s -w "%{http_code}" -H "Authorization: ${PASSWORD}" http://127.0.0.1:${TCP_PORT}/online)
    http_code="${response: -3}"  
    json_data="${response:0:${#response}-3}" 

    if [[ "$http_code" -ne 200 ]]; then
        echo "获取当前在线设备数失败，状态码: $http_code"
        return 1
    fi
    
    num=$(echo "$json_data" | jq ".\"$USERNAME\"")

    if [[ -z "$num" || "$num" == "null" ]]; then
      num=0
    fi

    echo "当前在线设备数: $num"
}

check_process
get_tcp_port
get_online_num
get_traffic
echo
