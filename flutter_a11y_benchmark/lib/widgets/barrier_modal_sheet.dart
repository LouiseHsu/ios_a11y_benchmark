import 'package:material_ui/material_ui.dart';

import '../a11y/a11y_probe.dart';

/// Presents [BarrierModalSheet] the way the UIKit twin presents
/// `BarrierModalSheetViewController`:
///
///  * `UISheetPresentationController.detents = [.medium(), .large()]`
///    → [DraggableScrollableSheet] snapping between 50% and 100%,
///  * `prefersGrabberVisible = true` → `showDragHandle: true`,
///  * `accessibilityViewIsModal = true` → the modal route's barrier uses
///    [BlockSemantics], hiding every route underneath from assistive tech.
Future<void> showBarrierModalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5, // .medium()
        minChildSize: 0.5,
        maxChildSize: 1.0, // .large()
        snap: true,
        builder: (BuildContext context, ScrollController scrollController) {
          return BarrierModalSheet(scrollController: scrollController);
        },
      );
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    return A11yProbe(
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
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            A11yProbe(
              identifier: 'modal.sheetDescription',
              container: true,
              child: Text(
                'Presented as a modal route (BlockSemantics barrier ≈ '
                'accessibilityViewIsModal = true) inside a draggable sheet '
                'snapping between 50% and 100% with a visible drag handle.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  setState(() => _title = 'Modal Action Triggered'),
              child: const A11yProbe(
                identifier: 'modal.sheetActionButton',
                child: Text('Modal Sheet Action'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const A11yProbe(
                identifier: 'modal.dismissButton',
                child: Text('Dismiss Modal Sheet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
