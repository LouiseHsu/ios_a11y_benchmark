import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../a11y/a11y_probe.dart';

/// 100-row list with a pinned metrics header.
///
/// UIKit twin: `ScrollBaselineViewController`. The header shows
/// `contentOffset.y`, `frame.size.height`, the per-gesture scroll delta (Δy),
/// `Δy / viewportHeight` (native VoiceOver page scrolls move ~100% of the
/// viewport, Flutter's semantic scroll actions move 80%), and the computed
/// "Page X of Y" status. iOS lets `UIScrollViewAccessibilityDelegate` feed
/// that status into `UIAccessibilityPageScrolledNotification`; Flutter's iOS
/// embedder posts that notification with an empty string, so here the status
/// is only displayed — which is exactly the gap this screen benchmarks.
class ScrollBaselinePage extends StatefulWidget {
  const ScrollBaselinePage({super.key});

  @override
  State<ScrollBaselinePage> createState() => _ScrollBaselinePageState();
}

class _ScrollBaselinePageState extends State<ScrollBaselinePage> {
  static const int rowCount = 100;
  static const double rowHeight = 60;

  double _contentOffsetY = 0;
  double _viewportHeight = 0;
  double _contentHeight = 0;
  double _deltaY = 0;
  double _stepDeltaY = 0;
  double _gestureStartOffsetY = 0;
  double _previousFrameOffsetY = 0;
  String _scrollSource = 'none';

  double get _ratio => _viewportHeight > 0 ? _deltaY / _viewportHeight : 0;

  int get _totalPages {
    if (_viewportHeight <= 0) {
      return 1;
    }
    final double contentHeight = math.max(_contentHeight, _viewportHeight);
    return math.max(1, (contentHeight / _viewportHeight).ceil());
  }

  int get _currentPage {
    if (_viewportHeight <= 0) {
      return 1;
    }
    final int page =
        ((_contentOffsetY + _viewportHeight * 0.5) / _viewportHeight).floor() +
        1;
    return math.min(_totalPages, math.max(1, page));
  }

  String get _pageStatus => 'Page $_currentPage of $_totalPages';

  bool _handleMetricsNotification(ScrollMetricsNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    setState(() {
      _contentOffsetY = metrics.pixels;
      _viewportHeight = metrics.viewportDimension;
      _contentHeight = metrics.maxScrollExtent + metrics.viewportDimension;
    });
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (notification is ScrollStartNotification) {
      // scrollViewWillBeginDragging / accessibilityScroll(_:) twin.
      _gestureStartOffsetY = metrics.pixels;
      _scrollSource = notification.dragDetails != null
          ? 'drag'
          : 'programmatic/a11y';
      return false;
    }
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }

    final double currentOffsetY = metrics.pixels;
    final double stepDeltaY = currentOffsetY - _previousFrameOffsetY;
    _previousFrameOffsetY = currentOffsetY;
    final double deltaY = currentOffsetY - _gestureStartOffsetY;

    setState(() {
      _contentOffsetY = currentOffsetY;
      _viewportHeight = metrics.viewportDimension;
      _contentHeight = metrics.maxScrollExtent + metrics.viewportDimension;
      _deltaY = deltaY;
      _stepDeltaY = stepDeltaY;
    });

