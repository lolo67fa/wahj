<div align="center">

# Wahj (وهج)

**Every habit you complete earns a star. Your stars build real constellations.**

![Swift](https://img.shields.io/badge/Swift-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0A84FF?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?logo=apple&logoColor=white)
![Language](https://img.shields.io/badge/Arabic-RTL-9B6BC0)

A habit-tracking iOS app with a dark purple space theme.
Miss a day and your star waits for you instead of going out.

</div>

---

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/My-Habits.png" width="200"><br><sub><b>My Habits</b><br>Lamis</sub></td>
    <td align="center"><img src="docs/screenshots/Missed-habit.png" width="200"><br><sub><b>Missed Habit</b><br>Lamis</sub></td>
    <td align="center"><img src="docs/screenshots/Add-habits.png" width="200"><br><sub><b>Add Habit</b><br>Lamis</sub></td>
  </tr>
</table>

More screens are added as the team finishes them. Screenshots live in `docs/screenshots/`.

## About

**Challenge:** Help people who struggle with daily routines stay motivated and complete their daily tasks consistently.

**Our answer:** Wahj turns daily tasks into a game for young adults and busy people. Other habit apps only track habits. Wahj adds streaks, rewards and friends, so doing your habits feels rewarding and not like a chore.

## Features

- Mark a habit as done to earn a star
- Stars build constellations: Big Dipper, Orion, Cassiopeia and Scorpius
- Daily streaks, with a monthly "streak saver" when you miss a day
- Create habits with an icon, days, a reminder and a duration
- Do habits with friends, invite them from the iOS share sheet and see their progress
- Arabic, right-to-left, dark theme

## Getting started

```bash
git clone https://github.com/lolo67fa/wahj.git
```

Open `tawhj.xcodeproj` in Xcode, pick an iPhone simulator and press **Cmd + R**.

## Project structure

```
wahj/
├── Lamis/            My Habits, Missed Habit, Add Habit
├── Lujain/           Home, first star, completed constellation
├── Zaha/             Friends screens
├── Shared/           Theme, StarryBackground, BottomTabBar
├── docs/screenshots/ README screenshots
├── Assets.xcassets   Images and tab bar icons
├── MyApp.swift       App entry point
└── tawhj.xcodeproj   Xcode project
```

Each person works in their own folder. Files in `Shared/` are used by everyone, so tell the group before changing them.

## How we work

1. `git pull` before you start.
2. Only edit files in your own folder.
3. Commit with a short message that starts with a verb, like `Add Missed Habit page`.
4. `git push` at the end of each session.

> **Xcode:** a new file must be added to the Xcode project, not only copied into the folder, or it will not build. There is only one `@main` file (`MyApp.swift`).

> **Screenshots:** save a PNG in `docs/screenshots/` with a lowercase name and dashes (`my-habits.png`), then add a cell to the table above.

## Design

- [Figma design](https://www.figma.com/design/mYQ0TEcEO8A8MxJhZ3nzjY/Wahj?node-id=1-1322&t=43R1Los8qkt5NdsL-1)
- Miro board: _add the link here_

Colors live in `Shared/Theme.swift`. Use the name (like `Theme.pink`) in code, so a color change happens in one file.

| Color | Name | Hex | Used for |
|:---:|---|---|---|
| ![2F2240](https://img.shields.io/badge/%20%20%20%20%20%20%20-2F2240) | `Theme.bg` | `#2F2240` | Screen background |
| ![3F2B55](https://img.shields.io/badge/%20%20%20%20%20%20%20-3F2B55) | `Theme.card` | `#3F2B55` | Cards, buttons, tab bar |
| ![5A3F73](https://img.shields.io/badge/%20%20%20%20%20%20%20-5A3F73) | `Theme.border` | `#5A3F73` | Borders and thin lines |
| ![E6B4E1](https://img.shields.io/badge/%20%20%20%20%20%20%20-E6B4E1) | `Theme.pink` | `#E6B4E1` | Buttons, progress bars, icons |
| ![FBEFC8](https://img.shields.io/badge/%20%20%20%20%20%20%20-FBEFC8) | `Theme.cream` | `#FBEFC8` | Completed-habit icon circle |
| ![9B6BC0](https://img.shields.io/badge/%20%20%20%20%20%20%20-9B6BC0) | `Theme.tabActive` | `#9B6BC0` | Selected tab |

## Team

| Member | Screens | GitHub |
|---|---|---|
| Ghala | Sign in, appearance, name, welcome, first-time experience | [@lolo67fa](https://github.com/lolo67fa) |
| Ghaida | Daily habits flow: create a habit, set a duration, mark as done |[@Ghhaidaa](https://github.com/lolo67fa) 
| Lujain | Home, first star, completed constellation | [@lujainayman1602-ux](https://github.com/lujainayman1602-ux) |
| Lamis | My Habits, Missed Habit, Add Habit | [@xtvkyx](https://github.com/xtvkyx) |
| Mays | Friends: home, choose a habit, choose a constellation, invitation, progress | |
| Zaha | Friends: home, choose a habit, choose a constellation, invitation, progress | [@zaha7](https://github.com/zaha7) |

Final step: connect all screens with `NavigationStack` and run the app on an iPhone.
