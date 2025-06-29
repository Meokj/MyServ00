#!/bin/sh
clear

get_or_create_filebrowser_port() {
  PORT=""	
  all_ports=($(devil port list | awk '$1 ~ /^[0-9]+$/ {print $1}'))
  total_ports=${#all_ports[@]}

  if (( total_ports < 3 )); then
    fb_port=$(devil port list | awk '$2 == "tcp" && $NF ~ /filebrowser/ {print $1}')

    if [[ -n "$fb_port" ]]; then
      PORT=$fb_port
    else
      while true; do
        rand_tcp_port=$(shuf -i 10000-65535 -n 1)
        result=$(devil port add tcp "$rand_tcp_port" filebrowser 2>&1)
        if [[ $result == *"Ok"* ]]; then
          PORT=$rand_tcp_port
          break
        fi
      done
    fi
  else
    echo "当前已有 $total_ports 个端口"
    exit 0
  fi
}

install_filebrowser() {
  USER_NAME=$(whoami)
  HOME_DIR=~/domains/${USER_NAME}.serv00.net
  INSTALL_DIR="$HOME_DIR/filebrowser"
  CONFIG_DB="$INSTALL_DIR/filebrowser.db"
  LOG_FILE="$INSTALL_DIR/filebrowser.log"
  SHARE_FILES="$INSTALL_DIR/filebrowser_share"
  DEFAULT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  mkdir -p "$INSTALL_DIR" "$SHARE_FILES"

  echo "下载最新 File Browser..."
  LATEST_RELEASE=$(curl -sL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  FILE_NAME="freebsd-amd64-filebrowser.tar.gz"
  URL="https://github.com/filebrowser/filebrowser/releases/download/$LATEST_RELEASE/$FILE_NAME"

  curl -L "$URL" -o "$INSTALL_DIR/$FILE_NAME" || { echo "下载失败"; return 1; }
  tar -xzf "$INSTALL_DIR/$FILE_NAME" -C "$INSTALL_DIR"
  rm -f "$INSTALL_DIR/$FILE_NAME"
  chmod +x "$INSTALL_DIR/filebrowser"

  echo "初始化配置..."
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config init > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config set --address 127.0.0.1 > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config set --port "$PORT" > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config set --locale zh-cn > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config set --log "$LOG_FILE" > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config set --baseurl / > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" config set --root "$SHARE_FILES" > /dev/null 2>&1
  "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" users add "$USER_NAME" "$DEFAULT_PASSWORD" --perm.admin 

  echo "启动 File Browser（后台）..."
  nohup "$INSTALL_DIR/filebrowser" -d "$CONFIG_DB" > "$LOG_FILE" 2>&1 &

  echo "✅ File Browser 启动完成，运行端口:$PORT"
  echo "🌐 请登录 https://panel15.serv00.com/ 设置websites，否则下面地址无法访问；登陆后请先修改密码，否则只能卸载后重新安装"
  echo "🌐 访问地址: https://$USER_NAME.serv00.net"
  echo "👤 用户名: $USER_NAME"
  echo "🔑 密码: $DEFAULT_PASSWORD"
}

get_or_create_filebrowser_port
install_filebrowser
