import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/state/commerce_state.dart';
import '../../core/theme/marina_theme.dart';
import '../../features/products/domain/product.dart';

/// Unified page scaffold: hairline app bar over the page background,
/// centered content column for wide screens.
class MarinaPage extends StatelessWidget {
  const MarinaPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.floatingActionButton,
    this.bottom,
    this.titleWidget,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottom;
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        systemOverlayStyle:
            p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: titleWidget ?? Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: p.line.withValues(alpha: .8),
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
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
}

/// Round glass icon button used across headers (dark hero or light pages).
class MarinaIconButton extends StatelessWidget {
  const MarinaIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
    this.badgeCount = 0,
    this.dot = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final int badgeCount;
  final bool dot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: .08)
              : (p.isDark ? Colors.white.withValues(alpha: .06) : Colors.white),
          shape: BoxShape.circle,
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: .16)
                : p.line,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: dark ? Colors.white : p.ink,
            ),
            if (badgeCount > 0)
              PositionedDirectional(
                top: 4,
                end: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5),
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  decoration: BoxDecoration(
                    color: p.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: p.onGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              )
            else if (dot)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: p.gold,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dark ? MarinaColors.navy : Colors.white,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Thin gold ornament divider with a diamond in the middle.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key, this.width = 120});
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    p.gold.withValues(alpha: .8),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration:
                BoxDecoration(color: p.gold, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.gold.withValues(alpha: .8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Picks a fitting icon for a catalog category by matching its name
/// (English or Arabic), with a rotating fallback set.
IconData marinaCategoryIcon(String name, {int fallbackIndex = 0}) {
  final n = name.toLowerCase();
  if (n.contains('offer') || n.contains('sale') || n.contains('عرض')) {
    return Icons.local_offer_rounded;
  }
  if (n.contains('new') || n.contains('وصل') || n.contains('جديد')) {
    return Icons.fiber_new_rounded;
  }
  if (n.contains('season') || n.contains('موسم')) {
    return Icons.calendar_month_rounded;
  }
  if (n.contains('shoe') || n.contains('حذاء') || n.contains('أحذية')) {
    return Icons.ice_skating_rounded;
  }
  if (n.contains('kid') || n.contains('child') || n.contains('أطفال')) {
    return Icons.child_care_rounded;
  }
  if (n.contains('accessor') || n.contains('إكسسوار') || n.contains('اكسسوار')) {
    return Icons.watch_rounded;
  }
  if (n.contains('bag') || n.contains('حقيبة') || n.contains('حقائب')) {
    return Icons.backpack_rounded;
  }
  const fallback = [
    Icons.checkroom_rounded,
    Icons.dry_cleaning_rounded,
    Icons.hiking_rounded,
    Icons.watch_rounded,
    Icons.child_friendly_rounded,
  ];
  return fallback[fallbackIndex % fallback.length];
}


/// Cinematic entrance: fades + slides up with a stagger based on [index].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.fromTop = false,
  });

  final Widget child;
  final int index;
  final bool fromTop;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void initState() {
    super.initState();
    final i = widget.index;
    final step = i < 0 ? 0 : (i > 8 ? 8 : i);
    Future.delayed(Duration(milliseconds: 70 * step), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final offset = widget.fromTop ? -18.0 : 26.0;
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Luxury press feedback: gentle scale-down while touched.
class MarinaPressable extends StatefulWidget {
  const MarinaPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  @override
  State<MarinaPressable> createState() => _MarinaPressableState();
}

class _MarinaPressableState extends State<MarinaPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) {
      if (mounted) setState(() => _down = true);
    },
    onTapUp: (_) {
      if (mounted) setState(() => _down = false);
    },
    onTapCancel: () {
      if (mounted) setState(() => _down = false);
    },
    child: AnimatedScale(
      scale: _down ? .965 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: widget.child,
    ),
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
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: p.surfaceSoft,
                shape: BoxShape.circle,
                border: Border.all(color: p.gold.withValues(alpha: .35)),
              ),
              child: Icon(icon, size: 36, color: p.gold),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? context.tr('empty'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return FadeTransition(
      opacity: Tween(begin: .35, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: p.isDark ? MarinaColors.nightSurfaceSoft : MarinaColors.navy,
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: p.gold.withValues(alpha: .28),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.sailing_rounded, color: p.gold),
      ),
    );
  }
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
    color: MarinaColors.sand,
    child: Center(
      child: Icon(
        Icons.image_outlined,
        color: MarinaColors.goldDeep,
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
  Widget build(BuildContext context) => ColoredBox(
    color: MarinaColors.sand,
    child: const Center(
      child: SizedBox.square(
        dimension: 22,
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
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: p.isDark
                    ? const Color(0xFF2A1A17)
                    : MarinaColors.dangerTint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (p.isDark
                          ? const Color(0xFFE58877)
                          : MarinaColors.danger)
                      .withValues(alpha: .4),
                ),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color:
                    p.isDark ? const Color(0xFFE58877) : MarinaColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? context.tr('noInternet'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fashion product experience card: full-bleed editorial image, refined
/// typography, gold discount seal and a quick-add jewel over the photo.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final variantId = product.variantId;
    if (variantId == null || variantId.isEmpty) return;
    if (!await apiClient.hasSession()) {
      if (context.mounted) context.push('/login');
      return;
    }
    try {
      await ref.read(cartProvider.notifier).add(variantId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('addToBag'))),
        );
      }
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
    final p = MarinaPalette.of(context);
    final compareAtValue = product.compareAtPrice;
    final hasDiscount =
        compareAtValue != null && compareAtValue > product.price;
    final compareAt = compareAtValue ?? 0.0;
    final discount =
        hasDiscount ? (((1 - product.price / compareAt) * 100).round()) : 0;
    final canQuickAdd =
        product.variantId != null && product.variantId!.isNotEmpty;

    return Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.line.withValues(alpha: .85)),
      ),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}', extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.image == null
                      ? ColoredBox(
                          color: p.surfaceSoft,
                          child: Icon(
                            Icons.checkroom_rounded,
                            size: 44,
                            color: p.muted.withValues(alpha: .55),
                          ),
                        )
                      : MarinaNetworkImage(
                          url: product.image!,
                          fit: BoxFit.cover,
                        ),
                  if (hasDiscount)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: MarinaGradients.gold,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: MarinaColors.gold.withValues(alpha: .4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: MarinaColors.onGold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  if (canQuickAdd)
                    PositionedDirectional(
                      bottom: 10,
                      end: 10,
                      child: GestureDetector(
                        onTap: () => _quickAdd(context, ref),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: MarinaGradients.gold,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66C29B4C),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: MarinaColors.onGold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.32,
                      letterSpacing: .1,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      MarinaPrice(value: product.price),
                      if (hasDiscount) ...[
                        const Spacer(),
                        Text(
                          'SAR ${compareAt.toStringAsFixed(0)}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: p.muted.withValues(alpha: .85),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line.withValues(alpha: .9)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onTap: () => context.push(route),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.goldSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.gold.withValues(alpha: .25)),
            ),
            child: Icon(icon, color: p.gold, size: 21),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: p.ink,
            ),
          ),
          trailing: trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: p.muted.withValues(alpha: .7),
              ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line.withValues(alpha: .9)),
        boxShadow: p.isDark
            ? const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x1A141420),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x0A141420),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }
}

