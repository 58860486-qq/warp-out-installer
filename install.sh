
#!/usr/bin/env bash
# Cloudflare WARP 一键安装脚本
# 支持 Ubuntu 22.04/24.04/26.04、Debian 12/13
# 支持 AMD64、ARM64

set -Eeuo pipefail

VERSION="1.0.0"
LOG_TAG="[WARP-INSTALL]"

log() {
    echo -e "\033[32m${LOG_TAG}\033[0m $*"
}

warn() {
    echo -e "\033[33m${LOG_TAG}\033[0m $*" >&2
}

error() {
    echo -e "\033[31m${LOG_TAG}\033[0m $*" >&2
}

fail() {
    error "$*"
    exit 1
}

# 检查 root 权限
[[ $EUID -eq 0 ]] || fail "请使用 root 权限运行"

# 检查系统
[[ -f /etc/os-release ]] || fail "无法识别操作系统"

source /etc/os-release

case "$ID" in
    ubuntu)
        case "$VERSION_ID" in
            22.04|24.04|26.04) ;;
            *) fail "暂不支持 Ubuntu ${VERSION_ID}" ;;
        esac
        ;;
    debian)
        case "$VERSION_ID" in
            12|13) ;;
            *) fail "暂不支持 Debian ${VERSION_ID}" ;;
        esac
        ;;
    *)
        fail "暂不支持操作系统：${ID}"
        ;;
esac

# 检查 CPU 架构
ARCH="$(dpkg --print-architecture)"

case "$ARCH" in
    amd64|arm64) ;;
    *) fail "暂不支持 CPU 架构：${ARCH}" ;;
esac

log "操作系统：${PRETTY_NAME}"
log "CPU 架构：${ARCH}"

# 检查网络工具
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl ca-certificates gnupg

# 添加 Cloudflare 官方软件源
install -d -m 0755 /usr/share/keyrings

curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | gpg --yes --dearmor \
    -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

chmod 0644 /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ ${VERSION_CODENAME} main" \
    > /etc/apt/sources.list.d/cloudflare-client.list

# 安装 WARP
log "正在安装 Cloudflare WARP..."

apt-get update
apt-get install -y cloudflare-warp

# 启动服务
systemctl enable warp-svc
systemctl restart warp-svc

sleep 3

# 检查 CLI
command -v warp-cli >/dev/null 2>&1 \
    || fail "WARP CLI 安装失败"

# 注册客户端（已有注册则跳过）
REG_STATUS="$(warp-cli registration show 2>&1 || true)"

if echo "$REG_STATUS" | grep -qiE "not registered|not enrolled|no registration"; then
    log "正在注册 WARP 客户端..."
    warp-cli --accept-tos registration new \
        || fail "WARP 注册失败"
else
    log "检测到已有注册信息，跳过注册"
fi

# 设置 WARP + DNS over HTTPS
log "设置 WARP + DoH 模式..."

warp-cli mode warp+doh

# 连接 WARP
log "正在连接 Cloudflare WARP..."

warp-cli --accept-tos connect

# 等待连接
CONNECTED=0

for i in $(seq 1 20); do
    if curl -4 -fsS --max-time 8 \
        https://www.cloudflare.com/cdn-cgi/trace \
        | grep -q "^warp=on$"; then
        CONNECTED=1
        break
    fi

    sleep 3
done

# 输出结果
echo
echo "========================================"

if [[ "$CONNECTED" -eq 1 ]]; then
    log "WARP IPv4 出口连接成功"
else
    warn "暂未验证 IPv4 出口，请检查网络和 WARP 状态"
fi

echo
log "WARP 状态："
warp-cli status || true

echo
log "Cloudflare Trace："
curl -fsS --max-time 10 \
    https://www.cloudflare.com/cdn-cgi/trace || true

echo
log "IPv4 出口："
curl -4 -fsS --max-time 10 https://api.ipify.org || true

echo
echo

log "IPv6 出口："
curl -6 -fsS --max-time 10 https://api64.ipify.org || true

echo
echo

echo "========================================"
log "安装流程结束，版本：${VERSION}"

if [[ "$CONNECTED" -ne 1 ]]; then
    warn "请检查 warp-cli status 和系统网络路由"
    exit 1
fi
