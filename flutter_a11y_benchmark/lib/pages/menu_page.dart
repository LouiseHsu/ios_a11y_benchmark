import 'package:material_ui/material_ui.dart';

import '../a11y/a11y_probe.dart';
import 'composite_arena_page.dart';
import 'custom_actions_page.dart';
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

/// Root screen: a list with the six benchmark destinations.
///
/// UIKit twin: `MenuViewController` (inset-grouped `UITableView`).
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static final List<MenuDestination> destinations = <MenuDestination>[
    MenuDestination(
      title: 'Scroll Baseline',
      subtitle:
          '100-cell list with Δy/viewportHeight ratio & secondary scroll view',
      identifier: 'menu.scrollBaseline',
      builder: (_) => const ScrollBaselinePage(),
    ),
    MenuDestination(
      title: 'Traversal Hierarchy',
      subtitle:
          '3x3 grid with RTL toggle, headers, zero-rect & stateful buttons',
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
    MenuDestination(
      title: 'Custom Actions',
      subtitle: 'Merged-label cells with Primary & Secondary rotor actions',
      identifier: 'menu.customActions',
      builder: (_) => const CustomActionsPage(),
    ),
    MenuDestination(
      title: 'Composite Arena',
      subtitle: 'Floating launcher & concurrent unfocus + modal present',
      identifier: 'menu.compositeArena',
      builder: (_) => const CompositeArenaPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter A11y Benchmark')),
      body: Semantics(
        container: true,
        identifier: 'menu.tableView',
        child: ListView.separated(
          itemCount: destinations.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final MenuDestination destination = destinations[index];
            // UITableViewCell twin: one merged element per row.
            return MergeSemantics(
              child: A11yProbe(
                identifier: destination.identifier,
                child: ListTile(
                  title: Text(destination.title),
                  subtitle: Text(destination.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: destination.builder),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
