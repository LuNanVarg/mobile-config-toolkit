# Recuperación de tablet Samsung Galaxy Tab 4 7.0 (SM-T230NU)

**Dispositivo:** Samsung Galaxy Tab 4 7.0, modelo SM-T230NU
**Android:** 4.4.2 (KitKat), kernel 3.10.0, arquitectura ARM 32 bits
**Objetivo:** usar Google Classroom y leer PDFs/imágenes del aula del profesorado

---

## 1. Problema inicial

La tablet, comprada y usada muy poco, no permitía:
- Descargar apps nuevas desde Play Store (filtro por versión de Android).
- Abrir PDFs de varias páginas con Firefox: solo mostraba/descargaba la primera hoja.
- Entrar a Google Drive desde el navegador.
- Ver o descargar imágenes desde el navegador.

Primera intuición: instalar Linux. Se descartó — el port disponible para este modelo (postmarketOS `samsung-degaswifi`) es experimental, sin mantenimiento, y con 1.5 GB de RAM el resultado sería peor que Android, además de perder Play Store.

## 2. Diagnóstico real

**Causa raíz: límite de memoria del kernel, no la app.**

Verificado con ADB:
```
adb shell cat /proc/meminfo
```
→ Kernel de 32 bits con memoria segmentada High/Low: de 1.35 GB totales, solo **548 MB son "LowMem"**, la única zona donde el sistema puede alojar buffers gráficos del navegador.

```
adb shell cat /sys/module/lowmemorykiller/parameters/minfree
```
→ Umbrales del `lowmemorykiller`: el sistema empieza a matar procesos en background por debajo de ~94 MB libres de LowMem, y mata hasta el proceso en primer plano por debajo de ~36 MB.

**Conclusión:** un navegador completo (Firefox) pide mucha más LowMem de la disponible al renderizar un PDF de varias páginas o al procesar la interfaz pesada de Drive. El kernel mata el proceso silenciosamente al llegar a la página 2, sin mostrar error — de ahí que "descargar" el PDF solo trajera la primera hoja.

Docs sí funcionaba porque se renderiza como HTML liviano, no como canvas página por página.

## 3. Solución: apps nativas en vez de navegador

Reemplazar el flujo "todo por el navegador" por apps chicas, de una sola tarea, que piden mucha menos LowMem:

| Función | App instalada | Fuente |
|---|---|---|
| Classroom | Google Classroom 7.1.061.05 | APKMirror (build minAPI19, última compatible con Android 4.4) |
| Archivos | Google Drive 2.18.232.03 | APKMirror (actualizó sobre la versión de fábrica de 2014) |
| PDFs | Librera Reader (Foobnix), build 6030 | F-Droid (la build de tienda moderna había subido el mínimo de Android) |
| Imágenes | F-Stop Gallery 5.3.6 | APKMirror (build declarada para Android 4.1+) |

**Método de instalación:** APK bajados en PC, transferidos por `adb push` e instalados por `adb install -r` (más prolijo que instalar desde el explorador de la tablet, porque muestra el error exacto si algo falla).

**Problema encontrado:** varias apps recientes ya no soportan Android 4.4 (error `INSTALL_FAILED_OLDER_SDK`). Solución: buscar builds viejas específicas, verificando siempre el "Min: Android X" declarado en la ficha de descarga antes de bajar.

## 4. Limpieza de espacio y RAM (post-instalación)

Con el diagnóstico de LowMem confirmado, se deshabilitó bloatware de fábrica para liberar RAM:
- Suite de oficina Hancom (Word/Cell/Show viewer)
- Servicios de Samsung Cloud (sync, backup, proxies)
- Navegador Samsung (Internet/Sbrowser) y Galaxy Apps
- Apps de Google sin uso (Play Videos, Play Revista, Google+, Samsung Push Service)
- Lectores de PDF redundantes (FBReader + su plugin)

**Nota técnica:** `adb uninstall` no funciona en apps de sistema preinstaladas (error `Failure`, sin permisos). La alternativa es `adb shell pm disable <paquete>` — no libera espacio en disco pero detiene el proceso y su consumo de RAM, que era el recurso crítico. En apps de terceros si funciona el `uninstall` normal.

## 5. Resultado final

- Classroom, Drive, PDFs de varias páginas e imágenes funcionan correctamente por apps nativas.
- Espacio libre recuperado: de estar prácticamente sin margen a **3.6 GB libres**.
- Se conservó Chrome (versión 81, sorprendentemente moderna para este Android) como navegador de respaldo; se desinstaló Firefox por tener un motor más viejo (Gecko 68 vs. Chromium 81).

## Aprendizajes clave

1. **Un síntoma de "app rota" puede ser en realidad un límite de memoria del sistema** — `/proc/meminfo` y los parámetros del `lowmemorykiller` lo confirman sin ambigüedad.
2. **El navegador no es garantía de compatibilidad universal** en hardware viejo: apps nativas livianas suelen sortear límites que el motor de un browser completo no puede.
3. **"Última versión disponible" no es sinónimo de "compatible"** — siempre verificar el `minSdkVersion`/"Min: Android X" declarado antes de instalar en un dispositivo viejo.
4. **`adb install -r` y `pm disable`** son las herramientas correctas para actualizar apps de fábrica y neutralizar bloatware de sistema sin root.
