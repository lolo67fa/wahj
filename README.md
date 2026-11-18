# Wahj (وهج)

A habit-tracking iOS app built with SwiftUI. Every habit you complete earns a star, and your stars slowly build real constellations. Miss a day and your star waits for you instead of going out.

The app is in Arabic (right-to-left) with a dark purple space theme.

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
  Lamis/        My Habits, Missed Habit, Add Habit, HabitCard, HabitStore, RootView
  Lujain/       Home, first star achievement, completed constellation
  Zaha/         Friends screens (HabitScreens)
  Shared/       Theme (colors), StarryBackground, BottomTabBar
  Assets.xcassets   Star images and tab bar icons
  MyApp.swift   App entry point (only one in the project)
  tawhj.xcodeproj
```

Each person works in their own folder (for example `Ghala/`, `Lujain/`). Files in `Shared/` are used by everyone, so tell the group before changing them.

## Getting started

1. Clone the repo:
   ```bash
   git clone https://github.com/lolo67fa/wahj.git
   ```
2. Open `tawhj.xcodeproj` in Xcode.
3. Pick an iPhone simulator and press Run (Cmd + R).

Requirements: a Mac with Xcode (_add the version you use_).

## How we work together

- Run `git pull` before you start working.
- Only edit files in your own folder.
- Commit with a short message that starts with a verb, for example: `Add Missed Habit page`.
- Run `git push` at the end of each session.
- There is only one `@main` app file (`MyApp.swift`). Do not add another.

## Design

- Figma: _add the link here_
- Miro board (research, concept and task planning): _add the link here_
- Colors are defined once in `Shared/Theme.swift`. Use `Theme.pink`, `Theme.card` and so on instead of typing hex codes in a screen.

## Team

- Ghala ([@lolo67fa](https://github.com/lolo67fa))
- Ghaida 
- Lujain
- Lamis ([@xtvkyx](https://github.com/xtvkyx))
- Mays
- Zaha
