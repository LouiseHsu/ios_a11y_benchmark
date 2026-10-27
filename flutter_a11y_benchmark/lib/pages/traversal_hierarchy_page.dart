import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import '../a11y/a11y_action_observer.dart';
import '../a11y/a11y_probe.dart';

enum TraversalMode {
  rowMajor('Row-Major'),
  columnMajor('Column-Major');

  const TraversalMode(this.label);

  final String label;
}

/// 3x3 grid with section headers, zero-rect sentinels and three stateful
/// buttons, exercising explicit traversal ordering and RTL layout.
///
/// UIKit twin: `TraversalHierarchyViewController` + `TraversalGridContainerView`
/// (a `UIAccessibilityContainer` that rebuilds `accessibilityElements`).
/// Flutter's equivalent of a custom element order is [OrdinalSortKey]; the
/// equivalent of `semanticContentAttribute` is [Directionality].
class TraversalHierarchyPage extends StatefulWidget {
  const TraversalHierarchyPage({super.key});

  @override
  State<TraversalHierarchyPage> createState() => _TraversalHierarchyPageState();
}

class _TraversalHierarchyPageState extends State<TraversalHierarchyPage> {
  static const int gridSize = 3;

  TraversalMode _mode = TraversalMode.rowMajor;
  bool _isRightToLeft = false;
  bool _buttonASelected = false;
  bool _buttonBEnabled = false;
  String _status = '';
  Timer? _anchorCheckTimer;

  @override
  void initState() {
    super.initState();
    A11yActionObserver.instance.addListener(_handleA11yAction);
    _updateOrderingStatus();
  }

  @override
  void dispose() {
    _anchorCheckTimer?.cancel();
    A11yActionObserver.instance.removeListener(_handleA11yAction);
    super.dispose();
  }

  void _handleA11yAction() {
    final A11yActionRecord? record = A11yActionObserver.instance.latest;
    if (record != null &&
        record.action == SemanticsAction.didGainAccessibilityFocus) {
      debugPrint(
        '[TraversalHierarchy] VoiceOver focused element: ${record.description}',
      );
    }
  }

  /// Explicit traversal order, identical to the UIKit container's
  /// `rebuildAccessibilityOrder()`.
  Map<String, double> _ordinals() {
    final List<int> columns = _isRightToLeft
        ? List<int>.generate(gridSize, (int i) => gridSize - 1 - i)
        : List<int>.generate(gridSize, (int i) => i);
    final List<String> keys = <String>[];
    switch (_mode) {
      case TraversalMode.rowMajor:
        for (int row = 0; row < gridSize; row += 1) {
          keys.add('header.$row');
          keys.add('zeroRect.$row');
          for (final int col in columns) {
            keys.add('button.$row.$col');
          }
        }
      case TraversalMode.columnMajor:
        for (final int col in columns) {
          keys.add('header.$col');
          for (int row = 0; row < gridSize; row += 1) {
            keys.add('button.$row.$col');
          }
          keys.add('zeroRect.$col');
        }
    }
    return <String, double>{
      for (int i = 0; i < keys.length; i += 1) keys[i]: i.toDouble(),
    };
  }

  void _recordEvent(String message) {
    setState(() => _status = message);
    debugPrint('[TraversalHierarchy] $message');
  }

  void _updateOrderingStatus() {
    final int count = gridSize * 2 + gridSize * gridSize;
    final String direction = _isRightToLeft ? 'RTL' : 'LTR';
    _recordEvent(
      'Mode: ${_mode.label} | $direction ($count container elements incl. '
      'headers & zero-rect sentinels)',
    );
  }

  void _toggleLayoutDirection() {
    setState(() => _isRightToLeft = !_isRightToLeft);
    _updateOrderingStatus();
  }

