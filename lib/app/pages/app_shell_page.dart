import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellDestination {
  const AppShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// O Controle -- item central, visualmente dominante na barra.
  final bool isPrimary;
}

class AppShellPage extends StatelessWidget {
  const AppShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Ordem == ordem dos branches em app_router.dart: Inicio, Times,
  /// Controle, Historico, Perfil -- Controle no meio de proposito.
  List<AppShellDestination> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return <AppShellDestination>[
      AppShellDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.navHome,
      ),
      AppShellDestination(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: l10n.navTeam,
      ),
      AppShellDestination(
        icon: Icons.sports_esports_outlined,
        selectedIcon: Icons.sports_esports,
        label: l10n.navControl,
        isPrimary: true,
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

/// Barra custom (nao Material `NavigationBar`) para poder dar ao item
/// central (Controle) um tratamento realmente dominante -- maior, elevado,
/// com acento -- sem parecer um FAB solto por cima da barra. Cada item
/// continua sendo um alvo de toque padrao, then acessibilidade/semantics dos
/// outros 4 nao muda -- so o item central ganha tratamento diferente.
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
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: destinations[i].isPrimary
                      ? _PrimaryNavItem(
                          destination: destinations[i],
                          isSelected: currentIndex == i,
                          onTap: () => onSelected(i),
                        )
                      : _NavItem(
                          destination: destinations[i],
                          isSelected: currentIndex == i,
                          onTap: () => onSelected(i),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final AppShellDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isSelected ? colors.textPrimary : colors.textTertiary;

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              isSelected ? destination.selectedIcon : destination.icon,
              color: color,
              size: AppSizing.iconMd,
            ),
            const SizedBox(height: AppSpacing.xxs),
            // Flexible + uma linha: o rotulo nunca empurra a barra alem dos
            // 64px, por maior que seja a escala de fonte do aparelho.
            Flexible(
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O Controle: circulo elevado com acento verde, translatado pra fora da
/// barra -- dominante sem depender de glow/neon.
class _PrimaryNavItem extends StatelessWidget {
  const _PrimaryNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final AppShellDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = isSelected ? colors.success : colors.surfaceHighest;
    final foreground = isSelected ? colors.onAccent : colors.textPrimary;

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        // Stack, nao Column: o circulo de 52px ocupa altura de layout mesmo
        // translatado, entao 52 + a linha do rotulo estourava a barra de
        // 64px por 2px assim que a metrica de texto do aparelho fosse um
        // pouco maior que a do desenho. Posicionado, o visual e o mesmo
        // (circulo saindo pra fora da barra, via Clip.none) e a altura nunca
        // depende do tamanho da fonte.
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.success.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected ? destination.selectedIcon : destination.icon,
                    color: foreground,
                    size: AppSizing.iconLg,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Text(
                destination.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: isSelected ? colors.success : colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          selectedIcon: Icon(
            destination.selectedIcon,
            color: destination.isPrimary ? context.colors.success : null,
          ),
          label: Text(destination.label),
        ),
    ],
  );
}
