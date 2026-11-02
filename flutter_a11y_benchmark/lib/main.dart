import 'package:cupertino_ui/cupertino_ui.dart';

import 'pages/menu_page.dart';

void main() {
  runApp(const FlutterA11yBenchmarkApp());
}

/// Flutter Cupertino twin of `uikit_a11y_benchmark`.
///
/// Both apps expose the same five screens and the same iOS control structure
/// so that identical manual QA checks (VoiceOver, Voice Control, Full Keyboard
/// Access) can be run side by side. The Flutter side uses stock Cupertino
/// widgets with no accessibility annotations beyond the intent a developer has
/// to state explicitly (headings, expanded state, live region, icon-only
/// labels, explicit traversal order, custom actions).
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
