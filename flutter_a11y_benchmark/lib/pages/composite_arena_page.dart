import 'package:material_ui/material_ui.dart';

import '../a11y/a11y_probe.dart';
import '../widgets/barrier_modal_sheet.dart';

/// Scrollable list of text inputs with a floating control bar that is *later*
/// in the widget tree but *visually above* the list, plus a button that
/// unfocuses the active field while presenting an alert in the same frame.
///
/// UIKit twin: `CompositeArenaViewController`.
class CompositeArenaPage extends StatefulWidget {
  const CompositeArenaPage({super.key});

  @override
  State<CompositeArenaPage> createState() => _CompositeArenaPageState();
}

class _CompositeArenaPageState extends State<CompositeArenaPage> {
  static const int rowCount = 24;
  static const double rowHeight = 60;
  static const double floatingBarInset = 108;

  late final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
        rowCount,
        (_) => TextEditingController(),
      );
  late final List<FocusNode> _focusNodes = List<FocusNode>.generate(
    rowCount,
    (int index) => FocusNode(debugLabel: 'Composite Input $index'),
  );

  int? _activeRow;

  @override
  void initState() {
    super.initState();
    for (int index = 0; index < rowCount; index += 1) {
      _focusNodes[index].addListener(() => _handleRowFocusChange(index));
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleRowFocusChange(int index) {
    if (_focusNodes[index].hasFocus) {
      _activeRow = index;
    } else if (_activeRow == index) {
      _activeRow = null;
    }
  }

  Future<void> _launchFloatingModal() async {
    debugPrint(
      '[CompositeArena] Launching modal sheet from floating top button',
    );
    await showBarrierModalSheet(context);
  }

  /// Twin of the UIKit "Resign FirstResponder & Present Alert" action: drops
  /// keyboard focus (`resignFirstResponder()`) and presents an alert in the
  /// same run-loop turn so the keyboard-dismiss and modal-present animations
  /// overlap while accessibility frames are being updated.
  void _resignFirstResponderAndPresentAlert() {
    final bool didResign = _activeRow != null;
    final int? resignedRow = _activeRow;
    FocusManager.instance.primaryFocus?.unfocus();

    debugPrint(
      '[CompositeArena] Concurrent unfocus (didResign=$didResign, '
      'row=$resignedRow) + present alert',
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return A11yProbe(
          identifier: 'composite.concurrentAlert',
          container: true,
          explicitChildNodes: true,
          trackFocus: false,
          child: AlertDialog(
            title: const Text('Concurrent Keyboard Dismiss & Modal'),
            content: Text(
              'Presented simultaneously with unfocus() '
              '(didResign=$didResign).',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const A11yProbe(
                  identifier: 'composite.alertOkButton',
                  child: Text('OK'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Composite Arena')),
      body: Stack(
        children: <Widget>[
          // 1. The list comes first in the tree (like `addSubview` order).
          Semantics(
            container: true,
            identifier: 'composite.tableView',
            child: ListView.builder(
              primary: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // Inset the content so rows start below the floating bar.
              padding: const EdgeInsets.only(top: floatingBarInset, bottom: 24),
              itemExtent: rowHeight,
              itemCount: rowCount,
              itemBuilder: (BuildContext context, int index) {
                return _CompositeTextInputRow(
                  index: index,
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                );
              },
            ),
          ),
          // 2. The floating bar is added last but positioned at the very top,
          //    testing visual vs. tree focus order.
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Semantics(
              container: true,
              identifier: 'composite.floatingTopBar',
              child: Material(
                elevation: 2,
                color: colorScheme.surfaceContainer.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton(
                        onPressed: _launchFloatingModal,
                        child: const A11yProbe(
                          identifier: 'composite.launchModalButton',
                          child: Text('Floating Modal Launcher (Top Visual)'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _resignFirstResponderAndPresentAlert,
                        child: const A11yProbe(
                          identifier: 'composite.resignAndPresentButton',
                          child: Text('Resign FirstResponder & Present Alert'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row with a caption and a text field; both are separate elements, like
/// the `UILabel` + `UITextField` inside `CompositeTextInputCell`.
class _CompositeTextInputRow extends StatelessWidget {
  const _CompositeTextInputRow({
    required this.index,
    required this.controller,
    required this.focusNode,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: 'composite.cell.$index',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: <Widget>[
            Semantics(
              container: true,
              child: Text(
                'Field #$index',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: A11yProbe(
                identifier: 'composite.textField.$index',
                container: true,
                trackFocus: false,
                label: 'Composite Input $index',
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Enter text for row $index',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
