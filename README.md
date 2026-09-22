# mobile-config-toolkit

Scripts y metodología para diagnosticar y recuperar dispositivos Android viejos o con recursos limitados (poca RAM, versión de sistema desactualizada), pensado para casos reales: tablets/celulares de uso educativo que quedaron obsoletos pero siguen siendo funcionales para tareas livianas (Classroom, lectura de PDFs, navegación básica).

## Por qué existe

Un dispositivo viejo suele descartarse asumiendo "está obsoleto, no sirve más". En muchos casos el problema real es más específico y tiene solución sin comprar hardware nuevo: límites de memoria del kernel, apps que subieron su versión mínima de Android, o simplemente bloatware de fábrica compitiendo por RAM escasa. Este proyecto documenta cómo diagnosticar la causa real antes de asumir que no tiene arreglo.

## Requisitos

- [ADB (Android Debug Bridge)](https://developer.android.com/tools/adb) instalado y en el PATH.
- Dispositivo con **depuración USB** habilitada (`Ajustes → Opciones de desarrollador → Depuración USB`).
- Cable USB de datos (no todos los cables cargan y transfieren).

## Estructura

```
mobile-config-toolkit/
├── docs/
│   ├── diagnostico.md      # metodología: qué mirar y cómo interpretarlo
│   └── casos/              # casos reales documentados
├── scripts/
│   ├── check-meminfo.sh    # estado de memoria del dispositivo
│   ├── check-lmk.sh        # umbrales del lowmemorykiller
│   └── batch-install.sh    # instalar/actualizar una carpeta de APKs por ADB
└── README.md
```

## Uso rápido

```bash
# Conectar el dispositivo por USB con depuración habilitada, confirmar el diálogo de autorización
adb devices

# Ver estado de memoria
./scripts/check-meminfo.sh

# Ver umbrales del lowmemorykiller (solo dispositivos con este mecanismo — común en Android 4.x-8.x)
./scripts/check-lmk.sh

# Instalar/actualizar todos los APK de una carpeta
./scripts/batch-install.sh ./apks
```

## Metodología

Ver [`docs/diagnostico.md`](docs/diagnostico.md) para la guía completa de cómo leer los síntomas antes de decidir una solución.

## Casos documentados

- [Galaxy Tab 4 7.0 (SM-T230NU)](docs/casos/galaxy-tab-4.md) — Android 4.4.2, cuello de botella de memoria diagnosticado y resuelto reemplazando el flujo de navegador por apps nativas.

## Licencia

MIT — usalo, adaptalo, y si te sirve para otro dispositivo, un PR con el caso documentado suma.

---

> **Gracias por la confianza.**
> — **Nan Lu** 🌙

---

