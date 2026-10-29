# iOS Accessibility QA Procedure (UIKit vs. Flutter)

## The idea

Two apps, same screens, same controls, side by side on the same iOS version:

1. **`UIKit A11y Benchmark`** — the **Ruler**. Stock UIKit, no custom accessibility code. Whatever it does is, by definition, correct.
2. **`Flutter A11y Benchmark`** — the **App Under Test**.

**You are not checking Flutter against a spec. You are checking Flutter against the other phone.** There is no list of expected strings to memorise: do each step on UIKit, do it again on Flutter, and write down anything that is different — order, label, trait ("Button", "Heading", "Adjustable"…), value, hint, where focus lands, what gets announced, how far it scrolls.

Record every observation as one of:

| Result | Meaning |
|---|---|
| **Match** | Flutter did the same thing as UIKit. |
| **Diff** | It didn't. Write down *exactly* what each app said or did. |
| **Intentional** | It differs, but the difference is a deliberate Flutter design choice (see the ⚠️ notes). Record it; don't file. |

If you only have one device, use the **Appendix: UIKit reference transcript** instead of the second phone, and build Flutter in release mode (`flutter build ios --release`) so it survives backgrounding.

---

## The sweep

The same procedure is applied to every screen. Do all of Pass 1 on every screen, then Pass 2 on every screen, etc.

### Pass 1 — VoiceOver

**Setup:** `Settings > Accessibility > VoiceOver` **on**, and turn on **Show Caption Panel** so you can read what was spoken.

For each screen:

1. **Open it.** Note what receives initial focus.
2. **Linear sweep.** Swipe right from the first element to the very last (keep going until VoiceOver bonks). For every element, compare: *order · label · trait · value · hint · whether it is one element or several*. This one step is most of the test.
3. **Activate everything.** Double-tap every actionable element once (buttons, switches, rows, tabs, links, menu items). Compare what is announced and **where focus is afterwards**. For adjustable elements (sliders, pickers) swipe up/down once each.
4. **Explore by touch.** Drag one finger slowly across the screen. The element under your finger must be the same on both phones, with no offset.
5. **Rotors.** Set the rotor to **Headings**, then **Links**, then **Form Controls**, then **Adjustable**; swipe down through each. The lists must match.
6. **Scroll gestures** (screens with a list): 3-finger swipe up/down — compare the chime, the spoken page status, and how far it moved. Tap the status bar once then double-tap — compare scroll-to-top.
7. **Modals** (anything that opens on top): while it is open, try to reach a background control by swiping *and* by touch. Dismiss with **2-finger Z-scrub**. Compare where focus lands after dismissal.
8. **Leave.** Swipe left to the Back button and double-tap, or Z-scrub. Compare where focus lands on the previous screen.

### Pass 2 — Full Keyboard Access

**Setup:** VoiceOver **off**. Hardware keyboard connected. `Settings > Accessibility > Keyboards > Full Keyboard Access` **on**.

For each screen:

1. **Tab from top to bottom**, then **Shift+Tab back**. Write down the list of stops (count and order). Off-screen stops must auto-scroll into view.
2. **Operate every stop:** `Space` on buttons/switches/rows, `←`/`→` on sliders and segmented controls, `↑`/`↓` inside menus and pickers, `Return` to commit.
3. **Modals:** `Tab` must stay inside while open; `Esc` must dismiss and return the ring to the control that opened it.
4. **Back:** `Shift+Tab` to Back, `Space`. Compare where the ring lands on the previous screen.

### Pass 3 — Voice Control

**Setup:** FKA **off**. `Settings > Accessibility > Voice Control` **on**, `Overlay = Item Numbers`.

For each screen:

1. **"Show numbers."** Compare the badge *count* and *placement* — every actionable element gets exactly one badge sitting on it; plain text gets none. Change some state (toggle a switch, select a tab) and check badges stay aligned.
2. **"Show names."** Compare the name list.
3. **"Tap \<name\>"** for every name on the screen. Each must activate the right thing.
4. **Lists:** "Scroll down", "Scroll up", "Scroll to bottom", "Scroll to top".
5. **Modals:** while open, "Show numbers" must badge only the modal; "Go back" / "Tap Cancel" must dismiss.

