import 'package:material_ui/material_ui.dart';

import '../a11y/a11y_action_observer.dart';
import '../a11y/a11y_probe.dart';

/// Scrollable form with a pre-filled username field, a 25% slider, a tall
/// event log and a secure password field, logging responder, VoiceOver and
/// Full Keyboard Access focus transitions.
///
/// UIKit twin: `FocusKeyboardViewController`.
///
/// Mapping of the logged events:
///  * `becomeFirstResponder` / `resignFirstResponder` → [FocusNode.hasFocus]
///    transitions of each control's focus node,
///  * `didUpdateFocus(in:with:)` (FKA) → [FocusManager] primary-focus changes,
///  * `accessibilityElementDidBecomeFocused` → `didGainAccessibilityFocus`
///    semantics actions observed by [A11yActionObserver],
///  * `accessibilityIncrement` / `accessibilityDecrement` → the slider's
///    `increase` / `decrease` semantics actions.
class FocusKeyboardPage extends StatefulWidget {
  const FocusKeyboardPage({super.key});

  @override
  State<FocusKeyboardPage> createState() => _FocusKeyboardPageState();
}

class _FocusKeyboardPageState extends State<FocusKeyboardPage> {
  static const String _topFieldName = 'Top Username Field';
  static const String _sliderName = 'Benchmark Slider';
  static const String _bottomFieldName = 'Bottom Password Field';

  // Pre-filled so deleting the last character benchmarks the empty-field
  // placeholder announcement.
  final TextEditingController _topController = TextEditingController(text: 'A');
  final TextEditingController _bottomController = TextEditingController();
  final FocusNode _topFocus = FocusNode(debugLabel: _topFieldName);
  final FocusNode _sliderFocus = FocusNode(debugLabel: _sliderName);
  final FocusNode _bottomFocus = FocusNode(debugLabel: _bottomFieldName);

  final List<String> _logEntries = <String>[];
  double _sliderValue = 0.25;
  bool _sliderDragging = false;

  @override
  void initState() {
    super.initState();
    _topFocus.addListener(() => _handleFocusNodeChange(_topFocus));
    _sliderFocus.addListener(() => _handleFocusNodeChange(_sliderFocus));
    _bottomFocus.addListener(() => _handleFocusNodeChange(_bottomFocus));
    _topController.addListener(
      () => _handleTextChanged(_topFieldName, _topController, 'Enter username'),
    );
    _bottomController.addListener(
      () => _handleTextChanged(_bottomFieldName, _bottomController, 'Password'),
    );
    FocusManager.instance.addListener(_handlePrimaryFocusChange);
    A11yActionObserver.instance.addListener(_handleA11yAction);
    _appendLog(
      'Ready. Top field pre-filled, slider at 25%, bottom field is secure.',
    );
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handlePrimaryFocusChange);
    A11yActionObserver.instance.removeListener(_handleA11yAction);
    _topController.dispose();
    _bottomController.dispose();
    _topFocus.dispose();
    _sliderFocus.dispose();
    _bottomFocus.dispose();
    super.dispose();
  }

  void _appendLog(String entry) {
    debugPrint('[FocusKeyboard] $entry');
    if (!mounted) {
      return;
    }
    setState(() => _logEntries.add(entry));
  }

  void _handleFocusNodeChange(FocusNode node) {
    final String name = node.debugLabel ?? 'control';
    _appendLog(
      node.hasFocus
          ? 'becomeFirstResponder (FocusNode gained): $name'
          : 'resignFirstResponder (FocusNode lost): $name',
    );
  }

  void _handlePrimaryFocusChange() {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    final String description = primary == null
        ? 'none'
        : primary.debugLabel ?? primary.toStringShort();
    _appendLog('didUpdateFocusIn (FKA primaryFocus): $description');
  }

  void _handleA11yAction() {
    final A11yActionRecord? record = A11yActionObserver.instance.latest;
    if (record == null) {
      return;
    }
    _appendLog('VO action ${record.action.name}: ${record.description}');
  }

  void _handleTextChanged(
    String name,
    TextEditingController controller,
    String placeholder,
  ) {
    _appendLog(
      "$name text changed (isEmpty=${controller.text.isEmpty}, "
      "placeholder='$placeholder')",
    );
  }

  void _handleSliderChanged(double value) {
    setState(() => _sliderValue = value);
    final String source = _sliderDragging
        ? 'drag'
        : 'accessibilityIncrement/Decrement or keyboard arrow';
    _appendLog(
      'Slider valueChanged: ${value.toStringAsFixed(2)} '
      '(${(value * 100).round()}%) via $source',
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus & Keyboard'),
        actions: <Widget>[
          A11yProbe(
            identifier: 'focus.dismissKeyboardButton',
            mergeDescendants: true,
            child: TextButton(
              onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: const Text('Dismiss Keyboard'),
            ),
          ),
        ],
      ),
      body: Semantics(
        container: true,
        identifier: 'focus.scrollView',
        child: SingleChildScrollView(
          primary: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SectionLabel('Top Input Region (Pre-filled + Placeholder)'),
              A11yProbe(
                identifier: 'focus.topTextField',
                container: true,
                trackFocus: false,
                child: TextField(
                  controller: _topController,
                  focusNode: _topFocus,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Enter username',
                    border: OutlineInputBorder(),
                    suffixIcon: _ClearButtonPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Intermediate Slider (Initial Value 25%)'),
              A11yProbe(
                identifier: 'focus.sliderValueLabel',
                container: true,
                child: Text(
                  'Slider Value: ${_sliderValue.toStringAsFixed(2)} '
                  '(${(_sliderValue * 100).round()}%)',
                  style: textTheme.bodyMedium?.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              // Slider is a semantics boundary of its own, so the identifier
              // is merged onto it with MergeSemantics rather than nested.
              MergeSemantics(
                child: A11yProbe(
                  identifier: 'focus.slider',
                  trackFocus: false,
                  child: Slider(
                    value: _sliderValue,
                    focusNode: _sliderFocus,
                    onChanged: _handleSliderChanged,
                    onChangeStart: (_) => _sliderDragging = true,
                    onChangeEnd: (_) => _sliderDragging = false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Responder, VoiceOver & FKA Focus Log'),
              // Tall log region: keeps the top and bottom fields far enough
              // apart that reaching the bottom one requires scrolling.
              A11yProbe(
                identifier: 'focus.eventLog',
                container: true,
                trackFocus: false,
                child: Container(
                  height: 520,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: Text(
                      _logEntries.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'Menlo',
                        fontFamilyFallback: <String>['Courier', 'monospace'],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Bottom Input Region (Secure Text Entry)'),
              A11yProbe(
                identifier: 'focus.bottomTextField',
                container: true,
                trackFocus: false,
                child: TextField(
                  controller: _bottomController,
                  focusNode: _bottomFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Keeps the trailing area of the top field visually similar to UIKit's
/// `clearButtonMode = .whileEditing` without adding an extra focusable control.
class _ClearButtonPlaceholder extends StatelessWidget {
  const _ClearButtonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(child: Icon(Icons.cancel_outlined, size: 18));
  }
}
