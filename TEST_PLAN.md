# iOS Accessibility QA Procedure (UIKit vs. Flutter)

## How This Test Works
You will test two apps side-by-side on the same iOS version:
1. **`UIKit A11y Benchmark`** (The **Ruler** — always shows the correct native iOS behavior)
2. **`Flutter A11y Benchmark`** (The **App Under Test**)

**Rule**: Perform each step below on **UIKit first**, then immediately perform the exact same step on **Flutter**. If Flutter behaves, speaks, scrolls, or focuses differently than UIKit, log a failure.

> [!TIP]
> **Why this procedure is grouped by Assistive Technology (not by screen)**
> So you only have to turn each iOS Accessibility setting ON and OFF **once** per pass. Complete all steps in Pass 1 (VoiceOver), then move to Pass 2 (Full Keyboard Access), Pass 3 (Voice Control), Pass 4 (Switch Control), and Pass 5 (Display & Motion).

---

## Pass 1: VoiceOver (~10 mins)

**Setup**: Turn on **VoiceOver** (`Settings > Accessibility > VoiceOver`) and enable **Show Caption Panel** BEFORE opening either app.

### 1.1 Home Menu & Navigation
- [ ] **1. Cold launch**: Launch both apps from a closed state with VoiceOver already on.
  - *Expected*: VoiceOver immediately focuses `"Flutter A11y Benchmark, Heading"` (UIKit: `"UIKit A11y Benchmark, Heading"`) without needing an app restart.
- [ ] **2. Menu row announcement**: Swipe right to the first row (**Scroll Baseline**).
  - *Expected*: Announces **`"Scroll Baseline, 100-cell list with Δy/viewportHeight ratio & page scroll status, Button"`** (must include **`"Button"`** at the end, matching UIKit).
- [ ] **3. Route push & Back button**: Double-tap **Scroll Baseline** to open it, then swipe left to the top-left Back button.
  - *Expected*:
    1. Immediately after opening **Scroll Baseline**, initial VoiceOver focus lands on **`"contentOffset.y: 0.0, 0.0"`** (not on the Back button).
    2. Swiping left to the Back button focuses it **once** (not twice) and announces **`"Flutter A11y Benchmark, Back button"`** (UIKit: `"UIKit A11y Benchmark, Back button"`).
- [ ] **4. Escape gesture (2-finger Z-scrub)**: Scrub two fingers in a "Z" shape to pop back to the Home Menu.
  - *Expected*: Returns to the Home Menu with VoiceOver focus restored on **`"Scroll Baseline, 100-cell list with Δy/viewportHeight ratio & page scroll status, Button"`**.

### 1.2 Screen 1 — Scroll Baseline
Open **Scroll Baseline** in both apps.
- [ ] **5. Single-finger swipe past bottom of screen**: Focus `Item #0` (**`"Item #0, Baseline scroll row 1 of 100"`**), then swipe right repeatedly past the last visible row (`Item #10` → `Item #15`).
  - *Expected*: Off-screen rows automatically scroll into view (`"Item #11, Baseline scroll row 12 of 100"`, etc.) without VoiceOver getting stuck at the bottom edge or jumping back to `"contentOffset.y..."`.
- [ ] **6. Two-finger swipe down ("Read All" continuous reading)**: Focus `Item #0`, then **swipe down with 2 fingers** and let VoiceOver read continuously past `Item #12`.
  - *Expected*: VoiceOver reads row after row continuously and automatically scrolls the list down when reaching the bottom of the visible screen (does not stop reading at the last visible row).
- [ ] **7. Three-finger page scroll**: Focus `Item #2`, then **3-finger swipe up** to scroll down one page.
  - *Expected*:
    1. VoiceOver plays the native scroll chime and announces **`"Page 2 of 11"`** (or matching total page count shown in `Page Scroll Status`).
    2. In the top metrics header, `Δy / viewportHeight` reads **`~1.000 (100.0%)`** (not `0.800 (80.0%)`).
