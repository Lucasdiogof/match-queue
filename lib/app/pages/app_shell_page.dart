import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellDestination {
  const AppShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppShellPage extends StatelessWidget {
  const AppShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  List<AppShellDestination> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return <AppShellDestination>[
      AppShellDestination(
        icon: Icons.search,
        selectedIcon: Icons.search,
        label: l10n.navSearch,
      ),
      AppShellDestination(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: l10n.navTeam,
      ),
      AppShellDestination(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: l10n.navHistory,
      ),
      AppShellDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.navProfile,
      ),
    ];
  }

  void _onDestinationSelected(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context);

    return ResponsiveLayout(
      mobile: (context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: _BottomNavigation(
          destinations: destinations,
          currentIndex: navigationShell.currentIndex,
          onSelected: _onDestinationSelected,
        ),
      ),
      tablet: (context) => Scaffold(
        body: Row(
          children: <Widget>[
            _SideNavigation(
              destinations: destinations,
              currentIndex: navigationShell.currentIndex,
              onSelected: _onDestinationSelected,
              extended: false,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      desktop: (context) => Scaffold(
        body: Row(
          children: <Widget>[
            _SideNavigation(
              destinations: destinations,
              currentIndex: navigationShell.currentIndex,
              onSelected: _onDestinationSelected,
              extended: true,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<AppShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: context.colors.borderSubtle)),
    ),
    child: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      destinations: <Widget>[
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ],
    ),
  );
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.extended,
  });

  final List<AppShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: currentIndex,
    onDestinationSelected: onSelected,
    extended: extended,
    minWidth: AppSizing.navigationRailWidth,
    minExtendedWidth: AppSizing.navigationRailExtendedWidth,
    labelType: extended ? null : NavigationRailLabelType.all,
    leading: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: extended
          ? const BrandLockup(markSize: BrandMarkSize.small)
          : const BrandMark(size: BrandMarkSize.small),
    ),
    destinations: <NavigationRailDestination>[
      for (final destination in destinations)
        NavigationRailDestination(
          icon: Icon(destination.icon),
          selectedIcon: Icon(destination.selectedIcon),
          label: Text(destination.label),
        ),
    ],
  );
}
