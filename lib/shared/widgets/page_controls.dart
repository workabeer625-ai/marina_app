import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/network/api_models.dart';

final pageSelectionProvider = StateProvider.family<int, String>((ref, endpoint) => 1);

class PageControls extends ConsumerWidget {
  const PageControls({super.key, required this.endpoint, required this.page, this.loading = false});
  final String endpoint;
  final ApiPage? page;
  final bool loading;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(pageSelectionProvider(endpoint));
    final total = page == null ? 0 : (page!.total / page!.pageSize).ceil();
    return SafeArea(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(tooltip: 'Previous', onPressed: !loading && current > 1
        ? () => ref.read(pageSelectionProvider(endpoint).notifier).state-- : null,
        icon: const Icon(Icons.chevron_left)),
      Text('$current / ${total < 1 ? 1 : total}'),
      IconButton(tooltip: 'Next', onPressed: !loading && page?.hasMore == true
        ? () => ref.read(pageSelectionProvider(endpoint).notifier).state++ : null,
        icon: const Icon(Icons.chevron_right)),
    ]));
  }
}
