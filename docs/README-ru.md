<p align="center">
  <a href="../README.md">English</a> /
  <a href="./README-fa.md">فارسی</a> /
  <a href="./README-ru.md">Русский</a> /
  <a href="./README-zh-cn.md">简体中文</a>
</p>

<p align="center">
  <img src="../assets/brand/gamaj-mark.svg" alt="Gamaj" width="104" height="104">
</p>

<h1>GAMAJ</h1>

### Node

**Gamaj Node** — плоскость данных экосистемы **Gamaj**: запускает Xray и VPN-протоколы на любом числе серверов и отдаёт здоровье, сессии и трафик в панель по двустороннему gRPC-каналу с mTLS.

## Быстрая установка

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install
```

Второй узел на том же хосте:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --name gamaj-node2
```

Конкретный релиз:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --version is.0.0.1
```

Только командный скрипт `gamaj-node`:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install-script
```

Все узлы работают на одном нативном бинарнике. Никаких контейнеров и режимов установки: OpenVPN, WireGuard, L2TP, PPTP, Remote Access и Extra VPN доступны на стандартном узле.

## WireGuard

При первом использовании узел ставит `wireguard-tools` и `nftables`, загружает модуль ядра и создаёт по одному интерфейсу на inbound. По умолчанию TCP/UDP каждого inbound идёт через nftables TPROXY на порт туннеля Xray, поэтому правила маршрутизации Gamaj продолжают работать. Прямой MASQUERADE/NAT включается только при `nat_enabled=true` в runtime. Панель присылает состояние WireGuard в общем runtime-конверте (`ov_runtime_json`) под ключом `wg_inbounds`; каждый inbound содержит `private_key`, `address_pool`, `listen_port`, `tunnel_port` и список `peers`. Расход rx+tx каждого peer читается из ядра и отправляется в панель как дельты `wg:<user_id>`.

## Команды

Порт управления по умолчанию — `62050` (Xray API на `62051`). Несколько узлов на хосте — через `--name` и форму узла в панели.

```bash
gamaj-node help
```

## Ручная установка

Полное руководство: [INSTALL.md](INSTALL.md)

## Runtime

Gamaj Node написан на Go и поставляет один бинарник уровня хоста:

- `gamaj-node`: gRPC-сервис с взаимной аутентификацией, через который панель управляет Xray и планирует безопасные restart/update

## Сборки

Артефакты релиза публикуются как сырые исполняемые файлы:

- `gamaj-node-<version>-linux-{386,amd64,arm64,armv5,armv6,armv7,s390x}`
- `gamaj-node-<version>-windows-amd64.exe`

Локальное воспроизведение CI-упаковки:

```bash
go run ./tools/build
go run ./tools/smoke
go test ./...
```

## Тесты

```bash
bash scripts/tests/e2e-node-install.sh   # установка и запуск узла + проверка порта управления
```

Скрипту нужны Linux, systemd, root и Go; на других платформах он сообщает `SKIP`.

## Участие

Руководство для контрибьюторов: [CONTRIBUTING.md](CONTRIBUTING.md).
