#!/usr/bin/env bash
#
# check-meminfo.sh — Muestra el estado de memoria del dispositivo Android
# conectado por ADB, con foco en los valores que importan para diagnosticar
# cuellos de botella en dispositivos con kernels de 32 bits (High/LowMem split).
#
# Uso: ./check-meminfo.sh

set -euo pipefail

if ! command -v adb &> /dev/null; then
    echo "Error: adb no está en el PATH. Instalá Android Platform Tools." >&2
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Error: no se detecta ningún dispositivo. Verificá el cable y la depuración USB." >&2
    exit 1
fi

RAW=$(adb shell cat /proc/meminfo)

get_kb() {
    echo "$RAW" | grep "^$1:" | awk '{print $2}'
}

MEM_TOTAL=$(get_kb "MemTotal")
MEM_FREE=$(get_kb "MemFree")
CACHED=$(get_kb "Cached")
HIGH_TOTAL=$(get_kb "HighTotal")
LOW_TOTAL=$(get_kb "LowTotal")
LOW_FREE=$(get_kb "LowFree")

to_mb() {
    echo "scale=1; $1 / 1024" | bc
}

echo "=== Memoria general ==="
echo "Total:       $(to_mb "$MEM_TOTAL") MB"
echo "Libre:       $(to_mb "$MEM_FREE") MB"
echo "En caché:    $(to_mb "$CACHED") MB (reclamable por el kernel si hace falta)"
echo

if [ -n "${HIGH_TOTAL:-}" ] && [ "$HIGH_TOTAL" -gt 0 ]; then
    echo "=== Kernel de 32 bits con split High/LowMem detectado ==="
    echo "LowMem total:  $(to_mb "$LOW_TOTAL") MB"
    echo "LowMem libre:  $(to_mb "$LOW_FREE") MB"
    echo
    echo "Nota: en este tipo de kernel, buffers gráficos y estructuras del kernel"
    echo "viven obligatoriamente en LowMem, aunque haya HighMem libre. Un navegador"
    echo "pesado (o cualquier app con renderizado intensivo) puede agotar LowMem"
    echo "mucho antes de agotar la memoria total — eso suele explicar procesos que"
    echo "se cierran sin error visible. Corré check-lmk.sh para ver los umbrales"
    echo "exactos en los que el sistema empieza a matar procesos."
else
    echo "No se detectó split High/LowMem (normal en kernels de 64 bits o Android reciente)."
fi