### Pass 4 — Display & Motion (quick visual pass)

**Setup:** Voice Control **off**. `Settings > Accessibility`: **Reduce Motion on**, **Bold Text on**, **Larger Text = AX3**.

Open every screen and every modal on both phones. Compare: transition style (cross-fade vs slide), text weight, and that nothing clips or overlaps at AX3.

### Pass 5 (optional) — Switch Control

**Setup:** `Settings > Accessibility > Switch Control` **on**, `Auto Scanning`, `Item Mode`.

Let the scanner run across each screen; compare the scan order to the Pass 2 Tab order, and trigger one control per screen.

---

## The screens

What is on each screen, so you know when "everything" is done. Identifiers are the same in both apps (visible in Xcode's Accessibility Inspector).

### 1. Home Menu
Title (heading) · 5 menu rows (each should be one element ending in "Button") · pushes a screen on tap.

### 2. Scroll Baseline
Pinned header with scroll metrics (`contentOffset.y`, `Δy / viewportHeight`, `Page Scroll Status`) · 100-row list (`Item #0`…`Item #99`, each row one element).
*Use steps 6 (scroll gestures) heavily here.*

### 3. Traversal Hierarchy
Row-Major / Column-Major segmented control · three **Section Header** headings, each with a row of three buttons (nine total; one toggles a selected state and changes its icon, one is **disabled until another enables it**) · **Expandable Disclosure Section** (expanded/collapsed) · paragraph with two inline **links** · **Selection Controls** heading · **Notifications** switch · **Accept Terms** checkbox ⚠️ · **Shipping Speed** radio group (Standard / Express / Overnight) ⚠️ · **Country** dropdown ⚠️ · a status label that logs every interaction.
*Use step 5 (rotors) heavily here: Headings, Links, Form Controls.*

### 4. Focus & Keyboard
**Dismiss Keyboard** bar button · pre-filled text field with a clear button · live-region status label · **Post Polite Announcement** button · slider at 25% · focus log · **Password** secure field · **Nickname** field with a `0/20` counter.
*Also: open the keyboard on each field, type, dismiss — compare where focus is at every stage, and whether typed characters / counter updates are spoken.*

### 5. Modal Barrier
Status label · **Background Button 1 / 2** · **Anchored Popup Menu** (three options + one **disabled**) · **Present Alert Dialog** · **Present Date Picker** · **Present Time Picker** · **Present Modal Sheet** (draggable sheet with a heading and two buttons) · 3-tab bottom tab bar.
*Use step 7 (modals) on each of the five things that open. Inside the pickers, sweep the days / wheels / AM-PM as their own mini-screen.* ⚠️ The time picker's clock dial is Flutter-only (UIKit uses wheels).

### 6. Sliver Scroll
Large title that collapses on scroll · 60-row list · **End of List** heading · **Footer Action** button and tap counter · floating **Compose** button over the list.
*Scroll until the title collapses, then check it is still reachable (4-finger tap top, swipe left from row 1). Reach the very end.*

---

## ⚠️ Where Flutter and UIKit are allowed to differ

These controls have **no stock iOS equivalent**; the UIKit app shows the nearest native idiom. Record what each app says — a difference here is data, not automatically a bug.

| Control | UIKit twin | What still must match |
|---|---|---|
| Checkbox | checkmark button (`Button`, `Selected` when checked) | state is announced, updates on toggle, and belongs to the right element |
| Radio group | single-select checkmark rows | the selected item announces it on focus; selection moves correctly |
| Dropdown | pull-down menu button (`Pop-up button`) | the *current* value is announced before and after selection |
| Time picker | wheels (Flutter: dial + AM/PM toggles) | AM/PM announces its state on focus and on change |
| Floating button | floating `UIButton` | reachable, badged once, never traps keyboard focus |
| List rows under FKA | UIKit cells are Tab stops; Flutter plain rows are not | record the stop count; the *interactive* stops must match |

---

## Known hotspots

Places where Flutter has diverged before. Slow down here, but **do not limit yourself to this list** — the sweep is the test; this is just where to look twice.

| Screen | Watch for | Issue |
|---|---|---|
| Home | initial focus on open and on return; Back button focused once, not twice | #124361 |
| Scroll | page-scroll announces a status; scrolls a full page, not 80%; status-bar tap scrolls to top; implicit scrolling past the fold | #189285 #193541 #191565 |
| Traversal | expanded/collapsed announced; both links in the Links rotor; disabled button says "Dimmed"; selected state survives a rebuild | #138891 #175907 #159127 #166750 |
| Traversal › selection controls | switch is one element with state; radio's initial selection; dropdown's initial value; checked state | #121636 #125495 #175950 #175184 #133742 #118176 |
| Focus | pre-filled value read before editing; password never spoken; focus stays put after keyboard dismiss; Tab reaches the slider; off-screen fields auto-scroll | #150260 #190320 #192171 #192159 |
| Focus › Nickname | counter is its own element, never a Tab stop, **never gets a Voice Control badge** | #156368 #54279 |
| Modal | dialog announces "Alert"; focus trapped; focus returns to the opener; disabled menu item "Dimmed"; AM/PM state; selected day | #171231 #173302 #186043 |
| Modal › Voice Control | badges land on the right buttons after state changes | #183821 |
| Sliver | collapsed title reachable; bottom sliver reachable; FAB badged once and not a focus trap; header resize doesn't steal focus | #143437 #142065 #184077 #179687 |

---

## Appendix: UIKit reference transcript (single-device fallback)

If you cannot run the UIKit app alongside, these are the strings it speaks for the fixed parts of each screen. Device-dependent values (page counts, row ranges) are written as `N`.

- **Home:** `"UIKit A11y Benchmark, Heading"` → `"Scroll Baseline, 100-cell table…, Button"` (×5 rows). Back: `"UIKit A11y Benchmark, Back button"`.
- **Scroll Baseline:** rows `"Item #0, Baseline scroll row 1 of 100"`; 3-finger page scroll `"Page 2 of N"`; status-bar double-tap returns to `contentOffset.y: 0.0`.
- **Traversal:** `"Row-Major, Button, 1 of 2"` · `"Section Header 1, Heading"` · `"Mutating Icon Button, Button"` → after tap `"Selected, Mutating Icon Button, Button"` · `"Target Enableable Button, Dimmed, Button"` → `"Target Enableable Button, Button"` once enabled · disclosure `"Collapsed"` / `"Expanded"` · `"Terms of Service, Link"`, `"Privacy Policy, Link"` · `"Selection Controls, Heading"` · `"Notifications, Switch button, Off, Double tap to toggle setting"` · `"Accept Terms, Button"` / `"Selected, Accept Terms, Button"` · `"Selected, Standard, Button"`, `"Express, Button"`, `"Overnight, Button"` · `"Country, Canada, Pop-up button"`.
- **Focus:** `"Enter username, A, Text field"` · `"Clear text, Button"` · `"Live Status: Polite Announcement #1"` · `"25%, Adjustable"` (±10% per swipe) · `"Password, Secure text field"` · `"Nickname, Max 20 characters, Text field"` → `"0/20"`.
- **Modal:** popup opens on `"Selected, Option Alpha, Button"`, last item `"Option Delta (Unavailable), Dimmed, Button"` · `"Alert, Benchmark Alert Dialog"` · date picker `"Thursday, January 15, Selected"`, month header `"January 2026, Button"` · time picker `"9 o'clock, Adjustable"`, `"30 minutes, Adjustable"`, `"AM, Adjustable"` · sheet `"Modal Barrier Active, Heading"` · `"Tab Bar, Selected, Overview, Tab, 1 of 3"`.
- **Sliver:** `"Sliver Scroll, Heading"` · `"Sliver Item 1"`… · page status `"Rows N to M of 60"` · `"End of List, Heading"` · `"Footer Action, Button"` · `"Compose, Button"`.
