#!/bin/bash

# 1. 检查环境变量
if [ -z "$UUID" ] || [ -z "$DEST_DOMAIN" ]; then
    echo "错误: 请设置 UUID 和 DEST_DOMAIN (回落域名，如 www.google.com)"
    exit 1
fi

# 2. 生成 REALITY 密钥对
if [ ! -f "/etc/reality_keys.txt" ]; then
    /usr/local/bin/sing-box generate reality-keypair > /etc/reality_keys.txt
fi

PRIVATE_KEY=$(awk '/Private key:/ {print $3}' /etc/reality_keys.txt)
PUBLIC_KEY=$(awk '/Public key:/ {print $3}' /etc/reality_keys.txt)
SHORT_ID=$(/usr/local/bin/sing-box generate rand --hex 8)
LISTEN_PORT=${PORT:-443}

# 3. 生成 sing-box 配置文件
cat <<EOF > /etc/sing-box.json
{
  "log": { "level": "warn" },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-reality",
      "listen": "::",
      "listen_port": ${LISTEN_PORT},
      "users": [{ "uuid": "${UUID}" }],
      "tls": {
        "enabled": true,
        "server_name": "${DEST_DOMAIN}",
        "reality": {
          "enabled": true,
          "handshake": { "server": "${DEST_DOMAIN}", "server_port": 443 },
          "private_key": "${PRIVATE_KEY}",
          "short_id": ["${SHORT_ID}"]
        }
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF

# 4. 定时重启逻辑 (清理内存)
run_singbox() {
    while true; do
        echo "开启 sing-box REALITY 进程..."
        sing-box run -c /etc/sing-box.json > /dev/null 2>&1
        sleep 3
    done
}
echo "0 4 * * * pkill sing-box" > /var/spool/cron/crontabs/root
crond

# 5. 输出节点信息 (需手动替换你的服务器IP)
echo "---------------------------------------------------"
echo "✅ sing-box VLESS-REALITY 服务已启动"
echo "🚀 节点配置信息:"
echo "协议: VLESS"
echo "端口: ${LISTEN_PORT}"
echo "UUID: ${UUID}"
echo "公钥 (Public Key): ${PUBLIC_KEY}"
echo "Short ID: ${SHORT_ID}"
echo "SNI (Dest Domain): ${DEST_DOMAIN}"
echo "传输层安全: REALITY / Vision"
echo "---------------------------------------------------"
echo "分享链接 (请将 IP 换成你服务器的真实 IP):"
echo "vless://${UUID}@你的服务器IP:${LISTEN_PORT}?encryption=none&security=reality&sni=${DEST_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=grpc#REALITY-${DEST_DOMAIN}"
echo "---------------------------------------------------"

run_singbox