class MarinaPrice extends StatelessWidget {
  const MarinaPrice({
    super.key,
    required this.value,
    this.large = false,
    this.color,
  });

  final double value;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Text(
      'SAR ${value.toStringAsFixed(2)}',
      style: TextStyle(
        fontFamily: 'Marcellus',
        fontFamilyFallback: const ['Tajawal'],
        color: color ?? p.ink,
        fontWeight: FontWeight.w700,
        fontSize: large ? 23 : 14.5,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Primary luxury call-to-action: gold gradient capsule with dark text.
class MarinaGoldButton extends StatelessWidget {
  const MarinaGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: enabled
              ? MarinaGradients.gold
              : const LinearGradient(
                  colors: [Color(0xFFB7A274), Color(0xFFB7A274)],
                ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: MarinaColors.gold.withValues(alpha: .38),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: MarinaColors.onGold,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon!, size: 19, color: MarinaColors.onGold),
                          const SizedBox(width: 9),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MarinaColors.onGold,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

/// Colored status pill with a small dot — used for order & return statuses.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.status});

  final String label;
  final String status;

  static Color colorFor(String status) {
    switch (status) {
      case 'Pending':
      case 'Requested':
      case 'RefundPending':
        return MarinaColors.warning;
      case 'Confirmed':
      case 'Approved':
      case 'Shipped':
        return MarinaColors.royal;
      case 'Preparing':
        return const Color(0xFF7C5CBF);
      case 'Ready':
      case 'OutForDelivery':
        return const Color(0xFF1F8A70);
      case 'Delivered':
      case 'Received':
      case 'Refunded':
        return MarinaColors.success;
      case 'Cancelled':
      case 'Rejected':
      case 'Returned':
        return MarinaColors.danger;
      default:
        return MarinaColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final color = colorFor(status);
    final tint = p.isDark ? color.withValues(alpha: .16) : color.withValues(alpha: .1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: p.isDark ? color.brighten() : color.deepen(),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

extension _StatusColorAdjust on Color {
  Color brighten() => Color.lerp(this, Colors.white, .25)!;
  Color deepen() => Color.lerp(this, Colors.black, .12)!;
}
