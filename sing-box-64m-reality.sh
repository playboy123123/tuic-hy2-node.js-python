#!/bin/bash
# 极简 VLESS-TCP 节点（适配 Pterodactyl / Docker / 只读系统）

set -e

BASE_DIR="$(pwd)/vless"
BIN_PATH="$BASE_DIR/sing-box"
CONF_PATH="$BASE_DIR/config.json"

mkdir -p "$BASE_DIR"

echo "[1/3] 下载 sing-box..."
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) SB_ARCH="amd64" ;;
  aarch64|arm64) SB_ARCH="arm64" ;;
  armv7l|armv7) SB_ARCH="armv7" ;;
  *) echo "不支持架构: $ARCH"; exit 1 ;;
esac

SB_VERSION="1.10.0"
URL="https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/sing-box-${SB_VERSION}-linux-${SB_ARCH}.tar.gz"

TMP_DIR=$(mktemp -d)
curl -L -o "$TMP_DIR/sb.tar.gz" "$URL"
tar -xzf "$TMP_DIR/sb.tar.gz" -C "$TMP_DIR"
cp $(find "$TMP_DIR" -name sing-box) "$BIN_PATH"
chmod +x "$BIN_PATH"
rm -rf "$TMP_DIR"

echo "[2/3] 生成配置..."

UUID=$(cat /proc/sys/kernel/random/uuid)
SERVER_IP="77.90.52.39"
PORT="6844"

cat > "$CONF_PATH" <<EOF
{
  "log": { "disabled": true },
  "inbounds": [
    {
      "type": "vless",
      "listen": "::",
      "listen_port": ${PORT},
      "users": [
        { "uuid": "${UUID}" }
      ],
      "tls": { "enabled": false }
    }
  ],
  "outbounds": [
    { "type": "direct" }
  ]
}
EOF

echo "[3/3] 启动节点..."

pkill -f sing-box || true
nohup "$BIN_PATH" run -c "$CONF_PATH" >/dev/null 2>&1 &

VLESS_LINK="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&security=none&type=tcp#VLESS-TCP"

echo
echo "================= 节点已启动 ================="
echo "VLESS-TCP 节点（不依赖 UDP）"
echo
echo "服务器: ${SERVER_IP}"
echo "端口: ${PORT}"
echo "UUID: ${UUID}"
echo
echo "可直接复制的链接："
echo "${VLESS_LINK}"
echo "=============================================="
