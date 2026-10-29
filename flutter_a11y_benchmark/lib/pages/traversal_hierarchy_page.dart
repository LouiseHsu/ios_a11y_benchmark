import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
// Prefixed to avoid any name collisions with package:cupertino_ui; only the
// Material selection controls (Switch/Checkbox/Radio/DropdownMenu) are used.
import 'package:material_ui/material_ui.dart' as material;
import 'package:flutter/semantics.dart';

import '../a11y/a11y_action_observer.dart';
import '../a11y/a11y_probe.dart';

enum TraversalMode {
  rowMajor('Row-Major'),
  columnMajor('Column-Major');

  const TraversalMode(this.label);

  final String label;
}

/// 3x3 grid with section headers and three stateful buttons, exercising
/// natural geometric traversal vs. explicit container ordering.
///
/// UIKit twin: `TraversalHierarchyViewController` + `TraversalGridContainerView`
/// (a `UIAccessibilityContainer` that sets `accessibilityElements` in
/// Column-Major mode and leaves it `nil` in Row-Major mode).
/// Flutter's equivalent of an explicit element order is [OrdinalSortKey].
class TraversalHierarchyPage extends StatefulWidget {
  const TraversalHierarchyPage({super.key});

  @override
  State<TraversalHierarchyPage> createState() => _TraversalHierarchyPageState();
}

class _TraversalHierarchyPageState extends State<TraversalHierarchyPage> {
  static const int gridSize = 3;
  static const List<String> shippingSpeeds = <String>[
    'Standard',
    'Express',
    'Overnight',
  ];
  static const List<String> countries = <String>[
    'Canada',
    'Mexico',
    'United States',
  ];

  TraversalMode _mode = TraversalMode.rowMajor;
  bool _buttonASelected = false;
  bool _buttonBEnabled = false;
  bool _disclosureExpanded = false;
  // "Selection Controls" section state (v2).
  bool _notificationsEnabled = false;
  bool _acceptedTerms = false;
  String _shippingSpeed = shippingSpeeds.first;
  String _country = countries.first;
  String _status = '';
  Timer? _anchorCheckTimer;
  late final TapGestureRecognizer _termsLinkRecognizer;
  late final TapGestureRecognizer _privacyLinkRecognizer;

  @override
  void initState() {
    super.initState();
    _termsLinkRecognizer = TapGestureRecognizer()
      ..onTap = () => _recordEvent('Link Activated: Terms of Service');
    _privacyLinkRecognizer = TapGestureRecognizer()
      ..onTap = () => _recordEvent('Link Activated: Privacy Policy');
    A11yActionObserver.instance.addListener(_handleA11yAction);
    _updateOrderingStatus();
  }

