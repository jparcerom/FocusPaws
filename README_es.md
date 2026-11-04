# FocusPaws

Aplicación móvil en Flutter para ayudar a personas con TDAH a organizar tareas de forma sencilla, visual y amable.

## Fase 1 completada

- El onboarding permite elegir nombre y uno de cinco animales; el perfil se guarda localmente. El saludo muestra solo el nombre y el animal seleccionado aparece en el recuadro de progreso: Nori (perro), Kitty (gato), Foxy (zorro), Bunny (conejo) o Bruno (oso).
- La pantalla principal permite añadir tareas por escrito o dictarlas en español, revisar y editar la transcripción, y marcar tareas como completadas.
- Cada tarea completada suma 15 puntos. Los niveles 1 y 2 requieren 150 puntos cada uno; los niveles 3 a 5, 180; y los niveles 6 a 8, 210. El requisito aumenta 30 puntos cada tres niveles. El animal celebra al subir de nivel y la barra muestra el avance del nivel junto con los puntos totales.
- El dictado usa el servicio de reconocimiento del dispositivo, requiere permiso del micrófono y puede necesitar conexión a internet; FocusPaws no guarda audio.
- El nombre y el animal se guardan en el dispositivo. Las tareas y los puntos siguen en memoria y se pierden al cerrar la app.

Esta fase se validó con `flutter test`, `flutter analyze` y una compilación e instalación de depuración en el emulador Android. Antes de empezar otra funcionalidad, vuelve a ejecutar las pruebas y el análisis.

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
