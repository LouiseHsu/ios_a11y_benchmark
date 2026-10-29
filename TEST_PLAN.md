# iOS Accessibility QA Procedure (UIKit vs. Flutter)

## How This Test Works
You will test two apps side-by-side on the same iOS version:
1. **`UIKit A11y Benchmark`** (The **Ruler** — always shows the correct native iOS behavior)
2. **`Flutter A11y Benchmark`** (The **App Under Test**)

**Rule**: Perform each step below on **UIKit first**, then immediately perform the exact same step on **Flutter**. If Flutter behaves, speaks, scrolls, or focuses differently than UIKit, log a failure.

> [!TIP]
> **Why this procedure is grouped by Assistive Technology (not by screen)**
> So you only have to turn each iOS Accessibility setting ON and OFF **once** per pass. Complete all steps in Pass 1 (VoiceOver), then move to Pass 2 (Full Keyboard Access), Pass 3 (Voice Control), and Pass 4 (Switch Control).

---

## Pass 1: VoiceOver (~8 mins)

**Setup**: Turn on **VoiceOver** (`Settings > Accessibility > VoiceOver`) and enable **Show Caption Panel** BEFORE opening either app.

### 1.1 Home Menu & Navigation
- [ ] **1. Cold launch**: Launch both apps from a closed state with VoiceOver already on.
  - *Check*: VoiceOver immediately focuses and reads the screen without needing an app restart.
- [ ] **2. Menu row announcement**: Swipe right through the 4 menu rows (`Scroll Baseline`, `Traversal Hierarchy`, `Focus & Keyboard`, `Modal Barrier`).
  - *Check*: Flutter announces the title, subtitle, and role (`"Button"`) identically to UIKit.
- [ ] **3. Route push & Back button**: Double-tap **Scroll Baseline** to open it, then swipe left/right across the top navigation bar.
  - *Check*: Initial focus lands in the same place as UIKit; swiping the Back button focuses it **once** (not twice) and reads the previous page title + `"Back button"`.
- [ ] **4. Escape gesture (2-finger Z-scrub)**: Scrub two fingers in a "Z" shape to go back to the Home Menu.
  - *Check*: The page closes and VoiceOver focus returns to the **Scroll Baseline** row on the Home Menu.

### 1.2 Screen 1 — Scroll Baseline
Open **Scroll Baseline** in both apps.
- [ ] **5. Single-finger swipe past bottom of screen**: Focus `Item #0`, then swipe right repeatedly past the last visible row (`Item #10` → `Item #15`).
  - *Check*: Off-screen rows automatically scroll into view without VoiceOver getting stuck or jumping back to the top header.
- [ ] **6. Three-finger page scroll**: Focus `Item #2`, then **3-finger swipe up** to scroll down one page.
  - *Check*:
    1. VoiceOver plays the scroll sound and announces **`"Page 2 of ..."`**.
    2. Look at the `Δy / viewportHeight` line in the top box: Flutter's scroll percentage matches UIKit (~100%).
- [ ] **7. Three-finger single tap & Scrollbar**: Focus any row and **single-tap with 3 fingers**, then touch the scrollbar on the right edge.
  - *Check*: 3-finger tap announces the visible row range; the right-edge scrollbar is focusable and adjustable.
- [ ] **8. Status bar scroll-to-top**: Scroll down to `Item #30`. Tap the **iOS Status Bar** (top clock/battery area) once to focus it, then **double-tap**.
  - *Check*: The list scrolls all the way back to `Item #0`.

### 1.3 Screen 2 — Traversal Hierarchy
Return to Home Menu and open **Traversal Hierarchy** in both apps.
- [ ] **9. Row-Major vs. Column-Major traversal**:
  1. Leave **Row-Major** selected and swipe right through the 3×3 grid.
  2. Double-tap **Column-Major** at the top, then swipe right through the 3×3 grid again.
  - *Check*: Row-Major reads left-to-right across each row; Column-Major reads top-to-bottom down each column (`R1C1` → `R2C1` → `R3C1`).
- [ ] **10. Stateful button & Custom Actions Rotor**:
  1. Focus `R1C1 (A)` and **double-tap** to select it (adds a checkmark), then swipe right to `R1C2 (B)`.
  2. Focus `R1C1 (A)` again, twist two fingers to set the **Rotor to Actions**, swipe down, and double-tap an action.
  - *Check*: Toggling `R1C1 (A)` announces `"Selected"` and does not trap focus; custom Rotor actions execute and update the bottom status text.
