import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';

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
  static const double rowHeight = 72;

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
      'deltaY=${deltaY.toStringAsFixed(1)} ratio=${_ratio.toStringAsFixed(3)} '
      'source=$_scrollSource',
    );
    if (notification is ScrollEndNotification) {
      debugPrint('[ScrollBaseline] scroll ended → $_pageStatus');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scroll Baseline'),
        previousPageTitle: 'Flutter A11y Benchmark',
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
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
                  child: CupertinoScrollbar(
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
    final Color backgroundColor = CupertinoColors
        .secondarySystemGroupedBackground
        .resolveFrom(context);
    final Color separatorColor = CupertinoColors.separator.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: separatorColor, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _MetricLabel(
              text: 'contentOffset.y: ${contentOffsetY.toStringAsFixed(1)}',
            ),
            _MetricLabel(
              text: 'frame.size.height: ${viewportHeight.toStringAsFixed(1)}',
            ),
            _MetricLabel(
              text:
                  'deltaY: ${deltaY.toStringAsFixed(1)} '
                  '(step: ${stepDeltaY.toStringAsFixed(1)})',
            ),
            _MetricLabel(
              text:
                  'deltaY / viewportHeight: ${ratio.toStringAsFixed(3)} '
                  '(${(ratio * 100).toStringAsFixed(1)}%)',
            ),
            _MetricLabel(
              text: 'Page Scroll Status: $pageStatus',
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain metrics label, like the monospaced `UILabel`s in the UIKit header.
class _MetricLabel extends StatelessWidget {
  const _MetricLabel({required this.text, this.secondary = false});

  final String text;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        (secondary ? CupertinoColors.secondaryLabel : CupertinoColors.label)
            .resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          color: textColor,
        ),
      ),
    );
  }
}

/// One fixed-height row (title + subtitle), the twin of a `UITableViewCell`
/// with a default content configuration. No semantics are added: whatever
/// Flutter produces for the two texts is what the benchmark compares.
class _BaselineRow extends StatelessWidget {
  const _BaselineRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final Color separatorColor = CupertinoColors.separator.resolveFrom(context);
    final Color primaryColor = CupertinoColors.label.resolveFrom(context);
    final Color secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(
      context,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: separatorColor, width: 0.5)),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Item #$index',
            style: TextStyle(fontSize: 17, color: primaryColor),
          ),
          Text(
            'Baseline scroll row ${index + 1} of '
            '${_ScrollBaselinePageState.rowCount}',
            style: TextStyle(fontSize: 15, color: secondaryColor),
          ),
        ],
      ),
    );
  }
}
