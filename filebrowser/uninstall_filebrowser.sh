#!/bin/sh

USER_NAME=$(whoami)
HOME_DIR=~/domains/${USER_NAME}.serv00.net
SHARE_DIR="$HOME_DIR/filebrowser/filebrowser_share"

echo "⚠️  若有重要内容，请先自行备份该文件夹: $SHARE_DIR 再执行卸载脚本"
echo
echo "是否退出脚本去备份？[y/N]"
read -r CONFIRM

case "$CONFIRM" in
    [yY][eE][sS]|[yY])
        echo "❌ 已取消卸载操作"
        exit 1
        ;;
    *)
        echo "✅ 正在卸载 File Browser..."
        ;;
esac

# 停止运行中的 File Browser
pkill -f filebrowser

# 删除安装目录
if [ -d "$HOME_DIR/filebrowser" ]; then
    rm -rf "$HOME_DIR/filebrowser"
fi

echo "✅ File Browser 已卸载完成（未删除端口配置，以便下次使用）"
