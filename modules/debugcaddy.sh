#!/usr/bin/env bash

# ============================================================
# NixOS Caddy + Cloudflared Debug Script
# ============================================================

set -e

echo
echo "============================================================"
echo " BASIC SYSTEM INFO"
echo "============================================================"
hostnamectl
echo

echo "============================================================"
echo " CADDY SERVICE STATUS"
echo "============================================================"
systemctl status caddy --no-pager || true
echo

echo "============================================================"
echo " CADDY JOURNAL LOGS (LAST 50)"
echo "============================================================"
journalctl -u caddy -n 50 --no-pager || true
echo

echo "============================================================"
echo " CLOUDFLARED STATUS"
echo "============================================================"
systemctl status cloudflared-tunnel --no-pager || true
echo

echo "============================================================"
echo " CLOUDFLARED LOGS (LAST 50)"
echo "============================================================"
journalctl -u cloudflared-tunnel -n 50 --no-pager || true
echo

echo "============================================================"
echo " LISTENING PORTS"
echo "============================================================"
ss -tulpn
echo

echo "============================================================"
echo " CADDY CONFIG VALIDATION"
echo "============================================================"

if command -v caddy >/dev/null; then
    caddy validate --config /etc/caddy/Caddyfile || true
else
    echo "Caddy binary not found"
fi

echo

echo "============================================================"
echo " SHOW CADDYFILE"
echo "============================================================"

if [ -f /etc/caddy/Caddyfile ]; then
    cat /etc/caddy/Caddyfile
else
    echo "/etc/caddy/Caddyfile not found"
fi

echo

echo "============================================================"
echo " LOCAL HTTP TESTS"
echo "============================================================"

for port in 80 81 443 3000 8080; do
    echo
    echo "---- Testing localhost:$port ----"
    curl -vk --max-time 5 http://127.0.0.1:$port 2>/dev/null || true
done

echo

echo "============================================================"
echo " DNS CHECK"
echo "============================================================"

if command -v dig >/dev/null; then
    dig npm.mgeek.in
else
    echo "dig not installed"
fi

echo

echo "============================================================"
echo " PUBLIC HTTPS CHECK"
echo "============================================================"

curl -vk --max-time 10 https://npm.mgeek.in || true

echo
echo "============================================================"
echo " CLOUDFLARED TUNNEL LIST"
echo "============================================================"

cloudflared tunnel list || true

echo
echo "============================================================"
echo " SYSTEMD FAILED UNITS"
echo "============================================================"

systemctl --failed || true

echo
echo "============================================================"
echo " FIREWALL STATUS"
echo "============================================================"

if command -v firewall-cmd >/dev/null; then
    firewall-cmd --list-all || true
else
    echo "firewalld not installed (normal on NixOS)"
fi

echo
echo "============================================================"
echo " NIXOS FIREWALL CONFIG"
echo "============================================================"

nixos-option networking.firewall.allowedTCPPorts || true

echo
echo "============================================================"
echo " DONE"
echo "============================================================"

