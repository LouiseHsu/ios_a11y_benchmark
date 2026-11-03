# Findings log

Divergences observed while running the twin apps, with repro steps, what each app did, the suspected cause, and status. Newest at the bottom. Keep entries short; the issue tracker is where the detail goes once filed.

Legend — **Owner:** who would fix it. **Status:** `observed` (seen once, not yet re-run) · `confirmed` (re-run, stable) · `filed #N` · `commented #N` · `same` (recorded for the record, no action).

Setup for all entries unless noted: iPhone, iOS 26, both apps release builds, Flutter master (3.50.0-x), `ios_a11y_benchmark` at the commit named in the entry.

---

## F1 · Cupertino back button has no Voice Control badge or name

- **Screen / step:** Traversal Hierarchy · Voice Control `C1`/`C2` ("Show numbers", "Show names").
- **Repro:** Open Traversal Hierarchy. Voice Control on. Say "Show numbers", then "Show names".
- **UIKit:** Back is badge `1`; "Show names" shows `UIKit` (previous title) on it; "Tap Back" works.
- **Flutter:** Back has no badge and no name. A nameless badge appears elsewhere (see F3). "Tap Back" has nothing to resolve to.
- **Cause:** `CupertinoNavigationBarBackButton` (`cupertino/nav_bar.dart`) emits two nodes: `CupertinoButton`'s node (tap action, no label) wrapping `Semantics(container: true, excludeSemantics: true, label: 'Back', button: true)` (label, no action). Voice Control only targets actionable elements → it targets the nameless one. VoiceOver copes by synthesizing a touch, which is why the VoiceOver symptom is only "focuses twice" (#124361, open P2).
- **Owner:** cupertino_ui (framework). Not the embedder.
- **Related:** #124361 (same root cause, VoiceOver symptom), #110790 (Material `BackButton` fixed this years ago).
- **Status:** `observed` → file as new issue, suggest P1 (navigation blocker for Voice Control in every Cupertino app). Commit `6021f1f`.

## F2 · Disabled `CupertinoButton` is not "Dimmed" and stays targetable by Voice Control

- **Screen / step:** Traversal Hierarchy · `T6` (VoiceOver), `C1` (Voice Control).
- **Repro:** "Show numbers" with **Target Enableable Button** still disabled.
- **UIKit:** disabled `UIButton` → no badge; VoiceOver says "…, Dimmed, Button".
- **Flutter:** badge drawn on the disabled button; name offered under "Show names".
- **Cause:** `CupertinoButton.build` emits `Semantics(button: true)` with **no `enabled:`** (compare `ButtonStyleButton`, which passes `enabled: widget.enabled`). With no enabled state in the node, the embedder never applies `UIAccessibilityTraitNotEnabled` (`SemanticsObject.mm` line ~909 only fires on `kFalse`, not `kNone`). Embedder is correct given its input.
- **Owner:** cupertino_ui. One-line fix: `enabled: enabled` in the `Semantics`.
- **Note:** `CupertinoMenuItem` *does* set enabled — the disabled `Option Delta` correctly gets no badge (F5 screenshot).
- **Status:** `observed` → file. Also verify VoiceOver omits "Dimmed" on Flutter (expected). Commit `6021f1f`.

## F3 · Nameless Voice Control badge at the content's top-left corner

- **Screen / step:** Traversal Hierarchy · `C1`.
- **Repro:** "Show numbers". A badge (`12` in the first run) sits at x≈0 just below the nav bar, over nothing. "Tap 12" does nothing. "Show names" shows no name there.
- **UIKit:** no such element.
- **Candidates:** (a) the back button's actionable node (F1) with a collapsed/misplaced frame — embedder `accessibilityFrame`/`accessibilityActivationPoint`; (b) the page's scroll container being exposed as actionable — embedder `accessibilityRespondsToUserInteraction` / `isAccessibilityElement`.
- **To resolve:** VoiceOver on, single-finger tap exactly at the badge position; or Xcode Accessibility Inspector pointed at it. Not reproduced in the second run (badge `12` was the system timer that time) — may depend on scroll offset / fresh open.
- **Owner:** TBD (embedder if either candidate).
- **Status:** `observed`, unresolved.

## F4 · Inline links are individually badged in Flutter, not in UIKit

- **Screen / step:** Traversal Hierarchy · `C1`.
- **UIKit:** `UITextView` links get no Voice Control badges.
- **Flutter:** `Terms of Service` and `Privacy Policy` each get a badge and are tappable by name.
- **Assessment:** Flutter is arguably more accessible here. Record; triage decides whether to treat as intentional divergence.
- **Status:** `same`-ish / `observed`.

## F5 · `CupertinoMenuAnchor` does not block background from Voice Control or move VoiceOver focus into the menu

