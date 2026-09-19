import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/marina_theme.dart';
import '../../features/products/domain/product.dart';

class MarinaPage extends StatelessWidget {
  const MarinaPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.floatingActionButton,
    this.bottom,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      backgroundColor: MarinaColors.navy,
      foregroundColor: Colors.white,
      toolbarHeight: 72,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -.3,
        ),
      ),
      actions: actions,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: child,
        ),
      ),
    ),
    floatingActionButton: floatingActionButton,
    bottomNavigationBar: bottom,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.shopping_bag_outlined,
    this.message,
    this.action,
  });
  final IconData icon;
  final String? message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: MarinaColors.softBlue,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(icon, size: 38, color: MarinaColors.deepRoyal),
          ),
          const SizedBox(height: 18),
          Text(
            message ?? context.tr('empty'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: _MarinaPulse());
}

class _MarinaPulse extends StatefulWidget {
  const _MarinaPulse();
  @override
  State<_MarinaPulse> createState() => _MarinaPulseState();
}

class _MarinaPulseState extends State<_MarinaPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(
      begin: .35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: MarinaColors.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: MarinaColors.royal.withValues(alpha: .24),
            blurRadius: 24,
          ),
        ],
      ),
      child: const Icon(Icons.water_outlined, color: MarinaColors.royal),
    ),
  );
}

class MarinaImage extends StatelessWidget {
  const MarinaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });
  final String? url;
  final BoxFit fit;
  final double? width, height;
  @override
  Widget build(BuildContext context) {
    final resolved = apiClient.mediaUrl(url);
    if (resolved.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: MarinaMotion.normal,
      placeholder: (_, _) => const _ImageLoading(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => const ColoredBox(
    color: MarinaColors.softBlue,
    child: Center(
      child: Icon(
        Icons.image_outlined,
        color: MarinaColors.deepRoyal,
        size: 42,
      ),
    ),
  );
}

class MarinaNetworkImage extends MarinaImage {
  const MarinaNetworkImage({
    super.key,
    required super.url,
    super.fit,
    super.width,
    super.height,
  });
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: MarinaColors.softBlue,
    child: Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: MarinaColors.softBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.cloud_off_outlined,
            size: 36,
            color: MarinaColors.deepRoyal,
          ),
        ),
        const SizedBox(height: 12),
        Text(message ?? context.tr('noInternet'), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text(context.tr('retry'))),
      ],
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/product/${product.id}', extra: product),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: product.image == null
                    ? Container(
                        color: MarinaTheme.sand,
                        child: const Center(
                          child: Icon(Icons.checkroom, size: 50),
                        ),
                      )
                    : MarinaNetworkImage(
                        url: product.image!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'SAR ${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: MarinaColors.royal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label, route;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: MarinaColors.softBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: MarinaColors.deepRoyal, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: MarinaColors.muted,
        ),
        onTap: () => context.push(route),
      ),
    ),
  );
}

class MarinaSectionCard extends StatelessWidget {
  const MarinaSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: MarinaColors.navy.withValues(alpha: .055),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

class MarinaPrice extends StatelessWidget {
  const MarinaPrice({super.key, required this.value, this.large = false});
  final double value;
  final bool large;
  @override
  Widget build(BuildContext context) => Text(
    'SAR ${value.toStringAsFixed(2)}',
    style: TextStyle(
      color: MarinaColors.royal,
      fontWeight: FontWeight.w800,
      fontSize: large ? 24 : 15,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}