- [ ] **8. Three-finger single tap & Scrollbar**: Focus `Item #3` and **single-tap with 3 fingers**, then touch the vertical scrollbar along the right edge of the list.
  - *Expected*:
    1. 3-finger single tap announces the visible row range (e.g. **`"Rows 1 to 10 of 100"`**).
    2. Touching the right edge focuses **`"Vertical scroll bar, 11 pages, 0%, Adjustable"`**.
- [ ] **9. Status bar double-tap (scroll-to-top)**: Scroll down to `Item #30`. Tap the **iOS Status Bar** (top clock/battery area) once to focus it, then **double-tap**.
  - *Expected*: The list scrolls smoothly back to `Item #0` and `contentOffset.y` resets to **`0.0`**.

### 1.3 Screen 2 — Traversal Hierarchy
Return to Home Menu and open **Traversal Hierarchy** in both apps.
- [ ] **10. Row-Major vs. Column-Major traversal**:
  1. Leave **Row-Major** selected (`"Row-Major, Selected, Button, 1 of 2"`) and swipe right through the 3×3 grid.
  2. Double-tap **Column-Major** (`"Column-Major, Button, 2 of 2"`), then swipe right through the 3×3 grid again.
  - *Expected*:
    - **Row-Major order**: `"Section Header 1, Heading"` → `"Mutating Icon Button, Button"` → `"Target Enableable Button, Dimmed, Button"` → `"Toggle Button B, Button"` → `"Section Header 2, Heading"` → `"Grid Button Row 2 Column 1, Button"` → `"Grid Button Row 2 Column 2, Button"` → `"Grid Button Row 2 Column 3, Button"` → `"Section Header 3, Heading"` → `"Grid Button Row 3 Column 1, Button"` → `"Grid Button Row 3 Column 2, Button"` → `"Grid Button Row 3 Column 3, Button"`.
    - **Column-Major order**: `"Section Header 1, Heading"` → `"Mutating Icon Button, Button"` → `"Grid Button Row 2 Column 1, Button"` → `"Grid Button Row 3 Column 1, Button"` → `"Section Header 2, Heading"` → `"Target Enableable Button, Dimmed, Button"` → `"Grid Button Row 2 Column 2, Button"` → `"Grid Button Row 3 Column 2, Button"` → `"Section Header 3, Heading"` → `"Toggle Button B, Button"` → `"Grid Button Row 2 Column 3, Button"` → `"Grid Button Row 3 Column 3, Button"`.
- [ ] **11. Explore by Touch (dragging 1 finger across the grid)**: Drag one finger slowly from top to bottom and left to right across the 3×3 grid.
  - *Expected*: Each header and button highlights and speaks immediately under your finger without offset hit boxes or dead zones.
- [ ] **12. Stateful buttons (`Mutating Icon Button` & `Toggle Button B`)**:
  1. Focus **Mutating Icon Button** and **double-tap** to select it, then swipe right.
  2. Swipe to **Toggle Button B** and **double-tap** it, then swipe left back to **Target Enableable Button**.
  - *Expected*:
    1. Toggling **Mutating Icon Button** announces **`"Selected, Mutating Icon Button, Button"`**, keeps VoiceOver focus anchored on the button, and lets you swipe right to **Target Enableable Button** without focus jumping away.
    2. After tapping **Toggle Button B**, **Target Enableable Button** changes from **`"Target Enableable Button, Dimmed, Button"`** to **`"Target Enableable Button, Button"`** (enabled).
- [ ] **13. Headings & Links Rotors**:
  1. Twist two fingers to set the **Rotor to Headings**, then swipe down with one finger.
  2. Swipe down to *"Read our Terms of Service and Privacy Policy."*, then twist the **Rotor to Links** and swipe down.
  - *Expected*:
    1. **Headings Rotor** jumps directly through **`"Section Header 1, Heading"`** → **`"Section Header 2, Heading"`** → **`"Section Header 3, Heading"`**.
    2. Both **`"Terms of Service, Link"`** and **`"Privacy Policy, Link"`** can be focused individually by swiping AND both are listed in the **Links Rotor**.
- [ ] **14. Expandable Disclosure Section**: Focus **Expandable Disclosure Section** and double-tap it.
  - *Expected*: Announces **`"Expandable Disclosure Section, Button, Collapsed"`** before tapping, announces **`"Expanded"`** after tapping, and swiping right focuses **`"Hidden detail content revealed when expanded."`**

