import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell widget that wraps the five bottom-navigation destinations.
///
/// Uses [StatefulShellRoute.indexedStack] so each tab preserves its own
/// navigation stack and scroll position when the user switches tabs.
class MainShell extends StatelessWidget {
  /// The stateful navigation shell provided by [StatefulShellRoute].
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  // ── Tab destinations ────────────────────────────────────────────────────────

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      label: 'Vehicles',
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car_rounded,
    ),
    _NavDestination(
      label: 'Logs',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    _NavDestination(
      label: 'Analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    _NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-tap on the active tab navigates back to the branch's initial route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Private helper ─────────────────────────────────────────────────────────────

/// Immutable data class for a single bottom-nav destination.
class _NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
