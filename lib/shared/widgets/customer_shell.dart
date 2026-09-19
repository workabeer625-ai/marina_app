import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/marina_theme.dart';
import 'marina_wordmark.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final paths = ['/home', '/categories', '/favorites', '/cart', '/profile'];
    var index = paths.indexWhere(location.startsWith);
    if (index < 0) index = 0;
    final destinations = [
      (Icons.home_rounded, context.tr('home')),
      (Icons.grid_view_rounded, context.tr('shop')),
      (Icons.blur_on_rounded, 'MARINA'),
      (Icons.shopping_bag_rounded, context.tr('bag')),
      (Icons.person_rounded, context.tr('account')),
    ];
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MarinaRadius.floating),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? MarinaColors.navy.withValues(alpha: .96)
                    : Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(MarinaRadius.floating),
                border: Border.all(color: MarinaColors.line),
                boxShadow: MarinaShadows.soft,
              ),
              child: Row(
                children: List.generate(destinations.length, (i) {
                  final selected = i == index;
                  final center = i == 2;
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: destinations[i].$2,
                      child: InkWell(
                        onTap: () => context.go(paths[i]),
                        borderRadius: BorderRadius.circular(28),
                        child: AnimatedContainer(
                          duration: MarinaMotion.normal,
                          curve: MarinaMotion.curve,
                          height: center ? 62 : 54,
                          transform: Matrix4.translationValues(
                            0,
                            center ? -9 : 0,
                            0,
                          ),
                          decoration: BoxDecoration(
                            shape: center
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            color: center
                                ? MarinaColors.royal
                                : selected
                                ? const Color(0xFF12395F)
                                : Colors.transparent,
                            borderRadius: center
                                ? null
                                : BorderRadius.circular(20),
                            boxShadow: center ? MarinaShadows.glow : null,
                          ),
                          child: center
                              ? const Center(
                                  child: MarinaWordmark(
                                    dark: false,
                                    compact: true,
                                    markOnly: true,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      destinations[i].$1,
                                      size: 21,
                                      color: selected
                                          ? MarinaColors.royal
                                          : Theme.of(context).brightness == Brightness.dark ? Colors.white60 : MarinaColors.muted,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      destinations[i].$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                        color: selected
                                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : MarinaColors.ink)
                                            : MarinaColors.muted,
                                        fontSize: 9.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
