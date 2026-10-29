import 'package:cupertino_ui/cupertino_ui.dart';

import '../a11y/a11y_probe.dart';

/// Second scrolling fixture: a `CustomScrollView` whose header is a collapsing
/// `CupertinoSliverNavigationBar`, followed by a 60-row `SliverList`, a
/// `SliverFillRemaining` footer, and a floating circular `CupertinoButton`
/// layered over the list.
///
/// UIKit twin: `SliverScrollViewController` — a plain `UITableView` under a
/// large-title navigation bar (`prefersLargeTitles = true`), with a
/// `tableFooterView` and a floating circular compose `UIButton`.
///
/// Targets:
///  * flutter/flutter#143437 — VoiceOver cannot get back to the sliver
///    navigation bar once it has scrolled off / collapsed.
///  * flutter/flutter#142065 — VoiceOver cannot navigate into the bottom
///    sliver (`SliverFillRemaining`).
///  * flutter/flutter#184077 — Full Keyboard Access tab order of a floating
///    action button layered over a long list.
///  * flutter/flutter#179687 — a resizing header captures accessibility focus
///    while it animates.
class SliverScrollPage extends StatefulWidget {
  const SliverScrollPage({super.key});

  @override
  State<SliverScrollPage> createState() => _SliverScrollPageState();
}

class _SliverScrollPageState extends State<SliverScrollPage> {
  static const int rowCount = 60;
  static const double rowHeight = 60;
  static const double fabDiameter = 56;

  int _fabTapCount = 0;
  int _footerTapCount = 0;

  void _handleFabPressed() {
    setState(() {
      _fabTapCount++;
    });
    debugPrint('[SliverScroll] Compose FAB Tapped (Count: $_fabTapCount)');
  }

  void _handleFooterPressed() {
    setState(() {
      _footerTapCount++;
    });
    debugPrint('[SliverScroll] Footer Action Tapped (Count: $_footerTapCount)');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: <Widget>[
          Semantics(
            container: true,
            identifier: 'sliver.list',
            child: CustomScrollView(
              // Attached to the PrimaryScrollController so the iOS status-bar
              // tap scrolls *this* list (UIKit: scrollsToTop).
              primary: true,
              slivers: <Widget>[
                const CupertinoSliverNavigationBar(
                  previousPageTitle: 'Flutter A11y Benchmark',
                  largeTitle: Text('Sliver Scroll'),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) =>
                        _SliverRow(index: index),
                    childCount: rowCount,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SliverFooter(
                    tapCount: _footerTapCount,
                    onPressed: _handleFooterPressed,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              left: false,
              child: A11yProbe(
                identifier: 'sliver.fab',
                mergeDescendants: true,
                label: 'Compose',
                child: SizedBox(
                  width: fabDiameter,
                  height: fabDiameter,
                  child: CupertinoButton.filled(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(fabDiameter / 2),
                    onPressed: _handleFabPressed,
                    child: const ExcludeSemantics(
                      child: Icon(CupertinoIcons.add, size: 24),
                    ),
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

/// One fixed-height row; `MergeSemantics` makes it a single element like a
/// `UITableViewCell` with a default content configuration. Rows are 1-based
/// ("Sliver Item 1" … "Sliver Item 60") on both platforms.
class _SliverRow extends StatelessWidget {
  const _SliverRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final int itemNumber = index + 1;
    final Color separatorColor = CupertinoColors.separator.resolveFrom(context);
    final Color primaryColor = CupertinoColors.label.resolveFrom(context);
    return MergeSemantics(
      child: A11yProbe(
        identifier: 'sliver.row.$itemNumber',
        child: Container(
          height: _SliverScrollPageState.rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: separatorColor, width: 0.5),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            'Sliver Item $itemNumber',
            style: TextStyle(fontSize: 17, color: primaryColor),
          ),
        ),
      ),
    );
  }
}

/// Footer shown by `SliverFillRemaining`: a heading plus a button, the twin of
/// the UIKit `tableFooterView`. Extra bottom padding keeps the button clear of
/// the FloatingActionButton.
class _SliverFooter extends StatelessWidget {
  const _SliverFooter({required this.tapCount, required this.onPressed});

  final int tapCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(
      context,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            A11yProbe(
              identifier: 'sliver.footerHeader',
              header: true,
              child: const Text(
                'End of List',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            A11yProbe(
              identifier: 'sliver.footerButton',
              mergeDescendants: true,
              child: CupertinoButton.filled(
                onPressed: onPressed,
                child: const Text('Footer Action'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Footer Action taps: $tapCount',
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
