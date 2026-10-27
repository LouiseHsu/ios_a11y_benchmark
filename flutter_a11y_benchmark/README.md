# flutter_a11y_benchmark

Flutter twin of [`uikit_a11y_benchmark`](../uikit_a11y_benchmark): the same four
core accessibility "ruler" screens, the same control structure, and the same
`accessibilityIdentifier`s, so iOS VoiceOver, Full Keyboard Access (FKA) and
Voice Control behaviour can be compared control-for-control against pure UIKit.

Only Flutter-team packages are used (`package:flutter` and `material_ui`, the
first-party home of the Material widgets on this SDK).

## Screens

| Identifier prefix | Flutter page | UIKit twin | What it benchmarks |
| --- | --- | --- | --- |
| `menu.*` | `MenuPage` | `MenuViewController` | Root list of destinations |
| `scroll.*` | `ScrollBaselinePage` | `ScrollBaselineViewController` | `contentOffset.y`, viewport height, Δy, `Δy / viewportHeight` (100% native vs. 80% Flutter page scroll), "Page X of Y" |
| `traversal.*` | `TraversalHierarchyPage` | `TraversalHierarchyViewController` | Natural geometric Row-Major (`sortKey: null` ≈ `accessibilityElements = nil`) vs. explicit Column-Major (`OrdinalSortKey` ≈ `accessibilityElements`), headers, stateful Buttons A/B/C |
| `focus.*` | `FocusKeyboardPage` | `FocusKeyboardViewController` | Pre-filled + placeholder field, 25% slider, secure field; `FocusNode` ≈ first responder, `FocusManager` ≈ `didUpdateFocus(in:with:)` |
| `modal.*` | `ModalBarrierPage` | `ModalBarrierViewController` | Modal route `BlockSemantics` ≈ `accessibilityViewIsModal`, `DraggableScrollableSheet` 50%/100% ≈ `.medium()/.large()` detents, `showDragHandle` ≈ grabber |

## Instrumentation

* `lib/a11y/a11y_probe.dart` — attaches identifier / value / traits / sort key /
  custom actions to the semantics node a widget contributes to (placement
  rules are documented in the file, including `mergeDescendants: true` for buttons).
* `lib/a11y/a11y_action_observer.dart` — wraps
  `PlatformDispatcher.onSemanticsActionEvent` and logs every semantics action the
  platform sends (`didGainAccessibilityFocus`, `increase`, `scrollUp`, custom
  actions, …) with the targeted node's merged identifier. This is the Flutter stand-in
  for UIKit's global `UIAccessibility.elementFocusedNotification` observer. All
  logs are prefixed `[A11yAction]`, `[ScrollBaseline]`, `[FocusKeyboard]`, etc.

## Running

```sh
# Sibling of the flutter/flutter checkout (~/Development/flutter is on PATH):
cd ~/Development/flutter_a11y_benchmark
flutter pub get
flutter run -d <simulator-id>

# Widget-level twins of the XCUITests:
flutter test

# XCUITests (same assertions as uikit_a11y_benchmarkUITests):
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RunnerUITests
```

If the checkout's engine artifacts are not published yet, point the tool at a
built engine (`FLUTTER_PREBUILT_ENGINE_VERSION=<content hash>`) or run with
`--local-engine ios_debug_sim_unopt_arm64 --local-engine-host host_debug_unopt_arm64`
to benchmark local `SemanticsObject.mm` changes.

## Known, intentional differences

* Flutter's iOS embedder posts `UIAccessibilityPageScrolledNotification` with a
  `SemanticsObject*` instead of an `NSString*`; the "Page X of Y" status is
  therefore displayed on screen and announced in UIKit, while silent in Flutter.
