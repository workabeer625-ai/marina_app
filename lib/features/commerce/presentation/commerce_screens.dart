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
    final p = MarinaPalette.of(context);
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
              message: context.tr('emptyBag'),
              action: MarinaGoldButton(
                label: context.tr('continueShopping'),
                icon: Icons.storefront_rounded,
                onPressed: () => context.go('/products'),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('bag'),
                        style: MarinaType.display(context, size: 26),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: p.gold.withValues(alpha: .35),
                        ),
                      ),
                      child: Text(
                        () {
                          final count = data.items.length;
                          final arabic =
                              Localizations.localeOf(context).languageCode ==
                                  'ar';
                          return '$count ${arabic ? (count == 1 ? 'منتج' : 'منتجات') : (count == 1 ? 'item' : 'items')}';
                        }(),
                        style: TextStyle(
                          color: p.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: p.isDark
                            ? const Color(0xFFE58877)
                            : MarinaColors.danger,
                        textStyle: const TextStyle(fontSize: 12.5),
                      ),
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        size: 17,
                      ),
                      label: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'إفراغ السلة'
                            : 'Clear cart',
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(cartProvider.notifier).clear();
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
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(cartProvider.notifier).refreshCart(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    itemCount: data.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _CartItem(line: data.items[index]),
                  ),
                ),
              ),
              OrderTotals(snapshot: data),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(top: BorderSide(color: p.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: MarinaGoldButton(
                    label: context.tr('checkout'),
                    icon: Icons.lock_outline_rounded,
                    onPressed: () => context.push('/checkout'),
                  ),
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
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final variantsText = [
      widget.line.color,
      widget.line.size,
    ].whereType<String>().where((x) => x.isNotEmpty).join(' • ');
    return MarinaSectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 114,
              child: widget.line.image == null
                  ? ColoredBox(
                      color: p.surfaceSoft,
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 38,
                        color: p.muted.withValues(alpha: .6),
                      ),
                    )
                  : MarinaNetworkImage(
                      url: widget.line.image!,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                    color: p.ink,
                  ),
                ),
                if (variantsText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    variantsText,
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                MarinaPrice(value: widget.line.price),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: p.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepButton(
                        icon: Icons.remove_rounded,
                        onTap: busy
                            ? null
                            : () => update(widget.line.quantity - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: busy
                            ? const SizedBox.square(
                                dimension: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                '${widget.line.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: p.ink,
                                ),
                              ),
                      ),
                      _StepButton(
                        icon: Icons.add_rounded,
                        onTap: busy ||
                                widget.line.quantity >= widget.line.available
                            ? null
                            : () => update(widget.line.quantity + 1),
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
            style: IconButton.styleFrom(
              foregroundColor:
                  p.isDark ? const Color(0xFFE58877) : MarinaColors.danger,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        icon,
        size: 16,
        color: onTap == null
            ? MarinaPalette.of(context).muted.withValues(alpha: .5)
            : MarinaPalette.of(context).gold,
      ),
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
    final p = MarinaPalette.of(context);
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
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 19),
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
            _row(context, p, context.tr('subtotal'), subtotal),
            if (discount > 0)
              _row(
                context,
                p,
                context.tr('discount'),
                -discount,
                color: p.gold,
              ),
            _row(
              context,
              p,
              context.tr('shipping'),
              shipping,
              hint: shipping == 0 ? context.tr('free') : null,
            ),
            _row(context, p, context.tr('tax'), tax),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.line,
                    p.gold.withValues(alpha: .55),
                    p.line,
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('total'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: p.ink,
                  ),
                ),
                MarinaPrice(value: total, large: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    MarinaPalette p,
    String label,
    double value, {
    bool bold = false,
    Color? color,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.5, color: p.muted),
        ),
        Row(
          children: [
            if (hint != null) ...[
              Text(
                hint,
                style: TextStyle(
                  color: p.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _money(value),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color ?? p.ink.withValues(alpha: .85),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
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
                _StepCard(
                  step: '1',
                  title: context.tr('deliveryAddress'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isEmpty)
                        OutlinedButton.icon(
                          onPressed: () => context.push('/addresses/new'),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(context.tr('addAddress')),
                        )
                      else
                        for (final address in items)
                          _RadioCard(
                            selected: selected == address.id,
                            onTap: () =>
                                setState(() => addressId = address.id),
                            title:
                                '${address.label} — ${address.recipient}',
                            subtitle:
                                '${address.line1}, ${address.city}',
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  step: '2',
                  title: context.tr('deliveryOption'),
                  child: CheckoutTile(
                    title: context.tr('standardDelivery'),
                    subtitle: snapshot.quote?.shipping == 0
                        ? context.tr('standardDeliveryFree')
                        : '${context.tr('standardDelivery')} — ${_money(snapshot.quote?.shipping ?? 20)}',
                    icon: Icons.local_shipping_outlined,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  step: '3',
                  title: context.tr('paymentMethod'),
                  child: Column(
                    children: [
                      _RadioCard(
                        selected: true,
                        onTap: () {},
                        title: context.tr('cashOnDelivery'),
                        subtitle: context.tr('cashOnDeliveryDescription'),
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 8),
                      _RadioCard(
                        selected: false,
                        enabled: false,
                        onTap: null,
                        title: context.tr('onlinePayment'),
                        subtitle: context.tr('onlineUnavailable'),
                        icon: Icons.credit_card_off_outlined,
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
                      style: TextStyle(
                        color: MarinaPalette.of(context).isDark
                            ? const Color(0xFFE58877)
                            : MarinaColors.danger,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                MarinaGoldButton(
                  label: context.tr('confirmOrder'),
                  icon: Icons.verified_rounded,
                  busy: busy,
                  onPressed: busy ? null : () => submit(snapshot, items),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Numbered checkout section with a gold step marker.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step, title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return MarinaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: MarinaGradients.gold,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: MarinaColors.onGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
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
    this.compact = false,
  });

  final String title, subtitle;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.goldSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: p.gold, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
        ],
      ),
    );
  }
}

/// Card-styled radio option used for addresses & payment methods.
class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
    this.icon,
  });

  final bool selected;
  final String title, subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final borderColor = selected
        ? p.gold
        : enabled ? p.line : p.line.withValues(alpha: .6);
    return Opacity(
      opacity: enabled ? 1 : .62,
      child: Material(
        color: selected
            ? p.goldSoft.withValues(alpha: p.isDark ? .8 : .55)
            : p.background,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? p.gold : p.muted,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? p.gold : Colors.transparent,
                    border: Border.all(
                      color: selected ? p.gold : p.muted.withValues(alpha: .7),
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: MarinaColors.onGold,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Map<String, dynamic>? order;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final id = order?['id']?.toString();
    final number = order?['publicNumber']?.toString();
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: MarinaGradients.gold,
                      boxShadow: MarinaShadows.glow,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 54,
                      color: MarinaColors.onGold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.tr('orderSuccess'),
                    textAlign: TextAlign.center,
                    style: MarinaType.display(context, size: 27),
                  ),
                  const SizedBox(height: 14),
                  const GoldDivider(width: 150),
                  const SizedBox(height: 18),
                  if (number != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.gold.withValues(alpha: .4)),
                      ),
                      child: SelectableText(
                        '${context.tr('orderNumber')}: $number',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                  const SizedBox(height: 34),
                  if (id != null)
                    FilledButton(
                      onPressed: () => context.go('/orders/$id'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 19),
                          const SizedBox(width: 9),
                          Text(context.tr('trackOrder')),
                        ],
                      ),
                    ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(context.tr('continueShopping')),
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
