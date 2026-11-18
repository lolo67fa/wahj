# Wahj (وهج)

A habit-tracking iOS app built with SwiftUI. Every habit you complete earns a star, and your stars slowly build real constellations. Miss a day and your star waits for you instead of going out.

The app is in Arabic (right-to-left) with a dark purple space theme.

## Screenshots

Each person adds their own screens to `docs/screenshots/` and a row to the table below.

| Owner | Screen | Screenshot |
|---|---|---|
| Lamis | My Habits | <img src="docs/screenshots/my-habits.png" width="200"> |
| Lamis | Missed Habit | <img src="docs/screenshots/missed-habit.png" width="200"> |
| Lamis | Add Habit | <img src="docs/screenshots/add-habit.png" width="200"> |
| Ghala | _coming soon_ | |
| Ghaida | _coming soon_ | |
| Lujain | _coming soon_ | |
| Mays | _coming soon_ | |
| Zaha | _coming soon_ | |

## Contents

- [The idea](#the-idea)
- [Features](#features)
- [Screens and owners](#screens-and-owners)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [How we work together](#how-we-work-together)
- [Design](#design)
- [Team](#team)

## The idea

**Challenge:** Help people who struggle with daily routines stay motivated and complete their daily tasks consistently.

**App concept:** An app that helps young adults and busy people build healthy habits and stay motivated by turning daily tasks into a fun game. Users stay consistent through daily streaks and can share their progress with friends.

**What makes it different:** Other habit apps track habits. Wahj combines habit tracking, gamification and personalized rewards in one experience, so doing your habits feels rewarding and not like a chore.

## Features

- Create daily habits with an icon, days, a reminder and a duration
- Mark a habit as done to earn a star
- Stars build constellations: Big Dipper (الدب الأكبر), Orion (الجبار), Cassiopeia (ذات الكرسي) and Scorpius (العقرب)
- Daily streaks, with a monthly "streak saver" when you miss a day
- Friends: start a habit together, invite friends with the iOS share sheet, and see each other's progress
- Arabic, right-to-left, dark theme

## Screens and owners

| Owner | Screens |
|---|---|
| Ghala | Sign in, appearance choice, name, welcome and first-time experience |
| Ghaida | Daily habits flow: create a habit, set a duration, mark habits as done |
| Lujain | Home, first star achievement, completed constellation |
| Lamis | My Habits, Missed Habit, Add a New Habit |
| Mays and Zaha | Friends home, choose a habit, choose a constellation, share invitation, friends progress |

Final step: connect all screens with `NavigationStack` and run the app on an iPhone.

## Project structure

```
wahj/
  Lamis/            My Habits, Missed Habit, Add Habit, HabitCard
  Lujain/           Home, first star achievement, completed constellation
  Zaha/             Friends screens
  Shared/           Theme (colors), StarryBackground, BottomTabBar
  docs/
    screenshots/    PNG screenshots of each screen (used in this README)
  Assets.xcassets   Star images and tab bar icons
  MyApp.swift       App entry point (only one in the project)
  tawhj.xcodeproj   Xcode project file (created by Ghala)
  README.md
```

Each person works in their own folder (for example `Ghala/`, `Ghaida/`). Files in `Shared/` are used by everyone, so tell the group before changing them.

## Getting started

1. Clone the repo:
   ```bash
   git clone https://github.com/lolo67fa/wahj.git
   ```
2. Open `tawhj.xcodeproj` in Xcode.
3. Pick an iPhone simulator and press Run (Cmd + R).

Requirements: a Mac with Xcode (_add the version you use_).

## How we work together

**Git**
- Run `git pull` before you start working.
- Only edit files in your own folder.
- Commit with a short message that starts with a verb, for example: `Add Missed Habit page`.
- Run `git push` at the end of each session.

**Xcode**
- There is only one `@main` app file (`MyApp.swift`). Do not add another.
- New files must be added to the Xcode project (`tawhj.xcodeproj`) as well as the folder. If you only copy a file into the folder, Xcode will not build it.

**Screenshots**
- Save them in `docs/screenshots/`, as PNG.
- Use lowercase names with dashes and no spaces, for example `my-habits.png`.
- To add yours, copy a row in the Screenshots table and change the owner, screen name and file name.
- Screenshots are for the README only, so they do not need to be added to the Xcode project.

## Design

- Figma: [Wahj design](https://www.figma.com/design/mYQ0TEcEO8A8MxJhZ3nzjY/Wahj?node-id=1-1322&t=43R1Los8qkt5NdsL-1)
- Miro board (research, concept and task planning): _add the link here_
- Colors live in `Shared/Theme.swift`. In code, use the name (for example `Theme.pink`) so a color change only happens in one file.

| Name | Hex | Used for |
|---|---|---|
| `Theme.bg` | `#2F2240` | Screen background |
| `Theme.card` | `#3F2B55` | Cards, buttons, tab bar |
| `Theme.border` | `#5A3F73` | Borders and thin lines |
| `Theme.pink` | `#E6B4E1` | Main accent: buttons, progress bars, icons |
| `Theme.cream` | `#FBEFC8` | Completed-habit icon circle |
| `Theme.tabActive` | `#9B6BC0` | Selected tab |

## Team

- Ghala ([@lolo67fa](https://github.com/lolo67fa))
- Ghaida
- Lujain ([@lujainayman1602-ux](https://github.com/lujainayman1602-ux))
- Lamis ([@xtvkyx](https://github.com/xtvkyx))
- Mays
- Zaha ([@zaha7](https://github.com/zaha7))
