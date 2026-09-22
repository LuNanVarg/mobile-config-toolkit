#!/usr/bin/env bash
#
# check-lmk.sh — Muestra los umbrales del lowmemorykiller del dispositivo
# conectado por ADB, traducidos a MB para lectura rápida.
#
# El lowmemorykiller es el mecanismo del kernel Android (común en versiones
# 4.x a 8.x) que mata procesos por prioridad cuando la memoria libre cae por
# debajo de ciertos umbrales. Ver estos valores ayuda a confirmar si procesos
# que "se cierran solos sin error" son en realidad víctimas de este mecanismo.
#
# Uso: ./check-lmk.sh

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

MINFREE_PATH="/sys/module/lowmemorykiller/parameters/minfree"

RAW=$(adb shell "cat $MINFREE_PATH 2>/dev/null" || true)

if [ -z "$RAW" ]; then
    echo "No se encontró $MINFREE_PATH en este dispositivo."
    echo "Es esperable en Android 9+ (reemplazado por lmkd en espacio de usuario)"
    echo "o en dispositivos sin lowmemorykiller clásico habilitado."
    exit 0
fi

IFS=',' read -ra VALUES <<< "$RAW"
LABELS=("foreground" "visible" "secondary" "hidden" "content_empty" "empty")

echo "=== Umbrales del lowmemorykiller ==="
echo "(páginas de 4KB → MB libres en los que el kernel empieza a matar procesos de esa prioridad)"
echo

for i in "${!VALUES[@]}"; do
    PAGES="${VALUES[$i]}"
    MB=$(echo "scale=1; $PAGES * 4 / 1024" | bc)
    LABEL="${LABELS[$i]:-desconocido}"
    printf "  %-15s %8s páginas  ≈ %6s MB\n" "$LABEL" "$PAGES" "$MB"
done

echo
echo "Lectura: si 'MemFree' (ver check-meminfo.sh) anda cerca o por debajo del"
echo "umbral 'foreground', el sistema puede estar matando hasta el proceso en"
echo "primer plano — esto explica cierres silenciosos de apps pesadas."
