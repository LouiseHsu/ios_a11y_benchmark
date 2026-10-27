import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A single semantics action received from the platform (VoiceOver, Full
/// Keyboard Access, Voice Control, Switch Control, or XCUITest).
@immutable
class A11yActionRecord {
  const A11yActionRecord({
    required this.action,
    required this.nodeId,
    required this.description,
    required this.timestamp,
  });

  final ui.SemanticsAction action;
  final int nodeId;
  final String description;
  final DateTime timestamp;

  @override
  String toString() => '${action.name} → $description';
}

/// Observes every [ui.SemanticsAction] the platform dispatches to Flutter.
///
/// The UIKit twin can observe assistive-technology focus globally through
/// `UIAccessibility.elementFocusedNotification`. Flutter has no public
/// equivalent, so this observer wraps [ui.PlatformDispatcher.onSemanticsActionEvent]
/// (the single platform → framework entry point for semantics actions),
/// records each event together with the identifier/label of the targeted
/// [SemanticsNode], and then forwards the event to the framework untouched.
///
/// Note: the iOS embedder only dispatches `didGainAccessibilityFocus` /
/// `didLoseAccessibilityFocus` to nodes that declare those handlers, which is
/// why [A11yProbe] attaches no-op handlers to the benchmark's controls.
class A11yActionObserver extends ChangeNotifier {
  A11yActionObserver._();

  static final A11yActionObserver instance = A11yActionObserver._();

  static const int _maxRecords = 250;
  static bool _installed = false;

  final List<A11yActionRecord> _records = <A11yActionRecord>[];
  int? _focusedNodeId;

  /// All recorded actions, oldest first (capped at [_maxRecords]).
  List<A11yActionRecord> get records =>
      List<A11yActionRecord>.unmodifiable(_records);

  /// The most recently recorded action, if any.
  A11yActionRecord? get latest => _records.isEmpty ? null : _records.last;

  /// Installs the observer in front of the framework's own handler.
  ///
  /// Must be called after `WidgetsFlutterBinding.ensureInitialized()` so that
  /// the framework handler already exists and can be forwarded to.
  static void install() {
    if (_installed) {
      return;
    }
    _installed = true;
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final ui.SemanticsActionEventCallback? frameworkHandler =
        dispatcher.onSemanticsActionEvent;
    dispatcher.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      instance._record(event);
      frameworkHandler?.call(event);
    };
  }

  /// Whether the node annotated with [identifier] currently holds
  /// assistive-technology (VoiceOver) focus, as far as the platform told us.
  bool isAccessibilityFocused(String identifier) {
    final int? nodeId = _focusedNodeId;
    if (nodeId == null) {
      return false;
    }
    final SemanticsNode? node = _findNode(nodeId);
    if (node == null) {
      return false;
    }
    return node.getSemanticsData().identifier == identifier;
  }

  /// Human readable description of the currently VoiceOver-focused node.
  String get focusedNodeDescription {
    final int? nodeId = _focusedNodeId;
    if (nodeId == null) {
      return 'none';
    }
    return describeNode(_findNode(nodeId), nodeId);
  }

  void _record(ui.SemanticsActionEvent event) {
    final SemanticsNode? node = _findNode(event.nodeId, viewId: event.viewId);
    if (event.type == ui.SemanticsAction.didGainAccessibilityFocus) {
      _focusedNodeId = event.nodeId;
    } else if (event.type == ui.SemanticsAction.didLoseAccessibilityFocus &&
        _focusedNodeId == event.nodeId) {
      _focusedNodeId = null;
    }

    final A11yActionRecord record = A11yActionRecord(
      action: event.type,
      nodeId: event.nodeId,
      description: describeNode(node, event.nodeId),
      timestamp: DateTime.now(),
    );
    _records.add(record);
    if (_records.length > _maxRecords) {
      _records.removeAt(0);
    }
    debugPrint('[A11yAction] $record');
    notifyListeners();
  }

  SemanticsNode? _findNode(int nodeId, {int? viewId}) {
    for (final RenderView renderView in WidgetsBinding.instance.renderViews) {
      if (viewId != null && renderView.flutterView.viewId != viewId) {
        continue;
      }
      final SemanticsNode? root =
          renderView.owner?.semanticsOwner?.rootSemanticsNode;
      if (root == null) {
        continue;
      }
      final SemanticsNode? match = _search(root, nodeId);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  static SemanticsNode? _search(SemanticsNode node, int nodeId) {
    if (node.id == nodeId) {
      return node;
    }
    SemanticsNode? found;
    node.visitChildren((SemanticsNode child) {
      found = _search(child, nodeId);
      return found == null;
    });
    return found;
  }

  /// Describes [node] using its merged identifier, label and value (in that
  /// order of preference), falling back to the raw node id.
  static String describeNode(SemanticsNode? node, int nodeId) {
    if (node == null) {
      return 'node#$nodeId';
    }
    final SemanticsData data = node.getSemanticsData();
    final List<String> parts = <String>[
      if (data.identifier.isNotEmpty) data.identifier,
      if (data.label.isNotEmpty) '"${data.label.replaceAll('\n', ' / ')}"',
      if (data.value.isNotEmpty) 'value=${data.value}',
    ];
    if (parts.isEmpty) {
      return 'node#$nodeId';
    }
    return '${parts.join(' ')} (#$nodeId)';
  }
}
