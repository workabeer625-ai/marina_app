import '../../../shared/widgets/page_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../data/customer_repository.dart';

class ApiProfileScreen extends ConsumerWidget {
  const ApiProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(customerProfileProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(customerProfileProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.tr('account'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 22),
            profile.when(
              loading: () => const SizedBox(height: 76, child: LoadingState()),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(customerProfileProvider),
              ),
              data: (data) => Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: MarinaTheme.sand,
                    child: Text(_initials(data.displayName)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data.email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SettingsTile(
              icon: Icons.person_outline,
              label: context.tr('editProfile'),
              route: '/edit-profile',
            ),
            SettingsTile(
              icon: Icons.location_on_outlined,
              label: context.tr('addresses'),
              route: '/addresses',
            ),
            SettingsTile(
              icon: Icons.receipt_long_outlined,
              label: context.tr('orders'),
              route: '/orders',
            ),
            SettingsTile(
              icon: Icons.assignment_return_outlined,
              label: context.tr('returns'),
              route: '/returns',
            ),
            SettingsTile(
              icon: Icons.security_outlined,
              label: context.tr('security'),
              route: '/security',
            ),
            SettingsTile(
              icon: Icons.language,
              label: context.tr('language'),
              route: '/language',
            ),
            SettingsTile(
              icon: Icons.info_outline,
              label: context.tr('about'),
              route: '/about',
            ),
            SettingsTile(
              icon: Icons.storefront_outlined,
              label: context.tr('brands'),
              route: '/brands',
            ),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: context.tr('privacy'),
              route: '/privacy',
            ),
            SettingsTile(
              icon: Icons.gavel_outlined,
              label: context.tr('terms'),
              route: '/terms',
            ),
            SettingsTile(
              icon: Icons.help_outline,
              label: context.tr('help'),
              route: '/support',
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                final revoked = await apiClient.logout();
                if (!revoked && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Signed out locally; server revocation could not be confirmed.',
                      ),
                    ),
                  );
                }
                if (context.mounted) context.go('/welcome');
              },
              icon: const Icon(Icons.logout),
              label: Text(context.tr('logout')),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiEditProfileScreen extends ConsumerStatefulWidget {
  const ApiEditProfileScreen({super.key});
  @override
  ConsumerState<ApiEditProfileScreen> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<ApiEditProfileScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  bool initialized = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(customerRepositoryProvider)
          .updateProfile(name.text.trim(), phone.text.trim());
      ref.invalidate(customerProfileProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(customerProfileProvider);
    return MarinaPage(
      title: context.tr('editProfile'),
      child: profile.when(
        loading: () => const LoadingState(),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(customerProfileProvider)),
        data: (data) {
          if (!initialized) {
            initialized = true;
            name.text = data.displayName;
            phone.text = data.phone ?? '';
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextField(
                controller: name,
                maxLength: 100,
                decoration: InputDecoration(labelText: context.tr('fullName')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                maxLength: 30,
                decoration: InputDecoration(labelText: context.tr('phone')),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: busy ? null : save,
                child: busy
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(context.tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ApiAddressesScreen extends ConsumerWidget {
  const ApiAddressesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(customerAddressesProvider);
    return MarinaPage(
      title: context.tr('addresses'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addresses/new'),
        label: Text(context.tr('addAddress')),
        icon: const Icon(Icons.add),
      ),
      child: addresses.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(customerAddressesProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(customerAddressesProvider.future),
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(
                      height: 500,
                      child: EmptyState(icon: Icons.location_off_outlined),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final address = items[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: MarinaTheme.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: MarinaTheme.blue,
                        child: Icon(Icons.home_outlined),
                      ),
                      title: Text(
                        '${address.label}${address.isDefault ? ' · ${context.tr('defaultAddress')}' : ''}',
                      ),
                      subtitle: Text(
                        '${address.recipient}\n${address.line1}, ${address.city}\n${address.phone}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await context.push(
                              '/addresses/edit',
                              extra: address,
                            );
                          } else {
                            await ref
                                .read(customerRepositoryProvider)
                                .deleteAddress(address.id);
                          }
                          ref.invalidate(customerAddressesProvider);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(context.tr('edit')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
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

class ApiAddressFormScreen extends ConsumerStatefulWidget {
  const ApiAddressFormScreen({super.key, this.address});
  final CustomerAddress? address;
  @override
  ConsumerState<ApiAddressFormScreen> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<ApiAddressFormScreen> {
  late final Map<String, TextEditingController> fields;
  late bool isDefault;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fields = {
      'label': TextEditingController(text: widget.address?.label),
      'recipient': TextEditingController(text: widget.address?.recipient),
      'phone': TextEditingController(text: widget.address?.phone),
      'city': TextEditingController(text: widget.address?.city),
      'line1': TextEditingController(text: widget.address?.line1),
      'postalCode': TextEditingController(text: widget.address?.postalCode),
    };
    isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (fields.entries
        .where((x) => x.key != 'postalCode')
        .any((x) => x.value.text.trim().isEmpty)) {
      setState(() => error = context.tr('requiredFields'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(customerRepositoryProvider)
          .saveAddress(
            CustomerAddress(
              id: widget.address?.id ?? '',
              label: fields['label']!.text.trim(),
              recipient: fields['recipient']!.text.trim(),
              phone: fields['phone']!.text.trim(),
              city: fields['city']!.text.trim(),
              line1: fields['line1']!.text.trim(),
              postalCode: fields['postalCode']!.text.trim(),
              isDefault: isDefault,
            ),
          );
      ref.invalidate(customerAddressesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MarinaPage(
    title: widget.address == null
        ? context.tr('addAddress')
        : context.tr('editAddress'),
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (final entry in fields.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextField(
              controller: entry.value,
              keyboardType: entry.key == 'phone'
                  ? TextInputType.phone
                  : TextInputType.text,
              decoration: InputDecoration(labelText: context.tr(entry.key)),
            ),
          ),
        SwitchListTile(
          value: isDefault,
          onChanged: (value) => setState(() => isDefault = value),
          title: Text(context.tr('setDefault')),
        ),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : save,
          child: busy
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Text(context.tr('save')),
        ),
      ],
    ),
  );
}

class ApiFavoritesScreen extends ConsumerWidget {
  const ApiFavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = Localizations.localeOf(context).languageCode;
    final favorites = ref.watch(customerFavoritesProvider(culture));
    return SafeArea(
      child: favorites.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(customerFavoritesProvider(culture)),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(icon: Icons.favorite_border)
            : GridView.builder(
                padding: const EdgeInsets.all(18),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 20,
                ),
                itemCount: items.length,
                itemBuilder: (_, index) => Stack(
                  children: [
                    ProductCard(product: items[index]),
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: IconButton.filledTonal(
                        onPressed: () async {
                          await ref
                              .read(customerRepositoryProvider)
                              .removeFavorite(items[index].id);
                          ref.invalidate(customerFavoritesProvider(culture));
                        },
                        icon: const Icon(Icons.favorite),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ApiNotificationsScreen extends ConsumerWidget {
  const ApiNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(customerNotificationsProvider);
    return MarinaPage(
      bottom: PageControls(endpoint: '/customer/notifications', page: notifications.value, loading: notifications.isLoading),
      title: context.tr('notifications'),
      actions: [
        TextButton(
          onPressed: notifications.value?.items.any((x) => x.readUtc == null) == true
              ? () async {
                  await ref
                      .read(customerRepositoryProvider)
                      .readAllNotifications();
                  ref.invalidate(customerNotificationsProvider);
                }
              : null,
          child: Text(context.tr('readAll')),
        ),
      ],
      child: notifications.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(customerNotificationsProvider),
        ),
        data: (page) => page.items.isEmpty
            ? const EmptyState(icon: Icons.notifications_none)
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: page.items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) {
                  final item = page.items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.readUtc == null
                          ? MarinaTheme.blue
                          : MarinaTheme.sand,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                    onTap: () async {
                      if (item.readUtc == null) {
                        await ref
                            .read(customerRepositoryProvider)
                            .readNotification(item.id);
                        ref.invalidate(customerNotificationsProvider);
                      }
                      final route = _safeDeepLink(item.deepLink);
                      if (context.mounted && route != null) {
                        context.push(route);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

String _initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((x) => x.isNotEmpty)
      .take(2);
  final value = words.map((x) => x[0].toUpperCase()).join();
  return value.isEmpty ? 'M' : value;
}

String? _safeDeepLink(String? value) {
  if (value == null || !value.startsWith('/') || value.contains('://')) {
    return null;
  }
  const staticRoutes = {
    '/home',
    '/offers',
    '/new-arrivals',
    '/products',
    '/support',
    '/orders',
    '/returns',
    '/cart',
    '/favorites',
  };
  if (staticRoutes.contains(value)) return value;
  final allowedDetail = RegExp(r'^/(orders|returns|product)/[0-9a-fA-F-]{36}$');
  return allowedDetail.hasMatch(value) ? value : null;
}