### 1.4 Screen 3 — Focus & Keyboard
Return to Home Menu and open **Focus & Keyboard** in both apps.
- [ ] **15. Pre-filled text field (before opening keyboard)**: Swipe to the top text field (pre-filled with `"A"`) **without** double-tapping it. Twist the Rotor to check available items.
  - *Expected*:
    1. Announces **`"Enter username, A, Text field"`** (must speak the pre-filled value **`"A"`** even before the keyboard opens).
    2. **`Characters`**, **`Words`**, and **`Edit`** appear in the Rotor before the keyboard is opened.
- [ ] **16. Editing, Clear button & Keyboard dismiss**:
  1. Double-tap the top text field to open the keyboard.
  2. Swipe right to the trailing **`X`** icon inside the text field, then delete `"A"` using the keyboard `delete` key.
  3. Double-tap **`done`** on the bottom-right of the keyboard.
  - *Expected*:
    1. The trailing `X` icon focuses as **`"Clear text, Button"`**.
    2. Deleting `"A"` announces `"A"` and the empty field's placeholder **`"Enter username"`**.
    3. Tapping **`done`** closes the keyboard and leaves VoiceOver focus on the text field (does **not** jump focus back to **`"Flutter A11y Benchmark, Back button"`**).
- [ ] **17. Polite announcement**: Focus **Post Polite Announcement** and double-tap it.
  - *Expected*: VoiceOver speaks **`"Live Status: Polite Announcement #1"`** in full without getting cut off by `"Post Polite Announcement, Button"`.
- [ ] **18. Slider (`25%`)**: Swipe to the slider, double-tap it once without swiping, then swipe **up** and **down** with one finger.
  - *Expected*:
    1. Initial focus announces **`"25%, Adjustable"`** (never `"50%"`).
    2. Double-tapping the slider does **not** jump the value to `50%`.
    3. Swiping up/down adjusts the slider in `10%` steps (`"35%"`, `"25%"`, `"15%"`).
- [ ] **19. Password field (`obscureText`)**: Scroll to the bottom **Password** field, focus it before opening the keyboard, then double-tap and type `"abc"`.
  - *Expected*:
    1. Announces **`"Password, Secure text field"`** both before and after keyboard focus.
    2. Typing `"a"`, `"b"`, `"c"` echoes bullets/clicks—VoiceOver **never** speaks `"a"`, `"b"`, or `"c"` out loud.

### 1.5 Screen 4 — Modal Barrier
Return to Home Menu and open **Modal Barrier** in both apps.
- [ ] **20. 4-Finger tap at top/bottom & `Containers` Rotor**:
  1. Tap near the **bottom** of the screen with **4 fingers**, then tap near the **top** of the screen with **4 fingers**.
  2. Twist the **Rotor to Containers** and swipe down with one finger.
  - *Expected*:
    1. 4-finger bottom tap jumps VoiceOver to **`"Settings, Tab, 3 of 3"`**; 4-finger top tap jumps to **`"Flutter A11y Benchmark, Back button"`**.
    2. **Containers Rotor** jumps cleanly from the Navigation Bar → Main Content → Bottom **`"Tab Bar"`**.
- [ ] **21. Anchored Popup Menu**: Double-tap **Anchored Popup Menu: Option Alpha**, then swipe left/right and also drag 1 finger (**Explore by Touch**) over `Background Button 1`.
  - *Expected*:
    1. Initial focus lands on **`"Selected, Option Alpha, Button"`** (not the top-left corner of the screen).
    2. Swiping left/right and dragging 1 finger stays **trapped inside the popup menu** (`Option Alpha`, `Option Beta`, `Option Gamma`)—VoiceOver cannot focus **`"Background Button 1"`** or **`"Background Button 2"`** while the popup is open.
- [ ] **22. Alert Dialog**: Double-tap **Present Alert Dialog**, swipe through its contents, and double-tap **Confirm**.
  - *Expected*: Announces **`"Alert, Benchmark Alert Dialog"`** on open, blocks background controls, and restores VoiceOver focus to **`"Present Alert Dialog, Button"`** when closed.
