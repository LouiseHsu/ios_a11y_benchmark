import 'package:cupertino_ui/cupertino_ui.dart';

import 'a11y/a11y_action_observer.dart';
import 'pages/menu_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mirrors the UIKit twin's global `UIAccessibility.elementFocusedNotification`
  // observer: records every semantics action the platform sends to Flutter.
  A11yActionObserver.install();
  runApp(const FlutterA11yBenchmarkApp());
}

/// Flutter Cupertino twin of `uikit_a11y_benchmark`.
///
/// Both apps expose the same five screens, the same iOS control structure, and
/// the same `accessibilityIdentifier`s (via [SemanticsProperties.identifier])
/// so that identical XCUITests and manual QA checks can be run side by side.
class FlutterA11yBenchmarkApp extends StatelessWidget {
  const FlutterA11yBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Flutter A11y Benchmark',
      theme: CupertinoThemeData(primaryColor: CupertinoColors.systemIndigo),
      // UIKit twin: UINavigationController(rootViewController: MenuViewController()).
      home: MenuPage(),
    );
  }
}
