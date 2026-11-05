# ios_a11y_benchmark

Two apps with identical screens — one stock **UIKit**, one pure **Cupertino Flutter** — for comparing how VoiceOver, Voice Control, Full Keyboard Access and Switch Control behave on each. The UIKit app is the reference; the Flutter app is under test. Neither contains custom accessibility code beyond what a developer must write (headings, live regions, a label on an icon-only button).

Each screen exercises one part of the Flutter iOS embedder's translation of semantics into `UIAccessibility`:

| Screen | Exercises |
|---|---|
| Scroll Baseline | implicit scrolling, 3-finger page scroll, status-bar tap, a nested horizontal list |
| Sliver Scroll | collapsing large title, content after the last row, a button floating over the list |
| Traversal Hierarchy | traits and states (button, header, link, image, selected, disabled, toggle, check, radio, expanded, hidden, hint, attributed labels, custom actions), traversal order |
| Focus & Keyboard | text fields, keyboard show/hide, slider, live region, announcements |
| Modal Barrier | popup menu, alert, action sheet, modal sheet, tab bar — focus trapping and return |

## Build

- `flutter_a11y_benchmark/` — `flutter run --release` (release so the app survives being backgrounded while switching apps).
- `uikit_a11y_benchmark/` — open `uikit_a11y_benchmark.xcodeproj` in Xcode and run.

Install both on the same device, run one assistive technology at a time, do each step in UIKit first and Flutter second, and record anything that differs.

*Test script and findings log: coming soon.*
