import '../../../core/network/api_models.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/marina_wordmark.dart';
import '../data/admin_operations_repository.dart';

const adminItems = [
  ('dashboard', Icons.dashboard_outlined, '/admin', 'Reports.View'),
  ('products', Icons.shopping_bag_outlined, '/admin/products', 'Products.View'),
  ('categories', Icons.category_outlined, '/admin/reference', 'Products.View'),
  (
    'inventory',
    Icons.inventory_2_outlined,
    '/admin/inventory',
    'Inventory.View',
  ),
  ('orders', Icons.receipt_long_outlined, '/admin/orders', 'Orders.View'),
  (
    'adminReturns',
    Icons.assignment_return_outlined,
    '/admin/returns',
    'Orders.View',
  ),
  ('adminReviews', Icons.reviews_outlined, '/admin/reviews', 'Products.Edit'),
  ('customers', Icons.people_outline, '/admin/customers', 'Customers.View'),
  ('coupons', Icons.sell_outlined, '/admin/coupons', 'Coupons.Manage'),
  ('reports', Icons.pie_chart_outline, '/admin/reports', 'Reports.View'),
  (
    'usersRoles',
    Icons.manage_accounts_outlined,
    '/admin/users',
    'Users.Manage|Roles.Manage',
  ),
  ('audit', Icons.article_outlined, '/admin/audit', 'AuditLogs.View'),
  (
    'securityEvents',
    Icons.security_outlined,
    '/admin/security-events',
    'AuditLogs.View',
  ),
  (
    'manageNotifications',
    Icons.notifications_active_outlined,
    '/admin/notifications',
    'Notifications.Manage',
  ),
  ('settings', Icons.settings_outlined, '/admin/settings', 'Settings.Manage'),
];

final currentPermissionsProvider = FutureProvider<Set<String>>(
  (_) => apiClient.currentPermissions(),
);

