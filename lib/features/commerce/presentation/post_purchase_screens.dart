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
                  color: MarinaTheme.sand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      page.average.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Stars(value: page.average.round()),
                          Text(
                            '${page.count} ${context.tr('verifiedReviews')}',
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
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: MarinaTheme.line),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: MarinaTheme.blue,
                                child: Icon(Icons.person_outline),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  review.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _Stars(value: review.rating, size: 16),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (review.title.isNotEmpty)
                            Text(
                              review.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(review.body),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('verifiedPurchase'),
                            style: const TextStyle(
                              color: Color(0xFF66765B),
                              fontSize: 12,
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (i) => Icon(
        i < value ? Icons.star_rounded : Icons.star_border_rounded,
        size: size,
        color: const Color(0xFFB58945),
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
      24,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('writeReview'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: () => setState(() => rating = i + 1),
              icon: Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFB58945),
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
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('submitForReview')),
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
      bottom: PageControls(endpoint: '/orders', page: orders.value, loading: orders.isLoading),
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
                    return ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: MarinaTheme.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        order.publicNumber,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${_localizedStatus(context, order.status)} · ${order.itemCount} ${context.tr('items')} · SAR ${order.total.toStringAsFixed(2)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/orders/${order.id}'),
                    );
                  },
                ),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MarinaTheme.blue.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('orderNumber').toUpperCase()),
                  Text(
                    data.publicNumber,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_localizedStatus(context, data.status)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            for (final event in data.timeline)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: MarinaTheme.blue,
                  child: Icon(Icons.check, size: 18),
                ),
                title: Text(_localizedStatus(context, event.status)),
                subtitle: event.reason == null ? null : Text(event.reason!),
              ),
            const Divider(height: 32),
            Text(
              context.tr('items'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final line in data.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.productName),
                subtitle: Text('${line.sku} · ${line.quantity}x'),
                trailing: Text('SAR ${line.unitPrice.toStringAsFixed(2)}'),
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
              icon: const Icon(Icons.headset_mic_outlined),
              label: Text(context.tr('contact')),
            ),
          ],
        ),
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
      bottom: PageControls(endpoint: '/returns', page: returns.value, loading: returns.isLoading),
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
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final item = page.items[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: MarinaTheme.sand,
                        child: Icon(Icons.assignment_return_outlined),
                      ),
                      title: Text(item.publicNumber),
                      subtitle: Text(
                        '${_localizedStatus(context, item.status)} • ${item.reason}\n${item.itemCount} ${context.tr('items')}',
                      ),
                      isThreeLine: true,
                      trailing: item.status == 'Requested'
                          ? TextButton(
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
                      onTap: () => context.push('/returns/${item.id}'),
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MarinaTheme.blue.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.publicNumber),
                    const SizedBox(height: 6),
                    Text(
                      _localizedStatus(context, data.status),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${context.tr('returnReason')}: ${data.reason}'),
                    if (data.customerNote?.isNotEmpty == true)
                      Text(data.customerNote!),
                    if (data.adminNote?.isNotEmpty == true)
                      Text('${context.tr('adminNote')}: ${data.adminNote}'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                context.tr('returnTimeline'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final event in data.timeline)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: MarinaTheme.sand,
                    child: Icon(Icons.check, size: 18),
                  ),
                  title: Text(_localizedStatus(context, event.status)),
                  subtitle: event.note?.isNotEmpty == true
                      ? Text(event.note!)
                      : null,
                ),
              const Divider(height: 32),
              Text(
                context.tr('items'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final item in data.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: Text(item.sku),
                  trailing: Text('${item.quantity}×'),
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final line in data.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.productName),
                subtitle: Text('${line.sku} · ${line.quantity}x'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: (quantities[line.id] ?? 0) == 0
                          ? null
                          : () => setState(
                              () => quantities[line.id] =
                                  (quantities[line.id] ?? 0) - 1,
                            ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${quantities[line.id] ?? 0}'),
                    IconButton(
                      onPressed: (quantities[line.id] ?? 0) >= line.quantity
                          ? null
                          : () => setState(
                              () => quantities[line.id] =
                                  (quantities[line.id] ?? 0) + 1,
                            ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
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
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('submitReturn')),
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
