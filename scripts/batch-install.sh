#!/usr/bin/env bash
#
# batch-install.sh — Instala o actualiza (install -r) todos los .apk de una
# carpeta en el dispositivo conectado por ADB, con log de éxito/fallo por archivo.
#
# Uso: ./batch-install.sh <carpeta-con-apks>
#
# Notas:
#   - Usa 'adb install -r' (reemplaza conservando datos si el paquete ya existe,
#     por ejemplo apps de fábrica que se actualizan sobre la versión preinstalada).
#   - Apps de sistema protegidas pueden fallar igual con -r; en ese caso hay que
#     evaluar 'pm disable' en vez de reemplazo (ver docs/diagnostico.md).
#   - Errores típicos a esperar en dispositivos viejos:
#       INSTALL_FAILED_OLDER_SDK      → el APK pide una versión de Android mayor
#       INSTALL_FAILED_NO_MATCHING_ABI → arquitectura equivocada (ej. x86 en vez de arm)

set -uo pipefail

APK_DIR="${1:-}"

if [ -z "$APK_DIR" ]; then
    echo "Uso: $0 <carpeta-con-apks>" >&2
    exit 1
fi

if [ ! -d "$APK_DIR" ]; then
    echo "Error: '$APK_DIR' no es una carpeta válida." >&2
    exit 1
fi

if ! command -v adb &> /dev/null; then
    echo "Error: adb no está en el PATH. Instalá Android Platform Tools." >&2
    exit 1
fi

DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Error: no se detecta ningún dispositivo. Verificá el cable y la depuración USB." >&2
    exit 1
fi

shopt -s nullglob
APKS=("$APK_DIR"/*.apk)
shopt -u nullglob

if [ ${#APKS[@]} -eq 0 ]; then
    echo "No se encontraron archivos .apk en '$APK_DIR'." >&2
    exit 1
fi

echo "Encontrados ${#APKS[@]} archivo(s) .apk en '$APK_DIR'."
echo

SUCCESS=()
FAILED=()

for apk in "${APKS[@]}"; do
    NAME=$(basename "$apk")
    echo "→ Instalando: $NAME"

    OUTPUT=$(adb install -r "$apk" 2>&1)

    if echo "$OUTPUT" | grep -q "^Success"; then
        echo "  ✓ Success"
        SUCCESS+=("$NAME")
    else
        REASON=$(echo "$OUTPUT" | grep -oE "Failure \[[A-Z_]+\]" || echo "Failure [desconocido]")
        echo "  ✗ $REASON"
        FAILED+=("$NAME — $REASON")
    fi
    echo
done

echo "=== Resumen ==="
echo "Instalados con éxito: ${#SUCCESS[@]}/${#APKS[@]}"
for s in "${SUCCESS[@]}"; do
    echo "  ✓ $s"
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo
    echo "Fallidos: ${#FAILED[@]}"
    for f in "${FAILED[@]}"; do
        echo "  ✗ $f"
    done
    exit 1
fi