- [ ] **11. Headings & Links Rotors**:
  1. Twist the Rotor to **Headings** and swipe down through the 3 section headers.
  2. Swipe down to *"Read our Terms of Service and Privacy Policy"*, then also test the **Links** Rotor.
  - *Check*: All 3 headers are reachable via the Headings Rotor; **both** links (`Terms of Service` and `Privacy Policy`) can be focused individually and via the Links Rotor.
- [ ] **12. Expandable section**: Focus **Expandable Disclosure Section** and double-tap it.
  - *Check*: Announces **`"Collapsed"`** before tapping and **`"Expanded"`** after tapping, and reveals the hidden detail text to VoiceOver.

### 1.4 Screen 3 — Focus & Keyboard
Return to Home Menu and open **Focus & Keyboard** in both apps.
- [ ] **13. Pre-filled text field (before opening keyboard)**: Swipe to the top text field (pre-filled with `"A"`) **without** double-tapping it. Twist the Rotor to check available options.
  - *Check*: VoiceOver reads the current value `"A"` and placeholder `"Enter username"` immediately, and `Characters` / `Words` / `Edit` appear in the Rotor before the keyboard is open.
- [ ] **14. Editing, Clear button & Keyboard dismiss**:
  1. Double-tap the top text field to open the keyboard.
  2. Swipe right to verify the **`Clear text` (`X`)** button is focusable, then delete `"A"` using the keyboard backspace key.
  3. Tap **`done`** on the keyboard.
  - *Check*: Deleting the last character announces the placeholder; dismissing the keyboard leaves VoiceOver focus on the text field (does **not** jump back to the top-left Back button).
- [ ] **15. Polite announcement**: Focus **Post Polite Announcement** and double-tap it.
  - *Check*: VoiceOver finishes speaking `"Live Status: Polite Announcement #1"` without getting cut off by the button's own label.
- [ ] **16. Slider**: Swipe to the slider (set at `25%`), double-tap it once, then swipe **up** and **down** with one finger.
  - *Check*: Initial focus announces **`"25%"`** (not `"50%"`), double-tapping does not move the thumb, and swiping up/down adjusts the percentage smoothly.
- [ ] **17. Password field**: Scroll to the bottom **Password** field, focus it before opening the keyboard, then double-tap and type `"abc"`.
  - *Check*: Announces **`"Secure text field"`** both before and after focus, and never speaks the typed letters `"a"`, `"b"`, `"c"` out loud.

### 1.5 Screen 4 — Modal Barrier
Return to Home Menu and open **Modal Barrier** in both apps.
- [ ] **18. Popup Menu**: Double-tap **Anchored Popup Menu** (`Option Alpha`), then swipe left and right repeatedly.
  - *Check*: Focus lands directly on `Option Alpha` (not the top-left corner), and swiping stays **trapped inside the popup menu** (cannot focus `Background Button 1/2` while open).
- [ ] **19. Alert Dialog**: Double-tap **Present Alert Dialog**, swipe through its buttons, and double-tap **Confirm**.
  - *Check*: Announces `"Alert"` + title/body when opened, blocks background buttons, and returns focus to **Present Alert Dialog** when closed.
- [ ] **20. Modal Bottom Sheet**: Double-tap **Present Modal Sheet**, swipe through all items inside the sheet (including the top drag handle), then dismiss by tapping outside the sheet or 2-finger Z-scrubbing.
  - *Check*: Top drag handle is focusable, background buttons are completely hidden while the sheet is open, and tapping outside or Z-scrubbing closes the sheet.
- [ ] **21. Bottom Tab Bar**: Swipe to the bottom tab bar (`Overview`, `Details`, `Settings`) and double-tap **Details**.
  - *Check*: Announces **`"Tab Bar"`** and `"Details, Tab, 2 of 3"`, and keeps VoiceOver focus on the **Details** tab after selection.

---

## Pass 2: Full Keyboard Access (`FKA`) (~4 mins)

**Setup**: Turn **VoiceOver OFF**. Connect a hardware keyboard (or enable Simulator hardware keyboard) and turn **Full Keyboard Access ON** (`Settings > Accessibility > Keyboards > Full Keyboard Access`).

- [ ] **1. Menu & Back focus retention (Home Menu)**:
  1. Press `Tab` until the focus ring highlights **Focus & Keyboard**, then press `Space` to open it.
  2. Press `Shift + Tab` to highlight the **Back** button and press `Space` to return to the Home Menu.
  - *Check*: The blue focus ring returns to the **Focus & Keyboard** row (does not reset to the first row).
