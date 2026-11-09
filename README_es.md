# FocusPaws

Aplicación móvil en Flutter para ayudar a personas con TDAH a organizar tareas de forma sencilla, visual y amable.

## Funcionalidades implementadas

### Icono Android

- Se usa el icono circular sin texto del paquete `doc/FocusPaws_Flutter_Android` (el launcher muestra el nombre de la app). La fuente usada por el proyecto está en `assets/launcher`; `flutter_launcher_icons.yaml` genera los recursos para Android.
- La capa foreground se amplía un 5 % para que el círculo cubra el borde de la máscara y evitar halos. Al regenerar recursos, hay que quitar el `<inset>` del 16 % que `flutter_launcher_icons` añade en `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`; de lo contrario, el icono vuelve a verse pequeño.
- Al iniciar, la pantalla nativa muestra el icono circular con el texto FocusPaws y la marca inferior «FocusPaws: tareas TDAH versión 1.0 por jpm», en una línea y sobre el amarillo pastel `#FFF3D6`. Android 12 usa una variante reducida para que el círculo y el texto no se recorten con su máscara. Los recursos se configuran en `flutter_native_splash.yaml`.
- La aplicación está versionada como `1.0.0+1` en `pubspec.yaml`; el splash presenta la versión de producto como `1.0`. El mismo amarillo pastel es el fondo general de la aplicación.
- Los fondos secundarios usan un verde menta claro inspirado en el logotipo; los botones principales usan su verde azulado oscuro con texto blanco.
- En la cabecera de la pantalla principal se muestra el icono circular sin texto, con transparencia, junto a FocusPaws.
- Las notificaciones de descanso usan el recurso `ic_launcher_foreground` existente en Android.

## Versiones y mantenimiento

- La etiqueta Git `version-prueba-v1.0.0` identifica la versión de prueba gratuita completa descrita en este documento y sirve de base estable.
- La versión de prueba no recibirá funcionalidades nuevas. Solo se modificará para corregir errores, manteniendo separadas esas correcciones del desarrollo de la versión completa.
- La rama `version-completa` parte de esa misma base. Las nuevas funcionalidades pendientes se desarrollarán en ella sin alterar la versión de prueba.

### Perfiles

- El onboarding muestra el logotipo redondo y transparente de FocusPaws con el nombre integrado (recortado del mismo recurso circular del splash de Android 12 para quitar el margen transparente sobrante) y permite elegir un nombre y uno de seis animales, dispuestos en dos filas de tres; el perfil se guarda localmente. El saludo muestra el nombre y el día de la semana, y el animal seleccionado aparece en el recuadro de progreso: Nori (perro), Kitty (gato), Foxy (zorro), Bunny (conejo), Bruno (oso) o Panda.
- Al volver a abrir la aplicación aparece un selector de perfiles. Cada perfil da acceso a un panel intermedio para editar el nombre o el animalito, abrir su álbum y entrar a sus tareas. «Finalizar día» vuelve al selector sin borrar tareas ni recompensas.
- La versión gratuita permite un perfil y muestra el progreso diario en Inicio; no muestra la habitación ni el álbum de pegatinas. En el primer inicio aparecen una sola vez una bienvenida que presenta FocusPaws para personas con TDAH y neurodivergentes, y un aviso con estas limitaciones. Los perfiles adicionales y el álbum se pueden previsualizar durante el desarrollo y habilitar en compilaciones con `--dart-define=FOCUSPAWS_PREMIUM_MULTIUSER=true` y `--dart-define=FOCUSPAWS_PREMIUM_STICKER_ALBUM=true`. En release ambas opciones están desactivadas por defecto, así que `flutter build apk --release` genera la versión gratuita sin banderas adicionales; el progreso y los datos de otros perfiles no se borran.

### Tareas y pantalla principal

- Las tareas se pueden añadir por escrito o dictar en español. La transcripción se puede revisar y editar antes de guardarla. El dictado usa el servicio de reconocimiento del dispositivo y FocusPaws no guarda audio.
- Inicio muestra hasta tres tareas pendientes recientes y permite desplegar las demás y las completadas. Al cambiar el día, las tareas completadas salen de la lista activa y el contador diario empieza de cero; las pendientes se conservan y se puede elegir conservarlas para terminarlas o cancelarlas.
- La cabecera de tareas muestra FocusPaws y «Finalizar día» como botón alineado a la derecha; no incluye acceso al perfil. La tarjeta de la mascota omite el encabezado «Tu compañero de hoy» y los puntos totales. La lista se titula «Tu reto del día», muestra «0/0 tareas hechas» y, al completar todas, «¡Misión cumplida por hoy!».
- El saludo muestra el nombre del usuario y el día de la semana actual. La tarjeta de progreso presenta a la mascota como «Soy [nombre]».

