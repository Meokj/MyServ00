#!/bin/sh
clear

USER_NAME=$(whoami)
NAME="picoshare"
HOME_DIR=~/domains/${USER_NAME}.serv00.net
INSTALL_DIR="$HOME_DIR/picoshare"

echo "🛑 正在停止 PicoShare..."

pkill -f "$INSTALL_DIR/$NAME" 2>/dev/null && echo "✅ 已终止运行中的 PicoShare " || echo "ℹ️ 没有运行中的 PicoShare。"

if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR" && echo "🗑️ 已删除目录：$INSTALL_DIR"
else
  echo "ℹ️ 未找到安装目录：$INSTALL_DIR"
fi

echo "✅ 卸载完成"