- **Screen / step:** Modal Barrier · `M3`, `M4`, Voice Control `C6`.
- **Repro:** Open **Anchored Popup Menu**. Say "Show numbers". Also note VoiceOver caption after opening.
- **UIKit:** only the three menu items are badged (plus system). VoiceOver focus moves into the menu (`Anchored Options`).
- **Flutter:** Background Button 1/2, Present Alert/Sheet buttons and all three tabs are badged and activatable while the menu is open. VoiceOver focus stays on the anchor button.
- **Cause:** `RawMenuAnchor` renders through `OverlayPortal` (`raw_menu_anchor.dart` ~869), not a modal route: no barrier, no `BlockSemantics`, no route change → background nodes stay in the tree, no screen-changed notification. Embedder reports what it is given.
- **Owner:** framework (`RawMenuAnchor`; affects Material `MenuAnchor` and `CupertinoMenuAnchor`).
- **Related:** **#171548** (open, P2, customer: google) — filed for screen readers; this shows Voice Control can *activate* background controls, which is worse.
- **Status:** `observed` → comment on #171548 with the Voice Control screenshot and severity note.

## F6 · After a route push, VoiceOver focus goes to Back (Flutter) vs first content element (UIKit)

- **Screen / step:** Home → any screen · `H3`.
- **Repro:** From Home, double-tap a row. Note where focus lands.
- **UIKit:** first element of the new screen's content (e.g. the metrics header on Scroll Baseline).
- **Flutter:** the Back button, every time.
- **Cause:** `accessibility_bridge.mm`: on `routeChanged` the embedder posts `LayoutChanged` with `FindNextFocusableIfNecessary()`; the previously focused node is gone, so `FindFirstFocusable(nil)` falls back to the tree root → first element → Back. Deliberate: **#62873** (2020, P0) was closed WAI ("desired behavior introduced in engine#19826") over central a11y's stated objection. The same root fallback produces **#53022** (focus to Back after keyboard dismiss) and **#156170** (focused node removed → Back).
- **Owner:** embedder (team-ios).
- **Status:** `observed` → open a *revisit* issue linking #62873/#53022/#156170 with the UIKit comparison. Candidate talk example for "make the native rule two-way".

## F7 · 3-finger scroll pins VoiceOver focus to the scrolled-off element, then loses it when the node is recycled

- **Screen / step:** Scroll Baseline · chip strip · `S1b`.
- **Repro:** VoiceOver on. Tap once on **Chip 3**. 3-finger swipe left repeatedly. Watch the VoiceOver cursor.
- **UIKit:** (to confirm with the `UICollectionView` strip, commit `ed3bf95`) expected: status announced, focus lands on the first visible chip.
- **Flutter:** no announcement (#189285). The cursor stays on Chip 3 and travels off-screen ("stuck"). After enough swipes, focus disappears entirely, then resets.
- **Cause (two halves, both `accessibility_bridge.mm`):**
  1. *Pin:* on scroll the embedder posts `PageScrolled` with the previously focused **element** (TODO comment above it), and/or `LayoutChanged` with `NULL` because `next == lastFocused`. Either keeps focus on the now-hidden node. UIKit posts a string and lets VoiceOver pick the first visible element.
  2. *Vanish:* `ListView.builder` disposes the chip past `cacheExtent` → its `SemanticsObject` dies → `AccessibilityObjectDidLoseFocus` sets `last_focused` to **Invalid** (meaning "focus left the app") → next notification carries `nil` → cursor gone.
- **In-flight PRs:** #193384 (announce string — fixes the silence; the `LayoutChanged(NULL)` that follows still pins focus), #193540 (scroll 100% not 80%), #195722 (cache extent 0.8×viewport — delays the vanish, doesn't remove it). Proposed addition to #193384: when `scrolledObject` is set, refocus `FindFirstFocusable` of its first non-hidden child instead of `NULL`; longer term, distinguish "focus left Flutter" from "focused node removed" in `AccessibilityObjectDidLoseFocus`.
- **Owner:** embedder (team-ios).
- **Status:** `observed` on master; re-run with the PR stack applied (focus Chip 3 → swipe → tap once → does it say "Chip 3"?).

---

## Confirmed Same (worth knowing)

- **Hidden row** (`T10c`): not reachable until toggled; both announce it once shown. `isHidden` path OK.
- **Attributed label** (`T10e`): both apps insert a pause/comma between "Order ID:" and the spelled-out "A B C 1 2 3" — native behaviour, not an embedder artifact.
- **Focus callbacks** (`T10f`): `onDidGain/LoseAccessibilityFocus` fire (status label logs gained/lost). Voice Control does *not* badge the row in Flutter (correct: no user action); UIKit badges the custom `UIView` twin — twin artifact, not a Flutter bug.
- **Disabled menu item** (`M4`): neither app badges `Option Delta`.
- **Static trait table:** on the first pass no divergence was found in the flag→trait mapping itself (button/header/link/image/selected). The divergences so far are upstream widgets (F1, F2, F5) or dynamic focus/scroll handling (F6, F7).