- [ ] **23. Modal Bottom Sheet**: Double-tap **Present Modal Sheet**, swipe through all items inside the sheet (including the top drag handle), then dismiss by tapping the dimmed background above the sheet or 2-finger Z-scrubbing.
  - *Expected*:
    1. Top drag handle and **`"Modal Barrier Active, Heading"`** are focusable inside the sheet.
    2. Background buttons and the bottom Tab Bar cannot be focused while the sheet is open.
    3. Double-tapping the dimmed barrier outside the sheet or 2-finger Z-scrubbing closes the sheet and updates the status text to **`"Modal Sheet Dismissed"`**.
- [ ] **24. Bottom Tab Bar**: Swipe to the bottom tab bar (`Overview`, `Details`, `Settings`) and double-tap **Details**.
  - *Expected*: Entering the bar announces **`"Tab Bar, Selected, Overview, Tab, 1 of 3"`**; double-tapping **Details** announces **`"Selected, Details, Tab, 2 of 3"`** and keeps VoiceOver focus on **Details**.

---

## Pass 2: Full Keyboard Access (`FKA`) (~4 mins)

**Setup**: Turn **VoiceOver OFF**. Connect a hardware keyboard (or enable Simulator hardware keyboard) and turn **Full Keyboard Access ON** (`Settings > Accessibility > Keyboards > Full Keyboard Access`).

- [ ] **1. Back navigation focus retention (`Home Menu`)**:
  1. Press `Tab` until the blue focus ring highlights **Focus & Keyboard**, then press `Space` to open it.
  2. Press `Shift + Tab` to highlight the top-left **Flutter A11y Benchmark** Back button and press `Space` to pop back.
  - *Expected*: The blue focus ring returns to the **Focus & Keyboard** row on the Home Menu (does not reset to **Scroll Baseline**).
- [ ] **2. List auto-scroll (`Scroll Baseline`)**:
  1. Open **Scroll Baseline** and press `Tab` repeatedly from `Item #0` down to `Item #15`.
  - *Expected*: When the focus ring reaches the bottom visible row, the list automatically scrolls down so `Item #11`..`Item #15` and their blue focus ring stay visible on screen.
- [ ] **3. Grid & Expandable section (`Traversal Hierarchy`)**:
  1. Open **Traversal Hierarchy** and press `Tab` through `Row-Major` / `Column-Major`, the 9 grid buttons, and **Expandable Disclosure Section**.
  2. Press `Space` on **Expandable Disclosure Section**.
  - *Expected*: Every enabled button shows a visible focus ring, disabled **Target Enableable Button** is skipped until enabled by **Toggle Button B**, and pressing `Space` expands **Expandable Disclosure Section**.
- [ ] **4. Form, Slider & Off-screen Password field (`Focus & Keyboard`)**:
  1. Open **Focus & Keyboard** and press `Tab` from the top text field down to the **Slider**.
  2. Press the **Left / Right Arrow keys** to adjust the slider.
  3. Keep pressing `Tab` past the slider to reach the off-screen **Password** field at the bottom, and inspect the on-screen **Responder, VoiceOver & FKA Focus Log**.
  - *Expected*:
    1. `Tab` lands on the **Slider** (does not skip it) and Left/Right arrow keys change `Slider Value: 0.25 (25%)`.
    2. Pressing `Tab` past the slider automatically scrolls the bottom **Password** field into view.
    3. The on-screen Focus Log records focus updates for each control visited.
- [ ] **5. Modal trapping (`Modal Barrier`)**:
  1. Open **Modal Barrier**, `Tab` to **Present Modal Sheet**, and press `Space`.
  2. Press `Tab` repeatedly while the modal sheet is up.
  - *Expected*: The keyboard focus ring stays trapped inside the modal sheet (`Modal Sheet Action` and `Dismiss Modal Sheet`) and never visits `Background Button 1/2`.

---

## Pass 3: Voice Control (~3 mins)

**Setup**: Turn **Full Keyboard Access OFF**. Turn **Voice Control ON** (`Settings > Accessibility > Voice Control`) and set **`Overlay = Item Numbers`**.

