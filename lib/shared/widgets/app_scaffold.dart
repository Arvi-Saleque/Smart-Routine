import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.floatingActionButton,
    this.showBottomNavigation = true,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndexFor(location);

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        actions:
            actions ?? [_SettingsAction(isCurrent: location == '/settings')],
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNavigation
          ? NavigationBar(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(_destinations[index].path),
              destinations: _destinations
                  .map(
                    (destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  int _selectedIndexFor(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/routine')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/coach')) return 4;
    return -1;
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Settings',
      onPressed: () => context.push('/settings'),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}

class _NavigationDestinationData {
  const _NavigationDestinationData({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _NavigationDestinationData(
    path: '/',
    label: 'Today',
    icon: Icons.timeline_outlined,
    selectedIcon: Icons.timeline,
  ),
  _NavigationDestinationData(
    path: '/routines',
    label: 'Activities',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
  ),
  _NavigationDestinationData(
    path: '/calendar',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  _NavigationDestinationData(
    path: '/analytics',
    label: 'Analytics',
    icon: Icons.query_stats_outlined,
    selectedIcon: Icons.query_stats,
  ),
  _NavigationDestinationData(
    path: '/coach',
    label: 'Coach',
    icon: Icons.lightbulb_outline,
    selectedIcon: Icons.lightbulb,
  ),
];
