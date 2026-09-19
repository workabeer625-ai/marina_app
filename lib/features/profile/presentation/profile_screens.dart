// ignore_for_file: deprecated_member_use

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
          icon: Icons.password,
          label: context.tr('changePassword'),
          route: '/change-password',
        ),
        SettingsTile(
          icon: Icons.devices,
          label: context.tr('sessions'),
          route: '/sessions',
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: MarinaTheme.blue,
            child: Icon(Icons.verified_user_outlined),
          ),
          title: Text(context.tr('twoFactorAuthentication')),
          subtitle: Text(context.tr('twoFactorDescription')),
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
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final session = items[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: MarinaTheme.sand,
                        child: Icon(Icons.devices),
                      ),
                      title: Text(session.deviceName),
                      subtitle: Text(
                        [
                          if (session.ipAddress?.isNotEmpty == true)
                            session.ipAddress!,
                          MaterialLocalizations.of(context)
                              .formatMediumDate(session.lastSeenUtc.toLocal()),
                        ].join(' • '),
                      ),
                      trailing: TextButton(
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
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded),
              label: Text('Day'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded),
              label: Text('Night'),
            ),
          ],
          selected: {ref.watch(themeModeProvider)},
          onSelectionChanged: (value) =>
              ref.read(themeModeProvider.notifier).set(value.first),
        ),
        const SizedBox(height: 28),
        Text('Language', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        RadioListTile<String>(
          value: 'en',
          groupValue: Localizations.localeOf(context).languageCode,
          onChanged: (_) => ref.read(localeProvider.notifier).setLocale('en'),
          title: Text(context.tr('english')),
        ),
        RadioListTile<String>(
          value: 'ar',
          groupValue: Localizations.localeOf(context).languageCode,
          onChanged: (_) => ref.read(localeProvider.notifier).setLocale('ar'),
          title: const Text('العربية'),
        ),
      ],
    ),
  );
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
        Text(
          context.tr(bodyKey),
          style: const TextStyle(height: 1.65, fontSize: 16),
        ),
      ],
    ),
  );
}
