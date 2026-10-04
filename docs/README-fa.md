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

<p align="center">
  <a href="https://github.com/TheGamaj/Node/releases"><img alt="Release" src="https://img.shields.io/badge/release-is.0.0.1-2ea043?style=flat-square" /></a>
  <img alt="Go" src="https://img.shields.io/badge/Go-1.25+-00ADD8?style=flat-square&logo=go&logoColor=white" />
  <img alt="Port" src="https://img.shields.io/badge/control%20port-62050-blue?style=flat-square" />
  <img alt="License" src="https://img.shields.io/badge/license-AGPL--3.0-lightgrey?style=flat-square" />
  <a href="https://github.com/TheGamaj/Node/actions/workflows/binary-build.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/TheGamaj/Node/binary-build.yml?style=flat-square&label=build" /></a>
  <a href="https://github.com/TheGamaj/Node/actions/workflows/e2e-install.yml"><img alt="E2E" src="https://img.shields.io/github/actions/workflow/status/TheGamaj/Node/e2e-install.yml?style=flat-square&label=e2e%20install" /></a>
</p>

**گمج نود** هواپیمای داده‌ی اکوسیستم **گمج** است: روی هر تعداد سرور، Xray و پروتکل‌های VPN را اجرا می‌کند و سلامت، نشست‌ها و ترافیک را از طریق یک کانال gRPC دوسویه با احراز هویت mTLS به پنل گزارش می‌دهد.

## نصب سریع

نصب به‌صورت سرویس باینری نیتیو:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install
```

نصب با نام دلخواه (نود دوم روی همان سرور):

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --name gamaj-node2
```

نصب یک نسخه‌ی مشخص:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --version is.0.0.1
```

نصب فقط اسکریپت فرمان `gamaj-node`:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install-script
```

هر نود روی همان مسیر نصب باینری نیتیو اجرا می‌شود. هیچ نصب کانتینری و هیچ سوئیچ حالت نصبی وجود ندارد: OpenVPN، WireGuard، L2TP، PPTP، Remote Access و Extra VPN همه روی یک نود استاندارد فعال‌اند.

## جزئیات WireGuard

در اولین استفاده، نود بسته‌های `wireguard-tools` و `nftables` را نصب می‌کند، ماژول کرنل را بار می‌کند و برای هر inbound یک اینترفیس کرنل می‌سازد. به‌صورت پیش‌فرض ترافیک TCP/UDP هر inbound از طریق nftables TPROXY به پورت تونل Xray هدایت می‌شود تا قواعد مسیریابی گمج اعمال شوند. حالت مستقیم MASQUERADE/NAT فقط وقتی فعال می‌شود که runtime صراحتاً `nat_enabled=true` بدهد. پنل وضعیت WireGuard را داخل پاکت مشترک runtime (`ov_runtime_json`) زیر کلید `wg_inbounds` می‌فرستد؛ هر inbound شامل `private_key` سرور، `address_pool`، `listen_port`، `tunnel_port` و فهرست `peers` (`public_key`، `preshared_key` اختیاری، `address`) است. مصرف rx+tx هر peer از کرنل خوانده و به‌صورت دلتای `wg:<user_id>` به پنل گزارش می‌شود.

## فرمان‌ها

پورت کنترل به‌صورت پیش‌فرض `62050` است (Xray API روی `62051`). با `--name` و فرم نود در پنل می‌توانید چند نود روی یک سرور اجرا کنید.

```bash
gamaj-node help
```

## نصب دستی

راهنمای کامل نصب: [INSTALL.md](INSTALL.md)

## Runtime

گمج نود در Go نوشته شده و یک باینری سطح-هاست دارد:

- `gamaj-node`: سرویس gRPC با احراز هویت دوسویه که پنل از طریق آن Xray را کنترل و فرمان‌های امن ری‌استارت/آپدیت را زمان‌بندی می‌کند

## ساخت‌های باینری

دارایی‌های ریلیز برای همه‌ی هدف‌ها به‌صورت اجرایی خام منتشر می‌شوند:

- `gamaj-node-<version>-linux-386`
- `gamaj-node-<version>-linux-amd64`
- `gamaj-node-<version>-linux-arm64`
- `gamaj-node-<version>-linux-armv5`
- `gamaj-node-<version>-linux-armv6`
- `gamaj-node-<version>-linux-armv7`
- `gamaj-node-<version>-linux-s390x`
- `gamaj-node-<version>-windows-amd64.exe`

بازتولید جریان بسته‌بندی CI به‌صورت لوکال:

```bash
go run ./tools/build
go run ./tools/smoke
```

بررسی مستقیم پکیج‌های Go:

```bash
go test ./...
```

## تست‌ها

```bash
bash scripts/tests/e2e-node-install.sh   # نصب و اجرای نود و سپس چک پورت کنترل
```

اسکریپت end-to-end به لینوکس، systemd، دسترسی root و Go نیاز دارد. روی پلتفرم‌های دیگر `SKIP` گزارش می‌کند و با موفقیت خارج می‌شود.

## مشارکت

راهنمای مشارکت‌کنندگان: [CONTRIBUTING.md](CONTRIBUTING.md) — خط‌های قرمز، جریان بیلد و تست، و قواعد پول‌ریکوئست.