  void _onButtonATapped() {
    setState(() => _buttonASelected = !_buttonASelected);
    final A11yActionObserver observer = A11yActionObserver.instance;
    final bool anchoredNow = observer.isAccessibilityFocused(
      'traversal.buttonA',
    );
    final String state = _buttonASelected
        ? 'Selected (with checkmark)'
        : 'Unselected (no icon)';
    _recordEvent(
      'Button A: $state | VO focus anchored on A at activation: $anchoredNow',
    );

    // Re-check once the semantics update has been flushed to the platform.
    _anchorCheckTimer?.cancel();
    _anchorCheckTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) {
        return;
      }
      final bool stillAnchored = observer.isAccessibilityFocused(
        'traversal.buttonA',
      );
      _recordEvent(
        'Button A: $state | VO focus anchored on A after update: '
        '$stillAnchored (focused: ${observer.focusedNodeDescription})',
      );
    });
  }

  void _onButtonBTapped() => _recordEvent('Button B activated while enabled');

  void _onButtonCTapped() {
    setState(() => _buttonBEnabled = !_buttonBEnabled);
    _recordEvent('Button C toggled Button B -> isEnabled = $_buttonBEnabled');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> ordinals = _ordinals();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traversal Hierarchy'),
        actions: <Widget>[
          TextButton(
            onPressed: _toggleLayoutDirection,
            child: A11yProbe(
              identifier: 'traversal.directionToggleButton',
              child: Text(_isRightToLeft ? 'Direction: RTL' : 'Direction: LTR'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            A11yProbe(
              identifier: 'traversal.orderingControl',
              container: true,
              trackFocus: false,
              child: SegmentedButton<TraversalMode>(
                segments: <ButtonSegment<TraversalMode>>[
                  for (final TraversalMode mode in TraversalMode.values)
                    ButtonSegment<TraversalMode>(
                      value: mode,
                      label: Text(mode.label),
                    ),
                ],
                selected: <TraversalMode>{_mode},
                onSelectionChanged: (Set<TraversalMode> selection) {
                  setState(() => _mode = selection.first);
                  _updateOrderingStatus();
                },
              ),
            ),
            const SizedBox(height: 20),
            // UIKit: TraversalGridContainerView with semanticContentAttribute.
            Directionality(
              textDirection: _isRightToLeft
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: A11yProbe(
                identifier: 'traversal.gridContainer',
                container: true,
                explicitChildNodes: true,
                trackFocus: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int row = 0; row < gridSize; row += 1) ...<Widget>[
                      if (row > 0) const SizedBox(height: 12),
                      _buildHeader(row, ordinals),
                      _buildZeroRectSentinel(row, ordinals),
                      Row(
                        children: <Widget>[
                          for (
                            int col = 0;
                            col < gridSize;
                            col += 1
                          ) ...<Widget>[
                            if (col > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _buildGridButton(row, col, ordinals),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            A11yProbe(
              identifier: 'traversal.statusLabel',
              container: true,
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int row, Map<String, double> ordinals) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: A11yProbe(
        identifier: 'traversal.header.$row',
        container: true,
        header: true,
        sortKey: OrdinalSortKey(ordinals['header.$row']!),
        child: Text(
          'Section Header ${row + 1}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  /// Zero-rect element placed between the header and its row of buttons.
  /// UIKit keeps zero-frame `accessibilityElements`; Flutter drops semantics
  /// nodes with an empty rect before they reach the platform.
  Widget _buildZeroRectSentinel(int row, Map<String, double> ordinals) {
    return A11yProbe(
      identifier: 'traversal.zeroRect.$row',
      container: true,
      label: 'Zero-Rect Sentinel ${row + 1}',
      sortKey: OrdinalSortKey(ordinals['zeroRect.$row']!),
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildGridButton(int row, int col, Map<String, double> ordinals) {
    final OrdinalSortKey sortKey = OrdinalSortKey(
      ordinals['button.$row.$col']!,
    );
    const TextStyle labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    // Compact padding so three buttons fit a row like UIButton.Configuration.
    final ButtonStyle gridButtonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );

    if (row == 0 && col == 0) {
      // Button A ("Mutating Icon Button"): toggles `.selected` and a leading
      // checkmark icon via the button content, like UIButton.Configuration.
      return FilledButton.tonal(
        style: gridButtonStyle,
        onPressed: _onButtonATapped,
        child: A11yProbe(
          identifier: 'traversal.buttonA',
          sortKey: sortKey,
          selected: _buttonASelected,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_buttonASelected) ...<Widget>[
                const Icon(Icons.check, size: 16),
                const SizedBox(width: 4),
              ],
              const Flexible(
                child: Text(
                  'Mutating Icon Button',
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (row == 0 && col == 1) {
      // Button B ("Target Enableable Button"): starts disabled.
      return FilledButton.tonal(
        style: gridButtonStyle,
        onPressed: _buttonBEnabled ? _onButtonBTapped : null,
        child: A11yProbe(
          identifier: 'traversal.buttonB',
          sortKey: sortKey,
          child: const Text(
            'Target Enableable Button',
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (row == 0 && col == 2) {
      // Button C ("Toggle Button B").
      return FilledButton.tonal(
        style: gridButtonStyle,
        onPressed: _onButtonCTapped,
        child: A11yProbe(
          identifier: 'traversal.buttonC',
          sortKey: sortKey,
          child: const Text(
            'Toggle Button B',
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return FilledButton.tonal(
      style: gridButtonStyle,
      onPressed: () =>
          _recordEvent('Activated Grid Button R${row + 1}C${col + 1}'),
      child: A11yProbe(
        identifier: 'traversal.button.$row.$col',
        sortKey: sortKey,
        label: 'Grid Button Row ${row + 1} Column ${col + 1}',
        child: ExcludeSemantics(
          child: Text(
            'R${row + 1}C${col + 1}',
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
