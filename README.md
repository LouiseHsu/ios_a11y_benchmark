# iOS Accessibility QA Procedure (UIKit vs. Flutter)

## How This Test Works
You will test two apps side-by-side on the same iOS version:
1. **`UIKit A11y Benchmark`** (The **Ruler** — always shows the correct native iOS behavior)
2. **`Flutter A11y Benchmark`** (The **App Under Test**)

**Rule**: Perform each screen flow below on **UIKit first**, then immediately on **Flutter**. If Flutter behaves, speaks, scrolls, or focuses differently than UIKit, file an issue. If you only have one device, launch the Flutter app in release mode `flutter build ios --release` to prevent the app from dying when backgrounded.

**⚠️ steps**: A few checks exercise Material widgets that have no stock iOS control (checkbox, radio, dropdown, clock dial). There the UIKit app shows the *nearest native idiom*; a difference may be intentional. For those steps, **write down exactly what each app says** rather than pass/fail.

---

## Pass 1: VoiceOver (6 Screens)

**Setup**: Turn **VoiceOver ON** (`Settings > Accessibility > VoiceOver`) and enable **Show Caption Panel** BEFORE opening either app.

- [ ] **1. Home Menu & Navigation**
  1. **Cold launch** both apps with VoiceOver already on.
     - *Expected*: Immediately focuses and announces **`"Flutter A11y Benchmark, Heading"`**.
  2. **Swipe right** to the first menu row.
     - *Expected*: Announces **`"Scroll Baseline, 100-cell list with Δy/viewportHeight ratio & page scroll status, Button"`** (must end with **`"Button"`**).
  3. **Double-tap** `Scroll Baseline` to open it, then **swipe left** to the Back button.
     - *Expected*: On open, initial focus lands on **`"contentOffset.y: 0.0, 0.0"`** (not the Back button). Swiping left focuses the Back button **once** (not twice) and announces **`"Flutter A11y Benchmark, Back button"`**.
  4. **2-finger Z-scrub** (scrub two fingers in a "Z" shape) to go back.
     - *Expected*: Returns to the Home Menu with focus restored on **`"Scroll Baseline, 100-cell list..., Button"`**.

- [ ] **2. Screen 1 — Scroll Baseline**
  1. **Single-finger swipe right** repeatedly from `Item #0` (**`"Item #0, Baseline scroll row 1 of 100"`**) past the bottom of the screen (`Item #10` → `Item #15`).
     - *Expected*: Off-screen rows automatically scroll into view without getting stuck at the bottom edge or jumping back to `"contentOffset.y..."`.
  2. **3-finger swipe up** (from `Item #2`) to scroll down one page.
     - *Expected*: Plays the scroll chime, announces **`"Page 2 of 11"`**, and the header's `Δy / viewportHeight` reads **`~1.000 (100.0%)`** (not `0.800 (80.0%)`).
  3. **Status-bar double-tap**: Scroll to `Item #30`, tap the **iOS Status Bar** (top clock/battery) once to focus it, then **double-tap**.
     - *Expected*: Smoothly scrolls back to `Item #0` (`contentOffset.y: 0.0`).

