#!/bin/sh
clear
USER_NAME=$(whoami)
NAME="picoshare"
HOME_DIR=~/domains/${USER_NAME}.serv00.net
INSTALL_DIR="$HOME_DIR/picoshare"
DATA_DIR="$INSTALL_DIR/data"
BIN="picoshare-freebsd-amd64"
URL="https://github.com/Meokj/MyServ00/releases/download/1.4.5/picoshare-freebsd-amd64"
ARCHIVE="$INSTALL_DIR/$BIN"

SECRET="$1"

check() {
  local secret="$1"

  if [ -z "$secret" ]; then
    echo "执行脚本时缺少密码参数"
    exit 1
  fi

  if [ ${#secret} -lt 6 ]; then
    echo "密码太短，至少使用 6 位字符。"
    exit 1
  fi

  if echo "$secret" | grep -q '[[:space:]]'; then
    echo "密码不能包含空格。"
    exit 1
  fi

  if ! echo "$secret" | grep -Eq '^[a-zA-Z0-9_]+$'; then
    echo "密码只能包含字母、数字和下划线。"
    exit 1
  fi

  if [ -d "$INSTALL_DIR" ]; then
    echo "目录 $INSTALL_DIR 已存在，请先备份或先执行卸载脚本。"
    exit 1
  fi
}

get_or_create_filebrowser_port() {
  PORT=""
  all_ports=$(devil port list | awk '$1 ~ /^[0-9]+$/ {print $1}')
  total_ports=$(echo "$all_ports" | wc -l)

  if [ "$total_ports" -lt 3 ]; then
    fb_port=$(devil port list | awk '$2 == "tcp" && $NF ~ /picoshare/ {print $1}')
    if [ -n "$fb_port" ]; then
      PORT="$fb_port"
    else
      while true; do
        rand_tcp_port=$(jot -r 1 10000 65535)  # FreeBSD 等效 shuf
        result=$(devil port add tcp "$rand_tcp_port" picoshare 2>&1)
        echo "$result" | grep -q "Ok" && PORT="$rand_tcp_port" && break
      done
    fi
  else
    echo "当前已有 $total_ports 个端口，不再自动分配。"
    exit 1
  fi
}

install_picoshare() {
  mkdir -p "$INSTALL_DIR"
  cd "$INSTALL_DIR" || exit 1

  echo "正在下载 PicoShare..."
  fetch -o "$ARCHIVE" "$URL" || {
    echo "下载失败"
    exit 1
  }

  chmod +x "$ARCHIVE"
  mv "$ARCHIVE" "$NAME"

  mkdir -p "$DATA_DIR"

  echo "启动 PicoShare..."
  nohup env PORT="$PORT" PS_SHARED_SECRET="$SECRET" "$INSTALL_DIR/$NAME" -db "$DATA_DIR/store.db" > /dev/null 2>&1 &

  echo "✅ PicoShare 启动成功"
  echo "🌐 访问地址： http://localhost:$PORT"
  echo "🔐 登录密码： $SECRET"
  echo "📁 数据库存储位置： $DATA_DIR/store.db"
  echo "🛑 停止服务请运行： kill \$(pgrep -f '$NAME')"
}

check "$SECRET"
get_or_create_filebrowser_port
install_picoshare
