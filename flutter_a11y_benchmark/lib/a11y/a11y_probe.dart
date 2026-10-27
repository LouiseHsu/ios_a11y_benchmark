import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Annotates the semantics node that [child] contributes to with the same
/// metadata the UIKit twin sets on its controls:
///
///  * [identifier] → `accessibilityIdentifier` (used by the shared XCUITests),
///  * [value] → `accessibilityValue`,
///  * [header] → `.header` trait, [selected] → `.selected` trait,
///  * [sortKey] → explicit `UIAccessibilityContainer` element ordering,
///  * [customSemanticsActions] → `UIAccessibilityCustomAction`s.
///
/// When [trackFocus] is true, no-op `didGain/didLoseAccessibilityFocus`
/// handlers are attached so that the iOS embedder reports VoiceOver focus
/// changes for this node to [A11yActionObserver]. Leave it false for widgets
/// that already declare those handlers themselves (e.g. [TextField], [Slider]).
///
/// Placement matters in Flutter: setting [identifier] implicitly marks a
/// [Semantics] node as a semantic boundary (`isSemanticBoundary = true`).
/// When annotating a widget that already creates its own semantics boundary
/// (such as `FilledButton`, `OutlinedButton`, `TextButton`, `ListTile`, or
/// `Slider`), wrap the widget with [A11yProbe] and set `mergeDescendants: true`
/// so the probe's identifier, traits, actions, and [sortKey] merge with the
/// control into a single platform accessibility element.
class A11yProbe extends StatelessWidget {
  const A11yProbe({
    super.key,
    required this.identifier,
    this.container = false,
    this.explicitChildNodes = false,
    this.mergeDescendants = false,
    this.trackFocus = true,
    this.header = false,
    this.selected,
    this.label,
    this.value,
    this.sortKey,
    this.customSemanticsActions,
    required this.child,
  });

  final String identifier;
  final bool container;
  final bool explicitChildNodes;
  final bool mergeDescendants;
  final bool trackFocus;
  final bool header;
  final bool? selected;
  final String? label;
  final String? value;
  final SemanticsSortKey? sortKey;
  final Map<CustomSemanticsAction, VoidCallback>? customSemanticsActions;
  final Widget child;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    Widget result = Semantics(
      container: container,
      explicitChildNodes: explicitChildNodes,
      identifier: identifier,
      header: header,
      selected: selected,
      label: label,
      value: value,
      sortKey: mergeDescendants ? null : sortKey,
      customSemanticsActions: customSemanticsActions,
      onDidGainAccessibilityFocus: trackFocus ? _noop : null,
      onDidLoseAccessibilityFocus: trackFocus ? _noop : null,
      child: child,
    );
    if (mergeDescendants) {
      if (sortKey != null) {
        // Place sortKey on a non-boundary Semantics directly under
        // MergeSemantics so RenderMergeSemantics absorbs sortKey onto the
        // merged SemanticsNode itself.
        result = Semantics(sortKey: sortKey, child: result);
      }
      result = MergeSemantics(child: result);
    }
    return result;
  }
}
