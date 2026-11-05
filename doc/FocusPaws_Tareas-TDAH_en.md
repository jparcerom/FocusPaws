# Well-being and focus for ADHD minds

Productivity apps on the market (such as Notion or Todoist) often fail people with ADHD (Attention-Deficit/Hyperactivity Disorder) because they can feel too dull or complex, causing frustration.

- **The user problem:** Not enough dopamine for routine tasks, "time blindness" (difficulty estimating how long things take), and a tendency to forget tasks if the app takes too many steps to capture them.
- **The app concept:** A structured, gamified ADHD organizer. It offers an ultra-visual, clean interface where capturing a task takes only a second (or can be done by voice). To address time blindness, the app includes visual countdown timers and rewards users with game mechanics (points, badges, or avatar unlocks) whenever they complete a task.
- **Monetization model:** Freemium with a subscription. Users can organize their day for free. Advanced features (such as mood and energy charts, interactive home-screen widgets, or white-noise sounds designed for focus) are available for around €4.99 per month.

---

## 🧩 The three essential features (MVP)

To avoid overwhelming users (which could make them uninstall the app), the initial prototype should focus on three visual tools:

- **One-tap capture (zero friction):** Add a task by typing or dictating with one large button on the home screen. Let users review and edit the transcription before saving. Only access the microphone when users choose dictation; speech recognition uses the device's speech service, and FocusPaws does not store audio.
- **Focus Mode with a visual countdown:** People with ADHD may experience "time blindness" (difficulty perceiving the passage of time). Instead of a digital clock with numbers, use a visual timer, such as a colored circle that gradually empties, similar to a Time Timer. This creates a healthy sense of urgency.
- **Immediate dopamine reward (gamification):** Completing a task should be more satisfying than checking a box. Show a lively animation, play a satisfying sound (a pop or burst), or award points toward leveling up a virtual pet. Immediate feedback encourages users to return to the app.

## 🎨 Design and user experience (UX/UI)

People with ADHD can be overwhelmed by visual clutter. The design should follow these principles:

- **Purposeful colors:** Avoid interfaces full of small text. Use colors with strong contrast that are still calming (such as blues, greens, or dark pastels) to distinguish sections.
- **Clear typography:** Use highly legible fonts, such as OpenDyslexic or clean sans-serif typefaces with generous spacing.
- **Uncluttered screens:** Keep the number of elements on each screen low. Showing one primary task at a time helps avoid analysis paralysis.

## 🛠️ Technology roadmap: getting started

Depending on your current skills, there are two clear ways to build the app:

| Development path | Recommended tools | Benefits for this project |
|---|---|---|
| No-code | FlutterFlow or Glide | Ideal if you do not know how to code. Build the visual interface with drag-and-drop tools and launch an MVP in a few weeks. |
| Cross-platform coding | Flutter (Dart) or React Native | The best long-term option. Write the code once and export the app for both Android and iOS, saving development time. |

---

## 1. Home screen proposal (conceptual mockup)

Following the principles of "zero friction and low visual stimulation," the app's home screen should feel like a clean, lively space rather than a boring task list (like a spreadsheet).

### Screen layout (top to bottom)

1. **The pet's area (top 40% of the screen):**
   - The user's pet lives here (for example, a small alien, raccoon, or evolving egg).
   - **Energy/happiness bar:** A visual bar fills up as tasks are completed. If the user does not open the app for a long time, the pet may fall asleep or look sad as a gentle prompt to return.
2. **Quick-capture button (middle 20%):**
   - A single large floating (+) button in the center or lower-right corner.
   - Tapping it opens a simple field: type a task (or press and hold to record it by voice), then tap Save. Do not require categories or complex dates. People with ADHD need to get an idea out of their head right away.
3. **The task at hand (bottom 40%):**
   - Instead of an endless list of 20 tasks that can cause paralysis, show only the day's three main tasks in large, well-spaced cards.
   - Each card has a **Start Focus** (Play) button that opens the visual timer.

## 2. Pet mechanics

To keep the pet system sustainable to build for the initial MVP, use simple progression rules:

