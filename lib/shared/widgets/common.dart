import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
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
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  p.gold.withValues(alpha: .8),
                ],
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
              gradient: LinearGradient(
                colors: [
                  p.gold.withValues(alpha: .8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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

/// Signature product card — image, gold discount badge, serif price.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final compareAt = product.compareAtPrice;
    final hasDiscount = compareAt != null && compareAt > product.price;
    final discount =
        hasDiscount ? (((1 - product.price / compareAt) * 100).round()) : 0;

    return Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}', extra: product),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line.withValues(alpha: .9)),
          ),
          padding: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: product.image == null
                          ? Container(
                              color: p.surfaceSoft,
                              child: Icon(
                                Icons.checkroom_rounded,
                                size: 46,
                                color: p.muted.withValues(alpha: .6),
                              ),
                            )
                          : MarinaNetworkImage(
                              url: product.image!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (hasDiscount)
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: MarinaGradients.gold,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '-$discount%',
                            style: TextStyle(
                              color: MarinaColors.onGold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
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
                        height: 1.3,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        MarinaPrice(value: product.price, large: false),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'SAR ${compareAt!.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.muted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: p.muted.withValues(alpha: .7),
                              ),
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
                  color: Color(0x0F141420),
                  blurRadius: 22,
                  offset: Offset(0, 10),
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