### Modo foco y recompensas

- Al crear una tarea se elige entre tres botones de texto: Corto (15 min, +10 puntos), Medio (30 min, +20 puntos) y Largo (45 min, +40 puntos). Los botones no muestran tiempos ni puntos; las tareas anteriores a esta opción se interpretan como estándar.
- La nueva tabla se aplica a las tareas que se completen a partir de ahora; los puntos ya ganados se conservan sin cambios.
- Los puntos se conceden una sola vez por tarea, tanto al completarla desde Inicio como tras una sesión de foco.
- Si se termina la tarea antes de consumir la mitad del tiempo estimado, se reciben los puntos del tamaño elegido, pero no minutos extra de descanso. Si se completa al menos la mitad, el tiempo restante se suma al descanso, con un máximo de 3, 7 o 10 minutos según el tamaño.
- Si se agota el bloque sin terminar, se puede añadir una prórroga visual de 5 minutos, pasar al modo libre con tiempo extra ascendente o finalizar. Completar tras más de 10 minutos extra también concede un snack coleccionable.
- Abandonar el foco requiere confirmación y no completa la tarea ni concede puntos. Las recompensas de una sesión se aplican al pulsar «Continuar».

### Progreso y persistencia

- El temporizador visual usa la duración estimada de la tarea, no muestra una cuenta numérica y permite pausar/reanudar. Incluye una micro-pausa de 2 minutos que vuelve al foco automáticamente.
- El saldo de descanso y los snacks se muestran junto al progreso de la mascota. La tarjeta muestra nivel y progreso hacia el siguiente nivel, no los puntos totales acumulados. Los niveles 1 y 2 requieren 150 puntos cada uno; los niveles 3 a 5, 180; y los niveles 6 a 8, 210. El requisito aumenta 30 puntos cada tres niveles.
- El progreso diario cuenta tareas distintas completadas en la fecha local. Al completar tres en un día se desbloquea una pegatina; el historial y el álbum persisten junto al resto del progreso. La versión gratuita mantiene visible el progreso diario en Inicio, pero oculta la habitación y el álbum. El cambio de día se detecta aunque la app permanezca abierta o se vuelva a abrir.
- El nombre y el animal se guardan por perfil. Las tareas, puntos, tiempo de descanso, snacks, caricias e historial diario se guardan en un registro independiente por perfil. Al actualizar, los datos existentes se migran al perfil anterior sin mezclar el progreso de usuarios nuevos.

### Entrada al descanso

- Al completar una tarea desde el foco (o marcarla terminada) se canjea automáticamente el saldo acumulado y se abre el descanso activo. El temporizador circular empieza de inmediato y su hora de fin se guarda para reanudarlo si se cierra y vuelve a abrir la app.
- Las opciones «Paseo físico», «Jugar con mi mascota» y «Modo libre», junto con el título «¿Cómo quieres descansar?», aparecen centradas.
- Se puede elegir un paseo con sugerencias físicas o jugar a acariciar a la mascota mientras cruza despacio la pantalla y se detiene unos segundos en posiciones aleatorias y a distintas alturas. Cada 10 caricias se conceden 2 puntos de estado, que aparecen sobre la mascota; el contador persiste por perfil. Cada minuto de compañía también mejora el humor de la mascota.
- El modo libre mantiene una notificación de Android y programa un aviso al finalizar aunque la app esté en segundo plano. Si Android no permite las notificaciones, el modo libre sigue activo y el temporizador continúa en la app.
- El botón «Terminar descanso» vuelve a las tareas y acumula el tiempo restante para otro descanso; el saldo puede canjearse en un descanso posterior.
- Al terminar, la aplicación cancela las notificaciones, reproduce una vibración y un sonido breves, muestra el mensaje de la mascota y vuelve directamente a las tareas pendientes.
- El saldo se consume al iniciar el descanso. En el juego de descanso, la mascota se representa con su emoji animado; quedan pendientes las ilustraciones específicas del parque descrito en la propuesta.

## Pendiente para alinear con el documento

- Integrar compras y acceso de pago para perfiles adicionales y habitación/álbum; por ahora se controlan mediante banderas de compilación (`FOCUSPAWS_PREMIUM_MULTIUSER` y `FOCUSPAWS_PREMIUM_STICKER_ALBUM`).
- Completar la celebración de recompensa con confeti y sonido.
- Revisar la presentación y los estados de ánimo/energía de la mascota frente a la propuesta visual.
- Evaluar el aviso sutil al salir de la app durante el foco, respetando permisos y comportamiento del sistema.

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
