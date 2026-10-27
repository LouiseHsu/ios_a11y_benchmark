import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_benchmark/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level twins of the XCUITests shared with `uikit_a11y_benchmark`.
void main() {
  const List<String> menuIdentifiers = <String>[
    'menu.scrollBaseline',
    'menu.traversalHierarchy',
    'menu.focusKeyboard',
    'menu.modalBarrier',
    'menu.customActions',
    'menu.compositeArena',
  ];

  bool traversalContains(WidgetTester tester, String identifier) {
    // Compare the *merged* data, i.e. what the platform embedder receives.
    return tester.semantics.simulatedAccessibilityTraversal().any(
      (SemanticsNode node) => node.getSemanticsData().identifier == identifier,
    );
  }

  double semanticsValue(WidgetTester tester, String identifier) {
    return double.parse(
      tester.getSemantics(find.bySemanticsIdentifier(identifier)).value,
    );
  }

  testWidgets('menu exposes the six destinations with shared identifiers', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());

    for (final String identifier in menuIdentifiers) {
      expect(find.bySemanticsIdentifier(identifier), findsOneWidget);
      expect(traversalContains(tester, identifier), isTrue);
    }
    handle.dispose();
  });

  testWidgets('scroll baseline updates contentOffset.y, Δy and ratio', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.bySemanticsIdentifier('menu.scrollBaseline'));
    await tester.pumpAndSettle();

    expect(semanticsValue(tester, 'scroll.heightLabel'), greaterThan(0));
    expect(semanticsValue(tester, 'scroll.offsetYLabel'), 0);

    await tester.drag(
      find.bySemanticsIdentifier('scroll.cell.3'),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(semanticsValue(tester, 'scroll.offsetYLabel'), greaterThan(0));
    expect(semanticsValue(tester, 'scroll.deltaLabel'), greaterThan(0));
    expect(semanticsValue(tester, 'scroll.ratioLabel'), greaterThan(0));
    handle.dispose();
  });

  testWidgets('modal barrier sheet isolates background buttons', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.bySemanticsIdentifier('menu.modalBarrier'));
    await tester.pumpAndSettle();

    expect(traversalContains(tester, 'modal.backgroundButton1'), isTrue);
    expect(traversalContains(tester, 'modal.backgroundButton2'), isTrue);

    await tester.tap(find.bySemanticsIdentifier('modal.presentButton'));
    await tester.pumpAndSettle();

    expect(traversalContains(tester, 'modal.sheetTitle'), isTrue);
    expect(traversalContains(tester, 'modal.dismissButton'), isTrue);
    // The modal route's BlockSemantics barrier (accessibilityViewIsModal twin)
    // must remove the background controls from the accessibility tree.
    expect(traversalContains(tester, 'modal.backgroundButton1'), isFalse);
    expect(traversalContains(tester, 'modal.backgroundButton2'), isFalse);

    await tester.tap(find.bySemanticsIdentifier('modal.dismissButton'));
    await tester.pumpAndSettle();

    expect(traversalContains(tester, 'modal.backgroundButton1'), isTrue);
    expect(traversalContains(tester, 'modal.backgroundButton2'), isTrue);
    handle.dispose();
  });
}
