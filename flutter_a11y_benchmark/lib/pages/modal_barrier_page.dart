import 'package:cupertino_ui/cupertino_ui.dart';

import '../widgets/barrier_modal_sheet.dart';

/// Interactive background buttons plus a launcher for the modal barrier sheet.
///
/// UIKit twin: `ModalBarrierViewController`. While the sheet is up, the modal
/// route's own barrier hides these buttons from assistive technologies, the
/// same way `accessibilityViewIsModal = true` does natively; nothing extra is
/// annotated here.
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
    debugPrint('[ModalBarrier] Presenting CupertinoAlertDialog');
    final String? result = await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Benchmark Alert Dialog'),
          content: const Text(
            'Tests alert dialog announcement, Voice Control dismissal, and '
            'focus restoration on close.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop('Cancel'),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop('Confirm'),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (mounted && result != null) {
      _setStatus('Alert Dialog: $result');
    }
  }

  /// Action sheet: the one modal with a *dismissible* barrier, so the
  /// ModalBarrier's "Dismiss" semantics element appears (UIKit twin: the
  /// action sheet's backdrop, "Dismiss pop-up").
  Future<void> _presentActionSheet() async {
    debugPrint('[ModalBarrier] Presenting CupertinoActionSheet');
    final String? result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Benchmark Action Sheet'),
          message: const Text('Choose an action.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop('Share'),
              child: const Text('Share'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop('Duplicate'),
              child: const Text('Duplicate'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(sheetContext).pop('Delete'),
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(sheetContext).pop('Cancel'),
            child: const Text('Cancel'),
          ),
        );
      },
    );
    if (mounted) {
      _setStatus('Action Sheet: ${result ?? 'Dismissed'}');
    }
  }

  Future<void> _presentModalSheet() async {
    debugPrint(
      '[ModalBarrier] Presenting Cupertino modal sheet '
      '(showDragHandle: true)',
    );
    await showBarrierModalSheet(context);
    if (mounted) {
      _setStatus('Modal Sheet Dismissed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = CupertinoTheme.of(context)
        .textTheme
        .navTitleTextStyle;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Modal Barrier'),
        previousPageTitle: 'Flutter A11y Benchmark',
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.tinted(
                      onPressed: () => _backgroundButtonTapped(1),
                      child: const Text('Background Button 1'),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.tinted(
                      onPressed: () => _backgroundButtonTapped(2),
                      child: const Text('Background Button 2'),
                    ),
                    const SizedBox(height: 16),
                    // Contrasts an overlay-portal anchored popup
                    // (CupertinoMenuAnchor ≈ UIMenu) against a modal-route
                    // barrier (showCupertinoSheet) on the same screen.
                    CupertinoMenuAnchor(
                      menuChildren: <Widget>[
                        for (int i = 0; i < _popupOptions.length; i += 1)
                          CupertinoMenuItem(
                            onPressed: () =>
                                _selectPopupOption(_popupOptions[i]),
                            child: Text(_popupOptions[i]),
                          ),
                        // Disabled item (issue #171231: disabled menu item not
                        // announced as "dimmed"). UIKit twin:
                        // UIAction(attributes: .disabled).
                        const CupertinoMenuItem(
                          onPressed: null,
                          child: Text('Option Delta (Unavailable)'),
                        ),
                      ],
                      builder:
                          (
                            BuildContext context,
                            MenuController controller,
                            Widget? child,
                          ) {
                            return CupertinoButton.tinted(
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
                            );
                          },
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.tinted(
                      onPressed: _presentAlertDialog,
                      child: const Text('Present Alert Dialog'),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.tinted(
                      onPressed: _presentActionSheet,
                      child: const Text('Present Action Sheet'),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: _presentModalSheet,
                      child: const Text('Present Modal Sheet'),
                    ),
                  ],
                ),
              ),
            ),
            CupertinoTabBar(
              currentIndex: _selectedTabIndex,
              onTap: _selectTab,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.list_bullet),
                  label: 'Overview',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.doc_text),
                  label: 'Details',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
