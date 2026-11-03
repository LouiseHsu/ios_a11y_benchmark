import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';

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

  TraversalMode _mode = TraversalMode.rowMajor;
  bool _buttonASelected = false;
  bool _buttonBEnabled = false;
  bool _disclosureExpanded = false;
  // "Selection Controls" section state (Switch / Checkbox / Radio traits).
  bool _notificationsEnabled = false;
  bool _acceptedTerms = false;
  String _shippingSpeed = shippingSpeeds.first;
  // "Traits & Attributes" section state.
  bool _showHiddenRow = false;
  bool _focusRowHighlighted = false;
  String _status = '';
  late final TapGestureRecognizer _termsLinkRecognizer;
  late final TapGestureRecognizer _privacyLinkRecognizer;

  @override
  void initState() {
    super.initState();
    _termsLinkRecognizer = TapGestureRecognizer()
      ..onTap = () => _recordEvent('Link Activated: Terms of Service');
    _privacyLinkRecognizer = TapGestureRecognizer()
      ..onTap = () => _recordEvent('Link Activated: Privacy Policy');
    _updateOrderingStatus();
  }

  @override
  void dispose() {
    _termsLinkRecognizer.dispose();
    _privacyLinkRecognizer.dispose();
    super.dispose();
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
    final String state = _buttonASelected
        ? 'Selected (with checkmark)'
        : 'Unselected (no icon)';
    _recordEvent('Button A: $state');
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

  void _toggleHiddenRow() {
    setState(() => _showHiddenRow = !_showHiddenRow);
    _recordEvent('Hidden row -> ${_showHiddenRow ? 'shown' : 'hidden'}');
  }

  void _onFocusRowGainedFocus() {
    setState(() => _focusRowHighlighted = true);
    _recordEvent('VO focus -> gained (highlight row)');
  }

  void _onFocusRowLostFocus() {
    setState(() => _focusRowHighlighted = false);
    _recordEvent('VO focus -> lost (highlight row)');
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
              CupertinoSlidingSegmentedControl<TraversalMode>(
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
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int row = 0; row < gridSize; row += 1) ...<Widget>[
                    if (row > 0) const SizedBox(height: 12),
                    _buildHeader(row),
                    Row(
                      children: <Widget>[
                        for (int col = 0; col < gridSize; col += 1) ...<Widget>[
                          if (col > 0) const SizedBox(width: 8),
                          Expanded(child: _buildGridButton(row, col)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Expandable disclosure header: benchmarks Semantics(expanded: ...)
              // on iOS (#138891, #132264, #175907, #173446).
              Semantics(
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
                      Icon(
                        _disclosureExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (_disclosureExpanded) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Hidden detail content revealed when expanded.',
                  style: bodyStyle.copyWith(
                    fontSize: 13,
                    color: secondaryLabelColor,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Paragraph with two inline links: benchmarks multi-link RichText
              // traversal and the VoiceOver Links rotor (#159127, #166750, #18760).
              Text.rich(
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
              const SizedBox(height: 16),
              // Custom actions row: benchmarks `CustomSemanticsAction` ->
              // `UIAccessibilityCustomAction` (VoiceOver Actions rotor).
              // UIKit twin: a cell with `accessibilityCustomActions`.
              Semantics(
                customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                  const CustomSemanticsAction(label: 'Archive'): () =>
                      _recordEvent('Custom action -> Archive'),
                  const CustomSemanticsAction(label: 'Delete'): () =>
                      _recordEvent('Custom action -> Delete'),
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Message from Alex', style: bodyStyle),
                      const SizedBox(height: 2),
                      Text(
                        'Lunch tomorrow?',
                        style: bodyStyle.copyWith(
                          fontSize: 13,
                          color: secondaryLabelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTraitsAndAttributesSection(bodyStyle, secondaryLabelColor),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: bodyStyle.copyWith(
                  fontSize: 14,
                  color: secondaryLabelColor,
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

  /// "Selection Controls": CupertinoSwitch / CupertinoCheckbox / CupertinoRadio
  /// benchmarked against UISwitch, a checkmark UIButton, and a single-select
  /// radio row group (`isToggled`, `isChecked`, `isInMutuallyExclusiveGroup`
  /// in `SemanticsObject.mm`, #125495, #118176, #183821).
  Widget _buildSelectionControlsSection(
    TextStyle bodyStyle,
    Color secondaryLabelColor,
  ) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Selection Controls', style: titleStyle),
        ),
        const SizedBox(height: 8),
        // 1. Switch row (`SemanticsFlag.isToggled` -> `FlutterSwitchSemanticsObject`).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Notifications', style: bodyStyle),
            CupertinoSwitch(
              value: _notificationsEnabled,
              onChanged: _onNotificationsChanged,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 2. Checkbox row (`SemanticsFlag.isChecked` -> `FlutterSwitchSemanticsObject`).
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: <Widget>[
              CupertinoCheckbox(
                value: _acceptedTerms,
                tapTargetSize: const Size.square(24),
                onChanged: _onAcceptTermsChanged,
              ),
              const SizedBox(width: 8),
              Text('Accept Terms', style: bodyStyle),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 3. Radio group (`SemanticsFlag.isInMutuallyExclusiveGroup` + `isChecked`).
        Text(
          'Shipping Speed',
          style: bodyStyle.copyWith(fontSize: 13, color: secondaryLabelColor),
        ),
        const SizedBox(height: 4),
        RadioGroup<String>(
          groupValue: _shippingSpeed,
          onChanged: _onShippingSpeedChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final String speed in shippingSpeeds)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 6,
                  ),
                  child: Row(
                    children: <Widget>[
                      CupertinoRadio<String>(value: speed),
                      const SizedBox(width: 11),
                      Text(speed, style: bodyStyle),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// "Traits & Attributes": one small fixture per `SemanticsObject.mm` input
  /// that no other screen exercises — image trait, hidden/offstage elements,
  /// hint, attributed label (spell-out / locale), and accessibility-focus
  /// gain/lose callbacks.
  Widget _buildTraitsAndAttributesSection(
    TextStyle bodyStyle,
    Color secondaryLabelColor,
  ) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    final TextStyle captionStyle = bodyStyle.copyWith(
      fontSize: 13,
      color: secondaryLabelColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Traits & Attributes', style: titleStyle),
        ),
        const SizedBox(height: 8),
        // 1. Image trait: a meaningful image (`SemanticsFlag.isImage` + label)
        // next to a decorative one that is excluded from the tree entirely.
        Row(
          children: <Widget>[
            Semantics(
              image: true,
              label: 'Sunset over the bay',
              child: const Icon(CupertinoIcons.photo, size: 44),
            ),
            const SizedBox(width: 16),
            const ExcludeSemantics(
              child: Icon(CupertinoIcons.sparkles, size: 44),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Meaningful image / Decorative image', style: captionStyle),
        const SizedBox(height: 8),
        // 2. Hidden elements: a row that is only built while shown, plus a
        // permanently offstage text that must never become an element.
        CupertinoButton.tinted(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          onPressed: _toggleHiddenRow,
          child: const Text('Toggle hidden row'),
        ),
        Visibility(
          visible: _showHiddenRow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('You should not hear this', style: bodyStyle),
          ),
        ),
        Offstage(
          offstage: true,
          child: Text('Offstage text', style: bodyStyle),
        ),
        const SizedBox(height: 8),
        // 3. Hint: merges into the CupertinoButton's own semantics node
        // (`accessibilityHint` on iOS).
        Semantics(
          hint: 'Sends the message',
          child: CupertinoButton.tinted(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onPressed: () => _recordEvent('Send tapped'),
            child: const Text('Send'),
          ),
        ),
        const SizedBox(height: 8),
        // 4. Attributed labels: spell-out range and locale range
        // (`accessibilityAttributedLabel`). The Semantics wrapper supplies the
        // label itself, so the Text's own semantics are excluded to avoid
        // announcing it twice.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Semantics(
            excludeSemantics: true,
            attributedLabel: AttributedString(
              'Order ID: ABC123',
              attributes: <StringAttribute>[
                SpellOutStringAttribute(
                  range: const TextRange(start: 10, end: 16),
                ),
              ],
            ),
            child: Text('Order ID: ABC123', style: bodyStyle),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Semantics(
            excludeSemantics: true,
            attributedLabel: AttributedString(
              'Bonjour tout le monde',
              attributes: <StringAttribute>[
                LocaleStringAttribute(
                  range: const TextRange(start: 0, end: 21),
                  locale: const Locale('fr', 'FR'),
                ),
              ],
            ),
            child: Text('Bonjour tout le monde', style: bodyStyle),
          ),
        ),
        const SizedBox(height: 8),
        // 5. Accessibility-focus callbacks: the row highlights while VoiceOver
        // focus is on it (`accessibilityElementDidBecomeFocused` /
        // `accessibilityElementDidLoseFocus`).
        Semantics(
          onDidGainAccessibilityFocus: _onFocusRowGainedFocus,
          onDidLoseAccessibilityFocus: _onFocusRowLostFocus,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: _focusRowHighlighted ? CupertinoColors.systemYellow : null,
            child: Text('Focus-highlight row', style: bodyStyle),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int row) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
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
      return Semantics(
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
      return Semantics(
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
      return Semantics(
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
    return Semantics(
      sortKey: sortKey,
      child: CupertinoButton.tinted(
        padding: gridButtonPadding,
        onPressed: () =>
            _recordEvent('Activated Grid Button R${row + 1}C${col + 1}'),
        child: Text(
          'R${row + 1}C${col + 1}',
          style: labelStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
