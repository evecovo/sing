#!/bin/bash

# 1. 检查 UUID
if [ -z "$UUID" ]; then
    echo "错误: 请设置 UUID 环境变量。"
    exit 1
fi

# 2. 硬编码固定参数 (构建时即确定)
FIXED_DEST="www.microsoft.com"
FIXED_SID="12345678abcdef00"
FIXED_PRIV="uB-Example-Private-Key-Fixed-Value-88"
FIXED_PUB="pB-Example-Public-Key-Fixed-Value-99"
LISTEN_PORT=${PORT:-443}

# 3. 生成配置文件
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
        "server_name": "${FIXED_DEST}",
        "reality": {
          "enabled": true,
          "handshake": { "server": "${FIXED_DEST}", "server_port": 443 },
          "private_key": "${FIXED_PRIV}",
          "short_id": ["${FIXED_SID}"]
        }
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF

# 4. 定时重启逻辑
run_singbox() {
    while true; do
        sing-box run -c /etc/sing-box.json > /dev/null 2>&1
        sleep 3
    done
}
echo "0 4 * * * pkill sing-box" > /var/spool/cron/crontabs/root
crond

# 5. 输出固定后的节点链接
echo "---------------------------------------------------"
echo "✅ sing-box REALITY 节点已启动"
echo "🚀 节点信息 (已硬编码固定):"
echo "域名 (SNI): ${FIXED_DEST}"
echo "公钥 (pbk): ${FIXED_PUB}"
echo "Short ID (sid): ${FIXED_SID}"
echo "---------------------------------------------------"
echo "分享链接 (请将 IP 换成服务器真实 IP):"
echo "vless://${UUID}@你的服务器IP:${LISTEN_PORT}?encryption=none&security=reality&sni=${FIXED_DEST}&fp=chrome&pbk=${FIXED_PUB}&sid=${FIXED_SID}#REALITY-PERMANENT"
echo "---------------------------------------------------"

run_singbox
