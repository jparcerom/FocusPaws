# FocusPaws

A Flutter mobile app designed to help people with ADHD organize tasks in a simple, visual, and supportive way.

## Implemented features

### Android app icon

- The app uses the circular icon without text from `doc/FocusPaws_Flutter_Android` (the launcher displays the app name). Its project source is in `assets/launcher`; `flutter_launcher_icons.yaml` generates the Android resources.
- The foreground layer is enlarged by 5% so the circle covers the mask edge and avoids halos. When regenerating resources, remove the 16% `<inset>` that `flutter_launcher_icons` adds to `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`; otherwise, the icon will look small again.
- On launch, the native splash shows the circular FocusPaws logo with its wordmark and the one-line footer “FocusPaws: tareas TDAH versión 1.0 por jpm” on a soft pastel yellow (`#FFF3D6`). Android 12 uses a reduced variant so the circle and wordmark fit inside its mask. The splash is configured in `flutter_native_splash.yaml`.
- The app is versioned as `1.0.0+1` in `pubspec.yaml`; the splash displays the product version as `1.0`. The same pastel yellow is used for the app background.
- Secondary surfaces use a light mint inspired by the logo; primary buttons use its dark teal with white text.
- The main-screen header shows the transparent circular icon without text next to FocusPaws.

### Profiles

- Onboarding lets users choose a name and one of six animals in a two-row, three-column grid; the profile is saved locally. The greeting shows the person's name and current weekday, and the selected animal appears in the progress card: Nori (dog), Kitty (cat), Foxy (fox), Bunny (rabbit), Bruno (bear), or Panda.
- Reopening the app shows a profile selector. Each profile opens an intermediate hub for editing its name or pet, opening its album, and entering its tasks. **Finish day** returns to the selector without deleting tasks or rewards.
- Creating additional profiles is available in development and can be enabled in a build with `--dart-define=FOCUSPAWS_PREMIUM_MULTIUSER=true`; release builds show only the default free profile. Each profile keeps its progress separate.

### Tasks and home screen

- Tasks can be added by typing or dictating in Spanish. Users can review and edit the transcription before saving. Dictation uses the device's speech-recognition service, and FocusPaws does not store audio.
- Home shows up to three recent pending tasks and lets users expand the list to see additional or completed tasks. When the date changes, completed tasks leave the active list and the daily counter starts at zero; pending tasks are kept, with an option to keep them for today or cancel them.
- The task header shows FocusPaws and a right-aligned **Finish day** button; it has no profile shortcut. The pet card omits the “Your companion today” heading and lifetime points. The task section is titled **Your challenge today**, the counter says **0/0 tasks completed**, and completing all tasks shows **Mission accomplished for today!**
- The pet progress card introduces the pet as “I am [name]”.

### Focus Mode and rewards

- New tasks use three text-only size buttons: Short (15 min, +10 points), Medium (30 min, +20 points), and Long (45 min, +40 points). The buttons do not display durations or points. Tasks created before this option was added are treated as standard.
- The new reward table applies to tasks completed from now on; previously earned points are preserved unchanged.
- Points are awarded only once per task, whether it is completed from Home or after a focus session.
- If a task is finished before half of its estimated time has elapsed, the user receives the size-based points but no bonus rest time. If at least half the block has elapsed, the remaining time is added to the rest balance, capped at 3, 7, or 10 minutes according to task size.
- If the focus block expires before the task is done, users can add a visual 5-minute extension, switch to count-up free mode, or finish the task. Completing after more than 10 extra minutes also grants a collectible snack.
- Abandoning Focus Mode requires confirmation and does not complete the task or award points. Session rewards are applied when the user taps **Continue**.

### Progress and persistence

- The visual timer uses the task's estimated duration, shows no numeric countdown, and can be paused/resumed. A 2-minute micro-break automatically returns to focus.
- The bonus-rest balance and snacks appear with the pet's progress. The card shows the current level and progress to the next level, not lifetime points. Levels 1 and 2 require 150 points each; levels 3–5 require 180 each; and levels 6–8 require 210 each. The requirement increases by 30 points every three levels.
- Daily progress counts distinct tasks completed on the local calendar date. Completing three tasks in one day unlocks a sticker; the history and sticker album persist with the rest of the progress. The album is visible during development and can later be hidden behind a feature flag while daily progress stays on Home. Day changes are detected both while the app stays open and when it is reopened.
- The name and animal are saved per profile. Tasks, points, bonus rest, snacks, and daily history are kept in a separate local record for each profile. Existing data is migrated to the original profile during an update so it is not mixed with new users' progress.

### Entering a rest break

- Completing a task through focus (or marking it complete) automatically redeems the accumulated balance and opens the active-rest screen. Its circular countdown starts immediately, and the end time is saved so the break can resume if the app is closed and reopened.
- Users can choose a physical-walk suggestion, interact with the pet (each full minute improves its persisted mood), or activate controlled free mode. Free mode keeps an ongoing Android notification and schedules an end alert even while the app is backgrounded.
- At the end, the app cancels the notifications, plays a brief vibration and sound, shows the pet's message, and returns directly to pending tasks.
- The balance is consumed when the break starts. The pet is currently represented by its emoji and a resting indicator; dedicated park illustrations and animations from the proposal remain to be created.

## Remaining work to align with the product brief

- Integrate per-user paid access for creating additional profiles; it is currently controlled by a build flag.
- Complete the reward celebration with pet animation, confetti, and sound.
- Review the pet's visual presentation and mood/energy states against the proposal.
- Evaluate a subtle notification when the app is backgrounded during focus, respecting permissions and system behavior.

## Resumption point

Task size now determines the focus timer and reward, including the 50% threshold and the size-based rest cap. There are six pets in a 2 × 3 grid. The profile selector, profile editor, and **Finish day** action are implemented; progress is isolated per profile and existing data is migrated. Continue without rebuilding these flows.

**Validation for this iteration:** `flutter analyze` reported no issues, all `flutter test` tests passed, and the debug APK was built, installed, and launched on `emulator-5554`.

**Paused for user testing:** the active-rest flow is implemented and covered by automated tests. Development is paused here so the user can test it on a device/emulator, especially notification permission, free mode in the background, and the end alert. When resuming, collect those test results before changing the flow.

**Next step after testing:** address any observed issues, then develop dedicated pet illustrations and animations.

**Pending decision:** the product brief suggests that the pet loses some energy when a user abandons a session, but does not define how much or how it should be calculated. Do not implement that penalty until its behavior is agreed.

## Development environment

- Android Studio: `F:\Android\Android Studio`
- Android SDK and emulator: `F:\Android\Sdk`
- Flutter SDK: `F:\Android\flutter`
- The Pixel 6 emulator initially has Gboard set to English (US). To type accented Spanish characters, add Spanish under **Settings → System → Keyboard → On-screen keyboard → Gboard → Languages**. The app does not filter accented characters.

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

- [Product brief (English)](doc/FocusPaws_Tareas-TDAH_en.md)
- [Descripción del producto (español)](doc/FocusPaws_Tareas-TDAH_es.md)
