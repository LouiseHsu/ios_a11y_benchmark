import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_benchmark/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Node-identity hygiene for the Traversal Hierarchy screen.
///
/// Flutter matches unkeyed siblings by position and type. A conditional child
/// in a `children:` list can therefore cause an unrelated sibling's Element,
/// and with it its SemanticsNode id, to be recycled into a different widget.
/// To an assistive technology that looks like focus sliding onto another
/// control. That is a framework effect, not embedder behaviour, and the twin
/// must not produce it by accident.
///
/// For every stateful control on the screen: tap it, then assert that each
/// label that existed both before and after still maps to the same node id,
/// except for the one fixture whose whole point is to change identity.
void main() {
  const String replaceLabel = 'Replace me (same label, new identity)';

  Map<String, int> idsByLabel(WidgetTester tester) {
    final Map<String, int> out = <String, int>{};
    for (final SemanticsNode n
        in tester.semantics.simulatedAccessibilityTraversal()) {
      final String label = n.getSemanticsData().label;
      if (label.isNotEmpty && !out.containsKey(label)) {
        out[label] = n.id;
      }
    }
    return out;
  }

  Future<void> tapAndCheck(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).first);
    await tester.pumpAndSettle();
    final Map<String, int> before = idsByLabel(tester);
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
    final Map<String, int> after = idsByLabel(tester);
    for (final MapEntry<String, int> e in before.entries) {
      if (e.key == replaceLabel || !after.containsKey(e.key)) {
        continue;
      }
      // The tapped control may legitimately relabel itself (Follow/Following,
      // Button A); everything else must keep its id.
      if (e.key == label) {
        continue;
      }
      expect(
        after[e.key],
        e.value,
        reason: "tapping '$label' changed the node id of '${e.key}'",
      );
    }
  }

  testWidgets('tapping any control keeps every other node id stable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const FlutterA11yBenchmarkApp());
    await tester.tap(find.text('Traversal Hierarchy'));
    await tester.pumpAndSettle();

    for (final String label in <String>[
      'Mutating Icon Button',
      'Toggle Button B',
      'Expandable Disclosure Section',
      'Expandable Disclosure Section', // collapse again
      'Toggle hidden row',
      'Follow',
      'Remove this button',
      'Restore removed button',
      replaceLabel,
    ]) {
      await tapAndCheck(tester, label);
    }
    handle.dispose();
  });
}