- [ ] **3. Screen 2 — Traversal Hierarchy**
  1. **Row-Major vs. Column-Major**: Swipe right through the first 4 grid items in **Row-Major**, then double-tap **Column-Major** (`"Column-Major, Button, 2 of 2"`) and swipe right through the first 4 grid items again.
     - *Expected*:
       - **Row-Major**: `"Section Header 1, Heading"` → `"Mutating Icon Button, Button"` → `"Target Enableable Button, Dimmed, Button"` → `"Toggle Button B, Button"`.
       - **Column-Major**: `"Section Header 1, Heading"` → `"Mutating Icon Button, Button"` → `"Grid Button Row 2 Column 1, Button"` → `"Grid Button Row 3 Column 1, Button"`.
  2. **Explore by Touch**: Drag 1 finger across the 3×3 grid.
     - *Expected*: Each button highlights directly under your finger without offset hit boxes.
  3. **Stateful buttons**: Double-tap **Mutating Icon Button** and swipe right; then double-tap **Toggle Button B** and swipe left to **Target Enableable Button**.
     - *Expected*: **Mutating Icon Button** announces **`"Selected, Mutating Icon Button, Button"`** and does not lose focus when swiping right; **Target Enableable Button** changes from **`"Dimmed"`** to enabled (**`"Target Enableable Button, Button"`**).
  4. **Expandable section & Rotors**:
     - Double-tap **Expandable Disclosure Section** → announces **`"Collapsed"`** before tap, **`"Expanded"`** after tap, and reveals **`"Hidden detail content revealed when expanded."`**
     - Set Rotor to **Headings** and swipe down → jumps through **`"Section Header 1"`**, **`"Section Header 2"`**, **`"Section Header 3"`**.
     - Swipe through *"Read our Terms of Service and Privacy Policy."* and test the **Links** Rotor → both **`"Terms of Service, Link"`** and **`"Privacy Policy, Link"`** are individually focusable.
  5. **Selection Controls header**: 3-finger swipe up to the bottom, swipe right onto the **Selection Controls** title; set Rotor to **Headings** and swipe down from `Section Header 3`.
     - *Expected*: **`"Selection Controls, Heading"`**, and the Headings rotor stops on it after `Section Header 3`.
  6. **Switch**: Swipe right onto the **Notifications** row, double-tap, double-tap again. *(#121636)*
     - *Expected*: One element announcing **`"Notifications, switch button, off, double tap to toggle setting"`**; after each double-tap speaks only **`"on"`** / **`"off"`** and focus stays on the row (never a separate unlabeled switch).
  7. ⚠️ **Checkbox**: Swipe right onto **Accept Terms**, double-tap, then swipe left and back right to re-focus it. *(#125495-family, #118176)*
     - *Expected (UIKit, nearest idiom)*: **`"Accept Terms, Button"`** → after double-tap **`"Selected, Accept Terms, Button"`**. **Record what Flutter says**; flag if the checked state is missing, stale, or announced for the wrong element.
  8. ⚠️ **Radio group**: Swipe right through `Shipping Speed` → **Standard** → **Express** → **Overnight**; double-tap **Express**; swipe left back to **Standard**. *(#125495 — P0)*
     - *Expected (UIKit, nearest idiom)*: **`"Selected, Standard, Button"`** → `"Express, Button"` → `"Overnight, Button"`; after double-tap **`"Selected, Express, Button"`** and **Standard** no longer says `Selected`. **Record what Flutter says** — the P0 check is that the initially selected **Standard** announces its selected state on first focus, and loses it after **Express** is chosen.
  9. ⚠️ **Dropdown**: Swipe onto the **Country** control *before* opening it, double-tap, swipe to **Mexico**, double-tap, then re-focus the control. *(#175950, #175184, #133742)*
     - *Expected (UIKit)*: **`"Country, Canada, Pop-up button"`** on first focus; menu opens with `"Canada, Selected"` ticked; afterwards **`"Country, Mexico, Pop-up button"`**. **Record what Flutter says** — initial focus must include `Canada` (not empty, not `United States`), and after selection must read `Mexico` (not the last item).

- [ ] **4. Screen 3 — Focus & Keyboard**
  1. **Top text field (before opening keyboard)**: Swipe to the top field (pre-filled with `"A"`) *without* double-tapping it, and check the Rotor.
     - *Expected*: Announces **`"Enter username, A, Text field"`** (reads `"A"` immediately) and includes **`Characters` / `Words` / `Edit`** in the Rotor.
  2. **Edit, Clear button & Dismiss keyboard**: Double-tap the top field to open the keyboard, verify the trailing **`"Clear text, Button"`** (`X`) is focusable, delete `"A"` with the keyboard backspace, then double-tap **`done`** on the keyboard.
     - *Expected*: Deleting `"A"` announces the placeholder **`"Enter username"`**; tapping **`done`** leaves focus on the text field (does **not** jump to the top-left Back button).
  3. **Announcement**: Double-tap **Post Polite Announcement**.
     - *Expected*: Speaks **`"Live Status: Polite Announcement #1"`** completely without being cut off by `"Post Polite Announcement, Button"`.
  4. **Slider (`25%`)**: Swipe to the slider, double-tap once, then swipe **up** and **down** with 1 finger.
     - *Expected*: Announces **`"25%, Adjustable"`** on initial focus (not `"50%"`), double-tapping does not move the thumb, and swiping up/down adjusts by `10%` (`"35%"`, `"25%"`, `"15%"`).
  5. **Password field**: Scroll to the bottom **Password** field, focus it before opening the keyboard, then double-tap and type `"abc"`.
     - *Expected*: Announces **`"Password, Secure text field"`** even when unfocused, and never speaks `"a"`, `"b"`, or `"c"` out loud while typing.
  6. **Limited-length field (`Nickname`, max 20)**: Scroll below Password, focus the **Nickname** field without opening the keyboard, then swipe right once. *(#156368, #54279)*
     - *Expected*: **`"Nickname, Max 20 characters, Text field"`**, and the next swipe lands on a separate **`"0/20"`** static text (the counter is its own element in both apps).
  7. ⚠️ **Counter while typing**: Double-tap **Nickname** and type `"abc"`.
     - *Expected*: Counter shows `3/20`. **Record what each app says** while typing — UIKit speaks only the typed characters (the counter is silent); flag if Flutter interrupts with `"3/20"` after every keystroke or never exposes the new value.

- [ ] **5. Screen 4 — Modal Barrier**
  1. **Popup Menu**: Double-tap **Anchored Popup Menu: Option Alpha**, then swipe left/right and drag 1 finger over `Background Button 1`.
     - *Expected*: Initial focus lands on **`"Selected, Option Alpha, Button"`** (not the top-left corner), and focus stays **trapped inside the popup** (cannot focus **`"Background Button 1"`** while open).
  2. **Alert Dialog**: Double-tap **Present Alert Dialog**, swipe through its buttons, and double-tap **Confirm**.
     - *Expected*: Announces **`"Alert, Benchmark Alert Dialog"`** on open, blocks background buttons, and returns focus to **`"Present Alert Dialog, Button"`** on close.
  3. **Modal Bottom Sheet**: Double-tap **Present Modal Sheet**, swipe through the sheet (including the top drag handle), then dismiss via **2-finger Z-scrub** or tapping the dimmed area above the sheet.
     - *Expected*: Top drag handle and **`"Modal Barrier Active, Heading"`** are focusable, background controls are completely blocked, and dismissing closes the sheet.
  4. **Bottom Tab Bar**: Swipe to the bottom tab bar and double-tap **Details**.
     - *Expected*: Announces **`"Tab Bar, Selected, Overview, Tab, 1 of 3"`** on entry, and **`"Selected, Details, Tab, 2 of 3"`** when tapped without losing focus.
  5. **Disabled menu item**: Double-tap **Anchored Popup Menu: Option Alpha**, swipe right past `Option Gamma` to the last item and double-tap it. *(#171231)*
     - *Expected*: **`"Option Delta (Unavailable), Dimmed, Button"`** — focusable, announced as dimmed, and double-tap does nothing (menu stays open, status unchanged).
  6. **Date picker — selected day**: Double-tap **Present Date Picker**, swipe right into the calendar grid and through the days around `15`, then double-tap `16`. *(#186043, #194657-family)*
     - *Expected*: Opening moves focus into the picker (not left on the button). Days read as plain dates (**`"Wednesday, January 14"`**); the pre-selected day reads **`"Thursday, January 15, Selected"`**; after double-tapping `16` the `Selected` trait moves to **`"Friday, January 16, Selected"`**.
  7. ⚠️ **Date picker — month/year toggle**: Double-tap the month header (UIKit **`"January 2026, Button"`**; Flutter the `January 2026` arrow), swipe right once, double-tap it again to close. *(#186043)*
     - *Expected*: **Record what each app says.** UIKit exposes `"January, Adjustable"` / `"2026, Adjustable"` wheels once open; note whether Flutter announces **`Expanded`/`Collapsed`** on the header and whether the year list is reachable by swipe.
  8. **Date picker — confirm & focus return**: With `16` selected swipe to **Done** (UIKit) / **OK** (Flutter) and double-tap.
     - *Expected*: Status reads **`Date Picker: Jan 16, 2026`** and focus returns to **`"Present Date Picker, Button"`**.
  9. **Time picker — AM/PM**: Double-tap **Present Time Picker**, swipe right through the time controls to the period (AM/PM) control, swipe up once (UIKit) / double-tap **PM** (Flutter), then confirm. *(#173302 — P1)*
     - *Expected*: Hours/minutes read **`"9 o'clock, Adjustable"`** / **`"30 minutes, Adjustable"`**. The period control must announce its **current state on focus** (UIKit **`"AM, Adjustable"`**; Flutter `"AM, Selected"`) and the change (**`"PM"`** / `"PM, Selected"`). Status reads **`Time Picker: 9:30 PM`**, focus returns to **`"Present Time Picker, Button"`**.
  10. ⚠️ **Time picker — Flutter clock dial** (Flutter only): Re-open and swipe through the dial.
     - *Expected*: No native twin exists (UIKit uses wheels). **Record what each dial number says**; every number must be reachable and double-tapping one must update the hour field.

- [ ] **6. Screen 5 — Sliver Scroll**
  1. **Collapsing header & focus return**: Open **Sliver Scroll**, swipe right from the title through `Sliver Item 1`…`Sliver Item 20` so the large title collapses, then **4-finger single-tap near the top** and, separately, swipe left from `Sliver Item 20` all the way back up. *(#143437 — P0, #179687)*
     - *Expected*: On open **`"Sliver Scroll, Heading"`**; rows read `"Sliver Item 1"`, `"Sliver Item 2"`… After the header collapses, 4-finger-tap-top lands on the Back button or **`"Sliver Scroll, Heading"`** (never a row), and swiping left from `Sliver Item 1` still reaches the heading — the collapsed header stays focusable.
  2. ⚠️ **Header resize must not steal focus**: Focus `Sliver Item 3`, then **3-finger swipe up** once so the header animates while a row is focused. *(#179687)*
     - *Expected*: **Record what each app says.** UIKit keeps focus on a row and plays the scroll chime; flag if Flutter focus jumps to the heading because the header resized.
  3. **Reach the bottom sliver**: 3-finger swipe up repeatedly to the end, then swipe right past `Sliver Item 60`. *(#142065 — P1)*
     - *Expected*: **`"Sliver Item 60"`** → **`"End of List, Heading"`** → **`"Footer Action, Button"`** → `"Footer Action taps: 0"` → **`"Compose, Button"`**. Double-tapping Footer Action updates to `taps: 1`.
  4. ⚠️ **Page scroll status**: Focus `Sliver Item 2`, 3-finger swipe up once, then down once.
     - *Expected*: **Record what each app says.** UIKit speaks a native **`"Rows 11 to 22 of 60"`**-style status (row numbers depend on device); note whether Flutter speaks any status at all.
  5. **Floating Compose button**: With `Sliver Item 5` focused, drag one finger over the round bottom-right button, then double-tap. *(#184077 — P1)*
     - *Expected*: Explore-by-touch announces **`"Compose, Button"`** directly under the finger (not the row beneath); double-tap logs `Compose FAB Tapped (Count: 1)` and focus stays on it.

---

## Pass 2: Full Keyboard Access (`FKA`)

**Setup**: Turn **VoiceOver OFF**. Connect a hardware keyboard and turn **Full Keyboard Access ON** (`Settings > Accessibility > Keyboards > Full Keyboard Access`).

- [ ] **1. Back navigation focus retention (`Home Menu`)**: `Tab` to **Focus & Keyboard**, press `Space` to open it, then `Shift + Tab` to the **Back** button and press `Space`.
  - *Expected*: Blue focus ring returns to **Focus & Keyboard** on the Home Menu (does not reset to **Scroll Baseline**).
- [ ] **2. List auto-scroll (`Scroll Baseline`)**: Open **Scroll Baseline** and press `Tab` repeatedly from `Item #0` to `Item #15`.
  - *Expected*: The list automatically scrolls down to keep `Item #11`..`Item #15` and the blue focus ring visible on screen.
- [ ] **3. Form, Slider & Off-screen Password field (`Focus & Keyboard`)**: Open **Focus & Keyboard** and press `Tab` from the top field down to the bottom **Password** field.
  - *Expected*: `Tab` stops on the **Slider** (Left/Right arrows adjust its value), auto-scrolls the off-screen **Password** field into view, and logs each stop in the on-screen **Focus Log**.
- [ ] **4. Modal trapping (`Modal Barrier`)**: Open **Modal Barrier**, `Tab` to **Present Modal Sheet**, press `Space`, and press `Tab` repeatedly.
  - *Expected*: Focus ring stays trapped inside the open sheet (`Modal Sheet Action` and `Dismiss Modal Sheet`).
- [ ] **5. Selection controls (`Traversal Hierarchy`)**: Open **Traversal Hierarchy** and press `Tab` repeatedly past the links paragraph; press `Space` on **Notifications**, **Accept Terms**, **Express**, then on **Country** followed by `Down Arrow` + `Space` on **Mexico**. *(#125495, #175950)*
  - *Expected*: Ring stops in order on **Notifications → Accept Terms → Standard → Express → Overnight → Country** (plain text skipped, each auto-scrolled into view). `Space` flips the switch, checks the box, moves the checkmark from Standard to Express, and opens the country menu, committing **Mexico**. *(If Flutter's `RadioGroup` exposes a single stop with arrow keys inside, record that.)*
- [ ] **6. Limited-length field (`Focus & Keyboard`)**: `Tab` from the **Password** field. *(#156368)*
  - *Expected*: Ring lands on **Nickname**; the `0/20` counter is **never** a Tab stop; typing updates the counter.
- [ ] **7. Picker dismissal & focus return (`Modal Barrier`)**: `Tab` to **Present Date Picker**, `Space`, `Tab` twice inside the picker, then `Esc`. Repeat for **Present Time Picker**. *(#173302)*
  - *Expected*: `Tab` stays inside the picker (the AM/PM control is a Tab stop and `Space`/arrows toggle it). `Esc` dismisses without changing the value, status reads **`Date Picker: Cancelled`** / **`Time Picker: Cancelled`**, and the ring returns to the presenting button.
- [ ] **8. Disabled menu item skipped (`Modal Barrier`)**: `Tab` to **Anchored Popup Menu**, `Space`, then `Down Arrow` repeatedly. *(#171231)*
  - *Expected*: Focus cycles `Option Alpha → Beta → Gamma` and never lands on **Option Delta (Unavailable)**.
- [ ] **9. Floating button & footer (`Sliver Scroll`)**: Open **Sliver Scroll** and `Tab` from the Back button through all 60 rows to the end. *(#184077, #142065, #143437)*
  - *Expected*: **Compose** receives the ring exactly **once** per pass (UIKit: after the list content) and `Tab` continues past it — never trapped, never alternating with a row. The list auto-scrolls, the ring reaches **Footer Action** (`Space` → `taps: 1`), and the collapsed header never steals the ring.

---

## Pass 3: Voice Control

**Setup**: Turn **Full Keyboard Access OFF**. Turn **Voice Control ON** (`Settings > Accessibility > Voice Control`, `Overlay = Item Numbers`).

- [ ] **1. Voice scrolling (`Scroll Baseline`)**: Open **Scroll Baseline** and say **`"Scroll down"`**, then **`"Scroll up"`**.
  - *Expected*: Scrolls down one page and back up one page, updating `contentOffset.y`.
- [ ] **2. Badge alignment & state updates (`Traversal Hierarchy`)**: Open **Traversal Hierarchy**, inspect the number badges on the 3×3 grid, then say **`"Tap <number>"`** for **Mutating Icon Button**.
  - *Expected*: Badges sit directly on each button (none on plain text headers), and remain aligned after **Mutating Icon Button** adds its checkmark icon.
- [ ] **3. Overlays & Tab Bar (`Modal Barrier`)**: Open **Modal Barrier**, say **`"Tap <number>"`** for **Details** in the bottom tab bar, then say **`"Tap Present Alert Dialog"`** followed by **`"Tap Cancel"`** (or **`"Go back"`**).
  - *Expected*: Activates **Details** (`"Selected Tab: Details (2 of 3)"`), shows badges only on `Cancel`/`Confirm` while the alert is open, and dismisses the alert via voice.
- [ ] **4. Selection controls (`Traversal Hierarchy`)**: Scroll to the bottom, say **`"Show numbers"`**, then **`"Tap Express"`**, **`"Tap Notifications"`**, **`"Tap Country"`** → **`"Tap Mexico"`**. *(#175950, #133742)*
  - *Expected*: Exactly one badge each on **Notifications**, **Accept Terms**, **Standard**, **Express**, **Overnight**, **Country** (none on plain text); badges stay aligned after state changes; each command works by name (status logs `Shipping Speed radio -> Express`, `Country dropdown -> Mexico`). If a name isn't recognised in Flutter, say **`"Show names"`** and record what it shows.
- [ ] **5. Counter label must not get a badge (`Focus & Keyboard`)**: Scroll to **Nickname**, say **`"Show numbers"`**, then **`"Tap <number>"`** for the field and **`"Type hello"`**. *(#156368 — P1)*
  - *Expected*: A badge on the **Nickname** field but **no badge on the `0/20` counter** (UIKit never badges a static label). `hello` is inserted and the counter reads `5/20` without badges shifting.
- [ ] **6. Pickers & disabled item (`Modal Barrier`)**: Say **`"Tap Present Date Picker"`**, **`"Show numbers"`**, **`"Tap <number>"`** on day `16`, **`"Tap Done"`** (UIKit) / **`"Tap OK"`** (Flutter). Then **`"Tap Anchored Popup Menu"`**, **`"Show numbers"`**.
  - *Expected*: Every day cell gets its own badge; the date commits (`Date Picker: Jan 16, 2026`); in the popup, `Alpha`/`Beta`/`Gamma` get badges and **Option Delta (Unavailable)** does not.
- [ ] **7. Floating button & footer (`Sliver Scroll`)**: Say **`"Show numbers"`**, **`"Tap Compose"`**, then **`"Scroll to bottom"`**, **`"Tap Footer Action"`**. *(#184077, #142065)*
  - *Expected*: The round button has its own badge sitting on the circle (not offset onto the row beneath); `Tap Compose` logs `Compose FAB Tapped (Count: 1)`; the list scrolls to **End of List** and **Footer Action** activates by name (`taps: 1`).

---

## Pass 4: Display & Motion Settings

**Setup**: Turn **Voice Control OFF**. In `Settings > Accessibility`, enable **Motion > Reduce Motion**, **Display & Text Size > Bold Text**, and set **Larger Text** to `AX3`.

- [ ] **1. Reduce Motion (`Home Menu` & `Modal Barrier`)**: Tap **Modal Barrier** on the Home Menu, then tap **Present Modal Sheet**.
  - *Expected*: Page push and modal sheet presentation use iOS's **cross-fade** animation instead of sliding.
- [ ] **2. Bold & Larger Text (`Home Menu` & `Traversal Hierarchy`)**: Compare both apps side-by-side.
  - *Expected*: Text renders bold and scales up without clipping or overlapping buttons.

---

## Pass 5 (Optional): Switch Control

**Setup**: Turn **Switch Control ON** (`Settings > Accessibility > Switch Control`, `Auto Scanning`, `Item Mode`).

- [ ] **1. Grid scanning (`Traversal Hierarchy`)**: Open **Traversal Hierarchy** and let the scanner cycle through `Row-Major` / `Column-Major` and the 3×3 grid; trigger your switch on **Mutating Icon Button**.
  - *Expected*: Scans and activates the segmented control and grid buttons in order without skipping.
- [ ] **2. Tab Bar & Modal Sheet (`Modal Barrier`)**: Open **Modal Barrier**, let the scanner cycle to the bottom tab bar and select **Settings**, then open **Present Modal Sheet** and let it scan.
  - *Expected*: Reaches and selects **Settings** (`"Selected Tab: Settings (3 of 3)"`), and scans only inside the modal sheet while open.

