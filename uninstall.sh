
#!/usr/bin/env bash
# Cloudflare WARP 卸载脚本

set -Eeuo pipefail

[[ $EUID -eq 0 ]] || {
    echo "请使用 root 权限运行"
    exit 1
}

echo "[WARP] 正在断开连接..."

if command -v warp-cli >/dev/null 2>&1; then
    warp-cli disconnect || true
fi

echo "[WARP] 停止服务..."

systemctl disable --now warp-svc 2>/dev/null || true

echo "[WARP] 卸载客户端..."

apt-get remove -y cloudflare-warp || true

echo "[WARP] 清理软件源..."

rm -f /etc/apt/sources.list.d/cloudflare-client.list
rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

apt-get update

echo "[WARP] 卸载完成"
echo "注意：如需彻底清除客户端注册数据，请另行检查 /var/lib/cloudflare-warp/"
