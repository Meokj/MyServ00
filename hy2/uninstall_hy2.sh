#!/bin/bash
clear
PROCESS_NAME="hysteria2"
manage_ports() {
    local udp_ports tcp_ports udp_port

    tcp_ports=$(devil port list | awk '$2=="tcp"{print $1}')
    for port in $tcp_ports; do
        devil port del tcp "$port"
    done

    udp_ports=$(devil port list | awk '$2=="udp"{print $1}')

    if [[ $(echo "$udp_ports" | wc -l) -gt 1 ]]; then
        udp_port=$(echo "$udp_ports" | head -n 1)
        echo "$udp_ports" | tail -n +2 | while read -r port; do
            devil port del udp "$port"
        done
    elif [[ $(echo "$udp_ports" | wc -l) -eq 1 ]]; then
        udp_port=$udp_ports
    else
        udp_port=""
    fi

    if [[ -n "$udp_port" ]]; then
        echo "✅ 已删除所有TCP端口，只保留了一个UDP端口"
    else
        echo "✅ 已删除所有TCP端口"
    fi
}

purge_home() {
  cd ~  
  for item in *; do
    if [[ "$item" == "backups" ]]; then
      continue
    fi
    rm -rf "$item"
  done
  echo "✅ 已清除主目录中除 backups 以外的所有内容"
}

pkill -x "$PROCESS_NAME"
sleep 1

if pgrep -x "$PROCESS_NAME" > /dev/null; then
    echo "❌ $PROCESS_NAME 卸载失败，请重试"
    exit 0
else
    echo "" > null
    crontab null
    rm null
    [ -d ~/hysteria2 ] && rm -r ~/hysteria2
    echo "✅ $PROCESS_NAME 卸载成功，已删除相关文件"
    manage_ports
    # purge_home
    exit 0
fi
