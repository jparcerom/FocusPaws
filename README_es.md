# FocusPaws

Aplicación móvil en Flutter para ayudar a personas con TDAH a organizar tareas de forma sencilla, visual y amable.

## Funcionalidades implementadas

- El onboarding permite elegir nombre y uno de cinco animales; el perfil se guarda localmente. El saludo muestra solo el nombre y el animal seleccionado aparece en el recuadro de progreso: Nori (perro), Kitty (gato), Foxy (zorro), Bunny (conejo) o Bruno (oso).
- La pantalla principal permite añadir tareas por escrito o dictarlas en español, revisar y editar la transcripción, y marcar tareas como completadas.
- Cada tarea completada suma 15 puntos una sola vez, aunque se desmarque y vuelva a marcar. Los niveles 1 y 2 requieren 150 puntos cada uno; los niveles 3 a 5, 180; y los niveles 6 a 8, 210. El requisito aumenta 30 puntos cada tres niveles. El animal celebra al subir de nivel y la barra muestra el avance del nivel junto con los puntos totales.
- El dictado usa el servicio de reconocimiento del dispositivo, requiere permiso del micrófono y puede necesitar conexión a internet; FocusPaws no guarda audio.
- El nombre y el animal se guardan en el dispositivo. Las tareas y los puntos siguen en memoria y se pierden al cerrar la app.
- Cada tarea pendiente permite iniciar el modo foco. El temporizador visual comienza en 25 minutos, no muestra una cuenta numérica, permite pausar/reanudar y ofrece una micro-pausa de 2 minutos que vuelve al foco automáticamente.
- Al terminar el temporizador aparece la recompensa de +15 puntos; al continuar, la tarea queda completada en la pantalla principal. Abandonar el foco pide confirmación y no completa la tarea ni otorga puntos.

El modo foco se validó con `flutter test` y `flutter analyze`. La pantalla de recompensa ya está conectada al progreso de la mascota; todavía faltan el sonido y la animación de confeti descritos en el documento.

## Pendiente para alinear con el documento

- Guardar tareas y puntos localmente para que sobrevivan al cierre de la app.
- Ajustar la pantalla principal para mostrar las tres tareas prioritarias sin perder el acceso a las demás.
- Completar la celebración de recompensa con confeti y sonido.
- Revisar la presentación y los estados de ánimo/energía de la mascota frente a la propuesta visual.
- Evaluar el aviso sutil al salir de la app durante el foco, respetando permisos y comportamiento del sistema.

La implementación se está realizando por bloques. Antes de avanzar al siguiente, ejecutar `flutter analyze` y `flutter test`.

## Punto de reanudación

Pausa de trabajo después de implementar y verificar el primer bloque del modo foco. Al retomar, continuar desde aquí; no rehacer el onboarding, la captura de tareas ni el flujo de foco ya implementados.

**Estado guardado en este punto:**

- Hay un botón de inicio de foco en cada tarea pendiente.
- El bloque de foco dura 25 minutos por defecto y muestra un anillo visual sin cuenta numérica. Permite pausar/reanudar, incluye una micro-pausa de 2 minutos y descuenta el tiempo transcurrido si la app pasa a segundo plano.
- Al agotarse el tiempo se muestra la recompensa. «Continuar» completa la tarea y concede 15 puntos; la misma tarea no vuelve a conceder puntos si se desmarca y se marca otra vez.
- Abandonar requiere confirmación y no completa la tarea ni concede puntos.
- La duración del foco y de la micro-pausa se pueden configurar en las pruebas para verificar el flujo sin esperar los tiempos reales.

**Validación realizada:** `flutter analyze` sin incidencias, `flutter test` con las 13 pruebas aprobadas y compilación correcta de `flutter build apk --debug`.

**Siguiente paso acordado:** implementar y probar el almacenamiento local de tareas y puntos para que sobrevivan al cierre de la app. Después, seguir alineando la pantalla principal y la recompensa con el documento de producto.

**Decisión pendiente:** el documento propone que la mascota pierda algo de energía al abandonar, pero no define cuánto ni cómo se calcula. No implementar esa penalización hasta acordar su comportamiento.

## Entorno de desarrollo

- Android Studio: `F:\Android\Android Studio`
- Android SDK y emulador: `F:\Android\Sdk`
- Flutter SDK: `F:\Android\flutter`

En Windows, los comandos de Flutter se pueden ejecutar indicando la ruta completa:

```powershell
& 'F:\Android\flutter\bin\flutter.bat' analyze
& 'F:\Android\flutter\bin\flutter.bat' test
& 'F:\Android\flutter\bin\flutter.bat' devices
& 'F:\Android\flutter\bin\flutter.bat' run
```

El AVD `Pixel_6` tiene una ruta de skin antigua en su configuración. Para iniciarlo usando los skins instalados en el SDK actual:

```powershell
& 'F:\Android\Sdk\emulator\emulator.exe' -avd Pixel_6 -skindir 'F:\Android\Sdk\skins' -skin pixel_6
```

Para desarrollar en Android, acepta las licencias del SDK desde Android Studio o ejecuta `flutter doctor --android-licenses` de forma interactiva. Las licencias deben aceptarse antes de compilar o instalar la app en el emulador.

Antes de avanzar a la siguiente funcionalidad, ejecuta `flutter analyze` y `flutter test`.

## Documentación

- [Descripción del producto (español)](doc/FocusPaws_Tareas-TDAH_es.md)
- [Product brief (English)](doc/FocusPaws_Tareas-TDAH_en.md)
