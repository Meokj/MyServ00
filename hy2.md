# Serv00 一键快速安装 hy2

---

## ⚠️ 注意事项
- **请不要再使用此脚本，已检测到搭建代理**

---

## 方式一：使用

- 命令后面参数为节点密码：

```bash
bash -c "$(curl -Ls https://raw.githubusercontent.com/Meokj/MyServ00/main/hy2/install_hy2.sh)" -- xxxx
```

- 查看节点信息：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Meokj/MyServ00/main/hy2/node_info.sh)
```

- 卸载：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Meokj/MyServ00/main/hy2/uninstall_hy2.sh)
```

- 恢复初始状态：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Meokj/MyServ00/main/hy2/init_serv00.sh)
```

---

## 方式二：批量使用 & 批量保活 & 批量卸载

- 要查看最新的工作流程运行记录和节点信息，请前往Actions页面

### 批量使用 & 批量保活  

1. 若有多个 Serv00 账号，请使用相同密码  
2. 创建新仓库
3. 启用Actions
4. 创建`keep_hy2.yml`和`uninstall_hy2.yml`
5. 分别复制[keep_hy2.yml](./hy2/yml/keep_hy2.yml)和[uninstall_hy2.yml](./hy2/yml/uninstall_hy2.yml)的内容到对应的yml中并保存
6. 添加三个**仓库机密**：`SERVER_PASSWORD`、`SERVER_HOSTNAME`、`PASSWORD`
7. 添加**仓库变量**`USERNAME_1`，`USERNAME_2`，根据SERV00账号数量以此类推
8. 修改`keep_hy2.yml`两处代码片段：

```bash
strategy:
  matrix:
    server: [1, 2]  # 根据 Serv00 账号数量修改，与下面数字对应，注意格式
```

```bash
      - name: Set server-specific username
        run: |
          case "${{ matrix.server }}" in
            1)
             echo "USERNAME=${{ vars.USERNAME_1 }}" >> $GITHUB_ENV
            ;;
           2)
             echo "USERNAME=${{ vars.USERNAME_2 }}" >> $GITHUB_ENV
           ;;
          esac
```

### 批量卸载

1. 修改`uninstall_hy2.yml`的代码片段同上

---

## 流量使用&在线设备数

- 参考[get_statistics.yml](.github/workflows/get_statistics.yml)

---

## 账号与服务器状态查询

- [Serv00 账号状态查询](https://ac.fkj.pp.ua)  
- [Serv00 服务器状态查询](https://status.eooce.com)