  @override
  void dispose() {
    _anchorCheckTimer?.cancel();
    _termsLinkRecognizer.dispose();
    _privacyLinkRecognizer.dispose();
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

  /// Explicit traversal ordinals for Column-Major mode; empty in Row-Major mode
  /// so Flutter uses its natural geometric traversal order (matching UIKit's
  /// `accessibilityElements = nil`).
  Map<String, double> _ordinals() {
    if (_mode == TraversalMode.rowMajor) {
      return const <String, double>{};
    }
    final List<String> keys = <String>[];
    for (int col = 0; col < gridSize; col += 1) {
      keys.add('header.$col');
      for (int row = 0; row < gridSize; row += 1) {
        keys.add('button.$row.$col');
      }
    }
    return <String, double>{
      for (int i = 0; i < keys.length; i += 1) keys[i]: i.toDouble(),
    };
  }

  OrdinalSortKey? _sortKeyFor(String key) {
    final double? order = _ordinals()[key];
    return order != null ? OrdinalSortKey(order) : null;
  }

  void _recordEvent(String message) {
    setState(() => _status = message);
    debugPrint('[TraversalHierarchy] $message');
  }

  void _updateOrderingStatus() {
    final String detail = _mode == TraversalMode.rowMajor
        ? 'natural geometric order'
        : 'explicit OrdinalSortKey order';
    _recordEvent('Mode: ${_mode.label} ($detail)');
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

  void _toggleDisclosure() {
    setState(() => _disclosureExpanded = !_disclosureExpanded);
    final String state = _disclosureExpanded ? 'Expanded' : 'Collapsed';
    _recordEvent('Disclosure toggled -> $state');
  }

  void _onNotificationsChanged(bool value) {
    setState(() => _notificationsEnabled = value);
    _recordEvent('Notifications switch -> ${value ? 'on' : 'off'}');
  }

  void _onAcceptTermsChanged(bool? value) {
    final bool accepted = value ?? false;
    setState(() => _acceptedTerms = accepted);
    _recordEvent(
      'Accept Terms checkbox -> ${accepted ? 'checked' : 'unchecked'}',
    );
  }

  void _onShippingSpeedChanged(String? value) {
    if (value == null) {
      return;
    }
    setState(() => _shippingSpeed = value);
    _recordEvent('Shipping Speed radio -> $value');
  }

  void _onCountrySelected(String? value) {
    if (value == null) {
      return;
    }
    setState(() => _country = value);
    _recordEvent('Country dropdown -> $value');
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final Color secondaryLabelColor = CupertinoColors.secondaryLabel
        .resolveFrom(context);
    final TextStyle bodyStyle = CupertinoTheme.of(context).textTheme.textStyle;
    final TextStyle linkStyle = bodyStyle.copyWith(
      color: primaryColor,
      decoration: TextDecoration.underline,
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Traversal Hierarchy'),
        previousPageTitle: 'Flutter A11y Benchmark',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // UISegmentedControl twin.
              A11yProbe(
                identifier: 'traversal.orderingControl',
                container: true,
                trackFocus: false,
                child: CupertinoSlidingSegmentedControl<TraversalMode>(
                  groupValue: _mode,
                  children: <TraversalMode, Widget>{
                    for (final TraversalMode mode in TraversalMode.values)
                      mode: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(mode.label),
                      ),
                  },
                  onValueChanged: (TraversalMode? selection) {
                    if (selection == null) {
                      return;
                    }
                    setState(() => _mode = selection);
                    _updateOrderingStatus();
                  },
                ),
              ),
              const SizedBox(height: 20),
              A11yProbe(
                identifier: 'traversal.gridContainer',
                container: true,
                explicitChildNodes: true,
                trackFocus: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int row = 0; row < gridSize; row += 1) ...<Widget>[
                      if (row > 0) const SizedBox(height: 12),
                      _buildHeader(row),
                      Row(
                        children: <Widget>[
                          for (
                            int col = 0;
                            col < gridSize;
                            col += 1
                          ) ...<Widget>[
                            if (col > 0) const SizedBox(width: 8),
                            Expanded(child: _buildGridButton(row, col)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Expandable disclosure header: benchmarks Semantics(expanded: ...)
              // on iOS (#138891, #132264, #175907, #173446).
              A11yProbe(
                identifier: 'traversal.disclosureHeader',
                mergeDescendants: true,
                expanded: _disclosureExpanded,
                child: CupertinoButton.tinted(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  onPressed: _toggleDisclosure,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Expandable Disclosure Section'),
                      ExcludeSemantics(
                        child: Icon(
                          _disclosureExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_disclosureExpanded) ...<Widget>[
                const SizedBox(height: 6),
                A11yProbe(
                  identifier: 'traversal.disclosureBody',
                  container: true,
                  child: Text(
                    'Hidden detail content revealed when expanded.',
                    style: bodyStyle.copyWith(
                      fontSize: 13,
                      color: secondaryLabelColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Paragraph with two inline links: benchmarks multi-link RichText
              // traversal and the VoiceOver Links rotor (#159127, #166750, #18760).
              A11yProbe(
                identifier: 'traversal.linksParagraph',
                container: true,
                explicitChildNodes: true,
                trackFocus: false,
                child: Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: <InlineSpan>[
                      const TextSpan(text: 'Read our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: linkStyle,
                        recognizer: _termsLinkRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: linkStyle,
                        recognizer: _privacyLinkRecognizer,
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              A11yProbe(
                identifier: 'traversal.statusLabel',
                container: true,
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: bodyStyle.copyWith(
                    fontSize: 14,
                    color: secondaryLabelColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSelectionControlsSection(bodyStyle, secondaryLabelColor),
            ],
          ),
        ),
      ),
    );
  }

  /// "Selection Controls" (v2): Material Switch / Checkbox / Radio /
  /// DropdownMenu, benchmarked against UISwitch, a checkmark UIButton, a
  /// single-select checkmark row group, and a UIButton pop-up menu.
  /// Targets Switch/Checkbox/Radio state announcement issues (#125495,
  /// #118176) and DropdownMenu selection announcement issues (#175950,
  /// #175184, #133742).
  Widget _buildSelectionControlsSection(
    TextStyle bodyStyle,
    Color secondaryLabelColor,
  ) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    return material.Material(
      type: material.MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          A11yProbe(
            identifier: 'traversal.selectionControlsHeader',
            container: true,
            header: true,
            child: Text('Selection Controls', style: titleStyle),
          ),
          const SizedBox(height: 8),
          // 1. Switch row. Merged into a single node so the label text becomes
          // the switch's accessibility label, like UISwitch.accessibilityLabel.
          A11yProbe(
            identifier: 'traversal.notificationsSwitch',
            mergeDescendants: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Notifications', style: bodyStyle),
                material.Switch(
                  value: _notificationsEnabled,
                  onChanged: _onNotificationsChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 2. Checkbox row (iOS has no checkbox; UIKit twin is a checkmark
          // UIButton that toggles `.selected`).
          A11yProbe(
            identifier: 'traversal.acceptTermsCheckbox',
            mergeDescendants: true,
            child: Row(
              children: <Widget>[
                material.Checkbox(
                  value: _acceptedTerms,
                  onChanged: _onAcceptTermsChanged,
                ),
                const SizedBox(width: 4),
                Text('Accept Terms', style: bodyStyle),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 3. Radio group (iOS has no radio; UIKit twin is three single-select
          // checkmark rows).
          A11yProbe(
            identifier: 'traversal.shippingSpeedLabel',
            container: true,
            child: Text(
              'Shipping Speed',
              style: bodyStyle.copyWith(
                fontSize: 13,
                color: secondaryLabelColor,
              ),
            ),
          ),
          material.RadioGroup<String>(
            groupValue: _shippingSpeed,
            onChanged: _onShippingSpeedChanged,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final String speed in shippingSpeeds)
                  A11yProbe(
                    identifier: 'traversal.radio$speed',
                    mergeDescendants: true,
                    child: Row(
                      children: <Widget>[
                        material.Radio<String>(value: speed),
                        const SizedBox(width: 4),
                        Text(speed, style: bodyStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 4. DropdownMenu (UIKit twin: UIButton pop-up menu with
          // changesSelectionAsPrimaryAction). The probe is a container (not
          // merged) so the inner text field and trailing icon button keep
          // their own semantics nodes, matching how the widget ships.
          A11yProbe(
            identifier: 'traversal.countryDropdown',
            container: true,
            explicitChildNodes: true,
            trackFocus: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: material.DropdownMenu<String>(
                label: const Text('Country'),
                initialSelection: _country,
                onSelected: _onCountrySelected,
                dropdownMenuEntries: <material.DropdownMenuEntry<String>>[
                  for (final String country in countries)
                    material.DropdownMenuEntry<String>(
                      value: country,
                      label: country,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int row) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: A11yProbe(
        identifier: 'traversal.header.$row',
        container: true,
        header: true,
        sortKey: _sortKeyFor('header.$row'),
        child: Text('Section Header ${row + 1}', style: titleStyle),
      ),
    );
  }

  Widget _buildGridButton(int row, int col) {
    final OrdinalSortKey? sortKey = _sortKeyFor('button.$row.$col');
    const TextStyle labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    const EdgeInsets gridButtonPadding = EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 10,
    );

    if (row == 0 && col == 0) {
      // Button A ("Mutating Icon Button"): toggles `.selected` and a leading
      // checkmark icon via the button content, like UIButton.Configuration.
      return A11yProbe(
        identifier: 'traversal.buttonA',
        mergeDescendants: true,
        sortKey: sortKey,
        selected: _buttonASelected,
        child: CupertinoButton.tinted(
          padding: gridButtonPadding,
          onPressed: _onButtonATapped,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_buttonASelected) ...<Widget>[
                const Icon(CupertinoIcons.check_mark, size: 14),
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
      return A11yProbe(
        identifier: 'traversal.buttonB',
        mergeDescendants: true,
        sortKey: sortKey,
        child: CupertinoButton.tinted(
          padding: gridButtonPadding,
          onPressed: _buttonBEnabled ? _onButtonBTapped : null,
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
      return A11yProbe(
        identifier: 'traversal.buttonC',
        mergeDescendants: true,
        sortKey: sortKey,
        child: CupertinoButton.tinted(
          padding: gridButtonPadding,
          onPressed: _onButtonCTapped,
          child: const Text(
            'Toggle Button B',
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return A11yProbe(
      identifier: 'traversal.button.$row.$col',
      mergeDescendants: true,
      sortKey: sortKey,
      label: 'Grid Button Row ${row + 1} Column ${col + 1}',
      child: CupertinoButton.tinted(
        padding: gridButtonPadding,
        onPressed: () =>
            _recordEvent('Activated Grid Button R${row + 1}C${col + 1}'),
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