bool _hasPermission(Set<String> permissions, String requirement) =>
    requirement.split('|').any(permissions.contains);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final permissions = ref.watch(currentPermissionsProvider).value ?? const {};
    final nav = Material(
      color: Colors.white.withValues(alpha: .55),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const MarinaWordmark(),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in adminItems)
                      if (_hasPermission(permissions, item.$4))
                        ListTile(
                          dense: true,
                          leading: Icon(item.$2),
                          title: Text(context.tr(item.$1)),
                          onTap: () => context.go(item.$3),
                        ),
                  ],
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.admin_panel_settings_outlined),
                ),
                title: Text(context.tr('administrator')),
                subtitle: Text(context.tr('mfaProtectedSession')),
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 240, child: nav),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const MarinaWordmark()),
      drawer: Drawer(child: nav),
      body: child,
    );
  }
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);
    final permissions = ref.watch(currentPermissionsProvider).value ?? const {};
    return SafeArea(
      child: dashboard.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(adminDashboardProvider),
        ),
        data: (data) {
          final recent = (data['recentOrders'] as List? ?? const [])
              .cast<Map>();
          final metrics = [
            (
              context.tr('totalSales'),
              'SAR ${_number(data['sales'])}',
              Icons.payments_outlined,
            ),
            (
              context.tr('orders'),
              _number(data['orders']),
              Icons.shopping_cart_outlined,
            ),
            (
              context.tr('newCustomers'),
              _number(data['newCustomers']),
              Icons.people_outline,
            ),
            (
              context.tr('averageOrder'),
              'SAR ${_number(data['averageOrderValue'])}',
              Icons.sell_outlined,
            ),
            (
              context.tr('lowStock'),
              _number(data['lowStock']),
              Icons.inventory_2_outlined,
            ),
          ];
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminDashboardProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  children: [
                    Text(
                      context.tr('dashboard'),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    if (permissions.contains('Products.Create'))
                      FilledButton.icon(
                        onPressed: () => context.push('/admin/products/new'),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('addProduct')),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: metrics.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 1100
                        ? 4
                        : 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (_, i) => _MetricCard(
                    label: metrics[i].$1,
                    value: metrics[i].$2,
                    icon: metrics[i].$3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('recentOrders'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const EmptyState(icon: Icons.receipt_long_outlined)
                else
                  for (final order in recent)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: MarinaTheme.sand,
                        child: Icon(Icons.receipt_long),
                      ),
                      title: Text((order['publicNumber'] ?? '').toString()),
                      subtitle: Text(_enumText(order['status'])),
                      trailing: Text('SAR ${_number(order['total'])}'),
                      onTap: () =>
                          _showData(context, Map<String, dynamic>.from(order)),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: MarinaTheme.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: MarinaTheme.blue.withValues(alpha: .5),
          child: Icon(icon),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AdminLiveListScreen extends ConsumerStatefulWidget {
  const AdminLiveListScreen({
    super.key,
    required this.titleKey,
    required this.endpoint,
    this.addRoute,
  });
  final String titleKey, endpoint;
  final String? addRoute;

  @override
  ConsumerState<AdminLiveListScreen> createState() => _AdminLiveListState();
}

class _AdminLiveListState extends ConsumerState<AdminLiveListScreen> {
  String search = '';
  int page = 1;
  String get requestEndpoint {
    final query =
        'page=$page&pageSize=30'
        '${search.isEmpty ? '' : '&search=${Uri.encodeQueryComponent(search)}'}';
    return '${widget.endpoint}${widget.endpoint.contains('?') ? '&' : '?'}$query';
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(adminListProvider(requestEndpoint));
    final permissions = ref.watch(currentPermissionsProvider).value ?? const {};
    final canAdd = switch (widget.endpoint) {
      '/admin/catalog/products' => permissions.contains('Products.Create'),
      '/admin/coupons' => permissions.contains('Coupons.Manage'),
      _ => true,
    };
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(widget.titleKey),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                if (widget.addRoute != null && canAdd)
                  FilledButton.icon(
                    onPressed: () => context.push(widget.addRoute!),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('save')),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: TextField(
              onChanged: (value) => setState(() {
                search = value.trim().toLowerCase();
                page = 1;
              }),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('search'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: result.when(
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(
                message: apiFailureMessage(error, context.tr('retry')),
                onRetry: () =>
                    ref.invalidate(adminListProvider(requestEndpoint)),
              ),
              data: (all) {
                final items = search.isEmpty
                    ? all
                    : all
                          .where(
                            (x) => jsonEncode(x).toLowerCase().contains(search),
                          )
                          .toList();
                if (items.isEmpty && page == 1) {
                  return const EmptyState(icon: Icons.inbox_outlined);
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.refresh(
                          adminListProvider(requestEndpoint).future,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, i) {
                            final item = items[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: MarinaTheme.sand,
                                child: Icon(Icons.data_object),
                              ),
                              title: Text(_title(item)),
                              subtitle: Text(
                                _subtitle(item),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _manage(item),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: context.tr('previousPage'),
                            onPressed: page == 1
                                ? null
                                : () => setState(() => page--),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('${context.tr('page')} $page'),
                          IconButton(
                            tooltip: context.tr('nextPage'),
                            onPressed: all.length < 30
                                ? null
                                : () => setState(() => page++),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _manage(Map<String, dynamic> item) async {
    final permissions = await ref.read(currentPermissionsProvider.future);
    if (!mounted) return;
    try {
      switch (widget.endpoint) {
        case '/admin/inventory':
          if (permissions.contains('Inventory.Adjust')) {
            await _adjustInventory(item);
          } else {
            await _showData(context, item);
          }
          return;
        case '/admin/orders':
          await _manageOrder(item, permissions);
          return;
        case '/admin/customers':
          final details =
              (await apiClient.dio.get('/admin/customers/${item['id']}')).data
                  as Map<String, dynamic>;
          if (mounted) await _showData(context, details);
          return;
        case '/admin/coupons':
          await _editCoupon(item);
          return;
        case '/admin/access/users':
          await _manageUser(item);
          return;
        case '/admin/catalog/products':
          await _manageProduct(item, permissions);
          return;
        default:
          await _showData(context, item);
          return;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiFailureMessage(error, context.tr('retry'))),
          ),
        );
      }
    }
  }

  Future<void> _adjustInventory(Map<String, dynamic> item) async {
    final delta = TextEditingController();
    final reason = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('adjust')} ${item['sku']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: delta,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText: context.tr('quantityChange'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: InputDecoration(labelText: context.tr('reason')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop('history'),
            child: Text(context.tr('movementHistory')),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => context.pop('apply'),
            child: Text(context.tr('apply')),
          ),
        ],
      ),
    );
    final change = int.tryParse(delta.text);
    final reasonText = reason.text.trim();
    delta.dispose();
    reason.dispose();
    if (action == 'history') {
      final movements = ApiPage<Map<String, dynamic>>.fromJson(
        (await apiClient.dio.get('/admin/inventory/${item['productVariantId']}/movements')).data,
        (json) => json,
      ).items;
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${context.tr('movementHistory')} — ${item['sku']}'),
            content: SizedBox(
              width: 620,
              child: movements.isEmpty
                  ? EmptyState(icon: Icons.history)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: movements.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, index) {
                        final movement = movements[index];
                        return ListTile(
                          title: Text(
                            '${movement['delta'] ?? 0} — ${movement['reason'] ?? ''}',
                          ),
                          subtitle: Text(
                            '${movement['oldQuantity'] ?? 0} → ${movement['newQuantity'] ?? 0} • ${movement['createdUtc'] ?? ''}',
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(context.tr('close')),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (action != 'apply' ||
        change == null ||
        change == 0 ||
        reasonText.isEmpty) {
      return;
    }
    await apiClient.dio.post(
      '/admin/inventory/${item['productVariantId']}/adjust',
      data: {'delta': change, 'reason': reasonText, 'type': 4},
    );
    ref.invalidate(adminListProvider(requestEndpoint));
  }

  Future<void> _manageOrder(
    Map<String, dynamic> item,
    Set<String> permissions,
  ) async {
    final details =
        (await apiClient.dio.get('/admin/orders/${item['id']}')).data
            as Map<String, dynamic>;
    if (!mounted) return;
    final current = ApiOrderStatus.parse(item['status']).index;
    final next = current < 6
        ? current + 1
        : null;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_title(details)),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(details),
            ),
          ),
        ),
        actions: [
          if ((current == 0 || current == 1) &&
              permissions.contains('Orders.Cancel'))
            TextButton(
              onPressed: () => context.pop('cancel'),
              child: Text(context.tr('cancelOrder')),
            ),
          if (next != null && permissions.contains('Orders.UpdateStatus'))
            FilledButton(
              onPressed: () => context.pop('next'),
              child: Text(
                '${context.tr('moveTo')} ${_orderStatus(context, next)}',
              ),
            ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
    if (action == 'next') {
      await apiClient.dio.put(
        '/admin/orders/${item['id']}/status',
        data: {'status': ApiOrderStatus.values[next!].wireName, 'reason': 'Updated by administrator'},
      );
    } else if (action == 'cancel') {
      await apiClient.dio.post(
        '/admin/orders/${item['id']}/cancel',
        data: {'reason': 'Cancelled by administrator'},
      );
    } else {
      return;
    }
    ref.invalidate(adminListProvider(requestEndpoint));
    ref.invalidate(adminDashboardProvider);
  }

  Future<void> _editCoupon(Map<String, dynamic> item) async {
    final usage =
        (await apiClient.dio.get('/admin/coupons/${item['id']}/usage')).data
            as Map<String, dynamic>;
    if (!mounted) return;
    final code = TextEditingController(text: item['code']?.toString());
    final value = TextEditingController(text: item['value']?.toString());
    final minimum = TextEditingController(
      text: item['minimumPurchase']?.toString(),
    );
    final maximum = TextEditingController(
      text: item['maximumDiscount']?.toString(),
    );
    final maxUses = TextEditingController(text: item['maxUses']?.toString());
    final maxPerCustomer = TextEditingController(
      text: item['maxUsesPerCustomer']?.toString(),
    );
    var type = ApiDiscountType.parse(item['type']).index;
    var validFrom =
        DateTime.tryParse(item['validFromUtc']?.toString() ?? '') ??
        DateTime.now();
    var validTo =
        DateTime.tryParse(item['validToUtc']?.toString() ?? '') ??
        DateTime.now().add(const Duration(days: 30));
    var active = item['isActive'] == true;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('editCoupon')),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.people_outline),
                    title: Text(context.tr('couponUsage')),
                    trailing: Text((usage['total'] ?? 0).toString()),
                  ),
                  TextField(
                    controller: code,
                    decoration: InputDecoration(labelText: context.tr('code')),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: context.tr('discountType'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(context.tr('percentage')),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(context.tr('fixedAmount')),
                      ),
                    ],
                    onChanged: (next) => setDialogState(() => type = next ?? 0),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: context.tr('value')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minimum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('minimumPurchase'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maximum,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('maximumDiscount'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: maxUses,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr('maxUses'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: maxPerCustomer,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.tr('maxUsesPerCustomer'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 3650),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                              initialDate: validFrom,
                            );
                            if (selected != null) {
                              setDialogState(() => validFrom = selected);
                            }
                          },
                          child: Text(
                            '${context.tr('validFrom')}: ${validFrom.toLocal().toString().split(' ').first}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              firstDate: validFrom,
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                              initialDate: validTo.isBefore(validFrom)
                                  ? validFrom
                                  : validTo,
                            );
                            if (selected != null) {
                              setDialogState(() => validTo = selected);
                            }
                          },
                          child: Text(
                            '${context.tr('validTo')}: ${validTo.toLocal().toString().split(' ').first}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    value: active,
                    onChanged: (x) => setDialogState(() => active = x),
                    title: Text(context.tr('active')),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    final amount = double.tryParse(value.text);
    final newCode = code.text.trim();
    final minimumValue = double.tryParse(minimum.text);
    final maximumValue = double.tryParse(maximum.text);
    final maxUsesValue = int.tryParse(maxUses.text);
    final maxPerCustomerValue = int.tryParse(maxPerCustomer.text);
    for (final controller in [
      code,
      value,
      minimum,
      maximum,
      maxUses,
      maxPerCustomer,
    ]) {
      controller.dispose();
    }
    if (accepted != true || amount == null || newCode.isEmpty) return;
    await apiClient.dio.put(
      '/admin/coupons/${item['id']}',
      data: {
        'code': newCode,
        'type': type,
        'value': amount,
        'minimumPurchase': minimumValue,
        'maximumDiscount': maximumValue,
        'validFromUtc': validFrom.toUtc().toIso8601String(),
        'validToUtc': validTo.toUtc().toIso8601String(),
        'maxUses': maxUsesValue,
        'maxUsesPerCustomer': maxPerCustomerValue,
        'isActive': active,
      },
    );
    ref.invalidate(adminListProvider(requestEndpoint));
  }

  Future<void> _manageUser(Map<String, dynamic> item) async {
    final details =
        (await apiClient.dio.get('/admin/access/users/${item['id']}')).data
            as Map<String, dynamic>;
    final roles =
        ((await apiClient.dio.get('/admin/access/roles')).data as List)
            .map((x) => (x as Map<String, dynamic>)['name'].toString())
            .toList();
    final selected = Set<String>.from(
      (details['roles'] as List? ?? const []).map((x) => x.toString()),
    );
    final sessions = (details['sessions'] as List? ?? const [])
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
    var active = details['isActive'] == true;
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(details['email'].toString()),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: active,
                    onChanged: (x) => setDialogState(() => active = x),
                    title: Text(context.tr('accountActive')),
                  ),
                  for (final role in roles)
                    CheckboxListTile(
                      value: selected.contains(role),
                      onChanged: (checked) => setDialogState(
                        () => checked == true
                            ? selected.add(role)
                            : selected.remove(role),
                      ),
                      title: Text(role),
                    ),
                  if (sessions.isNotEmpty) const Divider(),
                  for (final session in sessions)
                    ListTile(
                      leading: const Icon(Icons.devices_outlined),
                      title: Text(
                        (session['deviceName'] ?? context.tr('activeSession'))
                            .toString(),
                      ),
                      subtitle: Text(
                        '${session['ipAddress'] ?? ''} • ${session['lastSeenUtc'] ?? ''}',
                      ),
                      trailing: IconButton(
                        tooltip: context.tr('revoke'),
                        onPressed: () async {
                          await apiClient.dio.delete(
                            '/admin/access/users/${item['id']}/sessions/${session['id']}',
                          );
                          setDialogState(() => sessions.remove(session));
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    await apiClient.dio.put(
      '/admin/access/users/${item['id']}/roles',
      data: {'roles': selected.toList()},
    );
    if (active != details['isActive']) {
      await apiClient.dio.put(
        '/admin/access/users/${item['id']}/active',
        data: {'active': active},
      );
    }
    ref.invalidate(adminListProvider(requestEndpoint));
  }

  Future<void> _manageProduct(
    Map<String, dynamic> item,
    Set<String> permissions,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (permissions.contains('Products.Edit'))
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.tr('editProduct')),
                onTap: () => context.pop('edit'),
              ),
            if (permissions.contains('Products.Delete'))
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(context.tr('deactivateProduct')),
                onTap: () => context.pop('delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == null &&
        !permissions.contains('Products.Edit') &&
        !permissions.contains('Products.Delete')) {
      await _showData(context, item);
      return;
    }
    if (action == 'edit') {
      await context.push('/admin/products/${item['id']}/edit');
      ref.invalidate(adminListProvider(requestEndpoint));
    } else if (action == 'delete') {
      await apiClient.dio.delete('/admin/catalog/products/${item['id']}');
      ref.invalidate(adminListProvider(requestEndpoint));
    }
  }
}

class AdminAccessScreen extends ConsumerWidget {
  const AdminAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentPermissionsProvider).value ?? const {};
    final canUsers = permissions.contains('Users.Manage');
    final canRoles = permissions.contains('Roles.Manage');
    final pages = <Widget>[
      if (canUsers) const _AdminUsersTab(),
      if (canRoles) const _AdminRolesTab(),
    ];
    return DefaultTabController(
      length: pages.isEmpty ? 1 : pages.length,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('usersRoles'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            TabBar(
              tabs: [
                if (canUsers) Tab(text: context.tr('users')),
                if (canRoles) Tab(text: context.tr('rolesPermissions')),
                if (pages.isEmpty) Tab(text: context.tr('usersRoles')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: pages.isEmpty
                    ? const [EmptyState(icon: Icons.lock_outline)]
                    : pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();
  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  Future<void> _manage(Map<String, dynamic> item) async {
    final details =
        (await apiClient.dio.get('/admin/access/users/${item['id']}')).data
            as Map<String, dynamic>;
    final permissions = await ref.read(currentPermissionsProvider.future);
    final canManageRoles = permissions.contains('Roles.Manage');
    final roles = canManageRoles
        ? ((await apiClient.dio.get('/admin/access/roles')).data as List)
              .map((x) => (x as Map)['name'].toString())
              .toList()
        : <String>[];
    final selected = Set<String>.from(
      (details['roles'] as List? ?? const []).map((x) => x.toString()),
    );
    final sessions = (details['sessions'] as List? ?? const [])
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
    var active = details['isActive'] == true;
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(details['email'].toString()),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: active,
                    onChanged: (value) => update(() => active = value),
                    title: Text(context.tr('accountActive')),
                  ),
                  for (final role in roles)
                    CheckboxListTile(
                      value: selected.contains(role),
                      onChanged: (value) => update(
                        () => value == true
                            ? selected.add(role)
                            : selected.remove(role),
                      ),
                      title: Text(role),
                    ),
                  if (sessions.isNotEmpty) const Divider(),
                  for (final session in sessions)
                    ListTile(
                      leading: const Icon(Icons.devices_outlined),
                      title: Text(
                        (session['deviceName'] ?? context.tr('activeSession'))
                            .toString(),
                      ),
                      subtitle: Text((session['ipAddress'] ?? '').toString()),
                      trailing: IconButton(
                        tooltip: context.tr('revoke'),
                        onPressed: () async {
                          await apiClient.dio.delete(
                            '/admin/access/users/${item['id']}/sessions/${session['id']}',
                          );
                          update(() => sessions.remove(session));
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    try {
      if (canManageRoles) {
        await apiClient.dio.put(
          '/admin/access/users/${item['id']}/roles',
          data: {'roles': selected.toList()},
        );
      }
      if (active != details['isActive']) {
        await apiClient.dio.put(
          '/admin/access/users/${item['id']}/active',
          data: {'active': active},
        );
      }
      ref.invalidate(adminListProvider('/admin/access/users'));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiFailureMessage(error, context.tr('retry'))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminListProvider('/admin/access/users'));
    return users.when(
      loading: () => const LoadingState(),
      error: (_, _) => ErrorState(
        onRetry: () => ref.invalidate(adminListProvider('/admin/access/users')),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () =>
            ref.refresh(adminListProvider('/admin/access/users').future),
        child: items.isEmpty
            ? ListView(children: const [EmptyState(icon: Icons.people_outline)])
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(_title(items[index])),
                  subtitle: Text(_subtitle(items[index])),
                  trailing: const Icon(Icons.manage_accounts_outlined),
                  onTap: () => _manage(items[index]),
                ),
              ),
      ),
    );
  }
}

class _AdminRolesTab extends ConsumerWidget {
  const _AdminRolesTab();

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> role,
  ) async {
    final permissions = await ref.read(
      adminListProvider('/admin/access/permissions').future,
    );
    final selectedNames = Set<String>.from(
      (role['permissions'] as List? ?? const []).map((x) => x.toString()),
    );
    final selectedIds = <String>{
      for (final permission in permissions)
        if (selectedNames.contains(permission['name']))
          permission['id'].toString(),
    };
    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('${role['name']} — ${context.tr('permissions')}'),
          content: SizedBox(
            width: 600,
            height: 520,
            child: ListView(
              children: [
                for (final permission in permissions)
                  CheckboxListTile(
                    value: selectedIds.contains(permission['id'].toString()),
                    title: Text(permission['name'].toString()),
                    onChanged: (value) => update(
                      () => value == true
                          ? selectedIds.add(permission['id'].toString())
                          : selectedIds.remove(permission['id'].toString()),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    try {
      await apiClient.dio.put(
        '/admin/access/roles/${role['id']}/permissions',
        data: {'permissionIds': selectedIds.toList()},
      );
      ref.invalidate(adminListProvider('/admin/access/roles'));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiFailureMessage(error, context.tr('retry'))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(adminListProvider('/admin/access/roles'));
    return roles.when(
      loading: () => const LoadingState(),
      error: (_, _) => ErrorState(
        onRetry: () => ref.invalidate(adminListProvider('/admin/access/roles')),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () =>
            ref.refresh(adminListProvider('/admin/access/roles').future),
        child: items.isEmpty
            ? ListView(
                children: const [EmptyState(icon: Icons.policy_outlined)],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.policy_outlined),
                  ),
                  title: Text(_title(items[index])),
                  subtitle: Text(
                    '${(items[index]['permissions'] as List? ?? const []).length} ${context.tr('permissions')}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _edit(context, ref, items[index]),
                ),
              ),
      ),
    );
  }
}

class AdminReferenceScreen extends StatelessWidget {
  const AdminReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Text(
              context.tr('referenceData'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.tr('categories')),
              Tab(text: context.tr('brands')),
              Tab(text: context.tr('colors')),
              Tab(text: context.tr('sizes')),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ReferenceTab(
                  kind: 'category',
                  endpoint: '/admin/catalog/categories',
                ),
                _ReferenceTab(
                  kind: 'brand',
                  endpoint: '/admin/reference/brands',
                ),
                _ReferenceTab(
                  kind: 'color',
                  endpoint: '/admin/reference/colors',
                ),
                _ReferenceTab(kind: 'size', endpoint: '/admin/reference/sizes'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReferenceTab extends ConsumerWidget {
  const _ReferenceTab({required this.kind, required this.endpoint});
  final String kind, endpoint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref.watch(adminListProvider(endpoint));
    final permissions = ref.watch(currentPermissionsProvider).value ?? const {};
    final canCreate = permissions.contains('Products.Create');
    final canEdit = permissions.contains('Products.Edit');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 4),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: canCreate
                ? FilledButton.icon(
                    onPressed: () => _edit(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text('${context.tr('add')} ${context.tr(kind)}'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: values.when(
            loading: () => const LoadingState(),
            error: (error, _) => ErrorState(
              message: apiFailureMessage(error, context.tr('retry')),
              onRetry: () => ref.invalidate(adminListProvider(endpoint)),
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(icon: Icons.category_outlined)
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(adminListProvider(endpoint).future),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(28),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, index) => ListTile(
                        title: Text(_title(items[index])),
                        subtitle: Text(_subtitle(items[index])),
                        trailing: canEdit
                            ? const Icon(Icons.edit_outlined)
                            : null,
                        onTap: canEdit
                            ? () => _edit(context, ref, items[index])
                            : null,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    Map<String, dynamic>? item,
  ]) async {
    final translations = item?['translations'] as List? ?? const [];
    String translatedName(String culture) {
      for (final raw in translations) {
        final value = raw as Map;
        if (value['culture'] == culture) {
          return (value['name'] ?? '').toString();
        }
      }
      return '';
    }

    final code = TextEditingController(
      text:
          (item?[kind == 'brand' || kind == 'category' ? 'slug' : 'code'] ?? '')
              .toString(),
    );
    final english = TextEditingController(text: translatedName('en'));
    final arabic = TextEditingController(text: translatedName('ar'));
    final extra = TextEditingController(
      text: kind == 'color'
          ? (item?['hex'] ?? '#000000').toString()
          : (item?['sortOrder'] ?? 0).toString(),
    );
    var active = item?['isActive'] != false;
    var parentId = item?['parentId']?.toString();
    final categories = kind == 'category'
        ? await ref.read(adminListProvider(endpoint).future)
        : const <Map<String, dynamic>>[];
    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            '${context.tr(item == null ? 'add' : 'edit')} ${context.tr(kind)}',
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: code,
                    decoration: InputDecoration(
                      labelText: kind == 'brand' || kind == 'category'
                          ? context.tr('slug')
                          : context.tr('code'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: english,
                    decoration: InputDecoration(
                      labelText: context.tr('englishName'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: arabic,
                    decoration: InputDecoration(
                      labelText: context.tr('arabicName'),
                    ),
                  ),
                  if (kind == 'category') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: parentId,
                      decoration: InputDecoration(
                        labelText: context.tr('parentCategory'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.tr('none')),
                        ),
                        ...categories
                            .where(
                              (x) =>
                                  x['id']?.toString() !=
                                  item?['id']?.toString(),
                            )
                            .map(
                              (x) => DropdownMenuItem(
                                value: x['id'].toString(),
                                child: Text(_title(x)),
                              ),
                            ),
                      ],
                      onChanged: (value) => parentId = value,
                    ),
                  ],
                  if (kind == 'color' ||
                      kind == 'size' ||
                      kind == 'category') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: extra,
                      decoration: InputDecoration(
                        labelText: kind == 'color'
                            ? context.tr('hexColor')
                            : context.tr('sortOrder'),
                      ),
                    ),
                  ],
                  if (kind == 'brand' || kind == 'category')
                    SwitchListTile(
                      value: active,
                      title: Text(context.tr('active')),
                      onChanged: (value) => update(() => active = value),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    final codeValue = code.text.trim();
    final enValue = english.text.trim();
    final arValue = arabic.text.trim();
    final extraValue = extra.text.trim();
    code.dispose();
    english.dispose();
    arabic.dispose();
    extra.dispose();
    if (accepted != true || codeValue.isEmpty || enValue.isEmpty) return;

    final names = [
      {'culture': 'en', 'name': enValue},
      if (arValue.isNotEmpty) {'culture': 'ar', 'name': arValue},
    ];
    late final Map<String, dynamic> payload;
    late final String writeEndpoint;
    if (kind == 'category') {
      payload = {
        'slug': codeValue,
        'parentId': parentId,
        'sortOrder': int.tryParse(extraValue) ?? 0,
        'isActive': active,
        'translations': names,
      };
      writeEndpoint = item == null
          ? '/admin/catalog/categories'
          : '/admin/reference/categories/${item['id']}';
    } else if (kind == 'brand') {
      payload = {'slug': codeValue, 'isActive': active, 'translations': names};
      writeEndpoint =
          '/admin/reference/brands${item == null ? '' : '/${item['id']}'}';
    } else if (kind == 'color') {
      payload = {'code': codeValue, 'hex': extraValue, 'translations': names};
      writeEndpoint =
          '/admin/reference/colors${item == null ? '' : '/${item['id']}'}';
    } else {
      payload = {
        'code': codeValue,
        'sortOrder': int.tryParse(extraValue) ?? 0,
        'translations': names,
      };
      writeEndpoint =
          '/admin/reference/sizes${item == null ? '' : '/${item['id']}'}';
    }
    try {
      if (item == null) {
        await apiClient.dio.post(writeEndpoint, data: payload);
      } else {
        await apiClient.dio.put(writeEndpoint, data: payload);
      }
      ref.invalidate(adminListProvider(endpoint));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiFailureMessage(error, context.tr('retry'))),
          ),
        );
      }
    }
  }
}

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(adminReportProvider);
    return SafeArea(
      child: report.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(adminReportProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminReportProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Text(
                context.tr('reports'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text('Period: ${data['days']} days • Since ${data['since']}'),
              const SizedBox(height: 24),
              _ReportSection(
                title: context.tr('revenue'),
                values: data['revenue'] as List? ?? const [],
              ),
              _ReportSection(
                title: context.tr('bestSellers'),
                values: data['bestSellers'] as List? ?? const [],
              ),
              _ReportSection(
                title: context.tr('orderStatuses'),
                values: data['statuses'] as List? ?? const [],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.values});
  final String title;
  final List values;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 18),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (values.isEmpty)
            Text(context.tr('noDataForPeriod'))
          else
            for (final value in values)
              ListTile(
                dense: true,
                title: Text(_title(Map<String, dynamic>.from(value as Map))),
                subtitle: Text(_subtitle(Map<String, dynamic>.from(value))),
              ),
        ],
      ),
    ),
  );
}

class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({super.key, this.productId});
  final String? productId;
  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormState();
}

class _AdminProductFormState extends ConsumerState<AdminProductFormScreen> {
  final slug = TextEditingController(),
      english = TextEditingController(),
      arabic = TextEditingController();
  final englishDescription = TextEditingController(),
      arabicDescription = TextEditingController(),
      sku = TextEditingController(),
      price = TextEditingController(),
      stock = TextEditingController();
  String? categoryId, brandId, colorId, sizeId, error;
  bool busy = false,
      loaded = false,
      isActive = true,
      isFeatured = false,
      isNewArrival = true,
      isOffer = false;
  List<Map<String, dynamic>> variants = const [];
  List<Map<String, dynamic>> images = const [];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _load();
    } else {
      loaded = true;
    }
  }

  Future<void> _load() async {
    setState(() => busy = true);
    try {
      final responses = await Future.wait([
        apiClient.dio.get('/admin/catalog/products/${widget.productId}'),
        apiClient.dio.get('/admin/media/products/${widget.productId}/images'),
      ]);
      final data = responses.first.data as Map<String, dynamic>;
      slug.text = (data['slug'] ?? '').toString();
      categoryId = data['categoryId']?.toString();
      brandId = data['brandId']?.toString();
      isActive = data['isActive'] == true;
      isFeatured = data['isFeatured'] == true;
      isNewArrival = data['isNewArrival'] == true;
      isOffer = data['isOffer'] == true;
      for (final raw in data['translations'] as List? ?? const []) {
        final translation = raw as Map<String, dynamic>;
        if (translation['culture'] == 'ar') {
          arabic.text = (translation['name'] ?? '').toString();
          arabicDescription.text = (translation['description'] ?? '')
              .toString();
        } else {
          english.text = (translation['name'] ?? '').toString();
          englishDescription.text = (translation['description'] ?? '')
              .toString();
        }
      }
      variants = (data['variants'] as List? ?? const [])
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      images = (responses.last.data as List)
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      loaded = true;
    } catch (e) {
      if (mounted) {
        error = apiFailureMessage(e, context.tr('loadProductFailed'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      slug,
      english,
      arabic,
      englishDescription,
      arabicDescription,
      sku,
      price,
      stock,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    final parsedPrice = double.tryParse(price.text);
    final parsedStock = int.tryParse(stock.text);
    if (categoryId == null ||
        slug.text.trim().isEmpty ||
        english.text.trim().isEmpty ||
        (widget.productId == null &&
            (sku.text.trim().isEmpty ||
                parsedPrice == null ||
                parsedStock == null ||
                parsedStock < 0))) {
      setState(() => error = context.tr('requiredFields'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final payload = {
        'slug': slug.text.trim(),
        'categoryId': categoryId,
        'brandId': brandId,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'isNewArrival': isNewArrival,
        'isOffer': isOffer,
        'translations': [
          {
            'culture': 'en',
            'name': english.text.trim(),
            'description': englishDescription.text.trim(),
          },
          if (arabic.text.trim().isNotEmpty)
            {
              'culture': 'ar',
              'name': arabic.text.trim(),
              'description': arabicDescription.text.trim(),
            },
        ],
        'variants': widget.productId == null
            ? [
                {
                  'sku': sku.text.trim(),
                  'colorId': colorId,
                  'sizeId': sizeId,
                  'price': parsedPrice,
                  'initialStock': parsedStock,
                  'isActive': true,
                },
              ]
            : variants
                  .map(
                    (variant) => {
                      'id': variant['id'],
                      'sku': variant['sku'],
                      'barcode': variant['barcode'],
                      'colorId': variant['colorId'],
                      'sizeId': variant['sizeId'],
                      'price': variant['price'],
                      'compareAtPrice': variant['compareAtPrice'],
                      'initialStock': variant['quantity'] ?? 0,
                      'isActive': variant['isActive'] == true,
                    },
                  )
                  .toList(),
      };
      if (widget.productId == null) {
        final response = await apiClient.dio.post(
          '/admin/catalog/products',
          data: payload,
        );
        final id = (response.data as Map)['id'].toString();
        ref.invalidate(adminListProvider('/admin/catalog/products'));
        if (mounted) context.go('/admin/products/$id/edit');
        return;
      } else {
        await apiClient.dio.put(
          '/admin/catalog/products/${widget.productId}',
          data: payload,
        );
      }
      ref.invalidate(adminListProvider('/admin/catalog/products'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('savedSuccessfully'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('saveProductFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editVariant([Map<String, dynamic>? existing]) async {
    final skuInput = TextEditingController(
      text: (existing?['sku'] ?? '').toString(),
    );
    final barcode = TextEditingController(
      text: (existing?['barcode'] ?? '').toString(),
    );
    final priceInput = TextEditingController(
      text: (existing?['price'] ?? '').toString(),
    );
    final compareAt = TextEditingController(
      text: (existing?['compareAtPrice'] ?? '').toString(),
    );
    final initialStock = TextEditingController(text: '0');
    var selectedColor = existing?['colorId']?.toString();
    var selectedSize = existing?['sizeId']?.toString();
    var active = existing?['isActive'] != false;
    final colors = await ref.read(
      adminListProvider('/admin/reference/colors').future,
    );
    final sizes = await ref.read(
      adminListProvider('/admin/reference/sizes').future,
    );
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            context.tr(existing == null ? 'addVariant' : 'editVariant'),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: skuInput,
                    decoration: InputDecoration(
                      labelText: '${context.tr('sku')} *',
                    ),
                  ),
                  TextField(
                    controller: barcode,
                    decoration: InputDecoration(
                      labelText: context.tr('barcode'),
                    ),
                  ),
                  TextField(
                    controller: priceInput,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '${context.tr('price')} *',
                    ),
                  ),
                  TextField(
                    controller: compareAt,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('compareAtPrice'),
                    ),
                  ),
                  if (existing == null)
                    TextField(
                      controller: initialStock,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${context.tr('initialStock')} *',
                      ),
                    ),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedColor,
                    decoration: InputDecoration(labelText: context.tr('color')),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(context.tr('none')),
                      ),
                      ...colors.map(
                        (item) => DropdownMenuItem(
                          value: item['id'].toString(),
                          child: Text(_title(item)),
                        ),
                      ),
                    ],
                    onChanged: (value) => selectedColor = value,
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedSize,
                    decoration: InputDecoration(labelText: context.tr('size')),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(context.tr('none')),
                      ),
                      ...sizes.map(
                        (item) => DropdownMenuItem(
                          value: item['id'].toString(),
                          child: Text(_title(item)),
                        ),
                      ),
                    ],
                    onChanged: (value) => selectedSize = value,
                  ),
                  SwitchListTile(
                    value: active,
                    title: Text(context.tr('active')),
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    final skuValue = skuInput.text.trim();
    final barcodeValue = barcode.text.trim();
    final priceValue = double.tryParse(priceInput.text);
    final compareAtValue = double.tryParse(compareAt.text);
    final stockValue = int.tryParse(initialStock.text);
    skuInput.dispose();
    barcode.dispose();
    priceInput.dispose();
    compareAt.dispose();
    initialStock.dispose();
    if (accepted != true ||
        skuValue.isEmpty ||
        priceValue == null ||
        priceValue < 0 ||
        (existing == null && (stockValue == null || stockValue < 0))) {
      return;
    }
    try {
      final payload = {
        'sku': skuValue,
        'barcode': barcodeValue.isEmpty ? null : barcodeValue,
        'colorId': selectedColor,
        'sizeId': selectedSize,
        'price': priceValue,
        'compareAtPrice': compareAtValue,
        'initialStock': stockValue ?? 0,
        'isActive': active,
      };
      final base = '/admin/catalog/products/${widget.productId}/variants';
      if (existing == null) {
        await apiClient.dio.post(base, data: payload);
      } else {
        await apiClient.dio.put('$base/${existing['id']}', data: payload);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    }
  }

  Future<void> _deleteVariant(Map<String, dynamic> variant) async {
    final accepted = await _confirm(
      context,
      '${context.tr('deactivateVariant')} ${variant['sku']}?',
      context.tr('deactivateVariantMessage'),
    );
    if (!accepted) return;
    try {
      await apiClient.dio.delete(
        '/admin/catalog/products/${widget.productId}/variants/${variant['id']}',
      );
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    }
  }

  Future<void> _uploadImage() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final extension = (file.extension ?? '').toLowerCase();
    final contentType = extension == 'png'
        ? 'image/png'
        : extension == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
    setState(() => busy = true);
    try {
      await apiClient.dio.post(
        '/admin/media/products/${widget.productId}',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: file.name,
            contentType: DioMediaType.parse(contentType),
          ),
        }),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _moveImage(int index, int direction) async {
    final target = index + direction;
    if (target < 0 || target >= images.length) return;
    final reordered = [...images];
    final image = reordered.removeAt(index);
    reordered.insert(target, image);
    try {
      await apiClient.dio.put(
        '/admin/media/products/${widget.productId}/images/order',
        data: [
          for (var i = 0; i < reordered.length; i++)
            {
              'id': reordered[i]['id'],
              'sortOrder': i,
              'altText': reordered[i]['altText'],
            },
        ],
      );
      setState(() => images = reordered);
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    }
  }

  Future<void> _deleteImage(Map<String, dynamic> image) async {
    if (!await _confirm(
      context,
      context.tr('removeImageQuestion'),
      context.tr('removeImageMessage'),
    )) {
      return;
    }
    try {
      await apiClient.dio.delete(
        '/admin/media/products/${widget.productId}/images/${image['id']}',
      );
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(
      adminListProvider('/admin/catalog/categories'),
    );
    final brands = ref.watch(adminListProvider('/admin/catalog/brands'));
    final colors = ref.watch(adminListProvider('/admin/reference/colors'));
    final sizes = ref.watch(adminListProvider('/admin/reference/sizes'));
    if (!loaded && busy) return const LoadingState();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            widget.productId == null
                ? context.tr('addProduct')
                : context.tr('editProduct'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 22),
          _field(slug, '${context.tr('slug')} *'),
          _field(english, '${context.tr('englishName')} *'),
          _field(
            englishDescription,
            context.tr('englishDescription'),
            lines: 4,
          ),
          _field(arabic, context.tr('arabicName')),
          _field(arabicDescription, context.tr('arabicDescription'), lines: 4),
          categories.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(
              context.tr('loadCategoriesFailed'),
              style: const TextStyle(color: Colors.red),
            ),
            data: (items) => DropdownButtonFormField<String>(
              key: ValueKey(categoryId),
              initialValue: categoryId,
              decoration: InputDecoration(
                labelText: '${context.tr('category')} *',
              ),
              items: items
                  .map(
                    (x) => DropdownMenuItem(
                      value: x['id'].toString(),
                      child: Text(_title(x)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => categoryId = value),
            ),
          ),
          const SizedBox(height: 14),
          brands.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) => DropdownButtonFormField<String>(
              key: ValueKey(brandId),
              initialValue: brandId,
              decoration: InputDecoration(labelText: context.tr('brand')),
              items: items
                  .map(
                    (x) => DropdownMenuItem(
                      value: x['id'].toString(),
                      child: Text(_title(x)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => brandId = value),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            value: isActive,
            title: Text(context.tr('active')),
            onChanged: (value) => setState(() => isActive = value),
          ),
          SwitchListTile(
            value: isFeatured,
            title: Text(context.tr('featured')),
            onChanged: (value) => setState(() => isFeatured = value),
          ),
          SwitchListTile(
            value: isNewArrival,
            title: Text(context.tr('newArrival')),
            onChanged: (value) => setState(() => isNewArrival = value),
          ),
          SwitchListTile(
            value: isOffer,
            title: Text(context.tr('offer')),
            onChanged: (value) => setState(() => isOffer = value),
          ),
          if (widget.productId == null) ...[
            const Divider(height: 32),
            Text(
              context.tr('initialVariant'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _field(sku, '${context.tr('sku')} *'),
            _field(price, '${context.tr('price')} *', number: true),
            _field(stock, '${context.tr('initialStock')} *', number: true),
            colors.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: context.tr('color')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.tr('none')),
                  ),
                  ...items.map(
                    (item) => DropdownMenuItem(
                      value: item['id'].toString(),
                      child: Text(_title(item)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => colorId = value),
              ),
            ),
            const SizedBox(height: 14),
            sizes.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: context.tr('size')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.tr('none')),
                  ),
                  ...items.map(
                    (item) => DropdownMenuItem(
                      value: item['id'].toString(),
                      child: Text(_title(item)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => sizeId = value),
              ),
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: busy ? null : submit,
            child: busy
                ? const CircularProgressIndicator()
                : Text(context.tr('save')),
          ),
          if (widget.productId != null) ...[
            const Divider(height: 42),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('variants'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: busy ? null : () => _editVariant(),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('addVariant')),
                ),
              ],
            ),
            for (final variant in variants)
              ListTile(
                title: Text((variant['sku'] ?? '').toString()),
                subtitle: Text(
                  'SAR ${_number(variant['price'])} • ${context.tr('stock')} ${variant['quantity'] ?? 0} • ${context.tr(variant['isActive'] == true ? 'active' : 'inactive')}',
                ),
                onTap: () => _editVariant(variant),
                trailing: IconButton(
                  onPressed: () => _deleteVariant(variant),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            const Divider(height: 42),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('productImages'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _uploadImage,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(context.tr('uploadImage')),
                ),
              ],
            ),
            if (images.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(context.tr('noProductImages')),
              ),
            for (var index = 0; index < images.length; index++)
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index]['url'].toString(),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.square(
                      dimension: 56,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                title: Text(
                  (images[index]['altText'] ?? context.tr('productImage'))
                      .toString(),
                ),
                subtitle: Text('${context.tr('position')} ${index + 1}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      onPressed: index == 0
                          ? null
                          : () => _moveImage(index, -1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      onPressed: index == images.length - 1
                          ? null
                          : () => _moveImage(index, 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      onPressed: () => _deleteImage(images[index]),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class AdminCouponFormScreen extends ConsumerStatefulWidget {
  const AdminCouponFormScreen({super.key});
  @override
  ConsumerState<AdminCouponFormScreen> createState() => _AdminCouponFormState();
}

class _AdminCouponFormState extends ConsumerState<AdminCouponFormScreen> {
  final code = TextEditingController(),
      value = TextEditingController(),
      minimum = TextEditingController(),
      maximumDiscount = TextEditingController(),
      maxUses = TextEditingController(),
      maxPerCustomer = TextEditingController();
  bool busy = false, active = true;
  int type = 0;
  DateTime validFrom = DateTime.now(),
      validTo = DateTime.now().add(const Duration(days: 30));
  String? error;
  @override
  void dispose() {
    for (final controller in [
      code,
      value,
      minimum,
      maximumDiscount,
      maxUses,
      maxPerCustomer,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    final amount = double.tryParse(value.text);
    if (code.text.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        (type == 0 && amount > 100) ||
        validTo.isBefore(validFrom)) {
      setState(() => error = context.tr('invalidCoupon'));
      return;
    }
    setState(() => busy = true);
    try {
      await apiClient.dio.post(
        '/admin/coupons',
        data: {
          'code': code.text.trim(),
          'type': type,
          'value': amount,
          'minimumPurchase': double.tryParse(minimum.text),
          'maximumDiscount': double.tryParse(maximumDiscount.text),
          'validFromUtc': validFrom.toUtc().toIso8601String(),
          'validToUtc': validTo.toUtc().toIso8601String(),
          'maxUses': int.tryParse(maxUses.text),
          'maxUsesPerCustomer': int.tryParse(maxPerCustomer.text),
          'isActive': active,
        },
      );
      ref.invalidate(adminListProvider('/admin/coupons'));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(e, context.tr('createCouponFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          context.tr('createCoupon'),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: context.tr('code')),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: type,
          decoration: InputDecoration(labelText: context.tr('discountType')),
          items: [
            DropdownMenuItem(value: 0, child: Text(context.tr('percentage'))),
            DropdownMenuItem(value: 1, child: Text(context.tr('fixedAmount'))),
          ],
          onChanged: (value) => setState(() => type = value ?? 0),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.tr(type == 0 ? 'discountPercentage' : 'value'),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: minimum,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: context.tr('minimumPurchase')),
        ),
        const SizedBox(height: 14),
        if (type == 0)
          TextField(
            controller: maximumDiscount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr('maximumDiscount'),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: maxUses,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('maxUses')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: maxPerCustomer,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('maxUsesPerCustomer'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: validFrom,
                  );
                  if (date != null) setState(() => validFrom = date);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  '${context.tr('validFrom')}: ${validFrom.toLocal().toString().split(' ').first}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: validFrom,
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: validTo.isBefore(validFrom)
                        ? validFrom
                        : validTo,
                  );
                  if (date != null) setState(() => validTo = date);
                },
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  '${context.tr('validTo')}: ${validTo.toLocal().toString().split(' ').first}',
                ),
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: active,
          title: Text(context.tr('active')),
          onChanged: (value) => setState(() => active = value),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : submit,
          child: busy
              ? const CircularProgressIndicator()
              : Text(context.tr('save')),
        ),
      ],
    ),
  );
}

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsState();
}

class _AdminNotificationsState extends ConsumerState<AdminNotificationsScreen> {
  final title = TextEditingController();
  final body = TextEditingController();
  final deepLink = TextEditingController();
  String? userId, error;
  bool busy = false;

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    deepLink.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (userId == null ||
        title.text.trim().isEmpty ||
        body.text.trim().isEmpty) {
      setState(() => error = context.tr('requiredFields'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await apiClient.dio.post(
        '/admin/notifications',
        data: {
          'userId': userId,
          'channel': 'InApp',
          'title': title.text.trim(),
          'body': body.text.trim(),
          'deepLink': deepLink.text.trim().isEmpty
              ? null
              : deepLink.text.trim(),
        },
      );
      title.clear();
      body.clear();
      deepLink.clear();
      ref.invalidate(adminListProvider('/admin/notifications'));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('notificationSent'))));
      }
    } catch (exception) {
      if (mounted) {
        setState(
          () => error = apiFailureMessage(exception, context.tr('retry')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(adminListProvider('/admin/notifications'));
    final customers = ref.watch(adminListProvider('/admin/customers'));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            context.tr('manageNotifications'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('inAppNotificationDescription'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          customers.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => ErrorState(
              onRetry: () =>
                  ref.invalidate(adminListProvider('/admin/customers')),
            ),
            data: (items) => DropdownButtonFormField<String>(
              initialValue: userId,
              decoration: InputDecoration(labelText: context.tr('customer')),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['id'].toString(),
                      child: Text(_title(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => userId = value),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: title,
            maxLength: 160,
            decoration: InputDecoration(
              labelText: context.tr('notificationTitle'),
            ),
          ),
          TextField(
            controller: body,
            maxLength: 2000,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: context.tr('notificationBody'),
            ),
          ),
          TextField(
            controller: deepLink,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: context.tr('deepLinkOptional'),
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: busy ? null : _send,
            icon: const Icon(Icons.send_outlined),
            label: busy
                ? const CircularProgressIndicator()
                : Text(context.tr('sendNotification')),
          ),
          const Divider(height: 42),
          Text(
            context.tr('notificationHistory'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          notifications.when(
            loading: () => const LoadingState(),
            error: (_, _) => ErrorState(
              onRetry: () =>
                  ref.invalidate(adminListProvider('/admin/notifications')),
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(icon: Icons.notifications_none)
                : Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: Text((item['title'] ?? '').toString()),
                          subtitle: Text(
                            '${item['body'] ?? ''}\n${item['createdUtc'] ?? ''}',
                          ),
                          isThreeLine: true,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends ConsumerState<AdminSettingsScreen> {
  final key = TextEditingController(), value = TextEditingController();
  bool isPublic = false, busy = false;
  @override
  void dispose() {
    key.dispose();
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminListProvider('/admin/settings'));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            context.tr('settings'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 18),
          settings.when(
            loading: () => const LoadingState(),
            error: (_, _) => ErrorState(
              onRetry: () =>
                  ref.invalidate(adminListProvider('/admin/settings')),
            ),
            data: (items) => Column(
              children: [
                for (final item in items)
                  ListTile(
                    title: Text(item['key'].toString()),
                    subtitle: Text(item['value'].toString()),
                    trailing: item['isPublic'] == true
                        ? const Icon(Icons.public)
                        : const Icon(Icons.lock_outline),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          TextField(
            controller: key,
            decoration: InputDecoration(labelText: context.tr('settingKey')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: value,
            decoration: InputDecoration(labelText: context.tr('value')),
          ),
          SwitchListTile(
            value: isPublic,
            onChanged: (x) => setState(() => isPublic = x),
            title: Text(context.tr('publicAppSetting')),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (key.text.trim().isEmpty || value.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('requiredFields'))),
                      );
                      return;
                    }
                    setState(() => busy = true);
                    try {
                      await ref
                          .read(adminOperationsRepositoryProvider)
                          .saveSetting(key.text, value.text, isPublic);
                      ref.invalidate(adminListProvider('/admin/settings'));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              apiFailureMessage(e, context.tr('retry')),
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: busy
                ? const CircularProgressIndicator()
                : Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}

String _number(dynamic value) => value is num
    ? value.toStringAsFixed(value % 1 == 0 ? 0 : 2)
    : (value ?? '0').toString();
String _enumText(dynamic value) =>
    value is num ? 'Status ${value.toInt()}' : (value ?? '').toString();

String _orderStatus(BuildContext context, int value) {
  const statuses = [
    'statusPending',
    'statusConfirmed',
    'statusPreparing',
    'statusReady',
    'statusShipped',
    'statusOutForDelivery',
    'statusDelivered',
    'statusCancelled',
    'statusReturned',
    'statusRefunded',
  ];
  return value >= 0 && value < statuses.length
      ? context.tr(statuses[value])
      : context.tr('unknown');
}

String _title(Map<String, dynamic> item) {
  for (final key in [
    'name',
    'displayName',
    'publicNumber',
    'code',
    'sku',
    'email',
    'action',
    'key',
    'slug',
    'productName',
    'title',
  ]) {
    final value = item[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  final translations = item['translations'];
  if (translations is List && translations.isNotEmpty) {
    final first = translations.first as Map;
    if (first['name'] != null) return first['name'].toString();
  }
  return item['id']?.toString() ?? 'Record';
}

String _subtitle(Map<String, dynamic> item) {
  final ignored = {
    'id',
    'name',
    'displayName',
    'publicNumber',
    'code',
    'sku',
    'email',
    'title',
    'translations',
  };
  return item.entries
      .where(
        (x) =>
            !ignored.contains(x.key) &&
            x.value != null &&
            x.value is! List &&
            x.value is! Map,
      )
      .take(4)
      .map((x) => '${x.key}: ${_enumText(x.value)}')
      .join(' • ');
}

Future<void> _showData(BuildContext context, Map<String, dynamic> item) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_title(item)),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(item),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: MaterialLocalizations.of(context).closeButtonLabel.isEmpty
                ? const Text('Close')
                : Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    ) ??
    false;
