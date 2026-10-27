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

  testWidgets('menu exposes the four destinations with shared identifiers', (
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

  testWidgets(
    'traversal hierarchy merges button semantics and reorders row vs column major',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const FlutterA11yBenchmarkApp());
      await tester.tap(find.bySemanticsIdentifier('menu.traversalHierarchy'));
      await tester.pumpAndSettle();

      List<String> gridIdentifiersInTraversalOrder() {
        return tester.semantics
            .simulatedAccessibilityTraversal()
            .map((SemanticsNode node) => node.getSemanticsData().identifier)
            .where(
              (String id) =>
                  id.startsWith('traversal.header.') ||
                  id.startsWith('traversal.button'),
            )
            .toList();
      }

      // Verify buttonA merges the button trait with the probe's identifier.
      final SemanticsNode buttonANode = tester.semantics
          .simulatedAccessibilityTraversal()
          .firstWhere(
            (SemanticsNode n) =>
                n.getSemanticsData().identifier == 'traversal.buttonA',
          );
      expect(buttonANode.getSemanticsData().flagsCollection.isButton, isTrue);

      // Default Row-Major order: Row 0 buttons precede Row 1 header/buttons.
      final List<String> rowMajor = gridIdentifiersInTraversalOrder();
      expect(
        rowMajor.indexOf('traversal.buttonB'),
        lessThan(rowMajor.indexOf('traversal.header.1')),
      );
      expect(
        rowMajor.indexOf('traversal.header.1'),
        lessThan(rowMajor.indexOf('traversal.button.1.0')),
      );

      // Switch to Column-Major order: Column 0 buttons (buttonA, button.1.0,
      // button.2.0) precede Column 1 (header.1, buttonB).
      await tester.tap(find.text('Column-Major'));
      await tester.pumpAndSettle();

      final List<String> columnMajor = gridIdentifiersInTraversalOrder();
      expect(
        columnMajor.indexOf('traversal.button.1.0'),
        lessThan(columnMajor.indexOf('traversal.header.1')),
      );
      expect(
        columnMajor.indexOf('traversal.button.2.0'),
        lessThan(columnMajor.indexOf('traversal.buttonB')),
      );
      handle.dispose();
    },
  );
}
