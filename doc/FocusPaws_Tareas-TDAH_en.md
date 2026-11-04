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
- **Level progression:** Each completed task awards 15 points. Levels 1 and 2 require 150 points each; levels 3–5 require 180 each; and levels 6–8 require 210 each. The requirement increases by 30 points every three levels. The avatar displays its current level and celebrates each level-up, and the bar shows progress toward the next level. Lifetime points stay visible so earlier progress is never lost.
- **First-run personalization:** On first launch, users choose a name and one of five animals. The home-screen greeting shows only their name; the selected animal appears in the progress card and celebrates level-ups. The animals are named Nori (dog), Kitty (cat), Foxy (fox), Bunny (rabbit), and Bruno (bear).

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
- A large message appears: **"You did it! You earned +15 energy points for your pet."**

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
│ 💎 +15 points awarded to the pet                       │
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
- **Task 2.2:** Implement the Add Task button. Tapping it should open a simple text field with an option to dictate in Spanish. Let users review and edit the transcription before saving. Saving should add the record to the database and refresh the screen immediately.
- **Task 2.3:** Design the Focus Mode screen. Create an animated circular timer component (you could use a Flutter library such as `percent_indicator`) that starts at a fixed duration (for example, 25 minutes) and steadily reduces the colored circle.

### Block 3: Gamification and rewards

- **Task 3.1:** Implement the timer-completion logic. When the circle empties, automatically navigate to the success screen.
- **Task 3.2:** Implement the reward screen. Add a satisfying sound trigger (a short `.mp3` file) and add +15 points to the pet's database value when the user taps **Continue**.

---

## 🛠️ Development environment and workflow

- Android Studio is installed in `F:\Android\Android Studio`; the Android SDK and emulator are in `F:\Android\Sdk`. Use these locations when configuring or running Android tools; do not check the default locations first.
- The Flutter SDK will be installed in `F:\Android\flutter`.
- We will develop the app incrementally: complete and verify each feature before moving on to the next.
- The interface should be polished, clear, and intuitive, with particular care to reduce cognitive load and visual clutter for people with ADHD.
