import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../data/admin_operations_repository.dart';

class AdminReviewQueueScreen extends ConsumerWidget {
  const AdminReviewQueueScreen({super.key});

  Future<void> _moderate(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .moderateReview(id, status);
      ref.invalidate(adminReviewsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiFailureMessage(e, context.tr('retry')))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(adminReviewsProvider);
    return _AdminQueuePage(
      title: context.tr('adminReviews'),
      child: reviews.when(
        loading: () => const LoadingState(),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(adminReviewsProvider)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.verified_outlined,
                message: context.tr('queueEmpty'),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final review = items[index];
                  return _QueueCard(
                    title: review.title.isEmpty
                        ? '${review.rating}/5'
                        : review.title,
                    subtitle: review.body,
                    meta: '${review.rating}/5 · ${review.productId}',
                    actions: [
                      OutlinedButton(
                        onPressed: () =>
                            _moderate(context, ref, review.id, 'Rejected'),
                        child: Text(context.tr('reject')),
                      ),
                      FilledButton(
                        onPressed: () =>
                            _moderate(context, ref, review.id, 'Approved'),
                        child: Text(context.tr('approve')),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class AdminReturnQueueScreen extends ConsumerWidget {
  const AdminReturnQueueScreen({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final note = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('confirm')} — ${_status(context, status)}'),
        content: TextField(
          controller: note,
          maxLength: 1000,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: context.tr('adminNoteOptional'),
          ),
        ),
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
    );
    final noteValue = note.text.trim();
    note.dispose();
    if (accepted != true) return;
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .updateReturn(id, status, note: noteValue);
      ref.invalidate(adminReturnsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiFailureMessage(e, context.tr('retry')))),
        );
      }
    }
  }

  Future<void> _details(BuildContext context, String id) async {
    try {
      final data =
          (await apiClient.dio.get('/admin/returns/$id')).data
              as Map<String, dynamic>;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text((data['publicNumber'] ?? '').toString()),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${context.tr('returnReason')}: ${data['reason'] ?? ''}',
                  ),
                  if (data['customerNote']?.toString().isNotEmpty == true)
                    Text(data['customerNote'].toString()),
                  if (data['adminNote']?.toString().isNotEmpty == true)
                    Text('${context.tr('adminNote')}: ${data['adminNote']}'),
                  const Divider(height: 28),
                  Text(
                    context.tr('items'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final raw in data['items'] as List? ?? const [])
                    Builder(
                      builder: (context) {
                        final item = raw as Map;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text((item['productName'] ?? '').toString()),
                          subtitle: Text((item['sku'] ?? '').toString()),
                          trailing: Text('${item['quantity'] ?? 0}×'),
                        );
                      },
                    ),
                  const Divider(height: 28),
                  Text(
                    context.tr('returnTimeline'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final raw in data['timeline'] as List? ?? const [])
                    Builder(
                      builder: (context) {
                        final event = raw as Map;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(
                            _status(context, event['status'].toString()),
                          ),
                          subtitle: event['note'] == null
                              ? null
                              : Text(event['note'].toString()),
                        );
                      },
                    ),
                ],
              ),
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
    final returns = ref.watch(adminReturnsProvider);
    return _AdminQueuePage(
      title: context.tr('adminReturns'),
      child: returns.when(
        loading: () => const LoadingState(),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(adminReturnsProvider)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                message: context.tr('queueEmpty'),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final actions = <Widget>[
                    TextButton.icon(
                      onPressed: () => _details(context, item.id),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.tr('details')),
                    ),
                  ];
                  if (item.status == 'Requested') {
                    actions.add(
                      OutlinedButton(
                        onPressed: () =>
                            _update(context, ref, item.id, 'Rejected'),
                        child: Text(context.tr('reject')),
                      ),
                    );
                    actions.add(
                      FilledButton(
                        onPressed: () =>
                            _update(context, ref, item.id, 'Approved'),
                        child: Text(context.tr('approve')),
                      ),
                    );
                  } else if (item.status == 'Approved') {
                    actions.add(
                      FilledButton(
                        onPressed: () =>
                            _update(context, ref, item.id, 'Received'),
                        child: Text(context.tr('markReceived')),
                      ),
                    );
                  } else if (item.status == 'Received') {
                    actions.add(
                      FilledButton(
                        onPressed: () =>
                            _update(context, ref, item.id, 'RefundPending'),
                        child: Text(context.tr('requestRefund')),
                      ),
                    );
                  }
                  return _QueueCard(
                    title: item.publicNumber,
                    subtitle: item.reason,
                    meta:
                        '${item.status} · ${item.itemCount} ${context.tr('items')}',
                    actions: actions,
                  );
                },
              ),
      ),
    );
  }
}

class _AdminQueuePage extends StatelessWidget {
  const _AdminQueuePage({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 22),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.actions,
  });
  final String title, subtitle, meta;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(meta, style: TextStyle(color: p.muted, fontSize: 12.5)),
          const SizedBox(height: 12),
          Text(subtitle),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

String _status(BuildContext context, String value) {
  final key = 'status$value';
  final translated = context.tr(key);
  return translated == key ? value : translated;
}
