import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/state/commerce_state.dart';
import '../../core/theme/marina_theme.dart';

/// The MARINA signature dock: a floating glass bar with a gradient hairline,
/// four destinations and a raised gold bag jewel with a live item count.
class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  bool authed = false;

  @override
  void initState() {
    super.initState();
    authed = apiClient.isAuthenticated;
    apiClient.accountRevision.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    apiClient.accountRevision.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() {
    if (!mounted) return;
    final next = apiClient.isAuthenticated;
    if (next != authed) setState(() => authed = next);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final paths = ['/home', '/categories', '/favorites', '/cart', '/profile'];
    var index = paths.indexWhere(location.startsWith);
    if (index < 0) index = 0;

    final p = MarinaPalette.of(context);
    // Display order: Home, Shop · [Bag jewel] · Favorites, Account.
    final destinations = [
      (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded,
          context.tr('home'), '/home', 0),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, context.tr('shop'),
          '/categories', 1),
      (Icons.favorite_border_rounded, Icons.favorite_rounded,
          context.tr('favorites'), '/favorites', 2),
      (Icons.person_outline_rounded, Icons.person_rounded,
          context.tr('account'), '/profile', 4),
    ];
    final leftTabs = destinations.sublist(0, 2);
    final rightTabs = destinations.sublist(2);

    final cart = authed
        ? ref.watch(cartProvider)
        : const AsyncLoading<CartSnapshot>();
    final bagCount = cart.value?.items.fold<int>(
          0,
          (sum, line) => sum + line.quantity,
        ) ??
        0;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SizedBox(
          height: 94,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              // Glass dock with gradient hairline.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 78,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.gold.withValues(alpha: .85),
                        p.line.withValues(alpha: .55),
                        p.gold.withValues(alpha: .45),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.isDark
                            ? const Color(0x73000000)
                            : const Color(0x1E101B2D),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(1.2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(33),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: p.isDark
                              ? MarinaColors.nightBg.withValues(alpha: .88)
                              : Colors.white.withValues(alpha: .9),
                        ),
                        child: Row(
                          children: [
                            for (final tab in leftTabs)
                              Expanded(
                                child: _DockTab(
                                  icon: tab.$1,
                                  activeIcon: tab.$2,
                                  label: tab.$3,
                                  selected: index == tab.$5,
                                  palette: p,
                                  onTap: () => context.go(tab.$4),
                                ),
                              ),
                            const SizedBox(width: 76),
                            for (final tab in rightTabs)
                              Expanded(
                                child: _DockTab(
                                  icon: tab.$1,
                                  activeIcon: tab.$2,
                                  label: tab.$3,
                                  selected: index == tab.$5,
                                  palette: p,
                                  onTap: () => context.go(tab.$4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Raised bag jewel.
              PositionedDirectional(
                bottom: 21,
                start: 0,
                end: 0,
                child: Center(
                  child: _CenterJewel(
                    count: bagCount,
                    selected: index == 3,
                    palette: p,
                    onTap: () => context.go('/cart'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon, activeIcon;
  final String label;
  final bool selected;
  final MarinaPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: MarinaMotion.normal,
        curve: MarinaMotion.curve,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (palette.isDark
                  ? palette.gold.withValues(alpha: .14)
                  : MarinaColors.navy.withValues(alpha: .07))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? palette.gold.withValues(alpha: palette.isDark ? .5 : .35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: MarinaMotion.normal,
              curve: MarinaMotion.spring,
              child: Icon(
                selected ? activeIcon : icon,
                size: 22,
                color: selected
                    ? (palette.isDark ? palette.gold : MarinaColors.navy)
                    : palette.muted,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: MarinaMotion.normal,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? (palette.isDark ? palette.gold : MarinaColors.navy)
                    : palette.muted,
                fontFamily: 'Tajawal',
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CenterJewel extends StatelessWidget {
  const _CenterJewel({
    required this.count,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final MarinaPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: context.tr('bag'),
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        height: 68,
        child: Center(
          child: AnimatedContainer(
            duration: MarinaMotion.normal,
            curve: MarinaMotion.spring,
            height: selected ? 62 : 56,
            width: selected ? 62 : 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: MarinaGradients.gold,
              boxShadow: MarinaShadows.glow,
            ),
            padding: const EdgeInsets.all(2.4),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEFDDAE), Color(0xFFCBA95E)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_rounded,
                    size: 24,
                    color: MarinaColors.onGold,
                  ),
                  if (count > 0)
                    PositionedDirectional(
                      top: 2,
                      end: 2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 19),
                        height: 19,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: MarinaColors.midnight,
                          shape: count < 10 ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius:
                              count < 10 ? null : BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEFDDAE),
                            width: 1.4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Color(0xFFEFDDAE),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
