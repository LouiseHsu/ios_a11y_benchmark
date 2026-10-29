import 'package:cupertino_ui/cupertino_ui.dart';
// Material is imported with a prefix so that the Material date/time picker
// dialogs (the widgets the audited issues are filed against) can be presented
// without any name collisions with the Cupertino widgets used elsewhere here.
import 'package:flutter/material.dart' as material;

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
            A11yProbe(
              identifier: 'modal.alertCancelButton',
              mergeDescendants: true,
              child: CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop('Cancel'),
                child: const Text('Cancel'),
              ),
            ),
            A11yProbe(
              identifier: 'modal.alertConfirmButton',
              mergeDescendants: true,
              child: CupertinoDialogAction(
                isDefaultAction: true,
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
      '[ModalBarrier] Presenting Cupertino modal sheet '
      '(showDragHandle: true)',
    );
    await showBarrierModalSheet(context);
    if (mounted) {
      _setStatus('Modal Sheet Dismissed');
    }
  }

  static const List<String> _monthAbbreviations = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats like the UIKit twin's `DateFormatter(dateStyle: .medium)` in
  /// en_US, e.g. "Jan 15, 2026", without pulling in package:intl.
  static String _formatDate(DateTime date) {
    return '${_monthAbbreviations[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Material date picker (issue family #194657 / #186043: DatePicker
  /// expanded/collapsed and selected-day semantics). UIKit twin presents a
  /// sheet with an inline UIDatePicker (.date, .inline).
  Future<void> _presentDatePicker() async {
    debugPrint('[ModalBarrier] Presenting Material showDatePicker');
    final DateTime? picked = await material.showDatePicker(
      context: context,
      initialDate: DateTime(2026, 1, 15),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return A11yProbe(
          identifier: 'modal.datePicker',
          container: true,
          trackFocus: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (picked == null) {
      _setStatus('Date Picker: Cancelled');
    } else {
      _setStatus('Date Picker: ${_formatDate(picked)}');
    }
  }

  /// Material time picker (issue #173302: AM/PM state not announced). UIKit
  /// twin presents a sheet with a UIDatePicker (.time, .wheels, en_US).
  Future<void> _presentTimePicker() async {
    debugPrint('[ModalBarrier] Presenting Material showTimePicker');
    final material.TimeOfDay? picked = await material.showTimePicker(
      context: context,
      initialTime: const material.TimeOfDay(hour: 9, minute: 30),
      builder: (BuildContext context, Widget? child) {
        return A11yProbe(
          identifier: 'modal.timePicker',
          container: true,
          trackFocus: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (picked == null) {
      _setStatus('Time Picker: Cancelled');
    } else {
      // TimeOfDay.format uses MaterialLocalizations (en_US → "9:30 AM"),
      // matching the UIKit twin's DateFormatter(timeStyle: .short).
      _setStatus('Time Picker: ${picked.format(context)}');
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
                    A11yProbe(
                      identifier: 'modal.statusLabel',
                      container: true,
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    A11yProbe(
                      identifier: 'modal.backgroundButton1',
                      mergeDescendants: true,
                      child: CupertinoButton.tinted(
                        onPressed: () => _backgroundButtonTapped(1),
                        child: const Text('Background Button 1'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    A11yProbe(
                      identifier: 'modal.backgroundButton2',
                      mergeDescendants: true,
                      child: CupertinoButton.tinted(
                        onPressed: () => _backgroundButtonTapped(2),
                        child: const Text('Background Button 2'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Contrasts an overlay-portal anchored popup
                    // (CupertinoMenuAnchor ≈ UIMenu) against a modal-route
                    // barrier (showCupertinoSheet) on the same screen.
                    CupertinoMenuAnchor(
                      menuChildren: <Widget>[
                        for (int i = 0; i < _popupOptions.length; i += 1)
                          A11yProbe(
                            identifier: 'modal.popupOption.$i',
                            mergeDescendants: true,
                            selected: _popupOptions[i] == _selectedPopupOption,
                            child: CupertinoMenuItem(
                              onPressed: () =>
                                  _selectPopupOption(_popupOptions[i]),
                              child: Text(_popupOptions[i]),
                            ),
                          ),
                        // Disabled item (issue #171231: disabled menu item not
                        // announced as "dimmed"). UIKit twin:
                        // UIAction(attributes: .disabled).
                        const A11yProbe(
                          identifier: 'modal.popupOption.disabled',
                          mergeDescendants: true,
                          child: CupertinoMenuItem(
                            onPressed: null,
                            child: Text('Option Delta (Unavailable)'),
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
                              child: CupertinoButton.tinted(
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
                      child: CupertinoButton.tinted(
                        onPressed: _presentAlertDialog,
                        child: const Text('Present Alert Dialog'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    A11yProbe(
                      identifier: 'modal.presentDatePickerButton',
                      mergeDescendants: true,
                      child: CupertinoButton.tinted(
                        onPressed: _presentDatePicker,
                        child: const Text('Present Date Picker'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    A11yProbe(
                      identifier: 'modal.presentTimePickerButton',
                      mergeDescendants: true,
                      child: CupertinoButton.tinted(
                        onPressed: _presentTimePicker,
                        child: const Text('Present Time Picker'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    A11yProbe(
                      identifier: 'modal.presentButton',
                      mergeDescendants: true,
                      child: CupertinoButton.filled(
                        onPressed: _presentModalSheet,
                        child: const Text('Present Modal Sheet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            A11yProbe(
              identifier: 'modal.tabBar',
              container: true,
              explicitChildNodes: true,
              trackFocus: false,
              child: CupertinoTabBar(
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
            ),
          ],
        ),
      ),
    );
  }
}
