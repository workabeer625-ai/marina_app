// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/state/commerce_state.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../profile/data/customer_repository.dart';
import '../data/post_purchase_repository.dart';

String _money(double value) => 'SAR ${value.toStringAsFixed(2)}';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return SafeArea(
      child: cart.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              action: FilledButton(
                onPressed: () => context.go('/products'),
                child: Text(context.tr('continueShopping')),
              ),
            );
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                decoration: const BoxDecoration(
                  color: MarinaColors.navy,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    context.tr('bag'),
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(cartProvider.notifier).refreshCart(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: data.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _CartItem(line: data.items[index]),
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إفراغ السلة' : 'Clear cart'),
                onPressed: () async {
                  try {
                    await ref.read(cartProvider.notifier).clear();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(apiFailureMessage(error, context.tr('retry'))),
                      ));
                    }
                  }
                },
              ),
              OrderTotals(snapshot: data),
              Padding(
                padding: const EdgeInsets.all(18),
                child: FilledButton(
                  onPressed: () => context.push('/checkout'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(context.tr('checkout')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItem extends ConsumerStatefulWidget {
  const _CartItem({required this.line});
  final CartLine line;

  @override
  ConsumerState<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends ConsumerState<_CartItem> {
  bool busy = false;

  Future<void> update(int quantity) async {
    setState(() => busy = true);
    try {
      await ref.read(cartProvider.notifier).updateLine(widget.line, quantity);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiFailureMessage(error, context.tr('retry'))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MarinaSectionCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 96,
            height: 118,
            child: widget.line.image == null
                ? const ColoredBox(
                    color: MarinaTheme.sand,
                    child: Icon(Icons.checkroom, size: 40),
                  )
                : MarinaNetworkImage(
                    url: widget.line.image!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.line.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if ([
                widget.line.color,
                widget.line.size,
              ].whereType<String>().where((x) => x.isNotEmpty).isNotEmpty)
                Text(
                  [
                    widget.line.color,
                    widget.line.size,
                  ].whereType<String>().where((x) => x.isNotEmpty).join(' • '),
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 8),
              MarinaPrice(value: widget.line.price),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: MarinaColors.softBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: busy
                          ? null
                          : () => update(widget.line.quantity - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    if (busy)
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text('${widget.line.quantity}'),
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          busy || widget.line.quantity >= widget.line.available
                          ? null
                          : () => update(widget.line.quantity + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          onPressed: busy ? null : () => update(0),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFB42318),
            size: 20,
          ),
        ),
      ],
    ),
  );
}

class OrderTotals extends ConsumerStatefulWidget {
  const OrderTotals({
    super.key,
    required this.snapshot,
    this.allowCoupon = true,
  });
  final CartSnapshot snapshot;
  final bool allowCoupon;

  @override
  ConsumerState<OrderTotals> createState() => _OrderTotalsState();
}

class _OrderTotalsState extends ConsumerState<OrderTotals> {
  final coupon = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    coupon.dispose();
    super.dispose();
  }

  Future<void> apply() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(cartProvider.notifier).applyCoupon(coupon.text);
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
    final quote = widget.snapshot.quote;
    final subtotal = quote?.subtotal ?? widget.snapshot.subtotal;
    final shipping = quote?.shipping ?? (subtotal >= 300 ? 0 : 20);
    final discount = quote?.discount ?? 0;
    final tax = quote?.tax ?? ((subtotal - discount + shipping) * .15);
    final total = quote?.total ?? subtotal - discount + shipping + tax;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: MarinaSectionCard(
        child: Column(
          children: [
            if (widget.allowCoupon) ...[
              TextField(
                controller: coupon,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: context.tr('coupon'),
                  errorText: error,
                  suffixIcon: TextButton(
                    onPressed: busy ? null : apply,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('apply')),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _row(context.tr('subtotal'), subtotal),
            if (discount > 0) _row(context.tr('discount'), -discount),
            _row(context.tr('shipping'), shipping),
            _row(context.tr('tax'), tax),
            const Divider(height: 22),
            _row(context.tr('total'), total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)
              : null,
        ),
        Text(
          _money(value),
          style: bold
              ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)
              : null,
        ),
      ],
    ),
  );
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<CheckoutScreen> {
  late final String idempotencyKey =
      'flutter-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  String? addressId;
  bool busy = false;
  String? error;

  Future<void> submit(
    CartSnapshot cart,
    List<CustomerAddress> addresses,
  ) async {
    final selected =
        addressId ??
        addresses.where((x) => x.isDefault).firstOrNull?.id ??
        addresses.firstOrNull?.id;
    if (selected == null) {
      context.push('/addresses/new');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await apiClient.dio.post(
        '/orders',
        data: {
          'addressId': selected,
          'idempotencyKey': idempotencyKey,
          'couponCode': cart.quote?.couponCode,
          'items': [
            for (final line in cart.items)
              {'variantId': line.variantId, 'quantity': line.quantity},
          ],
        },
      );
      final order = response.data as Map<String, dynamic>;
      await ref.read(cartProvider.notifier).clearAfterOrder();
      ref.invalidate(ordersProvider);
      if (mounted) context.go('/order-success', extra: order);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              error = apiFailureMessage(e, context.tr('orderSubmissionFailed')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(customerAddressesProvider);
    return MarinaPage(
      title: context.tr('checkout'),
      child: cart.when(
        loading: () => const LoadingState(),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(cartProvider)),
        data: (snapshot) => addresses.when(
          loading: () => const LoadingState(),
          error: (_, _) => ErrorState(
            onRetry: () => ref.invalidate(customerAddressesProvider),
          ),
          data: (items) {
            if (snapshot.items.isEmpty) {
              return EmptyState(icon: Icons.shopping_bag_outlined);
            }
            final selected =
                addressId ??
                items.where((x) => x.isDefault).firstOrNull?.id ??
                items.firstOrNull?.id;
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                MarinaSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('deliveryAddress'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      if (items.isEmpty)
                        OutlinedButton.icon(
                          onPressed: () => context.push('/addresses/new'),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(context.tr('addAddress')),
                        )
                      else
                        for (final address in items)
                          RadioListTile<String>(
                            value: address.id,
                            groupValue: selected,
                            onChanged: (value) =>
                                setState(() => addressId = value),
                            title: Text(
                              '${address.label} — ${address.recipient}',
                            ),
                            subtitle: Text('${address.line1}, ${address.city}'),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                CheckoutTile(
                  title: context.tr('deliveryOption'),
                  subtitle: snapshot.quote?.shipping == 0
                      ? context.tr('standardDeliveryFree')
                      : '${context.tr('standardDelivery')} — ${_money(snapshot.quote?.shipping ?? 20)}',
                  icon: Icons.local_shipping_outlined,
                ),
                MarinaSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('paymentMethod'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      RadioListTile<String>(
                        value: 'CashOnDelivery',
                        groupValue: 'CashOnDelivery',
                        onChanged: (_) {},
                        title: Text(context.tr('cashOnDelivery')),
                        subtitle: Text(context.tr('cashOnDeliveryDescription')),
                        secondary: const Icon(Icons.payments_outlined),
                      ),
                      RadioListTile<String>(
                        value: 'Online',
                        groupValue: 'CashOnDelivery',
                        onChanged: null,
                        title: Text(context.tr('onlinePayment')),
                        subtitle: Text(context.tr('onlineUnavailable')),
                        secondary: const Icon(Icons.credit_card_off_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                OrderTotals(snapshot: snapshot, allowCoupon: false),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : () => submit(snapshot, items),
                  child: busy
                      ? const CircularProgressIndicator()
                      : Text(context.tr('confirmOrder')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CheckoutTile extends StatelessWidget {
  const CheckoutTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: ListTile(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: MarinaTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      leading: CircleAvatar(
        backgroundColor: MarinaTheme.blue.withValues(alpha: .45),
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    ),
  );
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final Map<String, dynamic>? order;

  @override
  Widget build(BuildContext context) {
    final id = order?['id']?.toString();
    final number = order?['publicNumber']?.toString();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 46,
                backgroundColor: MarinaTheme.blue,
                child: Icon(Icons.check, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('orderSuccess'),
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (number != null) SelectableText(number),
              const SizedBox(height: 30),
              if (id != null)
                FilledButton(
                  onPressed: () => context.go('/orders/$id'),
                  child: Text(context.tr('trackOrder')),
                ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(context.tr('continueShopping')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
