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
  static const List<String> _popupOptions = <String>[
    'Option Alpha',
    'Option Beta',
    'Option Gamma',
  ];
  static const List<String> _tabTitles = <String>[
    'Overview',
    'Details',
    'Settings',
  ];

  String _status = 'Background Action Count: 0';
  int _backgroundTapCount = 0;
  String _selectedPopupOption = _popupOptions.first;
  int _selectedTabIndex = 0;

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

  void _selectPopupOption(String option) {
    setState(() => _selectedPopupOption = option);
    _setStatus('Popup Selected: $option');
  }

  void _selectTab(int index) {
    setState(() => _selectedTabIndex = index);
    _setStatus(
      'Selected Tab: ${_tabTitles[index]} (${index + 1} of ${_tabTitles.length})',
    );
  }

  Future<void> _presentAlertDialog() async {
    debugPrint('[ModalBarrier] Presenting AlertDialog');
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Benchmark Alert Dialog'),
          content: const Text(
            'Tests alert dialog announcement, Voice Control dismissal, and '
            'focus restoration on close.',
          ),
          actions: <Widget>[
            A11yProbe(
              identifier: 'modal.alertCancelButton',
              mergeDescendants: true,
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('Cancel'),
                child: const Text('Cancel'),
              ),
            ),
            A11yProbe(
              identifier: 'modal.alertConfirmButton',
              mergeDescendants: true,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop('Confirm'),
                child: const Text('Confirm'),
              ),
            ),
          ],
        );
      },
    );
    if (mounted && result != null) {
      _setStatus('Alert Dialog: $result');
    }
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
      bottomNavigationBar: A11yProbe(
        identifier: 'modal.tabBar',
        container: true,
        explicitChildNodes: true,
        trackFocus: false,
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: _selectTab,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Overview'),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              label: 'Details',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
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
            A11yProbe(
              identifier: 'modal.backgroundButton1',
              mergeDescendants: true,
              child: OutlinedButton(
                onPressed: () => _backgroundButtonTapped(1),
                child: const Text('Background Button 1'),
              ),
            ),
            const SizedBox(height: 16),
            A11yProbe(
              identifier: 'modal.backgroundButton2',
              mergeDescendants: true,
              child: OutlinedButton(
                onPressed: () => _backgroundButtonTapped(2),
                child: const Text('Background Button 2'),
              ),
            ),
            const SizedBox(height: 16),
            // Contrasts an overlay-portal anchored popup (MenuAnchor) against a
            // modal-route barrier (showModalBottomSheet) on the same screen.
            MenuAnchor(
              menuChildren: <Widget>[
                for (int i = 0; i < _popupOptions.length; i += 1)
                  A11yProbe(
                    identifier: 'modal.popupOption.$i',
                    mergeDescendants: true,
                    selected: _popupOptions[i] == _selectedPopupOption,
                    child: MenuItemButton(
                      onPressed: () => _selectPopupOption(_popupOptions[i]),
                      child: Text(_popupOptions[i]),
                    ),
                  ),
              ],
              builder:
                  (
                    BuildContext context,
                    MenuController controller,
                    Widget? child,
                  ) {
                    return A11yProbe(
                      identifier: 'modal.popupMenuButton',
                      mergeDescendants: true,
                      value: _selectedPopupOption,
                      child: FilledButton.tonal(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: Text(
                          'Anchored Popup Menu: $_selectedPopupOption',
                        ),
                      ),
                    );
                  },
            ),
            const SizedBox(height: 16),
            A11yProbe(
              identifier: 'modal.presentAlertButton',
              mergeDescendants: true,
              child: FilledButton.tonal(
                onPressed: _presentAlertDialog,
                child: const Text('Present Alert Dialog'),
              ),
            ),
            const SizedBox(height: 16),
            A11yProbe(
              identifier: 'modal.presentButton',
              mergeDescendants: true,
              child: FilledButton(
                onPressed: _presentModalSheet,
                child: const Text('Present Modal Sheet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