- [ ] **1. Voice scrolling (`Scroll Baseline`)**:
  1. Open **Scroll Baseline** and say **`"Scroll down"`**, then **`"Scroll up"`**.
  - *Expected*: The list scrolls down one page and back up one page, updating `contentOffset.y` in the header.
- [ ] **2. Number badge alignment & state updates (`Traversal Hierarchy`)**:
  1. Open **Traversal Hierarchy** and visually inspect the numeric badges on the 3×3 grid buttons (`Mutating Icon Button`, `Toggle Button B`, `R2C1`..`R3C3`).
  2. Say **`"Tap <number>"`** for **Mutating Icon Button** so it adds its checkmark icon, and check the badges again.
  - *Expected*:
    1. Every number badge sits directly on its visual button (not shifted/offset, and no number badges appear on non-interactive headers or status text).
    2. After **Mutating Icon Button** adds its checkmark icon, its badge stays aligned and responsive.
- [ ] **3. Overlays & Bottom Tab Bar (`Modal Barrier`)**:
  1. Open **Modal Barrier** and check that number badges appear on **`Overview`**, **`Details`**, and **`Settings`** in the bottom tab bar. Say **`"Tap <number>"`** for **Details**.
  2. Say **`"Tap Present Alert Dialog"`**, then say **`"Tap Cancel"`** (or **`"Go back"`**).
  - *Expected*:
    1. Voice Control activates **Details** and updates the status label to **`"Selected Tab: Details (2 of 3)"`**.
    2. While the Alert Dialog is open, number badges only appear on **`Cancel`** and **`Confirm`** (not on background buttons), and `"Tap Cancel"` / `"Go back"` dismisses the dialog.

---

## Pass 4: Switch Control (~3 mins)

**Setup**: Turn **Voice Control OFF**. Turn **Switch Control ON** (`Settings > Accessibility > Switch Control`, `Scanning Style = Auto Scanning`, `Switch Control Mode = Item Mode`).

- [ ] **1. Grid & Segmented Control scanning (`Traversal Hierarchy`)**:
  1. Open **Traversal Hierarchy** and let the auto-scanner cycle through `Row-Major` / `Column-Major` and the 3×3 grid.
  2. Trigger your switch on **Mutating Icon Button** to toggle it.
  - *Expected*: The scanner highlights and activates the segmented control and grid buttons in order without skipping or getting stuck.
- [ ] **2. Bottom Tab Bar & Modal Sheet scanning (`Modal Barrier`)**:
  1. Open **Modal Barrier** and let the scanner cycle down to the bottom tab bar (`Overview`, `Details`, `Settings`). Select **Settings**.
  2. Trigger **Present Modal Sheet**, and let the scanner cycle through the open sheet.
  - *Expected*:
    1. Switch Control reaches and activates **Settings** in the bottom tab bar (updating the status label to **`"Selected Tab: Settings (3 of 3)"`**).
    2. While the modal sheet is open, the scanner only cycles through elements inside the sheet (`Modal Sheet Action` and `Dismiss Modal Sheet`).

---

## Pass 5: iOS Display & Motion Settings (~2 mins)

**Setup**: Turn **Switch Control OFF**. Open `Settings > Accessibility`:
1. Under **Motion**, turn **Reduce Motion ON**.
2. Under **Display & Text Size**, turn **Bold Text ON** and set **Larger Text** (`Larger Accessibility Sizes = ON`) to the middle accessibility size (`AX3`).

- [ ] **1. Reduce Motion transitions (`Home Menu` & `Modal Barrier`)**:
  1. Tap **Modal Barrier** on the Home Menu to push the page, then tap **Present Modal Sheet**.
  - *Expected*: Both the page push and the modal sheet presentation use iOS's **Reduce Motion cross-fade** instead of sliding horizontally/vertically, matching UIKit.
- [ ] **2. Bold Text & Larger Text scaling (`Home Menu` & `Traversal Hierarchy`)**:
  1. Compare the Home Menu rows and **Traversal Hierarchy** labels between UIKit and Flutter.
  - *Expected*: All text renders in bold weight and scales up cleanly without overlapping or clipping interactive buttons.
