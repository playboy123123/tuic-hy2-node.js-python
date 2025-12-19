#!/bin/sh
# 64M 小鸡专用：VLESS + Reality（监听 443）
# 外网端口你自己映射为 6844 即可

set -e

SB_VERSION="1.10.0"

echo "[1/5] 检测架构..."
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) SB_ARCH="amd64" ;;
  aarch64|arm64) SB_ARCH="arm64" ;;
  armv7l|armv7) SB_ARCH="armv7" ;;
  *) echo "不支持架构: $ARCH"; exit 1 ;;
esac

download() {
  URL="$1"
  OUT="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -L -o "$OUT" "$URL"
  else
    wget -O "$OUT" "$URL"
  fi
}

echo "[2/5] 下载 sing-box..."
TMP_DIR="$(mktemp -d)"
SB_TAR="$TMP_DIR/sb.tar.gz"
SB_URL="https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/sing-box-${SB_VERSION}-linux-${SB_ARCH}.tar.gz"

download "$SB_URL" "$SB_TAR"
tar -xzf "$SB_TAR" -C "$TMP_DIR"
install -m 755 "$(find "$TMP_DIR" -name sing-box)" /usr/local/bin/sing-box
rm -rf "$TMP_DIR"

echo "[3/5] 生成 Reality 密钥..."
KEY_OUT="$(sing-box generate reality-keypair)"
PRIVATE_KEY="$(echo "$KEY_OUT" | grep PrivateKey | awk '{print $2}')"
PUBLIC_KEY="$(echo "$KEY_OUT" | grep PublicKey | awk '{print $2}')"

UUID="$(cat /proc/sys/kernel/random/uuid)"
SHORT_ID="$(head -c 8 /dev/urandom | hexdump -v -e '/1 "%02x"' | cut -c1-8)"

HANDSHAKE_DOMAIN="www.microsoft.com"
LISTEN_PORT=443
OUTER_PORT=6844
SERVER_IP="77.90.52.39"

echo "[4/5] 写入配置..."
mkdir -p /etc/sing-box

cat >/etc/sing-box/config.json <<EOF
{
  "log": { "disabled": true },
  "inbounds": [
    {
      "type": "vless",
      "listen": "::",
      "listen_port": ${LISTEN_PORT},
      "users": [
        { "uuid": "${UUID}", "flow": "xtls-rprx-vision" }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${HANDSHAKE_DOMAIN}",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "${HANDSHAKE_DOMAIN}",
            "server_port": 443
          },
          "private_key": "${PRIVATE_KEY}",
          "short_id": ["${SHORT_ID}"]
        }
      }
    }
  ],
  "outbounds": [
    { "type": "direct" }
  ]
}
EOF

echo "[5/5] 写入 systemd..."
cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=sing-box VLESS Reality
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now sing-box

echo
echo "================= 完成 ================="
echo "你的 Reality 节点信息如下："
echo
echo "服务器 IP: ${SERVER_IP}"
echo "外网端口: ${OUTER_PORT}"
echo "本机监听端口: ${LISTEN_PORT}"
echo
echo "UUID: ${UUID}"
echo "Reality PublicKey: ${PUBLIC_KEY}"
echo "Reality ShortId: ${SHORT_ID}"
echo "伪装域名: ${HANDSHAKE_DOMAIN}"
echo

VLESS_LINK="vless://${UUID}@${SERVER_IP}:${OUTER_PORT}?encryption=none&security=reality&sni=${HANDSHAKE_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&flow=xtls-rprx-vision&type=tcp&headerType=none#Reality-443"

echo "================= 可直接复制的 vless:// 链接 ================"
echo "${VLESS_LINK}"
echo "============================================================="
