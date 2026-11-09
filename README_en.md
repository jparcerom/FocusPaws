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
- Rest notifications use the existing Android `ic_launcher_foreground` resource.

## Versions and maintenance

- The Git tag `version-prueba-v1.0.0` identifies the complete free trial version described here and serves as its stable baseline.
- The trial version will receive no new features. It will only be changed to fix bugs, keeping those fixes separate from development of the complete version.
- The `version-completa` branch starts from this same baseline. New planned features will be developed there without changing the trial version.

### Profiles

- Onboarding displays the round, transparent FocusPaws logo with its name (cropped from the same circular Android 12 splash asset to remove excess transparent padding) and lets users choose a name and one of six animals in a two-row, three-column grid; the profile is saved locally. The greeting shows the person's name and current weekday, and the selected animal appears in the progress card: Nori (dog), Kitty (cat), Foxy (fox), Bunny (rabbit), Bruno (bear), or Panda.
- Reopening the app shows a profile selector. Each profile opens an intermediate hub for editing its name or pet, opening its album, and entering its tasks. **Finish day** returns to the selector without deleting tasks or rewards.
- The free version allows one profile and shows daily progress on Home; it does not show the pet room or sticker album. On first launch, users see a one-time welcome introducing FocusPaws for people with ADHD and neurodivergent minds, followed by a notice describing these limitations. Additional profiles and the album can be previewed during development and enabled in builds with `--dart-define=FOCUSPAWS_PREMIUM_MULTIUSER=true` and `--dart-define=FOCUSPAWS_PREMIUM_STICKER_ALBUM=true`. Both options are off by default in release builds, so `flutter build apk --release` produces the free version without extra flags; progress and other profiles' data are not deleted.

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
- Daily progress counts distinct tasks completed on the local calendar date. Completing three tasks in one day unlocks a sticker; the history and sticker album persist with the rest of the progress. The free version keeps daily progress visible on Home but hides the pet room and album. Day changes are detected both while the app stays open and when it is reopened.
- The name and animal are saved per profile. Tasks, points, bonus rest, snacks, petting count, and daily history are kept in a separate local record for each profile. Existing data is migrated to the original profile during an update so it is not mixed with new users' progress.

### Entering a rest break

- Completing a task through focus (or marking it complete) automatically redeems the accumulated balance and opens the active-rest screen. Its circular countdown starts immediately, and the end time is saved so the break can resume if the app is closed and reopened.
- The **Physical walk**, **Play with my pet**, and **Free mode** options and the “How would you like to rest?” heading are centered.
- Users can choose a physical-walk suggestion or play by petting the animal as it moves slowly across the screen, pausing for a few seconds at random positions and heights. Every 10 pets grants 2 status points, shown above the pet; the counter persists per profile. Each full minute of company also improves the pet's persisted mood.
- Free mode keeps an ongoing Android notification and schedules an end alert even while the app is backgrounded. If Android does not allow notifications, free mode stays active and the timer continues in the app.
- The **Finish rest** button returns to the tasks and adds the remaining time to the rest balance for a later break.
- At the end, the app cancels the notifications, plays a brief vibration and sound, shows the pet's message, and returns directly to pending tasks.
- The rest balance is redeemed when the break starts. In the pet game, the pet is represented by its animated emoji; dedicated park illustrations from the proposal remain to be created.

## Remaining work to align with the product brief

- Integrate purchases and paid access for additional profiles and the pet room/album; these are currently controlled by build flags (`FOCUSPAWS_PREMIUM_MULTIUSER` and `FOCUSPAWS_PREMIUM_STICKER_ALBUM`).
- Complete the reward celebration with pet animation, confetti, and sound.
- Review the pet's visual presentation and mood/energy states against the proposal.
- Evaluate a subtle notification when the app is backgrounded during focus, respecting permissions and system behavior.

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