- **Starting state:** When they sign up, users receive a "Dopamine Egg."
- **Reward action:** Whenever users complete a task or finish a focus block:
  - Play a satisfying sound effect ("Pop!" or a celebratory chime).
  - Show digital confetti on screen.
  - Award the egg "focus points" until it hatches into a small creature.
- **Level progression:** Each task awards 10, 20, or 40 points according to its selected size. Levels 1 and 2 require 150 points each; levels 3–5 require 180 each; and levels 6–8 require 210 each. The requirement increases by 30 points every three levels. The avatar displays its current level and celebrates each level-up, and the bar shows progress toward the next level. Accumulated points are retained for level calculations, but the lifetime total is hidden to keep the screen simple.
- **First-run personalization:** On first launch, users choose a name and one of six animals, shown in a two-row, three-column grid. The home-screen greeting shows only their name; the selected animal appears in the progress card and celebrates level-ups. The animals are named Nori (dog), Kitty (cat), Foxy (fox), Bunny (rabbit), Bruno (bear), and Panda.

### Android app icon

- The app uses the circular icon without text from the provided `doc/FocusPaws_Flutter_Android` package; Android displays the app name underneath.
- The project keeps the base circular PNG, safe-zone foreground, and foreground enlarged by 5% in `assets/launcher` to cover the mask edge and avoid halos. `flutter_launcher_icons.yaml` selects these assets and generates Android variants.
- The generator adds a `<inset android:inset="16%">` to the adaptive icon by default. After running it, remove that inset from `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` so the foreground is not reduced a second time. Repeat this adjustment after regenerating resources, then build and install the app to check the actual launcher mask.

### Agreed task-screen refinements

- The header shows **FocusPaws** and a **Finish day** button aligned to its right; profile access stays in the selector and profile hub rather than the task screen.
- The progress card omits the “Your companion today” heading and lifetime-points line. It keeps the pet's name and level, progress toward the next level, and available rewards.
- The task section is titled **Your challenge today**, the counter uses the format **0/0 tasks completed**, and completing all tasks shows **Mission accomplished for today!**

---

## ⏱️ Focus Mode screen proposal

People with ADHD may find it difficult to sense the passage of time. A numerical countdown (24:59, 24:58...) can cause paralyzing anxiety or, conversely, boredom.

For this reason, FocusPaws' screen will use a fully visual, gamified approach:

### Screen layout (top to bottom)

1. **Focused pet (top area):**
   - The app's pet appears on screen doing the activity alongside the user. If the user is studying or working, the FocusPaws puppy wears reading glasses and concentrates over a book or computer.
   - If the user leaves the app to check social media, the app can send a gentle notification in the pet's voice: "Hey! I'll be right here when you're ready to keep going."
2. **Visual time indicator (center area):**
   - No large numbers. A colored graphic (for example, a paw print or a soft circle) gradually empties or fills, like sand in an hourglass.
   - This helps the brain estimate the remaining time at a glance, without the stress of a ticking clock.
3. **Simple controls and "panic button" (bottom area):**
   - A large Pause button for genuine interruptions.
   - An Abandon button that asks gently: "Are you sure you want to stop? Your pet will lose a little energy."
   - **Micro-break button (niche feature):** A special button for when the user feels overwhelmed. Tapping it pauses the timer for two minutes and suggests a quick physical action to release tension (for example, "Stretch your arms" or "Take a sip of water"). Focus resumes automatically when the break ends.

## 🏆 The climax: task-completion screen

When the visual timer reaches zero, the user enters a healthy dopamine boost:

- The screen fills with a celebratory animation (digital confetti or flashing paw prints).
- The pet jumps for joy and barks or celebrates with a satisfying sound.
- A large message shows the reward for the selected task size: **"You did it! You earned +10, +20, or +40 energy points for your pet."**

---

## 🗺️ 1. App flow diagram

This diagram shows the simplified user flow from opening the app to earning a reward. For an ADHD-focused app, the flow should be linear and free of distractions:

