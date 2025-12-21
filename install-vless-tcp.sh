#!/bin/bash

set -e

mkdir -p ~/vless-tcp
cd ~/vless-tcp

# 下载 sing-box
SB_VER="1.12.13"
wget -O sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${SB_VER}/sing-box-${SB_VER}-linux-amd64.tar.gz
tar -xzf sb.tar.gz
mv sing-box-${SB_VER}-linux-amd64/sing-box .
chmod +x sing-box

# 生成 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# 写入配置
cat > config.json <<EOF
{
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

# 运行脚本
cat > run.sh <<EOF
#!/bin/bash
cd ~/vless-tcp
nohup ./sing-box run -c config.json >/dev/null 2>&1 &
echo "VLESS-TCP started"
EOF

chmod +x run.sh

echo "=============================="
echo "VLESS-TCP 用户态节点安装完成"
echo "UUID: $UUID"
echo "端口: 443"
echo "运行方式: ~/vless-tcp/run.sh"
echo "=============================="
