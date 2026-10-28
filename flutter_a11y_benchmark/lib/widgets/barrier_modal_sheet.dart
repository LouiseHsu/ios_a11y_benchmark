import 'package:cupertino_ui/cupertino_ui.dart';

import '../a11y/a11y_probe.dart';

/// Presents [BarrierModalSheet] using [showCupertinoSheet], the Cupertino twin
/// of UIKit's `UISheetPresentationController` (`BarrierModalSheetViewController`):
///
///  * `prefersGrabberVisible = true` → `showDragHandle: true`,
///  * `accessibilityViewIsModal = true` → the modal route's barrier uses
///    [BlockSemantics], hiding every route underneath from assistive tech.
Future<void> showBarrierModalSheet(BuildContext context) {
  return showCupertinoSheet<void>(
    context: context,
    showDragHandle: true,
    scrollableBuilder: (BuildContext context, ScrollController scrollController) {
      return BarrierModalSheet(scrollController: scrollController);
    },
  );
}

/// Content of the modal barrier sheet.
///
/// UIKit twin: `BarrierModalSheetViewController`.
class BarrierModalSheet extends StatefulWidget {
  const BarrierModalSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<BarrierModalSheet> createState() => _BarrierModalSheetState();
}

class _BarrierModalSheetState extends State<BarrierModalSheet> {
  String _title = 'Modal Barrier Active';

  @override
  Widget build(BuildContext context) {
    final CupertinoTextThemeData textTheme = CupertinoTheme.of(
      context,
    ).textTheme;
    final Color secondaryLabelColor = CupertinoColors.secondaryLabel
        .resolveFrom(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: A11yProbe(
          identifier: 'modal.sheetContainer',
          container: true,
          explicitChildNodes: true,
          trackFocus: false,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                A11yProbe(
                  identifier: 'modal.sheetTitle',
                  container: true,
                  header: true,
                  child: Text(
                    _title,
                    style: textTheme.navLargeTitleTextStyle.copyWith(
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                A11yProbe(
                  identifier: 'modal.sheetDescription',
                  container: true,
                  child: Text(
                    'Presented as a CupertinoSheetRoute (BlockSemantics '
                    'barrier ≈ accessibilityViewIsModal = true) with a '
                    'native-styled drag handle (showDragHandle: true).',
                    style: textTheme.textStyle.copyWith(
                      color: secondaryLabelColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                A11yProbe(
                  identifier: 'modal.sheetActionButton',
                  mergeDescendants: true,
                  child: CupertinoButton.tinted(
                    onPressed: () =>
                        setState(() => _title = 'Modal Action Triggered'),
                    child: const Text('Modal Sheet Action'),
                  ),
                ),
                const SizedBox(height: 16),
                A11yProbe(
                  identifier: 'modal.dismissButton',
                  mergeDescendants: true,
                  child: CupertinoButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Dismiss Modal Sheet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
