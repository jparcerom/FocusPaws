# FocusPaws

Aplicación móvil en Flutter para ayudar a personas con TDAH a organizar tareas de forma sencilla, visual y amable.

## Funcionalidades implementadas

### Icono Android

- Se usa el icono circular sin texto del paquete `doc/FocusPaws_Flutter_Android` (el launcher muestra el nombre de la app). La fuente usada por el proyecto está en `assets/launcher`; `flutter_launcher_icons.yaml` genera los recursos para Android.
- La capa foreground se amplía un 5 % para que el círculo cubra el borde de la máscara y evitar halos. Al regenerar recursos, hay que quitar el `<inset>` del 16 % que `flutter_launcher_icons` añade en `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`; de lo contrario, el icono vuelve a verse pequeño.

### Perfiles

- El onboarding permite elegir nombre y uno de seis animales, dispuestos en dos filas de tres; el perfil se guarda localmente. El saludo muestra solo el nombre y el animal seleccionado aparece en el recuadro de progreso: Nori (perro), Kitty (gato), Foxy (zorro), Bunny (conejo), Bruno (oso) o Panda.
- Al volver a abrir la aplicación aparece un selector de perfiles. Cada perfil da acceso a un panel intermedio para editar el nombre o el animalito, abrir su álbum y entrar a sus tareas. «Finalizar día» vuelve al selector sin borrar tareas ni recompensas.
- Crear perfiles adicionales está disponible en desarrollo y puede habilitarse en una compilación con `--dart-define=FOCUSPAWS_PREMIUM_MULTIUSER=true`; en release se muestra solo el perfil gratuito predeterminado. Cada perfil conserva su progreso separado.

### Tareas y pantalla principal

- Las tareas se pueden añadir por escrito o dictar en español. La transcripción se puede revisar y editar antes de guardarla. El dictado usa el servicio de reconocimiento del dispositivo y FocusPaws no guarda audio.
- Inicio muestra hasta tres tareas pendientes recientes y permite desplegar las demás y las completadas.
- La cabecera de tareas muestra FocusPaws y «Finalizar día» como botón alineado a la derecha; no incluye acceso al perfil. La tarjeta de la mascota omite el encabezado «Tu compañero de hoy» y los puntos totales. La lista se titula «Tu reto del día», muestra «0/0 tareas hechas» y, al completar todas, «¡Misión cumplida por hoy!».

### Modo foco y recompensas

- Al crear una tarea se elige entre tres botones de texto: Corto (15 min, +10 puntos), Medio (30 min, +20 puntos) y Largo (45 min, +40 puntos). Los botones no muestran tiempos ni puntos; las tareas anteriores a esta opción se interpretan como estándar.
- La nueva tabla se aplica a las tareas que se completen a partir de ahora; los puntos ya ganados se conservan sin cambios.
- Los puntos se conceden una sola vez por tarea, tanto al completarla desde Inicio como tras una sesión de foco.
- Si se termina la tarea antes de consumir la mitad del tiempo estimado, se reciben los puntos del tamaño elegido, pero no minutos extra de descanso. Si se completa al menos la mitad, el tiempo restante se suma al descanso, con un máximo de 3, 7 o 10 minutos según el tamaño.
- Si se agota el bloque sin terminar, se puede añadir una prórroga visual de 5 minutos, pasar al modo libre con tiempo extra ascendente o finalizar. Completar tras más de 10 minutos extra también concede un snack coleccionable.
- Abandonar el foco requiere confirmación y no completa la tarea ni concede puntos. Las recompensas de una sesión se aplican al pulsar «Continuar».

### Progreso y persistencia

- El temporizador visual usa la duración estimada de la tarea, no muestra una cuenta numérica y permite pausar/reanudar. Incluye una micro-pausa de 2 minutos que vuelve al foco automáticamente.
- Los minutos de descanso y los snacks se muestran junto al progreso de la mascota. La tarjeta muestra nivel y progreso hacia el siguiente nivel, no los puntos totales acumulados. Los niveles 1 y 2 requieren 150 puntos cada uno; los niveles 3 a 5, 180; y los niveles 6 a 8, 210. El requisito aumenta 30 puntos cada tres niveles.
- El progreso diario cuenta tareas distintas completadas en la fecha local. Al completar tres en un día se desbloquea una pegatina; el historial y el álbum persisten junto al resto del progreso. El álbum está visible durante el desarrollo y preparado para ocultarse mediante una bandera, manteniendo el progreso diario en Inicio.
- El nombre y el animal se guardan por perfil. Las tareas, puntos, tiempo de descanso, snacks e historial diario se guardan en un registro independiente por perfil. Al actualizar, los datos existentes se migran al perfil anterior sin mezclar el progreso de usuarios nuevos.

## Pendiente para alinear con el documento

- Integrar el acceso de pago por usuario para crear perfiles adicionales; ahora se controla mediante una bandera de compilación.
- Completar la celebración de recompensa con confeti y sonido.
- Revisar la presentación y los estados de ánimo/energía de la mascota frente a la propuesta visual.
- Evaluar el aviso sutil al salir de la app durante el foco, respetando permisos y comportamiento del sistema.
- Definir cómo se canjea el tiempo de descanso acumulado.

## Punto de reanudación

El tamaño de tarea ya determina el temporizador y la recompensa, incluidos el límite del 50% y el tope de descanso por tamaño. Las mascotas son seis, en una cuadrícula 2 × 3. El selector de perfiles, el panel de edición y el botón «Finalizar día» ya están implementados; el progreso se separa por perfil y conserva los datos previos mediante migración. Continuar desde el siguiente paso sin rehacer estos flujos.

**Validación de esta iteración:** `flutter analyze` sin incidencias, todas las pruebas de `flutter test` aprobadas y APK debug compilado, instalado y abierto en `emulator-5554`.

**Siguiente paso:** completar la pantalla de recompensa según el diagrama de flujo: celebración animada de la mascota, confeti y sonido satisfactorio; después revisar la presentación visual del álbum.

**Decisión pendiente:** el documento propone que la mascota pierda algo de energía al abandonar, pero no define cuánto ni cómo se calcula. No implementar esa penalización hasta acordar su comportamiento.

## Entorno de desarrollo

- Android Studio: `F:\Android\Android Studio`
- Android SDK y emulador: `F:\Android\Sdk`
- Flutter SDK: `F:\Android\flutter`
- El emulador Pixel 6 tiene Gboard configurado inicialmente en inglés (EE. UU.). Para escribir con tildes, añade español en **Ajustes → Sistema → Teclado → Teclado en pantalla → Gboard → Idiomas**. La app no filtra los caracteres acentuados.

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
