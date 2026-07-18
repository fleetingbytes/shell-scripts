#!/bin/sh

PF_CONF="/etc/pf.conf"
BOGON_DIR="/etc/pf/tables"
[ -d "$BOGON_DIR" ] || mkdir -p "$BOGON_DIR"

echo "=== Updating bogons (Team Cymru, $(date -I)) ==="
fetch -T 30 -o "$BOGON_DIR/fullbogons-ipv4.txt" \
    https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt || exit 1

fetch -T 30 -o "$BOGON_DIR/fullbogons-ipv6.txt" \
    https://www.team-cymru.org/Services/Bogons/fullbogons-ipv6.txt || exit 1

# Strip comments/headers for pf tables (pf only wants the prefixes)
grep -E '^[0-9]' "$BOGON_DIR/fullbogons-ipv4.txt" > "$BOGON_DIR/bogons-ipv4.txt"
grep -E '^[0-9a-f:]' "$BOGON_DIR/fullbogons-ipv6.txt" > "$BOGON_DIR/bogons-ipv6.txt"

echo "Bogons updated – $(wc -l < "$BOGON_DIR/bogons-ipv4.txt") IPv4 prefixes"
echo "Bogons updated – $(wc -l < "$BOGON_DIR/bogons-ipv6.txt") IPv6 prefixes"

# Reload pf only if config references these files
grep -q -E 'bogons-ipv[46]\.txt' "$PF_CONF" && pfctl -f "$PF_CONF" 2>/dev/null && echo "pf reloaded" || echo "pf reload skipped"
