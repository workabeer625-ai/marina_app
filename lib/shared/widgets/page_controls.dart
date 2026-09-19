import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/network/api_models.dart';
import '../../core/theme/marina_theme.dart';

final pageSelectionProvider =
    StateProvider.family<int, String>((ref, endpoint) => 1);

class PageControls extends ConsumerWidget {
  const PageControls({
    super.key,
    required this.endpoint,
    required this.page,
    this.loading = false,
  });

  final String endpoint;
  final ApiPage? page;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(pageSelectionProvider(endpoint));
    final total = page == null ? 0 : (page!.total / page!.pageSize).ceil();
    final p = MarinaPalette.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous',
              onPressed: !loading && current > 1
                  ? () =>
                      ref.read(pageSelectionProvider(endpoint).notifier).state--
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '$current / ${total < 1 ? 1 : total}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: p.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: !loading && page?.hasMore == true
                  ? () =>
                      ref.read(pageSelectionProvider(endpoint).notifier).state++
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