```text
[ Loading / Start screen ]
            │
            ▼
┌────────────────────────────────────────────────────────┐
│                 HOME SCREEN                            │
│                                                        │
│ 🐾 Pet (mood/energy)                                   │
│ ➕ Large button (add a task in one tap)                │
│ 📋 Cards for the day's three tasks                     │
└───────────────────┬────────────────────────────────────┘
                    │
                    ├─► [ Tap ➕ ] ──► Open quick-entry dialog
                    │                   (type/voice) ──► [ Save ] ──► Home
                    │
                    └─► [ Tap Play (▶️) on a task ]
                                 │
                                 ▼
┌────────────────────────────────────────────────────────┐
│              FOCUS MODE (TIMER)                        │
│                                                        │
│ 🐶 Animated focused pet                                │
│ ⏳ Visual circle that empties (no stressful numbers)   │
│ ⏸️ Pause / 🚨 Micro-break button (2-minute stretch)     │
└───────────────────────────┬────────────────────────────┘
                            │
                  (Timer reaches zero)
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│              REWARD SCREEN                             │
│                                                        │
│ 🎉 Confetti animation / "Pop!" sound                   │
│ 🐕 Happy, jumping pet                                  │
│ 💎 Task-size reward (10/20/40 points)                  │
└───────────────────────────┬────────────────────────────┘
                            │
                   (Tap "Continue")
                            │
                            ▼
                   [ Return to Home ]
                   (Task is crossed out / pet is happy)
```

## 🛠️ 2. First technical tasks (Sprint 1)

If you are building this yourself (with Flutter/React Native or a no-code tool such as FlutterFlow), these are the first technical priorities, grouped into logical blocks. Focus only on these to get the first prototype ready:

### Block 1: Project setup and database (backend)

- **Task 1.1:** Create a clean project in your development environment (for example, Flutter) and configure the interface's base colors (a calming palette: pastel blue, soft green, and a dark background to reduce eye strain).
- **Task 1.2:** Create the local database structure (SQLite or Hive). You only need a table called `Tasks` with these fields: `id` (number), `title` (text), and `completed` (true/false).
- **Task 1.3:** Create a local table or variable for the pet that stores `energy_points` (an integer starting at 0).

### Block 2: Visual interface (frontend)

- **Task 2.1:** Design the home screen. Add a pet placeholder, a large button for adding tasks, and a dynamic list that reads tasks from the database.
- **Task 2.2:** Implement the Add Task button. Tapping it should open a simple text field with an option to dictate in Spanish. Let users review and edit the transcription before saving. Offer three text-only size buttons: Short (15 min), Medium (30 min), and Long (45 min); do not show durations or points inside the buttons. Save the title and estimated duration, then refresh the screen immediately.
- **Task 2.3:** Design the Focus Mode screen. Create an animated circular timer component (you could use a Flutter library such as `percent_indicator`) that uses the task estimate (15, 30, or 45 minutes) and steadily reduces the colored circle.

### Block 3: Gamification and rewards

- **Task 3.1:** Implement timer completion. When the circle empties, let users add a visual 5-minute extension, switch to count-up free mode, or finish the task.
- **Task 3.2:** Implement the reward screen. Add a satisfying sound trigger (a short `.mp3` file) and award the task-size points (10, 20, or 40) when the user taps **Continue**.

---

## Focus Mode behavior

FocusPaws should adapt to variable productivity windows and let users finish a task without waiting for the timer.

### Scenario 1: The user finishes before the timer expires

The user can tap **"I finished early!"** at any time during focus.

- The pet receives the full points for the selected task size: 10, 20, or 40.
- Show positive, pet-specific feedback, such as: "Wow! Your brain flew today. [Pet name] is proud of your speed."
- If at least half of the estimated focus block has elapsed, add the remaining timer duration to the bonus-rest balance, up to the cap for that task size.
- If the user finishes before half of the estimated block has elapsed, award the points but do not add the remaining time to the rest balance. Keep the standard rest and show a friendly explanation.

### Scenario 2: The timer expires before the task is done

Do not treat the task as failed or force the user to take a break. Move to a calm, "Zen" state with these choices:

