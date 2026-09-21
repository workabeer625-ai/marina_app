import '../../../shared/widgets/page_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../data/post_purchase_repository.dart';

class ProductReviewsScreen extends ConsumerWidget {
  const ProductReviewsScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(productReviewsProvider(productId));
    return MarinaPage(
      title: context.tr('reviews'),
      child: reviews.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(productReviewsProvider(productId)),
        ),
        data: (page) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(productReviewsProvider(productId).future),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MarinaPalette.of(context).goldSoft,
                      MarinaPalette.of(context).surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: MarinaPalette.of(context).gold.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      page.average.toStringAsFixed(1),
                      style: MarinaType.display(
                        context,
                        size: 40,
                        color: MarinaPalette.of(context).ink,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Stars(value: page.average.round()),
                          const SizedBox(height: 4),
                          Text(
                            '${page.count} ${context.tr('verifiedReviews')}',
                            style: TextStyle(
                              color: MarinaPalette.of(context).muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        final saved = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => _ReviewForm(productId: productId),
                        );
                        if (saved == true) {
                          ref.invalidate(productReviewsProvider(productId));
                        }
                      },
                      child: Text(context.tr('writeReview')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (page.items.isEmpty)
                EmptyState(
                  icon: Icons.reviews_outlined,
                  message: context.tr('noReviews'),
                )
              else
                for (final review in page.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MarinaSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor:
                                    MarinaPalette.of(context).goldSoft,
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 19,
                                  color: MarinaPalette.of(context).gold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  review.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _Stars(value: review.rating, size: 15),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (review.title.isNotEmpty)
                            Text(
                              review.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            review.body,
                            style: TextStyle(
                              height: 1.55,
                              color: MarinaPalette.of(context)
                                  .ink
                                  .withValues(alpha: .85),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MarinaPalette.of(context).isDark
                                  ? MarinaColors.success.withValues(alpha: .16)
                                  : MarinaColors.successTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: MarinaPalette.of(context).isDark
                                      ? MarinaColors.success
                                      : MarinaColors.success,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.tr('verifiedPurchase'),
                                  style: const TextStyle(
                                    color: MarinaColors.success,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 20});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < value ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: MarinaPalette.of(context).gold,
        ),
      ),
    ),
  );
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.productId});

  final String productId;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final title = TextEditingController();
  final body = TextEditingController();
  int rating = 5;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (body.text.trim().length < 10) {
      setState(() => error = context.tr('reviewTooShort'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(postPurchaseRepositoryProvider)
          .submitReview(
            widget.productId,
            rating: rating,
            title: title.text,
            body: body.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = apiFailureMessage(e, context.tr('retry')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      8,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('writeReview'),
          style: MarinaType.display(context, size: 22),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: () => setState(() => rating = i + 1),
              icon: Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: MarinaPalette.of(context).gold,
              ),
            ),
          ),
        ),
        TextField(
          controller: title,
          maxLength: 120,
          decoration: InputDecoration(labelText: context.tr('reviewTitle')),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: body,
          minLines: 3,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(labelText: context.tr('reviewBody')),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              error!,
              style: TextStyle(
                color: MarinaPalette.of(context).isDark
                    ? const Color(0xFFE58877)
                    : MarinaColors.danger,
              ),
            ),
          ),
        MarinaGoldButton(
          label: context.tr('submitForReview'),
          busy: busy,
          onPressed: busy ? null : submit,
        ),
      ],
    ),
  );
}

