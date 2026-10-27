import 'package:material_ui/material_ui.dart';

import '../a11y/a11y_probe.dart';
import '../widgets/barrier_modal_sheet.dart';

/// Interactive background buttons plus a launcher for the modal barrier sheet.
///
/// UIKit twin: `ModalBarrierViewController`. While the sheet is up, the modal
/// route's barrier ([BlockSemantics]) hides these buttons from assistive
/// technologies, the same way `accessibilityViewIsModal = true` does natively.
class ModalBarrierPage extends StatefulWidget {
  const ModalBarrierPage({super.key});

  @override
  State<ModalBarrierPage> createState() => _ModalBarrierPageState();
}

class _ModalBarrierPageState extends State<ModalBarrierPage> {
  String _status = 'Background Action Count: 0';
  int _backgroundTapCount = 0;

  void _setStatus(String message) {
    setState(() => _status = message);
    debugPrint('[ModalBarrier] $message');
  }

  void _backgroundButtonTapped(int number) {
    _backgroundTapCount += 1;
    _setStatus(
      'Background Button $number Tapped (Count: $_backgroundTapCount)',
    );
  }

  Future<void> _presentModalSheet() async {
    debugPrint(
      '[ModalBarrier] Presenting draggable modal sheet '
      '(0.5 ↔ 1.0 snap sizes, showDragHandle: true)',
    );
    await showBarrierModalSheet(context);
    if (mounted) {
      _setStatus('Modal Sheet Dismissed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modal Barrier')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            A11yProbe(
              identifier: 'modal.statusLabel',
              container: true,
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _backgroundButtonTapped(1),
              child: const A11yProbe(
                identifier: 'modal.backgroundButton1',
                child: Text('Background Button 1'),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _backgroundButtonTapped(2),
              child: const A11yProbe(
                identifier: 'modal.backgroundButton2',
                child: Text('Background Button 2'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _presentModalSheet,
              child: const A11yProbe(
                identifier: 'modal.presentButton',
                child: Text('Present Modal Sheet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
