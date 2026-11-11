
# Cloudflare WARP IPv4 Installer

适用于纯 IPv6 VPS 的 Cloudflare WARP 安装脚本。

## 支持系统

- Ubuntu 22.04 / 24.04 / 26.04
- Debian 12 / 13
- AMD64 / ARM64

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/你的用户名/warp-ipv4-installer/main/install.sh)
```

## 查看状态

```bash
warp-cli status
```

## 检查 WARP

```bash
curl -4 https://www.cloudflare.com/cdn-cgi/trace
```

出现以下内容表示 WARP 已生效：

```text
warp=on
```

## 查看出口 IP

IPv4:

```bash
curl -4 https://api.ipify.org
```

IPv6:

```bash
curl -6 https://api64.ipify.org
```

## 断开 WARP

```bash
warp-cli disconnect
```

## 重新连接

```bash
warp-cli connect
```

## 卸载

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/你的用户名/warp-ipv4-installer/main/uninstall.sh)
```

## 注意事项

1. WARP 出口 IP 和地理位置不保证固定。
2. WARP 可能改变服务器默认网络路由。
3. 可能影响已有 Tailscale、SSH 和代理转发服务。
4. 本项目使用 Cloudflare 官方软件源和官方客户端。
