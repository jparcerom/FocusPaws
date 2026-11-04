# FocusPaws

A Flutter mobile app designed to help people with ADHD organize tasks in a simple, visual, and supportive way.

## Implemented features

### Profile and tasks

- Onboarding lets users choose a name and one of five animals; the profile is saved locally. The greeting shows only the person's name, and the selected animal appears in the progress card: Nori (dog), Kitty (cat), Foxy (fox), Bunny (rabbit), or Bruno (bear).
- Tasks can be added by typing or dictating in Spanish. Users can review and edit the transcription before saving. Dictation uses the device's speech-recognition service, and FocusPaws does not store audio.
- Home shows up to three recent pending tasks and lets users expand the list to see additional or completed tasks.
- Tasks, their size, completion state, and reward markers are saved locally along with points, bonus rest time, and snacks.

### Task sizes and rewards

- New tasks can be assigned a quick size: Short step (15 min, +5 points), Standard block (30 min, +15 points), or Big effort (45 min, +30 points). Tasks created before this option was added are treated as standard.
- Points are awarded only once per task, whether it is completed from Home or after a focus session.
- If a task is finished before half of its estimated time has elapsed, the user receives the size-based points but no bonus rest time. If at least half the block has elapsed, the remaining time is added to the rest balance, capped at 3, 7, or 10 minutes according to task size.
- If the focus block expires before the task is done, users can add a visual 5-minute extension, switch to count-up free mode, or finish the task. Completing after more than 10 extra minutes also grants a collectible snack.
- Abandoning Focus Mode requires confirmation and does not complete the task or award points. Session rewards are applied when the user taps **Continue**.

### Focus Mode and progress

- The visual timer uses the task's estimated duration, shows no numeric countdown, and can be paused/resumed. A 2-minute micro-break automatically returns to focus.
- Bonus rest and snacks appear with the pet's progress. Levels 1 and 2 require 150 points each; levels 3–5 require 180 each; and levels 6–8 require 210 each. The requirement increases by 30 points every three levels.
- The name, animal, tasks, and points are saved on the device. Task and points progress are stored together in one local record.

## Remaining work to align with the product brief

- Complete the reward celebration with pet animation, confetti, and sound.
- Review the pet's visual presentation and mood/energy states against the proposal.
- Evaluate a subtle notification when the app is backgrounded during focus, respecting permissions and system behavior.
- Define how accumulated bonus rest time can be redeemed.

## Resumption point

Task size now determines the focus timer and reward, including the 50% threshold and the size-based rest cap. Continue with the next step without rebuilding onboarding, task capture and list views, local persistence, or the implemented focus flows.

**Validation for this iteration:** `flutter analyze` with no issues; all 19 `flutter test` tests passed; the debug APK was built, installed, and launched on Android emulator `emulator-5554`.

**Next step:** complete the reward screen from the flow diagram: an animated pet celebration, confetti, and a satisfying sound.

**Pending decision:** the product brief suggests that the pet loses some energy when a user abandons a session, but does not define how much or how it should be calculated. Do not implement that penalty until its behavior is agreed.

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

- [Product brief (English)](doc/FocusPaws_Tareas-TDAH_en.md)
- [Descripción del producto (español)](doc/FocusPaws_Tareas-TDAH_es.md)
