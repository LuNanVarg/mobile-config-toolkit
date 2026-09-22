# Metodología de diagnóstico

Antes de asumir que un dispositivo Android viejo "ya no sirve", vale la pena descartar en orden estas causas — de la más simple a la más profunda.

## 1. Espacio de almacenamiento

`Ajustes → Almacenamiento`. Menos de ~1 GB libre puede bloquear instalaciones y actualizaciones, incluso antes de tocar cualquier otra cosa. Un factory reset **no** resuelve esto si no hay datos que limpiar — solo saca caché y apps acumuladas.

## 2. Versión de Android vs. requisitos de las apps

Play Store filtra apps por `minSdkVersion`: si el dispositivo no las ve en la tienda, probablemente sea por esto, no por falta de espacio. Confirmar la versión instalada:

```bash
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
```

Buscar versiones antiguas de las apps necesarias (APKMirror, F-Droid para apps open source) que declaren explícitamente compatibilidad con esa versión — **cuidado**: la ficha general de una app en la tienda no garantiza que la build específica que bajás tenga el mismo mínimo; conviene verificar el minSdk de cada build puntual antes de instalar.

## 3. Memoria RAM disponible

Si las apps se cierran o cortan sin mostrar error, sospechar de límites de memoria antes que de bugs de la app:

```bash
./scripts/check-meminfo.sh
./scripts/check-lmk.sh
```

En kernels de 32 bits con split High/LowMem (típico en dispositivos con ≤2GB RAM y Android 4.x-6.x), los buffers gráficos solo pueden vivir en LowMem — que suele ser una fracción bastante menor que la RAM total. Un navegador completo con motor de renderizado pesado puede agotar esa fracción mucho antes que la memoria total, provocando que el `lowmemorykiller` mate el proceso silenciosamente.

**Síntoma característico:** una app "corta" siempre en el mismo punto (ej. siempre en la página 2 de un PDF, nunca antes, nunca después) sin mostrar ningún mensaje de error. Eso es memoria, no un bug de la app.

## 4. Motor de renderizado del navegador

Si el uso depende de un navegador y hay fallas específicas (ciertas páginas no cargan, otras sí), sospechar del motor:

- Verificar versión del navegador instalado y compararla con la más reciente compatible con el hardware.
- Chrome/Chromium suele mantener compatibilidad con Android viejo más tiempo del esperado en algunos builds de fabricante (vale la pena chequear qué versión trae precargada antes de descartarlo).
- Si el navegador es el cuello de botella, la solución suele ser **reemplazar el flujo por apps nativas** en vez de seguir optimizando el navegador — una app de una sola tarea pide mucha menos memoria que un navegador completo.

## 5. Instalación de apps compatibles

Con la causa identificada, instalar por ADB en vez de depender de Play Store (que puede no ofrecer versiones viejas):

```bash
./scripts/batch-install.sh ./apks
```

Errores comunes y su significado:

| Error | Causa |
|---|---|
| `INSTALL_FAILED_OLDER_SDK` | El APK pide una versión de Android mayor a la instalada |
| `INSTALL_FAILED_NO_MATCHING_ABI` | Arquitectura equivocada (ej. bajaste x86 en vez de arm) |
| `INSTALL_FAILED_ALREADY_EXISTS` | El paquete ya existe (app de fábrica) — usar `install -r` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Firmas distintas entre la versión instalada y la nueva — requiere desinstalar primero |

## 6. Liberar RAM sacando bloatware

Con la app crítica ya funcionando, deshabilitar servicios de fábrica que compiten por RAM:

```bash
adb uninstall <paquete>              # apps de terceros
adb shell pm disable <paquete>       # apps de sistema (uninstall normal falla con Failure)
```

No confundir "deshabilitado" con "desinstalado": `pm disable` detiene el proceso y su consumo de RAM, pero no libera espacio en disco. Para el problema de memoria, alcanza.

**Apps a nunca deshabilitar** sin investigar antes: cualquier paquete `com.android.*` core del sistema, Google Play Services (`com.google.android.gms`), Google Services Framework (`com.google.android.gsf`), el teclado del sistema, el launcher activo.
