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
    final themeMode = ref.watch(themeModeProvider);
    final p = MarinaPalette.of(context);
    final modeLabel = switch (themeMode) {
      ThemeMode.light => context.tr('themeLight'),
      ThemeMode.dark => context.tr('themeDark'),
      _ => context.tr('themeSystem'),
    };

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(customerProfileProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 122),
          children: [
            Text(
              context.tr('account'),
              style: MarinaType.display(context, size: 27),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: MarinaGradients.header(dark: p.isDark),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: MarinaColors.gold.withValues(alpha: .3)),
              ),
              child: profile.when(
                loading: () => const SizedBox(
                  height: 76,
                  child: LoadingState(),
                ),
                error: (_, _) => ErrorState(
                  onRetry: () => ref.invalidate(customerProfileProvider),
                ),
                data: (data) => Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: MarinaGradients.gold,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MarinaColors.navySoft,
                        ),
                        child: Text(
                          _initials(data.displayName),
                          style: const TextStyle(
                            color: MarinaColors.goldBright,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: 1,
                            fontFamily: 'Marcellus',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MarinaType.display(
                              context,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB7C9DB),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _QuickGrid(),
            const SizedBox(height: 22),
            _GroupLabel(context.tr('sectionPreferences')),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _GroupTile(
                  icon: Icons.person_outline_rounded,
                  label: context.tr('editProfile'),
                  route: '/edit-profile',
                ),
                _GroupTile(
                  icon: Icons.language_rounded,
                  label: context.tr('language'),
                  route: '/language',
                ),
                _GroupTile(
                  icon: Icons.contrast_rounded,
                  label: context.tr('appearance'),
                  route: '/appearance',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: p.goldSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      modeLabel,
                      style: TextStyle(
                        color: p.gold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _GroupTile(
                  icon: Icons.shield_outlined,
                  label: context.tr('security'),
                  route: '/security',
                ),
              ],
            ),
            const SizedBox(height: 18),
            _GroupLabel(context.tr('sectionSupport')),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _GroupTile(
                  icon: Icons.storefront_outlined,
                  label: context.tr('brands'),
                  route: '/brands',
                ),
                _GroupTile(
                  icon: Icons.info_outline_rounded,
                  label: context.tr('about'),
                  route: '/about',
                ),
                _GroupTile(
                  icon: Icons.privacy_tip_outlined,
                  label: context.tr('privacy'),
                  route: '/privacy',
                ),
                _GroupTile(
                  icon: Icons.gavel_outlined,
                  label: context.tr('terms'),
                  route: '/terms',
                ),
                _GroupTile(
                  icon: Icons.help_outline_rounded,
                  label: context.tr('help'),
                  route: '/support',
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: p.isDark
                    ? const Color(0xFFE58877)
                    : MarinaColors.danger,
                side: BorderSide(
                  color: (p.isDark
                          ? const Color(0xFFE58877)
                          : MarinaColors.danger)
                      .withValues(alpha: .45),
                ),
                minimumSize: const Size.fromHeight(54),
              ),
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
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: Text(context.tr('logout')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final tiles = [
      (
        Icons.receipt_long_outlined,
        context.tr('orders'),
        '/orders',
      ),
      (
        Icons.assignment_return_outlined,
        context.tr('returns'),
        '/returns',
      ),
      (
        Icons.favorite_outline_rounded,
        context.tr('favorites'),
        '/favorites',
      ),
      (
        Icons.location_on_outlined,
        context.tr('addresses'),
        '/addresses',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .78,
      ),
      itemBuilder: (context, i) => Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(tiles[i].$3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line.withValues(alpha: .9)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tiles[i].$1, size: 22, color: p.gold),
                const SizedBox(height: 7),
                Text(
                  tiles[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
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

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: MarinaType.kicker(context, color: MarinaPalette.of(context).muted),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line.withValues(alpha: .9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Divider(height: 1, color: p.line.withValues(alpha: .7)),
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.icon,
    required this.label,
    required this.route,
    this.trailing,
  });

  final IconData icon;
  final String label, route;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 21, color: p.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: p.muted.withValues(alpha: .6),
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
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: MarinaPalette.of(context).isDark
                          ? const Color(0xFFE58877)
                          : MarinaColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              MarinaGoldButton(
                label: context.tr('save'),
                icon: Icons.check_rounded,
                busy: busy,
                onPressed: busy ? null : save,
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
                    final p = MarinaPalette.of(context);
                    return MarinaSectionCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.goldSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: p.gold.withValues(alpha: .25),
                              ),
                            ),
                            child: Icon(
                              Icons.home_outlined,
                              size: 21,
                              color: p.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        address.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          color: p.ink,
                                        ),
                                      ),
                                    ),
                                    if (address.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: MarinaGradients.gold,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          context.tr('defaultAddress'),
                                          style: const TextStyle(
                                            color: MarinaColors.onGold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${address.recipient}\n${address.line1}, ${address.city}\n${address.phone}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
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
          contentPadding: EdgeInsets.zero,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(
                color: MarinaPalette.of(context).isDark
                    ? const Color(0xFFE58877)
                    : MarinaColors.danger,
              ),
            ),
          ),
        const SizedBox(height: 16),
        MarinaGoldButton(
          label: context.tr('save'),
          icon: Icons.check_rounded,
          busy: busy,
          onPressed: busy ? null : save,
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
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * .7,
                    child: EmptyState(
                      icon: Icons.favorite_outline_rounded,
                      message: context.tr('emptyWishlist'),
                      action: MarinaGoldButton(
                        label: context.tr('continueShopping'),
                        icon: Icons.storefront_rounded,
                        onPressed: () => context.go('/products'),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        context.tr('favorites'),
                        style: MarinaType.display(context, size: 26),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(customerFavoritesProvider(culture).future),
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 122),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .62,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 18,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, index) => Stack(
                          children: [
                            ProductCard(product: items[index]),
                            PositionedDirectional(
                              top: 13,
                              end: 13,
                              child: GestureDetector(
                                onTap: () async {
                                  await ref
                                      .read(customerRepositoryProvider)
                                      .removeFavorite(items[index].id);
                                  ref.invalidate(
                                    customerFavoritesProvider(culture),
                                  );
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: .92),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: .18),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 17,
                                    color: MarinaColors.danger,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
      bottom: PageControls(
        endpoint: '/customer/notifications',
        page: notifications.value,
        loading: notifications.isLoading,
      ),
      title: context.tr('notifications'),
      actions: [
        TextButton(
          onPressed:
              notifications.value?.items.any((x) => x.readUtc == null) == true
                  ? () async {
                      await ref
                          .read(customerRepositoryProvider)
                          .readAllNotifications();
                      ref.invalidate(customerNotificationsProvider);
                    }
                  : null,
          child: Text(context.tr('readAll')),
        ),
        const SizedBox(width: 4),
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
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = page.items[index];
                  final unread = item.readUtc == null;
                  final p = MarinaPalette.of(context);
                  return MarinaSectionCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () async {
                        if (unread) {
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
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: unread ? p.goldSoft : p.surfaceSoft,
                                shape: BoxShape.circle,
                                border: unread
                                    ? Border.all(
                                        color: p.gold.withValues(alpha: .4),
                                      )
                                    : null,
                              ),
                              child: Icon(
                                unread
                                    ? Icons.notifications_rounded
                                    : Icons.notifications_none_rounded,
                                size: 20,
                                color: unread ? p.gold : p.muted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: unread
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 14,
                                            color: p.ink,
                                          ),
                                        ),
                                      ),
                                      if (unread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: p.gold,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.body,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: p.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
