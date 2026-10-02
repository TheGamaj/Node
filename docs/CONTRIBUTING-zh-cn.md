<p align="center">
  <a href="./CONTRIBUTING.md">English</a> /
  <a href="./CONTRIBUTING-ru.md">Русский</a> /
  <a href="./CONTRIBUTING-zh-cn.md">简体中文</a>
</p>

# 参与开发 Gamaj Node

感谢你的帮助。本项目有一小套不可妥协的规则；写代码之前请先阅读——违反这些规则的拉取请求不会被合并。

## 红线

1. **只使用 Gamaj 这个名字。** 代码、注释、界面文本、文档或资源中不得出现任何其他面板、节点或脚本项目的名称。自动化的环境变量命名守卫与痕迹扫描会在出现此类名称时使构建失败。
2. **不留代理痕迹。** 代码、提交信息或文档中不得提及 AI 助手、代理或自动化工具。提交必须看起来像普通开发者的工作。
3. **唯一的安装路径：原生二进制 + systemd。** 不使用 Docker、compose 文件和安装模式开关；任何功能都不得因安装模式而禁用。所有 VPN 后端（OpenVPN、WireGuard、AmneziaWG、L2TP、PPTP、SSTP 和 MTProto 代理）默认全部启用。
4. **每个环境变量都以 `GAMAJ_NODE_` 开头**（与面板共享的值使用 `GAMAJ_`）。属于操作系统或第三方工具的名称（如 `PATH`）是唯一的例外，并列在守卫清单中。
5. **端口 62050** 始终是节点控制面的默认端口（Xray API 随后位于 62051）。
6. **文档自成体系。** 文档不得让读者“去 GitHub 或其他网站阅读更多”；内容应属于本仓库（以及 `Web/` 文档站）。

## 工作流程

1. 从 `Asli` 分叉或创建分支。
2. 保持改动聚焦；每个拉取请求只做一个主题。
3. 运行与你改动相关的检查：

```bash
cd Node
gofmt -l .                       # 无输出
go build ./... && go vet ./internal/... ./cmd/...
go test ./internal/config/ ./internal/platform/envguard/

# 修改了安装器或测试脚本时：
bash -n scripts/gamaj/gamaj-node.sh scripts/tests/e2e-node-install.sh

# 完整端到端安装（Linux + systemd + root，CI 每次推送都会运行）：
sudo bash scripts/tests/e2e-node-install.sh
```

4. 如果改动了 `internal/xray/` 下的任何内容，请运行完整测试套件：
   `go test ./...`。

## 提交信息

简短、祈使语气、说明改动本身，例如：

```
Fail fast when the Xray binary cannot be executed
Report WireGuard handshake age in the node status
```

不要添加工具页脚、generated-by 行或 co-author 尾注。提交的作者与提交者必须是您自己的 Git 身份。

## 代码风格

- Go：`gofmt`、`go vet`、用 `%w` 包装错误、表驱动测试放在所覆盖的包旁边。
- Shell：`set -euo pipefail`、以 `GAMAJ_NODE_` 为前缀的选项、除常见 POSIX 工具加 `curl`、`jq`、`tar` 外不依赖外部程序。
- CI 资产：AmneziaWG 与 accel-ppp 套件在原生运行器上用 musl 工具链构建——绝不要重新引入容器运行时。

## 供应商代码

`vendor/` 目录是普通的 Go vendor 目录；保持它与 `go.mod` 一致。不要手工修改供应商包，也不要让 `.gitignore` 规则泄漏进 `vendor/`（运行时下载的忽略规则必须锚定，例如 `/xray-core`）。

## 报告问题

请附上：节点版本（`gamaj-node version` 或发布标签）、操作系统与架构、日志输出（`journalctl -u gamaj-node -n 100`）以及最小复现步骤。安全问题请私下联系维护者——对于任何可能可被利用的问题，不要公开创建 issue。
