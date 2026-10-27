import 'package:material_ui/material_ui.dart';

import 'a11y/a11y_action_observer.dart';
import 'pages/menu_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mirrors the UIKit twin's global `UIAccessibility.elementFocusedNotification`
  // observer: records every semantics action the platform sends to Flutter.
  A11yActionObserver.install();
  runApp(const FlutterA11yBenchmarkApp());
}

/// Flutter twin of `uikit_a11y_benchmark`.
///
/// Both apps expose the same six screens, the same control structure, and the
/// same `accessibilityIdentifier`s (via [SemanticsProperties.identifier]) so
/// that identical XCUITests can be pointed at either binary.
class FlutterA11yBenchmarkApp extends StatelessWidget {
  const FlutterA11yBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter A11y Benchmark',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      // UIKit twin: UINavigationController(rootViewController: MenuViewController()).
      home: const MenuPage(),
    );
  }
}
