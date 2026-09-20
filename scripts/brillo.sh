#!/usr/bin/env bash

STATE_FILE="/tmp/wlsunset_brightness"

# Si no existe el archivo, asumir brillo al 100% (100)
if [ ! -f "$STATE_FILE" ]; then
    echo 100 > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")

case "$1" in
    up)
        NEW=$((CURRENT + 10))
        [ $NEW -gt 100 ] && NEW=100
        ;;
    down)
        NEW=$((CURRENT - 10))
        [ $NEW -lt 10 ] && NEW=10
        ;;
    *)
        echo "Uso: $0 {up|down}"
        exit 1
        ;;
esac

echo "$NEW" > "$STATE_FILE"

# Convertir entero (ej: 70) a valor decimal de gamma (ej: 0.70)
GAMMA=$(awk "BEGIN {printf \"%.2f\", $NEW/100}")

# Reiniciar wlsunset con el nuevo nivel
pkill -x wlsunset 2>/dev/null
wlsunset -T 6500 -g "$GAMMA" >/dev/null 2>&1 &
