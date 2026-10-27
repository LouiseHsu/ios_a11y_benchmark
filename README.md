# ios_a11y_benchmark

Two deliberately identical iOS apps — one in pure UIKit, one in Flutter — that
act as an accessibility "ruler" for comparing VoiceOver, Full Keyboard Access
(FKA) and Voice Control behaviour control-for-control.

| App | Stack | Bundle ID |
| --- | --- | --- |
| [`uikit_a11y_benchmark/`](uikit_a11y_benchmark) | Swift + UIKit, iOS 16+, no dependencies | `com.example.uikit-a11y-benchmark` |
| [`flutter_a11y_benchmark/`](flutter_a11y_benchmark) | Flutter (`package:flutter` + `material_ui`), iOS 16+ | `com.example.flutterA11yBenchmark` |

Both apps expose the same four core screens, the same control structure, and the same
`accessibilityIdentifier`s (Flutter: `SemanticsProperties.identifier`), so the
XCUITests in each project make the same assertions and can be diffed line by line.

## Screens

| Prefix | UIKit | Flutter | Benchmarks |
| --- | --- | --- | --- |
| `menu.*` | `MenuViewController` | `MenuPage` | Root list of destinations |
| `scroll.*` | `ScrollBaselineViewController` | `ScrollBaselinePage` | `contentOffset.y`, viewport height, Δy, `Δy / viewportHeight` (100% native vs. 80% Flutter page scroll), "Page X of Y" |
| `traversal.*` | `TraversalHierarchyViewController` | `TraversalHierarchyPage` | Natural geometric Row-Major (`accessibilityElements = nil` ≈ `sortKey: null`) vs. explicit Column-Major (`accessibilityElements` ≈ `OrdinalSortKey`), `.header` trait, stateful Buttons A/B/C (selected trait + mutating icon, enable/disable) |
| `focus.*` | `FocusKeyboardViewController` | `FocusKeyboardPage` | Pre-filled + placeholder field, 25% slider, secure field; first responder ≈ `FocusNode`, `didUpdateFocus(in:with:)` ≈ `FocusManager` |
| `modal.*` | `ModalBarrierViewController` | `ModalBarrierPage` | `accessibilityViewIsModal` ≈ modal-route `BlockSemantics`, `.medium()/.large()` detents ≈ 50%/100% `DraggableScrollableSheet`, grabber ≈ `showDragHandle` |

## Tests

Each project has an XCUITest bundle with the same three tests:

| Test | Checks |
| --- | --- |
| `testScrollBaselineUpdatesContentOffsetAndDelta` | viewport height > 0; offset, Δy and ratio grow after a swipe |
| `testModalBarrierIsolatesBackgroundButtons` | background buttons hittable → isolated while the sheet is up → back after dismiss |
| `ScreenshotTourUITests.testCaptureEveryScreen` | visits every screen (+ one interaction each) and attaches screenshots |

The Flutter app additionally has widget-level twins in `test/widget_test.dart`.

```sh
# UIKit
cd uikit_a11y_benchmark
xcodebuild test -project uikit_a11y_benchmark.xcodeproj -scheme uikit_a11y_benchmark \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Flutter
cd flutter_a11y_benchmark
flutter pub get && flutter test
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RunnerUITests

# Export the screenshot tour from a result bundle
xcodebuild test ... -only-testing:<bundle>/ScreenshotTourUITests -resultBundlePath tour.xcresult
xcrun xcresulttool export attachments --path tour.xcresult --output-path screenshots/
```

## Instrumentation worth knowing about

* UIKit observes assistive-tech focus globally via
  `UIAccessibility.elementFocusedNotification`; Flutter has no public equivalent,
  so `flutter_a11y_benchmark/lib/a11y/a11y_action_observer.dart` wraps
  `PlatformDispatcher.onSemanticsActionEvent` and logs every semantics action
  the platform sends, resolved to the target node's identifier.
* `flutter_a11y_benchmark/lib/a11y/a11y_probe.dart` documents where a
  `Semantics` annotation has to live for identifiers/sort keys to land on the
  intended node (inside a button's child, `container: true` around leaves,
  `MergeSemantics` for cells).
* All diagnostic logs are prefixed per screen (`[ScrollBaseline]`,
  `[FocusKeyboard]`, `[A11yAction]`, …) in both apps.

Known, intentional platform gaps are listed in
[`flutter_a11y_benchmark/README.md`](flutter_a11y_benchmark/README.md).
