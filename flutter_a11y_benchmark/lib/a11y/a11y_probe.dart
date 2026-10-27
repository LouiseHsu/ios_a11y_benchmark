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
/// Placement matters in Flutter: configuration merges *upward* into the
/// nearest semantics boundary. Put this widget *inside* a button's `child`
/// (so it merges into the button's own node), set [container] when wrapping
/// leaf widgets such as `Text` or `TextField`, or combine it with
/// [MergeSemantics] when a whole cell should become one element.
class A11yProbe extends StatelessWidget {
  const A11yProbe({
    super.key,
    required this.identifier,
    this.container = false,
    this.explicitChildNodes = false,
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
    return Semantics(
      container: container,
      explicitChildNodes: explicitChildNodes,
      identifier: identifier,
      header: header,
      selected: selected,
      label: label,
      value: value,
      sortKey: sortKey,
      customSemanticsActions: customSemanticsActions,
      onDidGainAccessibilityFocus: trackFocus ? _noop : null,
      onDidLoseAccessibilityFocus: trackFocus ? _noop : null,
      child: child,
    );
  }
}
