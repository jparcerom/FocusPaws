# FocusPaws — iconos Android para Flutter

## Recomendación
Usa la variante **sin texto** como icono de la app. El nombre ya aparece debajo del icono en el launcher de Android.

## Contenido
- `assets/launcher/*_1024.png`: icono circular transparente de 1024×1024.
- `assets/launcher/*_foreground.png`: capa foreground transparente, reducida para respetar la zona segura de Adaptive Icons.
- `assets/launcher/*.svg`: SVG con PNG incrustado (contenedor SVG; la ilustración sigue siendo raster, no trazados vectoriales).
- `flutter_launcher_icons.yaml`: configuración recomendada, sin texto.
- `flutter_launcher_icons_texto.yaml`: alternativa con texto.

## Instalación en Flutter
1. Copia la carpeta `assets` y el YAML elegido a la raíz de tu proyecto Flutter.
2. En `pubspec.yaml`, añade como dependencia de desarrollo:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
```

3. Ejecuta:

```bash
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

Para generar la alternativa con texto, ejecuta:

```bash
dart run flutter_launcher_icons -f flutter_launcher_icons_texto.yaml
```

4. Reconstruye la app:

```bash
flutter clean
flutter pub get
flutter run
```

## Transparencia y Adaptive Icons
La transparencia está en los PNG `*_foreground.png`. Android compone esa capa sobre `adaptive_icon_background` y aplica la máscara del launcher. El color de fondo actual es crema `#FFF3D6`. Si quieres otro fondo, cambia ese valor en el YAML.

El PNG `*_1024.png` también conserva transparencia exterior y sirve como icono convencional/fallback. No uses el SVG incrustado como fuente de `flutter_launcher_icons`: usa los PNG.

Nota: Android puede aplicar máscaras distintas según el fabricante/tema. La capa foreground deja margen para reducir el riesgo de recorte. El resultado final debe probarse en el launcher del dispositivo.
