import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/semantics.dart';

/// Scrollable form with a pre-filled username field, a 25% slider, a tall
/// status panel, and a secure password field.
///
/// UIKit twin: `FocusKeyboardViewController`.
///
/// Focus transitions (responder, VoiceOver, Full Keyboard Access) are observed
/// by the QA tester directly with the assistive technology; the app only shows
/// its own state: the latest text / slider / announcement event in the status
/// panel, and the live-region status line.
class FocusKeyboardPage extends StatefulWidget {
  const FocusKeyboardPage({super.key});

  @override
  State<FocusKeyboardPage> createState() => _FocusKeyboardPageState();
}

class _FocusKeyboardPageState extends State<FocusKeyboardPage> {
  static const String _topFieldName = 'Top Username Field';
  static const String _bottomFieldName = 'Bottom Password Field';

  // Pre-filled so deleting the last character benchmarks the empty-field
  // placeholder announcement.
  final TextEditingController _topController = TextEditingController(text: 'A');
  final TextEditingController _bottomController = TextEditingController();
  final FocusNode _topFocus = FocusNode(debugLabel: _topFieldName);
  final FocusNode _bottomFocus = FocusNode(debugLabel: _bottomFieldName);

  String _lastEvent =
      'Ready. Top field pre-filled, slider at 25%, bottom field is secure.';
  double _sliderValue = 0.25;
  bool _sliderDragging = false;
  String _liveStatus = 'Live Status: Username length 1 chars';
  int _announcementCount = 0;

  @override
  void initState() {
    super.initState();
    _topController.addListener(
      () => _handleTextChanged(_topFieldName, _topController, 'Enter username'),
    );
    _bottomController.addListener(
      () => _handleTextChanged(_bottomFieldName, _bottomController, 'Password'),
    );
  }

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    _topFocus.dispose();
    _bottomFocus.dispose();
    super.dispose();
  }

  void _setLastEvent(String entry) {
    debugPrint('[FocusKeyboard] $entry');
    if (!mounted) {
      return;
    }
    setState(() => _lastEvent = entry);
  }

  void _handleTextChanged(
    String name,
    TextEditingController controller,
    String placeholder,
  ) {
    final String text = controller.text;
    _setLastEvent(
      "$name text changed (isEmpty=${text.isEmpty}, "
      "placeholder='$placeholder')",
    );
    if (identical(controller, _topController) && mounted) {
      final String statusMessage =
          'Live Status: Username length ${text.length} chars';
      setState(() => _liveStatus = statusMessage);
      SemanticsService.sendAnnouncement(
        View.of(context),
        statusMessage,
        Directionality.of(context),
      );
    }
  }

  void _postPoliteAnnouncement() {
    _announcementCount += 1;
    final String message =
        'Live Status: Polite Announcement #$_announcementCount';
    setState(() => _liveStatus = message);
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
    _setLastEvent('Posted polite announcement #$_announcementCount');
  }

  void _handleSliderChanged(double value) {
    setState(() => _sliderValue = value);
    final String source = _sliderDragging
        ? 'drag'
        : 'accessibilityIncrement/Decrement or keyboard arrow';
    _setLastEvent(
      'Slider valueChanged: ${value.toStringAsFixed(2)} '
      '(${(value * 100).round()}%) via $source',
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle bodyStyle = CupertinoTheme.of(context).textTheme.textStyle;
    final Color secondaryLabelColor = CupertinoColors.secondaryLabel
        .resolveFrom(context);
    final Color logBackground = CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Focus & Keyboard'),
        previousPageTitle: 'Flutter A11y Benchmark',
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: const Text('Dismiss Keyboard'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          primary: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SectionLabel(
                'Top Input Region (Pre-filled + Placeholder)',
              ),
              // UITextField(clearButtonMode = .whileEditing) twin.
              CupertinoTextField(
                controller: _topController,
                focusNode: _topFocus,
                placeholder: 'Enter username',
                clearButtonMode: OverlayVisibilityMode.editing,
                textInputAction: TextInputAction.done,
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 12),
              // Live region: UIKit twin posts `UIAccessibility.Notification
              // .announcement` / marks the label as a live status.
              Semantics(
                liveRegion: true,
                child: Text(
                  _liveStatus,
                  style: bodyStyle.copyWith(
                    fontSize: 14,
                    color: secondaryLabelColor,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton.tinted(
                onPressed: _postPoliteAnnouncement,
                child: const Text('Post Polite Announcement'),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Intermediate Slider (Initial Value 25%)'),
              Text(
                'Slider Value: ${_sliderValue.toStringAsFixed(2)} '
                '(${(_sliderValue * 100).round()}%)',
                style: bodyStyle.copyWith(
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              CupertinoSlider(
                value: _sliderValue,
                onChanged: _handleSliderChanged,
                onChangeStart: (_) => _sliderDragging = true,
                onChangeEnd: (_) => _sliderDragging = false,
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Last App Event'),
              // Tall status panel: keeps the top and bottom fields far enough
              // apart that reaching the bottom one requires scrolling. Shows
              // only the latest app-state event (text / slider / announcement).
              Container(
                height: 520,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: logBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  primary: false,
                  child: Text(
                    _lastEvent,
                    style: bodyStyle.copyWith(
                      fontFamily: 'Menlo',
                      fontFamilyFallback: const <String>[
                        'Courier',
                        'monospace',
                      ],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Bottom Input Region (Secure Text Entry)'),
              CupertinoTextField(
                controller: _bottomController,
                focusNode: _bottomFocus,
                obscureText: true,
                placeholder: 'Password',
                textInputAction: TextInputAction.done,
                padding: const EdgeInsets.all(12),
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
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: titleStyle),
    );
  }
}
