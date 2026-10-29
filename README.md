# iOS Accessibility QA Procedure (UIKit vs. Flutter)

## How This Test Works
You will test two apps side-by-side on the same iOS version:
1. **`UIKit A11y Benchmark`** (The **Ruler** — always shows the correct native iOS behavior)
2. **`Flutter A11y Benchmark`** (The **App Under Test**)

**Rule**: Perform each screen flow below on **UIKit first**, then immediately on **Flutter**. If Flutter behaves, speaks, scrolls, or focuses differently than UIKit, file an issue. If you only have one device, launch the Flutter app in release mode `flutter build ios --release` to prevent the app from dying when backgrounded.

---

## Pass 1: VoiceOver (5 Screens)

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

- [ ] **5. Screen 4 — Modal Barrier**
  1. **Popup Menu**: Double-tap **Anchored Popup Menu: Option Alpha**, then swipe left/right and drag 1 finger over `Background Button 1`.
     - *Expected*: Initial focus lands on **`"Selected, Option Alpha, Button"`** (not the top-left corner), and focus stays **trapped inside the popup** (cannot focus **`"Background Button 1"`** while open).
  2. **Alert Dialog**: Double-tap **Present Alert Dialog**, swipe through its buttons, and double-tap **Confirm**.
     - *Expected*: Announces **`"Alert, Benchmark Alert Dialog"`** on open, blocks background buttons, and returns focus to **`"Present Alert Dialog, Button"`** on close.
  3. **Modal Bottom Sheet**: Double-tap **Present Modal Sheet**, swipe through the sheet (including the top drag handle), then dismiss via **2-finger Z-scrub** or tapping the dimmed area above the sheet.
     - *Expected*: Top drag handle and **`"Modal Barrier Active, Heading"`** are focusable, background controls are completely blocked, and dismissing closes the sheet.
  4. **Bottom Tab Bar**: Swipe to the bottom tab bar and double-tap **Details**.
     - *Expected*: Announces **`"Tab Bar, Selected, Overview, Tab, 1 of 3"`** on entry, and **`"Selected, Details, Tab, 2 of 3"`** when tapped without losing focus.

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

---

## Pass 3: Voice Control

**Setup**: Turn **Full Keyboard Access OFF**. Turn **Voice Control ON** (`Settings > Accessibility > Voice Control`, `Overlay = Item Numbers`).

- [ ] **1. Voice scrolling (`Scroll Baseline`)**: Open **Scroll Baseline** and say **`"Scroll down"`**, then **`"Scroll up"`**.
  - *Expected*: Scrolls down one page and back up one page, updating `contentOffset.y`.
- [ ] **2. Badge alignment & state updates (`Traversal Hierarchy`)**: Open **Traversal Hierarchy**, inspect the number badges on the 3×3 grid, then say **`"Tap <number>"`** for **Mutating Icon Button**.
  - *Expected*: Badges sit directly on each button (none on plain text headers), and remain aligned after **Mutating Icon Button** adds its checkmark icon.
- [ ] **3. Overlays & Tab Bar (`Modal Barrier`)**: Open **Modal Barrier**, say **`"Tap <number>"`** for **Details** in the bottom tab bar, then say **`"Tap Present Alert Dialog"`** followed by **`"Tap Cancel"`** (or **`"Go back"`**).
  - *Expected*: Activates **Details** (`"Selected Tab: Details (2 of 3)"`), shows badges only on `Cancel`/`Confirm` while the alert is open, and dismisses the alert via voice.

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

