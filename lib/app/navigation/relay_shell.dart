import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/relay_wordmark.dart';
import '../../features/transfers/application/transfer_providers.dart';
import '../../features/transfers/presentation/incoming_transfer_gate.dart';

class RelayDestination {
  const RelayDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const relayDestinations = <RelayDestination>[
  RelayDestination(
    label: 'Library',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  RelayDestination(
    label: 'Nearby',
    icon: Icons.near_me_outlined,
    selectedIcon: Icons.near_me_rounded,
  ),
  RelayDestination(
    label: 'Transfers',
    icon: Icons.swap_horiz_rounded,
    selectedIcon: Icons.swap_horiz_rounded,
  ),
  RelayDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];

/// Holds the four primary destinations in an indexed stack so scroll
/// positions and local state survive tab changes. Wide layouts use a rail;
/// compact layouts use a custom bottom navigation bar.
class RelayShell extends ConsumerWidget {
  const RelayShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.relayColors;
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppBreakpoints.medium;
    final activeTransfers = ref.watch(activeTransferCountProvider);
    final index = navigationShell.currentIndex;

    void select(int next) {
      navigationShell.goBranch(
        next,
        initialLocation: next == navigationShell.currentIndex,
      );
    }

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Row(
        children: [
          if (useRail)
            _RelayRail(
              currentIndex: index,
              activeTransfers: activeTransfers,
              onSelect: select,
              onImport: () => context.push('/import'),
            ),
          Expanded(child: IncomingTransferApprovalGate(child: navigationShell)),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : _RelayBottomNav(
              currentIndex: index,
              activeTransfers: activeTransfers,
              onSelect: select,
            ),
    );
  }
}

class _RelayBottomNav extends StatelessWidget {
  const _RelayBottomNav({
    required this.currentIndex,
    required this.activeTransfers,
    required this.onSelect,
  });

  final int currentIndex;
  final int activeTransfers;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: SizedBox(
            height: AppSizes.navBarHeight,
            child: Row(
              children: [
                for (var index = 0; index < relayDestinations.length; index++)
                  Expanded(
                    child: _BottomNavItem(
                      destination: relayDestinations[index],
                      selected: index == currentIndex,
                      badgeCount: index == 2 ? activeTransfers : 0,
                      onTap: () => onSelect(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final RelayDestination destination;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.quick;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: duration,
              width: 22,
              height: 2,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: selected ? colors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _NavIcon(
              icon: selected ? destination.selectedIcon : destination.icon,
              selected: selected,
              badgeCount: badgeCount,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.eyebrow(selected ? colors.ink : colors.muted)
                  .copyWith(
                    fontSize: 9,
                    letterSpacing: 0.65,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.badgeCount,
  });

  final IconData icon;
  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return SizedBox(
      width: 30,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 22, color: selected ? colors.accent : colors.muted),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15),
                height: 15,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.canvas, width: 1.5),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelayRail extends StatelessWidget {
  const _RelayRail({
    required this.currentIndex,
    required this.activeTransfers,
    required this.onSelect,
    required this.onImport,
  });

  final int currentIndex;
  final int activeTransfers;
  final ValueChanged<int> onSelect;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.25,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              RelayWordmark(compact: true, onTap: () => onSelect(0)),
              const SizedBox(height: AppSpacing.xxl),
              for (var index = 0; index < relayDestinations.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _RailItem(
                    destination: relayDestinations[index],
                    selected: index == currentIndex,
                    badgeCount: index == 2 ? activeTransfers : 0,
                    onTap: () => onSelect(index),
                  ),
                ),
              const Spacer(),
              Tooltip(
                message: 'Import a document',
                child: IconButton(
                  onPressed: onImport,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    side: BorderSide(color: colors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final RelayDestination destination;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Material(
          color: selected ? colors.sage : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavIcon(
                    icon: selected
                        ? destination.selectedIcon
                        : destination.icon,
                    selected: selected,
                    badgeCount: badgeCount,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTypography.eyebrow(
                          selected ? colors.ink : colors.muted,
                        ).copyWith(
                          fontSize: 8.5,
                          letterSpacing: 0.55,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