class ApiOrdersScreen extends ConsumerWidget {
  const ApiOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return MarinaPage(
      bottom: PageControls(
        endpoint: '/orders',
        page: orders.value,
        loading: orders.isLoading,
      ),
      title: context.tr('orders'),
      child: orders.when(
        loading: () => const LoadingState(),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(ordersProvider)),
        data: (page) => RefreshIndicator(
          onRefresh: () => ref.refresh(ordersProvider.future),
          child: page.items.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .65,
                      child: const EmptyState(
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final order = page.items[index];
                    return _OrderListCard(
                      title: order.publicNumber,
                      status: order.status,
                      statusLabel: _localizedStatus(context, order.status),
                      subtitle:
                          '${order.itemCount} ${context.tr('items')}',
                      trailing: 'SAR ${order.total.toStringAsFixed(2)}',
                      onTap: () => context.push('/orders/${order.id}'),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Card row used by orders & returns lists.
class _OrderListCard extends StatelessWidget {
  const _OrderListCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusLabel,
    required this.trailing,
    required this.onTap,
    this.icon = Icons.receipt_long_outlined,
    this.trailingWidget,
  });

  final String title, subtitle, status, statusLabel, trailing;
  final VoidCallback onTap;
  final IconData icon;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return MarinaSectionCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.gold.withValues(alpha: .25)),
              ),
              child: Icon(icon, size: 20, color: p.gold),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(label: statusLabel, status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(fontSize: 12.5, color: p.muted),
                        ),
                      ),
                      Text(
                        trailing,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: p.gold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: p.muted.withValues(alpha: .7),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiOrderDetailsScreen extends ConsumerWidget {
  const ApiOrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailsProvider(orderId));
    return MarinaPage(
      title: context.tr('orderTracking'),
      child: order.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(orderDetailsProvider(orderId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: MarinaGradients.header(
                  dark: MarinaPalette.of(context).isDark,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: MarinaColors.gold.withValues(alpha: .3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('orderNumber').toUpperCase(),
                    style: TextStyle(
                      color: MarinaColors.goldBright,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing:
                          MarinaType.isArabic(context) ? 0 : 2.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.publicNumber,
                    style: MarinaType.display(
                      context,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusChip(
                    label: _localizedStatus(context, data.status),
                    status: data.status,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('orderTracking'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < data.timeline.length; i++)
              _TimelineRow(
                isFirst: i == 0,
                isLast: i == data.timeline.length - 1,
                title: _localizedStatus(context, data.timeline[i].status),
                subtitle: data.timeline[i].reason,
              ),
            const SizedBox(height: 16),
            Text(
              context.tr('items'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final line in data.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  line.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MarinaPalette.of(context).ink,
                  ),
                ),
                subtitle: Text('${line.sku} · ${line.quantity}x'),
                trailing: Text(
                  'SAR ${line.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: MarinaPalette.of(context).gold,
                  ),
                ),
              ),
            if (data.status == 'Pending' || data.status == 'Confirmed') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final accepted = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.tr('cancelOrder')),
                      content: Text(context.tr('cancelOrderConfirmation')),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(false),
                          child: Text(context.tr('close')),
                        ),
                        FilledButton(
                          onPressed: () => context.pop(true),
                          child: Text(context.tr('cancelOrder')),
                        ),
                      ],
                    ),
                  );
                  if (accepted != true) return;
                  if (!context.mounted) return;
                  final cancellationReason = context.tr('customerCancellation');
                  try {
                    await ref
                        .read(postPurchaseRepositoryProvider)
                        .cancelOrder(orderId, cancellationReason);
                    ref.invalidate(orderDetailsProvider(orderId));
                    ref.invalidate(ordersProvider);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            apiFailureMessage(error, context.tr('retry')),
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: Text(context.tr('cancelOrder')),
              ),
            ],
            if (data.status == 'Delivered') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('/orders/$orderId/return'),
                icon: const Icon(Icons.assignment_return_outlined),
                label: Text(context.tr('requestReturn')),
              ),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.push('/support'),
              icon: const Icon(Icons.headset_mic_outlined, size: 18),
              label: Text(context.tr('contact')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold timeline row with connecting hairline.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.isFirst,
    required this.isLast,
    required this.title,
    this.subtitle,
  });

  final bool isFirst, isLast;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.goldSoft,
                  border: Border.all(color: p.gold.withValues(alpha: .5)),
                ),
                child: Icon(Icons.check_rounded, size: 15, color: p.gold),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.4,
                    color: p.gold.withValues(alpha: .35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 18),
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
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12.5, color: p.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApiReturnsScreen extends ConsumerWidget {
  const ApiReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returns = ref.watch(returnsProvider);
    return MarinaPage(
      bottom: PageControls(
        endpoint: '/returns',
        page: returns.value,
        loading: returns.isLoading,
      ),
      title: context.tr('returns'),
      child: returns.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(returnsProvider),
        ),
        data: (page) => page.items.isEmpty
            ? const EmptyState(icon: Icons.assignment_return_outlined)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(returnsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = page.items[index];
                    return _OrderListCard(
                      icon: Icons.assignment_return_outlined,
                      title: item.publicNumber,
                      status: item.status,
                      statusLabel: _localizedStatus(context, item.status),
                      subtitle:
                          '${item.reason}\n${item.itemCount} ${context.tr('items')}',
                      trailing: '',
                      onTap: () => context.push('/returns/${item.id}'),
                      trailingWidget: item.status == 'Requested'
                          ? TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(postPurchaseRepositoryProvider)
                                      .cancelReturn(item.id);
                                  ref.invalidate(returnsProvider);
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
                              child: Text(context.tr('cancel')),
                            )
                          : null,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class ReturnDetailsScreen extends ConsumerWidget {
  const ReturnDetailsScreen({super.key, required this.returnId});

  final String returnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(returnDetailsProvider(returnId));
    return MarinaPage(
      title: context.tr('returnDetails'),
      child: details.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(returnDetailsProvider(returnId)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(returnDetailsProvider(returnId).future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: MarinaGradients.header(
                    dark: MarinaPalette.of(context).isDark,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: MarinaColors.gold.withValues(alpha: .3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.publicNumber,
                      style: TextStyle(
                        color: MarinaColors.goldBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing:
                            MarinaType.isArabic(context) ? 0 : 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _localizedStatus(context, data.status),
                            style: MarinaType.display(
                              context,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: _localizedStatus(context, data.status),
                          status: data.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${context.tr('returnReason')}: ${data.reason}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    if (data.customerNote?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          data.customerNote!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (data.adminNote?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${context.tr('adminNote')}: ${data.adminNote}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('returnTimeline'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < data.timeline.length; i++)
                _TimelineRow(
                  isFirst: i == 0,
                  isLast: i == data.timeline.length - 1,
                  title: _localizedStatus(context, data.timeline[i].status),
                  subtitle: data.timeline[i].note,
                ),
              const SizedBox(height: 16),
              Text(
                context.tr('items'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final item in data.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MarinaPalette.of(context).ink,
                    ),
                  ),
                  subtitle: Text(item.sku),
                  trailing: Text(
                    '${item.quantity}×',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: MarinaPalette.of(context).gold,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/orders/${data.orderId}'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(context.tr('viewOrder')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ReturnRequestScreen> createState() => _ReturnRequestState();
}

class _ReturnRequestState extends ConsumerState<ReturnRequestScreen> {
  final reason = TextEditingController();
  final note = TextEditingController();
  final quantities = <String, int>{};
  bool busy = false;
  String? error;

  @override
  void dispose() {
    reason.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (reason.text.trim().length < 3 || !quantities.values.any((x) => x > 0)) {
      setState(() => error = context.tr('selectReturnItems'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref
          .read(postPurchaseRepositoryProvider)
          .createReturn(
            widget.orderId,
            reason: reason.text,
            note: note.text,
            quantities: quantities,
          );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(context.tr('returnSubmitted')),
            content: Text((result['publicNumber'] ?? '').toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('continueShopping')),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      }
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
    final order = ref.watch(orderDetailsProvider(widget.orderId));
    final p = MarinaPalette.of(context);
    return MarinaPage(
      title: context.tr('requestReturn'),
      child: order.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(orderDetailsProvider(widget.orderId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.tr('chooseItems'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final line in data.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  line.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                subtitle: Text('${line.sku} · ${line.quantity}x'),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: p.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (quantities[line.id] ?? 0) == 0
                            ? null
                            : () => setState(
                                () => quantities[line.id] =
                                    (quantities[line.id] ?? 0) - 1,
                              ),
                        icon: const Icon(Icons.remove_rounded, size: 16),
                      ),
                      Text(
                        '${quantities[line.id] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: p.ink,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: (quantities[line.id] ?? 0) >= line.quantity
                            ? null
                            : () => setState(
                                () => quantities[line.id] =
                                    (quantities[line.id] ?? 0) + 1,
                              ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: reason,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: context.tr('returnReason'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('additionalDetails'),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: p.isDark
                        ? const Color(0xFFE58877)
                        : MarinaColors.danger,
                  ),
                ),
              ),
            MarinaGoldButton(
              label: context.tr('submitReturn'),
              busy: busy,
              onPressed: busy ? null : submit,
            ),
          ],
        ),
      ),
    );
  }
}

String _prettyStatus(String value) => value
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAll('_', ' ');

String _localizedStatus(BuildContext context, String value) {
  final key = 'status$value';
  final translated = context.tr(key);
  return translated == key ? _prettyStatus(value) : translated;
}
