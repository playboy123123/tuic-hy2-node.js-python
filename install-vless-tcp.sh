#!/bin/bash

set -e

# 安装 sing-box
curl -fsSL https://sing-box.app/install.sh | bash

# 创建配置目录
mkdir -p /etc/sing-box

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 写入配置
cat >/etc/sing-box/config.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info"
  },
  "inbounds": [
    {
      "type": "vless",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "uuid": "$UUID"
        }
      ],
      "tls": {
        "enabled": false
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    }
  ]
}
EOF

# 创建 systemd 服务
cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=sing-box service
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sing-box
systemctl restart sing-box

echo "=============================="
echo "VLESS-TCP 节点安装完成"
echo "UUID: $UUID"
echo "端口: 443"
echo "协议: VLESS-TCP"
echo "=============================="
