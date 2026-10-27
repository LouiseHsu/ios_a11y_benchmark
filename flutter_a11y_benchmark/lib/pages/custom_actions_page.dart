import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import '../a11y/a11y_probe.dart';

class _ActionItem {
  _ActionItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
  int primaryCount = 0;
  int secondaryCount = 0;

  String get badge => 'Primary: $primaryCount • Secondary: $secondaryCount';
}

/// List whose rows merge their labels into one element and expose two custom
/// actions in the VoiceOver Actions rotor.
///
/// UIKit twin: `CustomActionsViewController` + `MergedCustomActionCell`
/// (`isAccessibilityElement = true` + two `UIAccessibilityCustomAction`s).
/// Flutter equivalents: [MergeSemantics] + [CustomSemanticsAction].
class CustomActionsPage extends StatefulWidget {
  const CustomActionsPage({super.key});

  @override
  State<CustomActionsPage> createState() => _CustomActionsPageState();
}

class _CustomActionsPageState extends State<CustomActionsPage> {
  static const CustomSemanticsAction _primaryAction = CustomSemanticsAction(
    label: 'Primary Action',
  );
  static const CustomSemanticsAction _secondaryAction = CustomSemanticsAction(
    label: 'Secondary Action',
  );

  final List<_ActionItem> _items = List<_ActionItem>.generate(
    20,
    (int index) => _ActionItem(
      title: 'Merged Item #$index',
      subtitle: 'VoiceOver rotor actions benchmark row ${index + 1}',
    ),
  );
  String _status = 'Last Rotor Action: None';

  void _handlePrimaryAction(int row) {
    final _ActionItem item = _items[row];
    item.primaryCount += 1;
    _setStatus(
      'Primary Action fired on ${item.title} (count=${item.primaryCount})',
    );
  }

  void _handleSecondaryAction(int row) {
    final _ActionItem item = _items[row];
    item.secondaryCount += 1;
    _setStatus(
      'Secondary Action fired on ${item.title} (count=${item.secondaryCount})',
    );
  }

  void _setStatus(String message) {
    setState(() => _status = 'Last Rotor Action: $message');
    debugPrint('[CustomActions] $message');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Actions')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: A11yProbe(
              identifier: 'customActions.statusLabel',
              container: true,
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              container: true,
              identifier: 'customActions.tableView',
              child: ListView.separated(
                primary: true,
                itemCount: _items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final _ActionItem item = _items[index];
                  return MergeSemantics(
                    child: A11yProbe(
                      identifier: 'customActions.cell.$index',
                      // accessibilityValue twin: the counters live in `value`,
                      // the title/subtitle labels merge into the element label.
                      value: item.badge,
                      customSemanticsActions:
                          <CustomSemanticsAction, VoidCallback>{
                            _primaryAction: () => _handlePrimaryAction(index),
                            _secondaryAction: () =>
                                _handleSecondaryAction(index),
                          },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.title, style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ExcludeSemantics(
                              child: Text(
                                item.badge,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
