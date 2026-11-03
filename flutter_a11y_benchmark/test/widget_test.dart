import 'dart:ui'
    show
        LocaleStringAttribute,
        SpellOutStringAttribute,
        StringAttribute,
        Tristate;

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoButton,
        CupertinoCheckbox,
        CupertinoIcons,
        CupertinoRadio,
        CupertinoSwitch,
        CupertinoTextField;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart'
    show Axis, ListView, Scrollable, Text, TextRange, Widget;
import 'package:flutter_a11y_benchmark/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level smoke tests for the Flutter twin of `uikit_a11y_benchmark`.
///
/// Elements are located by their visible text / widget type only, exactly as
/// a QA tester would find them; the semantics tree is inspected through the
/// *merged* data (`simulatedAccessibilityTraversal`), i.e. what the platform
/// embedder receives.
void main() {
  const List<String> menuTitles = <String>[
    'Scroll Baseline',
    'Traversal Hierarchy',
    'Focus & Keyboard',
    'Modal Barrier',
    'Sliver Scroll',
  ];

  List<SemanticsNode> traversal(WidgetTester tester) =>
      tester.semantics.simulatedAccessibilityTraversal().toList();

  /// Merged traversal nodes whose label contains [text].
  Iterable<SemanticsNode> nodesWithLabel(WidgetTester tester, String text) {
    return traversal(tester)
        .where((SemanticsNode n) => n.getSemanticsData().label.contains(text));
  }

  SemanticsNode nodeWithLabel(WidgetTester tester, String text) =>
      nodesWithLabel(tester, text).single;

  bool traversalContains(WidgetTester tester, String text) =>
      nodesWithLabel(tester, text).isNotEmpty;

  /// Parses the number that follows `prefix` in the first matching Text.
  double metricValue(WidgetTester tester, String prefix) {
    final Text text = tester.widget<Text>(find.textContaining(prefix));
    final String rest = text.data!.substring(prefix.length).trim();
    return double.parse(rest.split(' ').first);
  }

  Future<void> openScreen(WidgetTester tester, String title) async {
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  testWidgets('menu exposes the five destinations', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());

    for (final String title in menuTitles) {
      expect(find.text(title), findsOneWidget);
      expect(traversalContains(tester, title), isTrue, reason: title);
    }
    handle.dispose();
  });

  testWidgets('scroll baseline updates contentOffset.y, Δy and ratio', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openScreen(tester, 'Scroll Baseline');

    expect(metricValue(tester, 'frame.size.height:'), greaterThan(0));
    expect(metricValue(tester, 'contentOffset.y:'), 0);

    await tester.drag(find.text('Item #3'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(metricValue(tester, 'contentOffset.y:'), greaterThan(0));
    expect(metricValue(tester, 'deltaY:'), greaterThan(0));
    expect(metricValue(tester, 'deltaY / viewportHeight:'), greaterThan(0));
    handle.dispose();
  });

  testWidgets('modal barrier sheet isolates background buttons', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openScreen(tester, 'Modal Barrier');

    expect(traversalContains(tester, 'Background Button 1'), isTrue);
    expect(traversalContains(tester, 'Background Button 2'), isTrue);

    await tester.tap(find.text('Present Modal Sheet'));
    await tester.pumpAndSettle();

    expect(traversalContains(tester, 'Modal Barrier Active'), isTrue);
    expect(traversalContains(tester, 'Dismiss Modal Sheet'), isTrue);
    // The modal route's own barrier (accessibilityViewIsModal twin) must
    // remove the background controls from the accessibility tree.
    expect(traversalContains(tester, 'Background Button 1'), isFalse);
    expect(traversalContains(tester, 'Background Button 2'), isFalse);

    await tester.tap(find.text('Dismiss Modal Sheet'));
    await tester.pumpAndSettle();

    expect(traversalContains(tester, 'Background Button 1'), isTrue);
    expect(traversalContains(tester, 'Background Button 2'), isTrue);
    handle.dispose();
  });

  testWidgets(
    'traversal hierarchy exposes headers/buttons and reorders row vs column major',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openScreen(tester, 'Traversal Hierarchy');

      List<String> gridLabelsInTraversalOrder() {
        return traversal(tester)
            .map((SemanticsNode node) => node.getSemanticsData().label)
            .where(
              (String label) =>
                  label.startsWith('Section Header ') ||
                  label.startsWith('R') && label.contains('C') ||
                  label == 'Mutating Icon Button' ||
                  label == 'Target Enableable Button' ||
                  label == 'Toggle Button B',
            )
            .toList();
      }

      // Headers carry the header flag; Button A is a button with a selected
      // state that flips on tap.
      final SemanticsData header1 = nodeWithLabel(
        tester,
        'Section Header 1',
      ).getSemanticsData();
      expect(header1.flagsCollection.isHeader, isTrue);
      SemanticsData buttonA = nodeWithLabel(
        tester,
        'Mutating Icon Button',
      ).getSemanticsData();
      expect(buttonA.flagsCollection.isButton, isTrue);
      expect(buttonA.flagsCollection.isSelected, Tristate.isFalse);
      await tester.tap(find.text('Mutating Icon Button'));
      await tester.pumpAndSettle();
      buttonA = nodeWithLabel(
        tester,
        'Mutating Icon Button',
      ).getSemanticsData();
      expect(buttonA.flagsCollection.isSelected, Tristate.isTrue);
      expect(find.text('Button A: Selected (with checkmark)'), findsOneWidget);

      // Default Row-Major order: Row 1 buttons precede Row 2 header/buttons.
      final List<String> rowMajor = gridLabelsInTraversalOrder();
      expect(
        rowMajor.indexOf('Target Enableable Button'),
        lessThan(rowMajor.indexOf('Section Header 2')),
      );
      expect(
        rowMajor.indexOf('Section Header 2'),
        lessThan(rowMajor.indexOf('R2C1')),
      );

      // Switch to Column-Major order: Column 1 (button A, R2C1, R3C1)
      // precedes Column 2 (Section Header 2, button B).
      await tester.tap(find.text('Column-Major'));
      await tester.pumpAndSettle();

      final List<String> columnMajor = gridLabelsInTraversalOrder();
      expect(
        columnMajor.indexOf('R2C1'),
        lessThan(columnMajor.indexOf('Section Header 2')),
      );
      expect(
        columnMajor.indexOf('R3C1'),
        lessThan(columnMajor.indexOf('Target Enableable Button')),
      );

      // Disclosure header exposes expanded state and reveals the body.
      final SemanticsData disclosureCollapsed = nodeWithLabel(
        tester,
        'Expandable Disclosure Section',
      ).getSemanticsData();
      // `isExpanded` is a tri-state: `isFalse` means "has an expanded state
      // and is currently collapsed" (≈ UIKit's collapsed disclosure).
      expect(disclosureCollapsed.flagsCollection.isExpanded, Tristate.isFalse);
      expect(
        find.text('Hidden detail content revealed when expanded.'),
        findsNothing,
      );

      await tester.tap(find.text('Expandable Disclosure Section'));
      await tester.pumpAndSettle();
      expect(
        nodeWithLabel(
          tester,
          'Expandable Disclosure Section',
        ).getSemanticsData().flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      expect(
        find.text('Hidden detail content revealed when expanded.'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('traversal custom actions row exposes Archive and Delete', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openScreen(tester, 'Traversal Hierarchy');

    const CustomSemanticsAction archive = CustomSemanticsAction(
      label: 'Archive',
    );
    const CustomSemanticsAction delete = CustomSemanticsAction(label: 'Delete');

    final SemanticsNode row = nodeWithLabel(tester, 'Message from Alex');
    final SemanticsData data = row.getSemanticsData();
    expect(data.label, contains('Lunch tomorrow?'));
    expect(
      data.customSemanticsActionIds,
      containsAll(<int>[
        CustomSemanticsAction.getIdentifier(archive),
        CustomSemanticsAction.getIdentifier(delete),
      ]),
    );

    row.owner!.performAction(
      row.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(archive),
    );
    await tester.pumpAndSettle();
    expect(find.text('Custom action -> Archive'), findsOneWidget);

    row.owner!.performAction(
      row.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(delete),
    );
    await tester.pumpAndSettle();
    expect(find.text('Custom action -> Delete'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'modal barrier exposes anchored popup menu, alert dialog, and bottom tab bar',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openScreen(tester, 'Modal Barrier');

      expect(
        traversalContains(tester, 'Anchored Popup Menu: Option Alpha'),
        isTrue,
      );
      await tester.tap(find.text('Anchored Popup Menu: Option Alpha'));
      await tester.pumpAndSettle();

      expect(traversalContains(tester, 'Option Beta'), isTrue);
      await tester.tap(find.text('Option Beta'));
      await tester.pumpAndSettle();

      expect(find.text('Popup Selected: Option Beta'), findsOneWidget);

      await tester.tap(find.text('Present Alert Dialog'));
      await tester.pumpAndSettle();
      expect(traversalContains(tester, 'Confirm'), isTrue);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Alert Dialog: Confirm'), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Selected Tab: Details (2 of 3)'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'focus keyboard exposes live region status label and polite announcement button',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openScreen(tester, 'Focus & Keyboard');

      final SemanticsData liveData = nodeWithLabel(
        tester,
        'Live Status: Username length 1 chars',
      ).getSemanticsData();
      expect(liveData.flagsCollection.isLiveRegion, isTrue);

      final SemanticsData bottomField = tester
          .getSemantics(find.byType(CupertinoTextField).last)
          .getSemanticsData();
      expect(bottomField.flagsCollection.isTextField, isTrue);
      expect(bottomField.flagsCollection.isObscured, isTrue);

      await tester.tap(find.text('Post Polite Announcement'));
      await tester.pump();
      expect(find.text('Live Status: Polite Announcement #1'), findsOneWidget);
      expect(find.text('Posted polite announcement #1'), findsOneWidget);
      handle.dispose();
    },
  );

  v2Tests();
}

/// v2 fixtures: selection controls and Sliver Scroll.
void v2Tests() {
  testWidgets('traversal selection controls toggle, select and log', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text('Traversal Hierarchy'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Selection Controls'));
    await tester.pumpAndSettle();
    expect(
      tester.semantics
          .simulatedAccessibilityTraversal()
          .singleWhere(
            (SemanticsNode n) =>
                n.getSemanticsData().label == 'Selection Controls',
          )
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );

    await tester.ensureVisible(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications switch -> on'), findsOneWidget);

    await tester.ensureVisible(find.byType(CupertinoCheckbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoCheckbox));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Accept Terms checkbox -> checked'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byType(CupertinoRadio<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoRadio<String>).at(1));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Shipping Speed radio -> Express'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('modal barrier exposes disabled popup menu item', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text('Modal Barrier'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Anchored Popup Menu:'));
    await tester.pumpAndSettle();
    expect(find.text('Option Delta (Unavailable)'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('sliver scroll reaches footer and floating button works', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text('Sliver Scroll'));
    await tester.pumpAndSettle();

    expect(find.text('Sliver Item 1'), findsOneWidget);

    // The icon-only floating button is named "Compose" and is a button.
    final SemanticsNode fab = tester.semantics
        .simulatedAccessibilityTraversal()
        .singleWhere(
          (SemanticsNode n) => n.getSemanticsData().label == 'Compose',
        );
    expect(fab.getSemanticsData().flagsCollection.isButton, isTrue);
    await tester.tap(find.byType(CupertinoButton).last);
    await tester.pumpAndSettle();

    for (
      int i = 0;
      i < 40 && find.text('Footer Action').evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Footer Action'));
    await tester.pumpAndSettle();
    expect(
      tester.semantics
          .simulatedAccessibilityTraversal()
          .singleWhere(
            (SemanticsNode n) => n.getSemanticsData().label == 'End of List',
          )
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    await tester.tap(find.text('Footer Action'));
    await tester.pumpAndSettle();
    expect(find.text('Footer Action taps: 1'), findsOneWidget);
    handle.dispose();
  });

  traitsAndAttributesTests();
}

/// "Traits & Attributes" fixtures on Traversal Hierarchy plus the horizontal
/// chip strip on Scroll Baseline.
void traitsAndAttributesTests() {
  Future<void> openTraitsSection(WidgetTester tester) async {
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text('Traversal Hierarchy'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Traits & Attributes'));
    await tester.pumpAndSettle();
  }

  SemanticsNode mergedNode(WidgetTester tester, String label) {
    return tester.semantics.simulatedAccessibilityTraversal().singleWhere(
      (SemanticsNode n) => n.getSemanticsData().label == label,
    );
  }

  bool merged(WidgetTester tester, String label) {
    return tester.semantics.simulatedAccessibilityTraversal().any(
      (SemanticsNode n) => n.getSemanticsData().label == label,
    );
  }

  testWidgets('traits: meaningful image has image flag, decorative excluded', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openTraitsSection(tester);

    expect(
      mergedNode(
        tester,
        'Traits & Attributes',
      ).getSemanticsData().flagsCollection.isHeader,
      isTrue,
    );
    final SemanticsData image = mergedNode(
      tester,
      'Sunset over the bay',
    ).getSemanticsData();
    expect(image.flagsCollection.isImage, isTrue);

    // The decorative icon renders but produces no semantics node at all.
    expect(find.byIcon(CupertinoIcons.sparkles), findsOneWidget);
    expect(
      tester.getSemantics(find.byIcon(CupertinoIcons.sparkles)).label,
      isEmpty,
    );
    handle.dispose();
  });

  testWidgets('traits: hidden row absent until toggled, offstage never', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openTraitsSection(tester);

    expect(find.text('Hidden row (visible only after toggle)'), findsNothing);
    expect(merged(tester, 'Hidden row (visible only after toggle)'), isFalse);
    expect(merged(tester, 'Offstage text'), isFalse);

    await tester.ensureVisible(find.text('Toggle hidden row'));
    await tester.tap(find.text('Toggle hidden row'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden row -> shown'), findsOneWidget);
    expect(find.text('Hidden row (visible only after toggle)'), findsOneWidget);
    expect(merged(tester, 'Hidden row (visible only after toggle)'), isTrue);
    // Offstage text is laid out but never an accessibility element.
    expect(find.text('Offstage text', skipOffstage: false), findsOneWidget);
    expect(merged(tester, 'Offstage text'), isFalse);

    await tester.tap(find.text('Toggle hidden row'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden row -> hidden'), findsOneWidget);
    expect(merged(tester, 'Hidden row (visible only after toggle)'), isFalse);
    handle.dispose();
  });

  testWidgets('traits: Send button node carries the hint', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openTraitsSection(tester);

    final SemanticsData send = mergedNode(tester, 'Send').getSemanticsData();
    expect(send.flagsCollection.isButton, isTrue);
    expect(send.hint, 'Sends the message');
    expect(send.hasAction(SemanticsAction.tap), isTrue);

    await tester.ensureVisible(find.text('Send'));
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Send tapped'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('traits: attributed labels carry spell-out and locale ranges', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openTraitsSection(tester);

    final SemanticsData order = mergedNode(
      tester,
      'Order ID: ABC123',
    ).getSemanticsData();
    final StringAttribute spellOut = order.attributedLabel.attributes.single;
    expect(spellOut, isA<SpellOutStringAttribute>());
    expect(spellOut.range, const TextRange(start: 10, end: 16));

    final SemanticsData bonjour = mergedNode(
      tester,
      'Bonjour tout le monde',
    ).getSemanticsData();
    final StringAttribute locale = bonjour.attributedLabel.attributes.single;
    expect(locale, isA<LocaleStringAttribute>());
    expect(locale.range, const TextRange(start: 0, end: 21));
    expect((locale as LocaleStringAttribute).locale.toLanguageTag(), 'fr-FR');
    handle.dispose();
  });

  testWidgets('traits: focus-highlight row exposes focus actions and logs', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openTraitsSection(tester);

    final SemanticsNode row = mergedNode(tester, 'Focus-highlight row');
    final SemanticsData data = row.getSemanticsData();
    expect(data.hasAction(SemanticsAction.didGainAccessibilityFocus), isTrue);
    expect(data.hasAction(SemanticsAction.didLoseAccessibilityFocus), isTrue);

    row.owner!.performAction(row.id, SemanticsAction.didGainAccessibilityFocus);
    await tester.pumpAndSettle();
    expect(find.text('VO focus -> gained (highlight row)'), findsOneWidget);

    row.owner!.performAction(row.id, SemanticsAction.didLoseAccessibilityFocus);
    await tester.pumpAndSettle();
    expect(find.text('VO focus -> lost (highlight row)'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('scroll baseline horizontal strip has 20 chips, list scrolls', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text('Scroll Baseline'));
    await tester.pumpAndSettle();

    final Finder horizontal = find.byWidgetPredicate(
      (Widget w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsOneWidget);
    final ListView strip = tester.widget<ListView>(horizontal);
    expect(strip.childrenDelegate.estimatedChildCount, 20);
    expect(strip.primary, isNot(true));
    expect(find.text('Chip 1'), findsOneWidget);

    // The strip scrolls horizontally all the way to the last chip.
    await tester.drag(find.text('Chip 1'), const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(find.text('Chip 20'), findsOneWidget);

    // The vertical list is still the primary one and still scrolls.
    expect(find.textContaining('contentOffset.y: 0.0'), findsOneWidget);
    await tester.drag(find.text('Item #3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.textContaining('contentOffset.y: 0.0'), findsNothing);
    handle.dispose();
  });
}