    debugPrint(
      '[ScrollBaseline] contentOffset.y=${currentOffsetY.toStringAsFixed(1)} '
      'frame.size.height=${_viewportHeight.toStringAsFixed(1)} '
      'Δy=${deltaY.toStringAsFixed(1)} ratio=${_ratio.toStringAsFixed(3)} '
      'source=$_scrollSource',
    );
    if (notification is ScrollEndNotification) {
      debugPrint('[ScrollBaseline] scroll ended → $_pageStatus');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scroll Baseline')),
      body: Column(
        children: <Widget>[
          _MetricsHeader(
            contentOffsetY: _contentOffsetY,
            viewportHeight: _viewportHeight,
            deltaY: _deltaY,
            stepDeltaY: _stepDeltaY,
            ratio: _ratio,
            pageStatus: _pageStatus,
          ),
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: _handleMetricsNotification,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: Semantics(
                  container: true,
                  identifier: 'scroll.tableView',
                  child: ListView.builder(
                    // Attached to the PrimaryScrollController so the iOS
                    // status-bar tap scrolls *this* list (UIKit: scrollsToTop).
                    primary: true,
                    itemExtent: rowHeight,
                    itemCount: rowCount,
                    itemBuilder: (BuildContext context, int index) =>
                        _BaselineRow(index: index),
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

class _MetricsHeader extends StatelessWidget {
  const _MetricsHeader({
    required this.contentOffsetY,
    required this.viewportHeight,
    required this.deltaY,
    required this.stepDeltaY,
    required this.ratio,
    required this.pageStatus,
  });

  final double contentOffsetY;
  final double viewportHeight;
  final double deltaY;
  final double stepDeltaY;
  final double ratio;
  final String pageStatus;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      identifier: 'scroll.headerView',
      child: Material(
        color: colorScheme.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _MetricLabel(
                    identifier: 'scroll.offsetYLabel',
                    text:
                        'contentOffset.y: ${contentOffsetY.toStringAsFixed(1)}',
                    value: contentOffsetY.toStringAsFixed(1),
                  ),
                  _MetricLabel(
                    identifier: 'scroll.heightLabel',
                    text:
                        'frame.size.height: ${viewportHeight.toStringAsFixed(1)}',
                    value: viewportHeight.toStringAsFixed(1),
                  ),
                  _MetricLabel(
                    identifier: 'scroll.deltaLabel',
                    text:
                        'Δy: ${deltaY.toStringAsFixed(1)} '
                        '(step: ${stepDeltaY.toStringAsFixed(1)})',
                    value: deltaY.toStringAsFixed(1),
                  ),
                  _MetricLabel(
                    identifier: 'scroll.ratioLabel',
                    text:
                        'Δy / viewportHeight: ${ratio.toStringAsFixed(3)} '
                        '(${(ratio * 100).toStringAsFixed(1)}%)',
                    value: ratio.toStringAsFixed(3),
                  ),
                  _MetricLabel(
                    identifier: 'scroll.pageScrolledLabel',
                    text: 'Page Scroll Status: $pageStatus',
                    value: pageStatus,
                    secondary: true,
                  ),
                  const SizedBox(height: 8),
                  const _SecondaryTagStrip(),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}

/// Instrumented label: text + `accessibilityValue` + identifier, like the
/// monospaced `UILabel`s in the UIKit header.
class _MetricLabel extends StatelessWidget {
  const _MetricLabel({
    required this.identifier,
    required this.text,
    required this.value,
    this.secondary = false,
  });

  final String identifier;
  final String text;
  final String value;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: A11yProbe(
        identifier: identifier,
        container: true,
        value: value,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            color: secondary
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Secondary nested horizontal scroll view.
///
/// UIKit twin sets `scrollsToTop = false` so a status-bar tap deterministically
/// targets the primary table view. Flutter's equivalent is `primary: false`
/// (not attached to the [PrimaryScrollController]).
class _SecondaryTagStrip extends StatelessWidget {
  const _SecondaryTagStrip();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      identifier: 'scroll.secondaryScrollView',
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: 8,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) {
            final int number = index + 1;
            return A11yProbe(
              identifier: 'scroll.secondaryChip.$number',
              container: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tag #$number (primary: false)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One fixed-height row; `MergeSemantics` makes it a single element like a
/// `UITableViewCell` with a default content configuration.
class _BaselineRow extends StatelessWidget {
  const _BaselineRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return MergeSemantics(
      child: A11yProbe(
        identifier: 'scroll.cell.$index',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Item #$index', style: theme.textTheme.bodyLarge),
              Text(
                'Baseline scroll row ${index + 1} of '
                '${_ScrollBaselinePageState.rowCount}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
