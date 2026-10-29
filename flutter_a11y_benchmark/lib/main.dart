import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show DefaultMaterialLocalizations;

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
/// Both apps expose the same four screens, the same iOS control structure, and
/// the same `accessibilityIdentifier`s (via [SemanticsProperties.identifier])
/// so that identical XCUITests and manual QA checks can be run side by side.
class FlutterA11yBenchmarkApp extends StatelessWidget {
  const FlutterA11yBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Flutter A11y Benchmark',
      theme: CupertinoThemeData(primaryColor: CupertinoColors.systemIndigo),
      // The v2 "selection controls" and date/time picker fixtures use Material
      // widgets (Checkbox, Radio, Switch, DropdownMenu, showDatePicker,
      // TextField(maxLength:)) because the audited P0/P1 issues are filed
      // against those widgets. They need MaterialLocalizations to build.
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      // UIKit twin: UINavigationController(rootViewController: MenuViewController()).
      home: MenuPage(),
    );
  }
}
