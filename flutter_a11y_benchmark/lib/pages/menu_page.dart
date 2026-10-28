import 'package:cupertino_ui/cupertino_ui.dart';

import '../a11y/a11y_probe.dart';
import 'focus_keyboard_page.dart';
import 'modal_barrier_page.dart';
import 'scroll_baseline_page.dart';
import 'traversal_hierarchy_page.dart';

/// One row of the root menu; mirrors `MenuViewController.Destination`.
class MenuDestination {
  const MenuDestination({
    required this.title,
    required this.subtitle,
    required this.identifier,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final String identifier;
  final WidgetBuilder builder;
}

/// Root screen: an inset-grouped Cupertino list with the four benchmark
/// destinations.
///
/// UIKit twin: `MenuViewController` (inset-grouped `UITableView`).
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static final List<MenuDestination> destinations = <MenuDestination>[
    MenuDestination(
      title: 'Scroll Baseline',
      subtitle:
          '100-cell list with Δy/viewportHeight ratio & page scroll status',
      identifier: 'menu.scrollBaseline',
      builder: (_) => const ScrollBaselinePage(),
    ),
    MenuDestination(
      title: 'Traversal Hierarchy',
      subtitle: '3x3 grid with headers, container ordering & stateful buttons',
      identifier: 'menu.traversalHierarchy',
      builder: (_) => const TraversalHierarchyPage(),
    ),
    MenuDestination(
      title: 'Focus & Keyboard',
      subtitle:
          'Prefilled & secure text fields, 25% slider, VO & FKA focus logs',
      identifier: 'menu.focusKeyboard',
      builder: (_) => const FocusKeyboardPage(),
    ),
    MenuDestination(
      title: 'Modal Barrier',
      subtitle: 'Background buttons & draggable modal sheet barrier',
      identifier: 'menu.modalBarrier',
      builder: (_) => const ModalBarrierPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Flutter A11y Benchmark'),
      ),
      child: SafeArea(
        child: Semantics(
          container: true,
          identifier: 'menu.tableView',
          child: ListView(
            children: <Widget>[
              CupertinoListSection.insetGrouped(
                children: <Widget>[
                  for (final MenuDestination destination in destinations)
                    // UITableViewCell twin: one merged element per row.
                    A11yProbe(
                      identifier: destination.identifier,
                      mergeDescendants: true,
                      child: CupertinoListTile(
                        title: Text(destination.title),
                        subtitle: Text(destination.subtitle),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: destination.builder,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
