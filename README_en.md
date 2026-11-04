# FocusPaws

A Flutter mobile app designed to help people with ADHD organize tasks in a simple, visual, and supportive way.

## Phase 1 complete

- Onboarding lets users choose a name and one of five animals; the profile is saved locally. The greeting shows only the person's name, and the selected animal appears in the progress card: Nori (dog), Kitty (cat), Foxy (fox), Bunny (rabbit), or Bruno (bear).
- The home screen supports adding tasks by typing or dictating in Spanish, reviewing and editing the transcription, and marking tasks complete.
- Each completed task awards 15 points. Levels 1 and 2 require 150 points each; levels 3 to 5 require 180 each; and levels 6 to 8 require 210 each. The requirement increases by 30 points every three levels. The selected animal celebrates level-ups, and the bar shows progress toward the next level alongside lifetime points.
- Dictation uses the device's speech-recognition service, requires microphone permission, and may need an internet connection; FocusPaws does not store audio.
- The name and animal are saved on the device. Tasks and points are still held in memory and are lost when the app closes.

This phase was validated with `flutter test`, `flutter analyze`, and a debug build installed on the Android emulator. Run the tests and analyzer again before starting another feature.

## Development environment

- Android Studio: `F:\Android\Android Studio`
- Android SDK and emulator: `F:\Android\Sdk`
- Flutter SDK: `F:\Android\flutter`

On Windows, run Flutter commands by specifying the full path:

```powershell
& 'F:\Android\flutter\bin\flutter.bat' analyze
& 'F:\Android\flutter\bin\flutter.bat' test
& 'F:\Android\flutter\bin\flutter.bat' devices
& 'F:\Android\flutter\bin\flutter.bat' run
```

The `Pixel_6` AVD has an outdated skin path in its configuration. Start it using the skins installed with the current SDK:

```powershell
& 'F:\Android\Sdk\emulator\emulator.exe' -avd Pixel_6 -skindir 'F:\Android\Sdk\skins' -skin pixel_6
```

To develop for Android, accept the SDK licenses in Android Studio or run `flutter doctor --android-licenses` interactively. The licenses must be accepted before building or installing the app on the emulator.

Run `flutter analyze` and `flutter test` before moving on to the next feature.

## Documentation

- [Descripción del producto (español)](doc/FocusPaws_Tareas-TDAH_es.md)
- [Product brief (English)](doc/FocusPaws_Tareas-TDAH_en.md)
