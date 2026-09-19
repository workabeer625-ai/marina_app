import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../auth/data/auth_repository.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) => MarinaPage(
    title: context.tr('security'),
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SettingsTile(
          icon: Icons.password_rounded,
          label: context.tr('changePassword'),
          route: '/change-password',
        ),
        SettingsTile(
          icon: Icons.devices_rounded,
          label: context.tr('sessions'),
          route: '/sessions',
        ),
        const SizedBox(height: 8),
        MarinaSectionCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MarinaPalette.of(context).goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MarinaPalette.of(context).gold.withValues(alpha: .3),
                  ),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 21,
                  color: MarinaPalette.of(context).gold,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('twoFactorAuthentication'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: MarinaPalette.of(context).ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr('twoFactorDescription'),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: MarinaPalette.of(context).muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(userSessionsProvider);
    return MarinaPage(
      title: context.tr('sessions'),
      child: sessions.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(userSessionsProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(icon: Icons.devices_other)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(userSessionsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final session = items[i];
                    final p = MarinaPalette.of(context);
                    return MarinaSectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: p.goldSoft,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: p.gold.withValues(alpha: .25),
                              ),
                            ),
                            child: Icon(
                              Icons.devices_rounded,
                              size: 20,
                              color: p.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.deviceName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: p.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    if (session.ipAddress?.isNotEmpty == true)
                                      session.ipAddress!,
                                    MaterialLocalizations.of(context)
                                        .formatMediumDate(
                                      session.lastSeenUtc.toLocal(),
                                    ),
                                  ].join(' • '),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(authRepositoryProvider)
                                    .revokeSession(session.id);
                                ref.invalidate(userSessionsProvider);
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        apiFailureMessage(
                                          error,
                                          context.tr('retry'),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(context.tr('remove')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MarinaPage(
    title: context.tr('language'),
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          context.tr('language').toUpperCase(),
          style: MarinaType.kicker(
            context,
            color: MarinaPalette.of(context).muted,
          ),
        ),
        const SizedBox(height: 12),
        _LanguageCard(
          title: 'English',
          subtitle: 'Continue in English',
          selected: Localizations.localeOf(context).languageCode == 'en',
          onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
        ),
        const SizedBox(height: 10),
        _LanguageCard(
          title: 'العربية',
          subtitle: 'تابع باللغة العربية',
          selected: Localizations.localeOf(context).languageCode == 'ar',
          onTap: () => ref.read(localeProvider.notifier).setLocale('ar'),
        ),
        const SizedBox(height: 30),
        Text(
          context.tr('appearance').toUpperCase(),
          style: MarinaType.kicker(
            context,
            color: MarinaPalette.of(context).muted,
          ),
        ),
        const SizedBox(height: 12),
        const _AppearanceOptions(compact: true),
      ],
    ),
  );
}

/// Standalone appearance (day / night / system) screen.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MarinaPage(
    title: context.tr('appearance'),
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          context.tr('appearanceSubtitle'),
          style: TextStyle(
            height: 1.55,
            fontSize: 13.5,
            color: MarinaPalette.of(context).muted,
          ),
        ),
        const SizedBox(height: 20),
        const _AppearanceOptions(),
      ],
    ),
  );
}

class _AppearanceOptions extends ConsumerWidget {
  const _AppearanceOptions({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Column(
      children: [
        _AppearanceCard(
          mode: ThemeMode.system,
          selected: mode == ThemeMode.system,
          title: context.tr('themeSystem'),
          subtitle: context.tr('themeSystemHint'),
          icon: Icons.brightness_auto_rounded,
          compact: compact,
          onTap: () =>
              ref.read(themeModeProvider.notifier).set(ThemeMode.system),
        ),
        const SizedBox(height: 10),
        _AppearanceCard(
          mode: ThemeMode.light,
          selected: mode == ThemeMode.light,
          title: context.tr('themeLight'),
          subtitle: context.tr('themeLightHint'),
          icon: Icons.light_mode_rounded,
          compact: compact,
          onTap: () =>
              ref.read(themeModeProvider.notifier).set(ThemeMode.light),
        ),
        const SizedBox(height: 10),
        _AppearanceCard(
          mode: ThemeMode.dark,
          selected: mode == ThemeMode.dark,
          title: context.tr('themeDark'),
          subtitle: context.tr('themeDarkHint'),
          icon: Icons.dark_mode_rounded,
          compact: compact,
          onTap: () =>
              ref.read(themeModeProvider.notifier).set(ThemeMode.dark),
        ),
      ],
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.mode,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final ThemeMode mode;
  final bool selected, compact;
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final previewColors = switch (mode) {
      ThemeMode.light => (const Color(0xFFF7F5F0), MarinaColors.navy),
      ThemeMode.dark => (MarinaColors.nightBg, MarinaColors.goldBright),
      _ => (
        p.isDark ? MarinaColors.nightBg : const Color(0xFFF7F5F0),
        p.isDark ? MarinaColors.goldBright : MarinaColors.navy,
      ),
    };
    return Material(
      color: selected
          ? p.goldSoft.withValues(alpha: p.isDark ? .8 : .6)
          : p.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? p.gold : p.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: previewColors.$1,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.line),
                ),
                child: Icon(icon, size: 21, color: previewColors.$2),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: p.ink,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12.5, color: p.muted),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.gold : Colors.transparent,
                  border: Border.all(
                    color: selected ? p.gold : p.muted.withValues(alpha: .6),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: MarinaColors.onGold,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Material(
      color: selected
          ? p.goldSoft.withValues(alpha: p.isDark ? .8 : .6)
          : p.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? p.gold : p.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: p.muted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.gold : Colors.transparent,
                  border: Border.all(
                    color: selected ? p.gold : p.muted.withValues(alpha: .6),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: MarinaColors.onGold,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.titleKey, required this.bodyKey});

  final String titleKey, bodyKey;

  @override
  Widget build(BuildContext context) => MarinaPage(
    title: context.tr(titleKey),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        MarinaSectionCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const GoldDivider(width: 90),
              const SizedBox(height: 18),
              Text(
                context.tr(bodyKey),
                style: TextStyle(
                  height: 1.7,
                  fontSize: 15,
                  color: MarinaPalette.of(context).ink.withValues(alpha: .9),
                ),
              ),
              const SizedBox(height: 18),
              const GoldDivider(width: 90),
            ],
          ),
        ),
      ],
    ),
  );
}
