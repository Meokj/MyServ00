#!/bin/sh

USER_NAME=$(whoami)
HOME_DIR=~/domains/${USER_NAME}.serv00.net

pkill -f filebrowser

if [ -d "$HOME_DIR/filebrowser" ];then
  rm -rf "$HOME_DIR/filebrowser"
fi
echo "✅ File Browser 已卸载完成，未删除该端口，以便下次使用"
