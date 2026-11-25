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
  // "More Controls" section state.
  static const List<String> pickerSizes = <String>['Small', 'Medium', 'Large'];
  int _pickerIndex = 0;
  // "Mutation While Focused" section state.
  bool _isFollowing = false;
  bool _removableButtonPresent = true;
  int _replaceGeneration = 0;
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

  void _onPickerChanged(int index) {
    setState(() => _pickerIndex = index);
    _recordEvent('Picker -> ${pickerSizes[index]}');
  }

  void _onUnlabeledTapped() => _recordEvent('Unlabeled tappable -> tapped');

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    _recordEvent(
      'Label-changing button -> ${_isFollowing ? 'Following' : 'Follow'}',
    );
  }

  void _removeSelf() {
    setState(() => _removableButtonPresent = false);
    _recordEvent('Self-removing button -> removed');
  }

  void _restoreRemoved() {
    setState(() => _removableButtonPresent = true);
    _recordEvent('Self-removing button -> restored');
  }

  void _replaceSelf() {
    // Let the pressed-state fade finish before swapping the widget out, so the
    // tap still looks like a tap. Also closer to real apps, which rebuild a
    // beat after the tap (await, setState from a callback) rather than inline.
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) {
        return;
      }
      setState(() => _replaceGeneration += 1);
      _recordEvent(
        'Identity-replacing button -> generation $_replaceGeneration',
      );
    });
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
              const SizedBox(height: 24),
              _buildMoreControlsSection(bodyStyle, secondaryLabelColor),
              const SizedBox(height: 24),
              _buildMutationSection(bodyStyle, secondaryLabelColor),
            ],
          ),
        ),
      ),
    );
  }

  /// "More Controls": the remaining Cupertino semantics shapes that no other
  /// screen exercises — a picker wheel (adjustable-by-scroll), a long-press
  /// context menu, and an interactive element with no label and no role.
  ///
  /// UIKit twins: `UIPickerView`, `UIContextMenuInteraction`, and a bare
  /// `UIView` + `UITapGestureRecognizer` with no accessibility configuration.
  /// The last one is deliberately asymmetric: UIKit does not expose such a view
  /// to assistive technologies at all, while Flutter emits a node with a `tap`
  /// action and nothing else — the same shape as a scrollbar thumb or a
  /// dismissible banner (#157630, #196337), which is what Voice Control badges.
  Widget _buildMoreControlsSection(
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
          child: Text('More Controls', style: titleStyle),
        ),
        const SizedBox(height: 8),
        // 1. Picker wheel: `hasImplicitScrolling` + scrollUp/scrollDown with a
        // value, i.e. "adjustable" via swipe up/down under VoiceOver.
        Text('Size (picker wheel)', style: captionStyle),
        SizedBox(
          height: 120,
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(
              initialItem: _pickerIndex,
            ),
            onSelectedItemChanged: _onPickerChanged,
            children: <Widget>[
              for (final String size in pickerSizes)
                Center(child: Text(size, style: bodyStyle)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 2. Context menu: long-press target. Under VoiceOver the menu is
        // reached via the Actions rotor / "Show more items"; under Voice
        // Control via "long press <number>".
        CupertinoContextMenu(
          actions: <Widget>[
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.doc_on_clipboard,
              onPressed: () {
                Navigator.of(context).pop();
                _recordEvent('Context menu -> Copy');
              },
              child: const Text('Copy'),
            ),
            CupertinoContextMenuAction(
              trailingIcon: CupertinoIcons.share,
              onPressed: () {
                Navigator.of(context).pop();
                _recordEvent('Context menu -> Share');
              },
              child: const Text('Share'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Long-press for context menu', style: bodyStyle),
          ),
        ),
        const SizedBox(height: 8),
        // 3. Unlabeled tappable: a GestureDetector with no text child and no
        // Semantics. Visible as a tinted bar; nothing else about it is declared.
        GestureDetector(
          onTap: _onUnlabeledTapped,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemIndigo.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('Unlabeled tappable bar (no label, no role)', style: captionStyle),
      ],
    );
  }

  /// "Mutation While Focused": elements whose semantics node changes shape
  /// while an assistive technology has focus on them. Button A in the grid
  /// already covers "child icon added/removed"; these cover the other three
  /// structural mutations — label text replaced, node removed, node replaced
  /// by a new identity with identical appearance.
  ///
  /// UIKit twins: `UIButton` title swap, `UIStackView` arranged-subview
  /// `isHidden`, and removing the `UIButton` instance and inserting a fresh one
  /// at the same index.
  Widget _buildMutationSection(TextStyle bodyStyle, Color secondaryLabelColor) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Mutation While Focused', style: titleStyle),
        ),
        const SizedBox(height: 8),
        // 1. Label changes on tap (same node, new label).
        CupertinoButton.tinted(
          key: const ValueKey<String>('mutation.follow'),
          padding: buttonPadding,
          onPressed: _toggleFollow,
          child: Text(_isFollowing ? 'Following' : 'Follow'),
        ),
        const SizedBox(height: 8),
        // 2. Node removed on tap. The restore button is always present so the
        // fixture can be repeated without leaving the screen.
        // Every button here carries a stable Key. Without keys, Flutter matches
        // unkeyed siblings by position and type, so restoring the removed
        // button would *reuse* the Restore button's Element (and SemanticsNode
        // id) as the new Remove button, and VoiceOver focus would appear to
        // slide from Restore onto Remove. That is a framework identity effect,
        // not the embedder behaviour this fixture is meant to isolate.
        if (_removableButtonPresent)
          CupertinoButton.tinted(
            key: const ValueKey<String>('mutation.remove'),
            padding: buttonPadding,
            onPressed: _removeSelf,
            child: const Text('Remove this button'),
          ),
        if (_removableButtonPresent)
          const SizedBox(
            key: ValueKey<String>('mutation.remove.gap'),
            height: 8,
          ),
        CupertinoButton(
          key: const ValueKey<String>('mutation.restore'),
          padding: buttonPadding,
          onPressed: _removableButtonPresent ? null : _restoreRemoved,
          child: const Text('Restore removed button'),
        ),
        const SizedBox(height: 8),
        // 3. Node replaced on tap: a new Key forces a new Element, State, and
        // SemanticsNode id while the label and geometry stay identical.
        CupertinoButton.tinted(
          key: ValueKey<int>(_replaceGeneration),
          padding: buttonPadding,
          onPressed: _replaceSelf,
          child: const Text('Replace me (same label, new identity)'),
        ),
      ],
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
            child: Text(
              'Hidden row (visible only after toggle)',
              style: bodyStyle,
            ),
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
