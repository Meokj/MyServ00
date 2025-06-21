#!/bin/sh

USER_NAME=$(whoami)
HOME_DIR=~/domains/${USER_NAME}.serv00.net

pkill -f filebrowser

if [ -d "$HOME_DIR/filebrowser" ];then
  rm -rf "$HOME_DIR/filebrowser"
fi

PORT=$(devil port list | awk '$2 == "tcp" && $NF ~ /filebrowser/ {print $1}')
if [ -n "$PORT" ]; then
  devil port del tcp "$PORT"
fi

echo "✅ File Browser 已卸载完成"
