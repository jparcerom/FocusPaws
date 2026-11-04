# FocusPaws

Aplicación móvil en Flutter para ayudar a personas con TDAH a organizar tareas de forma sencilla, visual y amable.

## Funcionalidades implementadas

### Perfil y tareas

- El onboarding permite elegir nombre y uno de cinco animales; el perfil se guarda localmente. El saludo muestra solo el nombre y el animal seleccionado aparece en el recuadro de progreso: Nori (perro), Kitty (gato), Foxy (zorro), Bunny (conejo) o Bruno (oso).
- Las tareas se pueden añadir por escrito o dictar en español. La transcripción se puede revisar y editar antes de guardarla. El dictado usa el servicio de reconocimiento del dispositivo y FocusPaws no guarda audio.
- Inicio muestra hasta tres tareas pendientes recientes y permite desplegar las demás y las completadas.
- Las tareas, su tamaño, estado y marcas de recompensa se guardan localmente junto con los puntos, el tiempo de descanso y los snacks.

### Tamaño de tarea y recompensas

- Al crear una tarea se puede elegir un tamaño rápido: Paso corto (15 min, +5 puntos), Bloque estándar (30 min, +15 puntos) o Gran esfuerzo (45 min, +30 puntos). Las tareas anteriores a esta opción se interpretan como estándar.
- Los puntos se conceden una sola vez por tarea, tanto al completarla desde Inicio como tras una sesión de foco.
- Si se termina la tarea antes de consumir la mitad del tiempo estimado, se reciben los puntos del tamaño elegido, pero no minutos extra de descanso. Si se completa al menos la mitad, el tiempo restante se suma al descanso, con un máximo de 3, 7 o 10 minutos según el tamaño.
- Si se agota el bloque sin terminar, se puede añadir una prórroga visual de 5 minutos, pasar al modo libre con tiempo extra ascendente o finalizar. Completar tras más de 10 minutos extra también concede un snack coleccionable.
- Abandonar el foco requiere confirmación y no completa la tarea ni concede puntos. Las recompensas de una sesión se aplican al pulsar «Continuar».

### Modo foco y progreso

- El temporizador visual usa la duración estimada de la tarea, no muestra una cuenta numérica y permite pausar/reanudar. Incluye una micro-pausa de 2 minutos que vuelve al foco automáticamente.
- Los minutos de descanso y los snacks se muestran junto al progreso de la mascota. Los niveles 1 y 2 requieren 150 puntos cada uno; los niveles 3 a 5, 180; y los niveles 6 a 8, 210. El requisito aumenta 30 puntos cada tres niveles.
- El nombre, el animal, las tareas y los puntos se guardan en el dispositivo. El progreso de tareas y puntos se conserva junto en un registro local.

## Pendiente para alinear con el documento

- Completar la celebración de recompensa con confeti y sonido.
- Revisar la presentación y los estados de ánimo/energía de la mascota frente a la propuesta visual.
- Evaluar el aviso sutil al salir de la app durante el foco, respetando permisos y comportamiento del sistema.
- Definir cómo se canjea el tiempo de descanso acumulado.

## Punto de reanudación

El tamaño de tarea ya determina el temporizador y la recompensa, incluidos el límite del 50% y el tope de descanso por tamaño. Continuar desde el siguiente paso sin rehacer el onboarding, la captura y vista de tareas, la persistencia local ni los flujos de foco ya implementados.

**Validación de esta iteración:** `flutter analyze` sin incidencias; `flutter test` con las 19 pruebas aprobadas; APK debug compilado, instalado y abierto en el emulador Android `emulator-5554`.

**Siguiente paso:** completar la pantalla de recompensa según el diagrama de flujo: celebración animada de la mascota, confeti y sonido satisfactorio.

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