- [ ] **2. List auto-scroll (`Scroll Baseline`)**:
  1. Open **Scroll Baseline** and press `Tab` repeatedly from `Item #0` past `Item #15`.
  - *Check*: When the focus ring reaches the bottom of the screen, the list automatically scrolls down to keep the focused row visible.
- [ ] **3. Grid & Expandable section (`Traversal Hierarchy`)**:
  1. Open **Traversal Hierarchy** and press `Tab` through the segmented control, the 3×3 grid, and **Expandable Disclosure Section**.
  2. Press `Space` on **Expandable Disclosure Section**, then press `Tab` again.
  - *Check*: Every interactive control shows a clear focus ring; expanding the disclosure section reveals its content cleanly.
- [ ] **4. Form, Slider & Off-screen Password field (`Focus & Keyboard`)**:
  1. Open **Focus & Keyboard** and press `Tab` from the top text field down to the **Slider**.
  2. Use the **Left / Right Arrow keys** to change the slider value.
  3. Keep pressing `Tab` to reach the off-screen **Password** field at the bottom, and check the on-screen **Focus Log**.
  - *Check*:
    1. `Tab` stops on the **Slider** (does not skip it) and arrow keys adjust its value.
    2. Pressing `Tab` past the slider automatically scrolls the bottom **Password** field into view.
    3. The on-screen Focus Log records focus updates for each stop.
- [ ] **5. Modal trapping (`Modal Barrier`)**:
  1. Open **Modal Barrier**, `Tab` to **Present Modal Sheet**, and press `Space`.
  2. Press `Tab` repeatedly inside the open sheet.
  - *Check*: The keyboard focus ring stays trapped inside the modal sheet and never visits `Background Button 1/2` behind it.

---

## Pass 3: Voice Control (~3 mins)

**Setup**: Turn **Full Keyboard Access OFF**. Turn **Voice Control ON** (`Settings > Accessibility > Voice Control`) and set **`Overlay = Item Numbers`**.

- [ ] **1. Voice scrolling (`Scroll Baseline`)**:
  1. Open **Scroll Baseline** and say **`"Scroll down"`**, then **`"Scroll up"`**.
  - *Check*: The list scrolls down a page and back up a page just like UIKit.
- [ ] **2. Number badge alignment & state updates (`Traversal Hierarchy`)**:
  1. Open **Traversal Hierarchy** and visually compare the number badges on the 3×3 grid buttons (`R1C1 (A)` through `R3C3 (I)`).
  2. Say **`"Tap <number>"`** for `R1C1 (A)` so it toggles its checkmark icon, and check the badges again.
  - *Check*:
    1. Number badges sit directly on top of each button (not shifted/offset, and no badges on plain text labels).
    2. After `R1C1 (A)` updates its icon, its badge remains properly aligned and responsive.
- [ ] **3. Overlays & Bottom Tab Bar (`Modal Barrier`)**:
  1. Open **Modal Barrier** and verify number badges appear on the bottom tabs (`Overview`, `Details`, `Settings`). Say **`"Tap <number>"`** to select `Details`.
  2. Say **`"Tap Present Alert Dialog"`**, then say **`"Tap Cancel"`** (or **`"Go back"`**).
  - *Check*:
    1. Voice Control can activate all 3 bottom tabs.
    2. While the Alert Dialog is open, number badges only appear on the dialog buttons (not on background buttons), and voice commands can dismiss the dialog.

---

## Pass 4: Switch Control (~3 mins)

**Setup**: Turn **Voice Control OFF**. Turn **Switch Control ON** (`Settings > Accessibility > Switch Control`, `Scanning Style = Auto Scanning`, `Switch Control Mode = Item Mode`).

- [ ] **1. Grid & Segmented Control scanning (`Traversal Hierarchy`)**:
  1. Open **Traversal Hierarchy** and let the auto-scanner cycle through the top segmented control (`Row-Major` / `Column-Major`) and the 3×3 grid.
  2. Trigger your switch on `R1C1 (A)` to toggle it.
  - *Check*: The scanner highlights and activates the segmented control and grid buttons in order without skipping or getting stuck.
- [ ] **2. Bottom Tab Bar & Modal Sheet scanning (`Modal Barrier`)**:
  1. Open **Modal Barrier** and let the scanner cycle down to the bottom tab bar (`Overview`, `Details`, `Settings`). Select **Settings**.
  2. Trigger **Present Modal Sheet**, and let the scanner cycle through the open sheet.
  - *Check*:
    1. Switch Control can reach and select the bottom tab bar items (does not skip the tab bar).
    2. While the modal sheet is open, the scanner only cycles through elements inside the sheet (never scans background buttons).
