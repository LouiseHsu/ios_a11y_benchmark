# iOS Accessibility QA Script (UIKit vs. Flutter)

## How this works

Two apps with identical screens, side by side on the same iOS version:

- **`UIKit A11y Benchmark`** — stock UIKit. Whatever it does is correct.
- **`Flutter A11y Benchmark`** — the app under test.

Every step below is: **do the same thing on both phones → compare one thing → tick a box.**

- **Same** — both phones did the same thing. Tick and move on.
- **Different** — write down what *each* phone said or did, in the step's row of the [results sheet](https://docs.google.com/spreadsheets/d/1Hs36qt4wQvpky6DhGROSNSlJUOZlG-gJ5IcinnTwq2k/edit#gid=1933865667). Don't decide whether it matters — that's triage's job.

You never need to know what the "right" answer is. The UIKit phone is the answer.

Tips: Always do UIKit first, Flutter immediately after. Turn on **Show Caption Panel** so you can read what VoiceOver said. "Where are you?" means: what does VoiceOver say if you tap once (don't swipe) right now. If you only have one device, build Flutter with `flutter build ios --release` and use the reference transcript at the bottom in place of the UIKit phone.

Step IDs (`T3`, `M7`…) match the rows in the results sheet.

---

## Pass 1 — VoiceOver

**Setup:** `Settings > Accessibility > VoiceOver` **on**. `VoiceOver > Verbosity > Caption Panel` **on**. Launch both apps *after* VoiceOver is on.

### H — Home Menu

- [ ] **H1** Cold-launch the app. ⟶ *Compare:* the first thing spoken.
- [ ] **H2** Swipe right until VoiceOver bonks at the end. ⟶ *Compare:* **how many swipes** (UIKit __ / Flutter __) and whether every row ends with the same trait word.
- [ ] **H3** Double-tap **Scroll Baseline**. ⟶ *Compare:* where are you on the new screen?
- [ ] **H4** Swipe left until you reach the Back button. ⟶ *Compare:* how many swipes, and what the Back button says.
- [ ] **H5** 2-finger Z-scrub (scrub two fingers in a Z). ⟶ *Compare:* where are you on the Home Menu?

### S — Scroll Baseline

- [ ] **S1** Open **Scroll Baseline**. ⟶ *Compare:* first thing spoken.
- [ ] **S2** Swipe right one element at a time from `Item #0` until you pass `Item #15` (past the bottom of the screen). ⟶ *Compare:* does the list scroll itself to keep up, and does any swipe jump somewhere unexpected?
- [ ] **S3** Tap once on `Item #2`. 3-finger swipe **up**. ⟶ *Compare:* what is spoken, and the `Δy / viewportHeight` value in the header.
- [ ] **S4** 3-finger swipe **down**. ⟶ *Compare:* what is spoken, and where are you?
- [ ] **S5** Scroll to around `Item #30`. Tap the status bar (clock) once, then double-tap it. ⟶ *Compare:* does the list return to the top (`contentOffset.y: 0.0`)?

### T — Traversal Hierarchy

- [ ] **T1** Open **Traversal Hierarchy**. ⟶ *Compare:* first thing spoken.
- [ ] **T2** Swipe right from the top until VoiceOver bonks at the bottom. ⟶ *Compare:* **how many elements** (UIKit __ / Flutter __). If the count matches, also compare the *order* and the *trait word* ("Button", "Heading", "Link"…) of each element as you go.
- [ ] **T3** Double-tap **Column-Major**, then swipe right 4 times from `Section Header 1`. ⟶ *Compare:* the four elements you land on, in order.
- [ ] **T4** Drag one finger slowly across the 3×3 grid of buttons. ⟶ *Compare:* does the spoken button match the one under your finger?
- [ ] **T5** Double-tap **Mutating Icon Button**, then swipe right once. ⟶ *Compare:* what is spoken on the tap, and where you land.
- [ ] **T6** Tap once on **Target Enableable Button**. Double-tap **Toggle Button B**. Tap once on **Target Enableable Button** again. ⟶ *Compare:* what it says before and after.
- [ ] **T7** Tap once on **Expandable Disclosure Section**, double-tap it, then swipe right once. ⟶ *Compare:* the state word before/after, and what you land on.
- [ ] **T8** Rotor → **Headings**. Swipe down repeatedly from the top. ⟶ *Compare:* the list of headings.
- [ ] **T9** Rotor → **Links**. Swipe down repeatedly. ⟶ *Compare:* the list of links.
- [ ] **T10** Rotor → **Form Controls**. Swipe down repeatedly. ⟶ *Compare:* the list.
- [ ] **T11** Tap once on **Notifications**, double-tap it, double-tap again. ⟶ *Compare:* what is spoken on focus and after each tap; is it one element or two?
- [ ] **T12** Tap once on **Accept Terms**, double-tap it, swipe left then right to come back. ⟶ *Compare:* what is spoken on focus, on tap, and when you return.
- [ ] **T13** Tap once on **Standard**, then swipe right twice (Express, Overnight). ⟶ *Compare:* what each one says — especially any state word on **Standard**.
- [ ] **T14** Double-tap **Express**, then swipe left back to **Standard**. ⟶ *Compare:* what Express says after the tap, and what Standard says now.

### F — Focus & Keyboard

- [ ] **F1** Open **Focus & Keyboard**. ⟶ *Compare:* first thing spoken.
- [ ] **F2** Swipe right until bonk. ⟶ *Compare:* **element count** (UIKit __ / Flutter __) and trait words.
- [ ] **F3** Tap once on the top text field (don't double-tap). ⟶ *Compare:* what is spoken, including the pre-filled value.
- [ ] **F4** Double-tap the top field. Swipe right once. ⟶ *Compare:* did the keyboard open, and what do you land on (the clear button?).
- [ ] **F5** With the keyboard open, delete the pre-filled text with the keyboard's delete key. ⟶ *Compare:* what is spoken when the field becomes empty.
- [ ] **F6** Double-tap **done** on the keyboard. ⟶ *Compare:* where are you?
- [ ] **F7** Double-tap **Post Polite Announcement**. ⟶ *Compare:* what is spoken, and whether it gets cut off.
- [ ] **F8** Tap once on the slider. Swipe up once, then down twice. ⟶ *Compare:* the value spoken on focus and after each swipe.
- [ ] **F9** Tap once on the **Password** field (don't double-tap). ⟶ *Compare:* what is spoken.
- [ ] **F10** Double-tap **Password** and type `abc`. ⟶ *Compare:* what is spoken while typing.
- [ ] **F11** Rotor → **Form Controls**. Swipe down repeatedly. ⟶ *Compare:* the list.

### M — Modal Barrier

- [ ] **M1** Open **Modal Barrier**. ⟶ *Compare:* first thing spoken.
- [ ] **M2** Swipe right until bonk. ⟶ *Compare:* **element count** (UIKit __ / Flutter __) and trait words, including the tab bar.
- [ ] **M3** Double-tap **Anchored Popup Menu**. ⟶ *Compare:* where are you?
- [ ] **M4** With the menu open, swipe right until bonk, then drag one finger over **Background Button 1**. ⟶ *Compare:* the menu items spoken (including the last one), and whether you can reach Background Button 1.
- [ ] **M5** Double-tap the last menu item. ⟶ *Compare:* what happens.
- [ ] **M6** 2-finger Z-scrub to close the menu. ⟶ *Compare:* where are you?
- [ ] **M7** Double-tap **Present Alert Dialog**. ⟶ *Compare:* what is spoken on open.
- [ ] **M8** Swipe right until bonk, then drag a finger over the background. ⟶ *Compare:* the dialog's elements, and whether background buttons are reachable.
- [ ] **M9** Double-tap **Confirm**. ⟶ *Compare:* where are you, and the status label text.
- [ ] **M10** Double-tap **Present Modal Sheet**. ⟶ *Compare:* where are you?
- [ ] **M11** Swipe right until bonk, then drag a finger over the dimmed area above the sheet and over where the background buttons were. ⟶ *Compare:* the sheet's elements (is the drag handle one of them?), and whether anything behind the sheet is reachable.
- [ ] **M12** 2-finger Z-scrub. ⟶ *Compare:* did the sheet close, and where are you?
- [ ] **M13** Tap once on the bottom tab bar, then double-tap **Details**. ⟶ *Compare:* what is spoken on focus, and on selection.

### V — Sliver Scroll

- [ ] **V1** Open **Sliver Scroll**. ⟶ *Compare:* first thing spoken.
- [ ] **V2** 3-finger swipe up twice (the large title should collapse). 4-finger single-tap near the top of the screen, then swipe right once. ⟶ *Compare:* where the 4-finger tap lands, and what the next element is.
- [ ] **V3** Tap once on `Sliver Item 3`. 3-finger swipe up once. ⟶ *Compare:* what is spoken, and where are you after the scroll?
- [ ] **V4** 3-finger swipe up repeatedly to the very end, then swipe right past `Sliver Item 60` until bonk. ⟶ *Compare:* the elements after the last row, in order.
- [ ] **V5** Double-tap **Footer Action**. ⟶ *Compare:* the counter text, and where are you?
- [ ] **V6** Scroll back up a little. Drag one finger over the round button in the bottom-right corner, then double-tap it. ⟶ *Compare:* what is spoken under your finger, and where you are after the tap.
- [ ] **V7** Swipe left to Back, double-tap. ⟶ *Compare:* where are you on the Home Menu?

---

## Pass 2 — Voice Control

**Setup:** VoiceOver **off**. `Settings > Accessibility > Voice Control` **on**, `Overlay = Item Numbers`. Say every command out loud; the phone does the rest.

For **each** of the six screens:

- [ ] **C1** Open the screen. Say **"Show numbers."** ⟶ *Compare:* **how many badges** (UIKit __ / Flutter __), and what each badge sits on. Any badge on plain text, or any button without one, is a Different.
- [ ] **C2** Say **"Show names."** ⟶ *Compare:* the list of names.
- [ ] **C3** Say **"Tap \<name\>"** for every name on the screen (or **"Tap \<number\>"** if a name isn't recognised — note which). ⟶ *Compare:* does each one activate the right control?
- [ ] **C4** After changing some state (toggle a switch, select a tab, expand the section), say **"Show numbers"** again. ⟶ *Compare:* badges still aligned and the same count?

Plus, on the screens where they apply:

- [ ] **C5** *(Scroll Baseline, Sliver Scroll)* Say **"Scroll down"**, **"Scroll up"**, **"Scroll to bottom"**, **"Scroll to top"**. ⟶ *Compare:* each moves the list the same way.
- [ ] **C6** *(Modal Barrier)* Open each of: popup menu, alert, modal sheet. Say **"Show numbers"** while it is open. ⟶ *Compare:* badges only inside the modal, and the count. Then say **"Go back"** (or **"Tap Cancel"**). ⟶ *Compare:* it closes.
- [ ] **C7** *(Traversal)* Say **"Tap Express"**, **"Tap Notifications"**, **"Tap Accept Terms"**. ⟶ *Compare:* each works and the status label logs it.

---

## Pass 3 — Full Keyboard Access

**Setup:** Voice Control **off**. Hardware keyboard connected. `Settings > Accessibility > Keyboards > Full Keyboard Access` **on**.

For **each** of the six screens:

- [ ] **K1** Open the screen. Press `Tab` until the blue ring wraps back to where it started. ⟶ *Compare:* **how many stops** (UIKit __ / Flutter __) and the order. Off-screen stops should scroll into view.
- [ ] **K2** Press `Space` on every button, switch and row; `←`/`→` on sliders and segmented controls; `↑`/`↓` and `Return` inside menus. ⟶ *Compare:* each does the same thing.
- [ ] **K3** `Shift+Tab` to the Back button, `Space`. ⟶ *Compare:* where the ring lands on the Home Menu.

Plus:

- [ ] **K4** *(Modal Barrier)* For each of popup menu, alert, modal sheet: open it with `Space`, press `Tab` 5 times, then `Esc`. ⟶ *Compare:* the ring stays inside while open; `Esc` closes it; the ring returns to the button that opened it. In the popup menu, also note whether `↓` ever lands on the last (unavailable) item.
- [ ] **K5** *(Focus & Keyboard)* `Tab` from the top field to the bottom. ⟶ *Compare:* is the slider a stop; does the Password field scroll into view.
- [ ] **K6** *(Sliver Scroll)* `Tab` until the ring reaches the round **Compose** button, then keep going to **Footer Action**. ⟶ *Compare:* how many stops it took (UIKit __ / Flutter __), and that Compose is a stop exactly once and never traps the ring.

---

## Pass 4 — Display & Motion (visual, no assistive tech)

**Setup:** FKA **off**. `Settings > Accessibility`: **Reduce Motion on**, **Bold Text on**, **Larger Text = AX3**.

- [ ] **D1** Open every screen and every modal on both phones. ⟶ *Compare:* transition style (cross-fade vs slide), text weight, anything clipped or overlapping.

---

## Pass 5 (optional) — Switch Control

**Setup:** `Settings > Accessibility > Switch Control` **on**, `Auto Scanning`, `Item Mode`.

- [ ] **W1** On **Traversal Hierarchy** and **Modal Barrier**, let the scanner run a full cycle. ⟶ *Compare:* the scan order to the Tab order from K1; trigger one control on each screen.

---

## Appendix — UIKit reference transcript (single-device only)

Only use this if you cannot run the UIKit app alongside. `N` = depends on device size.

- **Home:** `"UIKit A11y Benchmark, Heading"`; rows `"<title>, <subtitle>, Button"`; Back `"UIKit A11y Benchmark, Back button"`.
- **Scroll:** `"Item #0, Baseline scroll row 1 of 100"`; page scroll `"Page 2 of N"`, header `~1.000 (100.0%)`; status-bar tap → `contentOffset.y: 0.0`.
- **Traversal:** `"Row-Major, Button, 1 of 2"` · `"Section Header 1, Heading"` · `"Mutating Icon Button, Button"` → `"Selected, Mutating Icon Button, Button"` · `"Target Enableable Button, Dimmed, Button"` → `"Target Enableable Button, Button"` · disclosure `"Collapsed"`/`"Expanded"` · `"Terms of Service, Link"`, `"Privacy Policy, Link"` · `"Selection Controls, Heading"` · `"Notifications, Switch button, Off, Double tap to toggle setting"` · `"Accept Terms, Button"` → `"Selected, Accept Terms, Button"` · `"Selected, Standard, Button"`, `"Express, Button"`, `"Overnight, Button"`.
- **Focus:** `"Enter username, A, Text field"` · `"Clear text, Button"` · `"Live Status: Polite Announcement #1"` · `"25%, Adjustable"` (±10%) · `"Password, Secure text field"`.
- **Modal:** menu opens on `"Selected, Option Alpha, Button"`, last item `"Option Delta (Unavailable), Dimmed, Button"` · `"Alert, Benchmark Alert Dialog"` · sheet `"Modal Barrier Active, Heading"` · `"Tab Bar, Selected, Overview, Tab, 1 of 3"`.
- **Sliver:** `"Sliver Scroll, Heading"` · `"Sliver Item 1"`… · page status `"Rows N to M of 60"` · `"End of List, Heading"` · `"Footer Action, Button"` · `"Compose, Button"`.

## Appendix — for triage, not for testers

Issues previously filed against these surfaces, by step: H3–H5 #124361 · S2–S5 #189285 #193541 #191565 · T7 #138891 #175907 · T9 #159127 #166750 · T6 #171231-family · T11 #121636 · T12 #121636 (checkbox announced as switch was a documented decision — relitigate if the ruler disagrees) · T13–T14 #125495 (fixed P0; a Different here is a regression) · F3 #150260 · F6 #186178 · F8 #192171 · F10 #190320 · M4–M5, K4 #171231 · C1 (Traversal) #183821 · V2 #143437 #179687 · V4 #142065 · V6, K6 #184077.