1. **"I need 5 more minutes"** starts a visual 5-minute extension without leaving the screen.
2. **"Continue in free mode"** starts a discreet count-up timer to track additional focus time.

When the user taps **"Finish task,"** award the points for the selected task size. Completing after more than 10 extra minutes also grants a collectible snack.

| User action | Timer state | Destination | Reward |
|---|---|---|---|
| Taps "I finished early!" | Manually stopped | Reward screen | Task-size points and eligible bonus rest |
| Timer expires after the task is done | Reaches 00:00 | Reward screen | Task-size points |
| Timer expires while the task is unfinished | Reaches 00:00 | Extension / free mode | Task-size points on completion; snack after more than 10 extra minutes |

## Time estimated for each task

### Quick size selection

Do not ask users to type a duration. Offer three task-size buttons when creating a task:

| Task size | Estimated time | Pet points | Maximum bonus rest |
|---|---:|---:|---:|
| Short step | 15 minutes | 10 | 3 minutes |
| Standard block | 30 minutes | 20 | 7 minutes |
| Big effort | 45 minutes | 40 | 10 minutes |

Do not offer durations above 45 or 60 minutes; encourage users to split larger tasks into smaller subtasks.

### Agreed implementation decisions

- The size-based reward table replaces the previous fixed reward and applies whether a task is completed from Home or in a focus session, including after an extension or in free mode.
- If **"I finished early!"** is tapped before half of the estimated time has elapsed, do not add the remaining time to the bonus-rest balance. Keep the standard rest and show a friendly message.
- Once at least half of the estimated block has elapsed, add the remaining time to the rest balance up to the size-specific cap. Any excess is discarded rather than stored in a separate bank.
- Tasks saved before task sizes were introduced are treated as Standard blocks (30 minutes and 20 points when completed under the new table). Points earned before this change are preserved without retroactive adjustment.

---

## Profile management

### Agreed implementation decisions

- When the app opens with saved profiles, it shows a profile selector. Each profile button displays the selected name and pet.
- Selecting a profile opens an intermediate hub with large buttons to change the pet, edit the name, open the pet room/sticker album, and access tasks.
- **Finish day** returns to the selector without deleting tasks, points, rewards, or daily history.
- Progress is stored by profile ID. When upgrading from the single-profile version, the existing profile retains the previous record; new profiles start with separate progress.
- Creating additional users is prepared for the paid version: the option is visible during development and hidden by default in release builds. A build can enable it with `--dart-define=FOCUSPAWS_PREMIUM_MULTIUSER=true`; the free version shows only the default profile and does not delete the other profiles' data. This flag does not replace purchase integration.

---

## Persistence system

The app should preserve progress between sessions and present accumulated effort visually through a pet room or sticker album rather than spreadsheet-like statistics. During development, all progress views remain available; the album can be hidden for the free tier later.

### Agreed implementation decisions

- The first collectible format is a sticker album. Each sticker represents a local calendar day on which the user completed three distinct tasks. Completions from Home and Focus Mode both count.
- Daily progress resets when the device's local date changes. Completing the same task again on the same day does not count it twice.
- Tasks, points, task sizes, bonus rest, snacks, daily completions, and sticker-unlock dates are saved together in the local progress record. Older records remain compatible; tasks without dated history are not attributed to past days.
- The album is visible during development. The `FocusPawsFeatures.showStickerAlbum` flag can hide it later while keeping daily progress visible on Home.

---

## 🛠️ Development environment and workflow

- Android Studio is installed in `F:\Android\Android Studio`; the Android SDK and emulator are in `F:\Android\Sdk`. Use these locations when configuring or running Android tools; do not check the default locations first.
- The Flutter SDK will be installed in `F:\Android\flutter`.
- The Pixel 6 emulator initially has Gboard set to English (US). To type accented Spanish characters, add Spanish under Settings → System → Keyboard → On-screen keyboard → Gboard → Languages; the app does not filter accented letters.
- We will develop the app incrementally: complete and verify each feature before moving on to the next.
- The interface should be polished, clear, and intuitive, with particular care to reduce cognitive load and visual clutter for people with ADHD.
