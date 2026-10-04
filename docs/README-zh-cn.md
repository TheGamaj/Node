<p align="center">
  <a href="../README.md">English</a> /
  <a href="./README-fa.md">فارسی</a> /
  <a href="./README-ru.md">Русский</a> /
  <a href="./README-zh-cn.md">简体中文</a>
</p>

<p align="center">
  <img src="../assets/brand/gamaj-node-logo.svg" alt="Gamaj Node" width="104" height="104">
</p>

<h1>GAMAJ</h1>

### Node

**Gamaj Node** 是 **Gamaj** 生态的数据平面：在任意数量的服务器上运行 Xray 与 VPN 协议，并通过 mTLS 双向认证的 gRPC 通道向面板上报健康状态、会话与流量。

## 快速安装

将 Gamaj-node 安装为原生二进制服务：

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install
```

使用自定义节点名（同一主机上的第二个节点）：

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --name gamaj-node2
```

安装指定版本：

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --version is.0.0.1
```

仅安装 `gamaj-node` 命令脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install-script
```

所有节点都使用相同的原生二进制安装。没有容器安装，也没有安装模式切换：OpenVPN、WireGuard、L2TP、PPTP、Remote Access 和 Extra VPN 在标准节点上全部可用。

WireGuard 运行时细节：首次使用时，节点会安装 `wireguard-tools` 与 `nftables`，加载内核模块，并为每个入站创建一个内核接口。默认情况下，每个入站的 TCP/UDP 流量通过 nftables TPROXY 转发到其 Xray 隧道端口，因此 Gamaj 路由规则仍然生效。只有当运行时显式设置 `nat_enabled=true` 时才使用直接 MASQUERADE/NAT。面板在共享运行时信封（`ov_runtime_json`）的 `wg_inbounds` 键下推送 WireGuard 状态；每个入站包含服务器 `private_key`、`address_pool`、`listen_port`、`tunnel_port` 以及 `peers` 列表（`public_key`、可选的 `preshared_key`、`address`）。每个对等端的 rx+tx 流量从内核读取，并以 `wg:<user_id>` 用量增量的形式上报给面板。

使用 `help` 查看所有命令：

```bash
gamaj-node help
```

控制端口默认为 `62050`（Xray API 位于 `62051`）。使用 `--name` 和面板的节点表单可以在同一主机上运行多个节点。

## 手动安装

完整安装指南：[INSTALL.md](INSTALL.md)

## 运行时

Gamaj Node 使用 Go 实现，只提供一个主机级二进制：

- `gamaj-node`：面板用来控制 Xray 并调度安全的主机重启/更新命令的 mTLS 双向认证 gRPC 服务

## 二进制构建

发布资产以原始可执行文件的形式为所有受支持的目标发布：

- `gamaj-node-<version>-linux-386`
- `gamaj-node-<version>-linux-amd64`
- `gamaj-node-<version>-linux-arm64`
- `gamaj-node-<version>-linux-armv5`
- `gamaj-node-<version>-linux-armv6`
- `gamaj-node-<version>-linux-armv7`
- `gamaj-node-<version>-linux-s390x`
- `gamaj-node-<version>-windows-amd64.exe`

也可以在本地复现 CI 打包流程：

```bash
go run ./tools/build
go run ./tools/smoke
```

Go 包可以直接检查：

```bash
go test ./...
```

## 测试

```bash
bash scripts/tests/e2e-node-install.sh   # 安装并启动节点，然后检查控制端口
```

端到端脚本需要 Linux、systemd、root 和 Go。在其他平台上它输出 `SKIP` 并成功退出。

## 参与贡献

贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)。
