import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../../core/state/commerce_state.dart';
import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/marina_wordmark.dart';
import '../../products/data/catalog_repository.dart';
import '../../products/domain/product.dart';
import '../../profile/data/customer_repository.dart';

CatalogQuery _query(
  BuildContext context, {
  String? search,
  String? categoryId,
  String? brandId,
  String? color,
  String? size,
  double? minPrice,
  double? maxPrice,
  bool offers = false,
  bool newArrivals = false,
  String sort = 'newest',
}) => (
  culture: Localizations.localeOf(context).languageCode,
  search: search,
  categoryId: categoryId,
  brandId: brandId,
  color: color,
  size: size,
  minPrice: minPrice,
  maxPrice: maxPrice,
  offers: offers,
  newArrivals: newArrivals,
  sort: sort,
);

/// ─────────────────────────────────────────────────────────────────────────
///  HOME — a cinematic fashion magazine cover, not a store listing.
/// ─────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = Localizations.localeOf(context).languageCode;
    final home = ref.watch(catalogHomeProvider(culture));
    final authed = apiClient.isAuthenticated;
    final AsyncValue<CartSnapshot> cart =
        authed ? ref.watch(cartProvider) : const AsyncLoading();
    final AsyncValue<ApiPage<CustomerNotification>> notifications = authed
        ? ref.watch(customerNotificationsProvider)
        : const AsyncLoading();
    final bagCount =
        cart.value?.items.fold<int>(0, (sum, line) => sum + line.quantity) ??
            0;
    final hasUnread =
        notifications.value?.items.any((x) => x.readUtc == null) ?? false;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(catalogHomeProvider(culture).future),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: home.when(
                    loading: () => SizedBox(
                      height: MediaQuery.sizeOf(context).height * .82,
                      child: const LoadingState(),
                    ),
                    error: (e, _) => SizedBox(
                      height: 420,
                      child: ErrorState(
                        message: apiFailureMessage(e, context.tr('retry')),
                        onRetry: () =>
                            ref.invalidate(catalogHomeProvider(culture)),
                      ),
                    ),
                    data: (data) => _MagazineBody(
                      data: data,
                      dark: dark,
                      bagCount: bagCount,
                      hasUnread: hasUnread,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed hero + overlapping editorial sheet.
class _MagazineBody extends ConsumerWidget {
  const _MagazineBody({
    required this.data,
    required this.dark,
    required this.bagCount,
    required this.hasUnread,
  });

  final CatalogHome data;
  final bool dark;
  final int bagCount;
  final bool hasUnread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MarinaPalette.of(context);
    final wide = MediaQuery.sizeOf(context).width;
    final desktop = wide >= 700;

    return Stack(
      children: [
        // ── The cover ──
        Container(
          height: desktop ? 560 : 470,
          decoration: const BoxDecoration(color: MarinaColors.midnight),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/visuals/home-hero.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, .42, .78, 1],
                    colors: const [
                      Color(0xD9070C15),
                      Color(0x33070C15),
                      Color(0xB8070C15),
                      Color(0xFF070C15),
                    ],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _pagePadding(wide),
                    8,
                    _pagePadding(wide),
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: SizedBox(
                                width: 150,
                                child: MarinaWordmark(
                                  dark: false,
                                  compact: true,
                                ),
                              ),
                            ),
                          ),
                          _ThemeToggleButton(),
                          const SizedBox(width: 8),
                          MarinaIconButton(
                            icon: Icons.notifications_none_rounded,
                            dark: true,
                            dot: hasUnread,
                            onTap: () => context.push('/notifications'),
                          ),
                          const SizedBox(width: 8),
                          MarinaIconButton(
                            icon: Icons.shopping_bag_outlined,
                            dark: true,
                            badgeCount: bagCount,
                            onTap: () => context.push('/cart'),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'MARINA COLLECTION',
                        style: TextStyle(
                          color: MarinaColors.goldBright,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing:
                              MarinaType.isArabic(context) ? 0 : 4.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: wide * .82),
                        child: Text(
                          data.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: MarinaType.display(
                            context,
                            size: desktop ? 44 : 33,
                            height: 1.14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (data.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          data.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFC9D3E3),
                            fontSize: desktop ? 15 : 13.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: desktop ? 320 : double.infinity,
                        child: MarinaGoldButton(
                          label: context.tr('discoverCollection'),
                          icon: Icons.arrow_outward_rounded,
                          height: 54,
                          onPressed: () => context.push('/products'),
                        ),
                      ),
                      const SizedBox(height: 88),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Editorial sheet sliding over the cover ──
        Transform.translate(
          offset: const Offset(0, -30),
          child: Container(
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .45 : .18),
                  blurRadius: 34,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _pagePadding(wide),
                  ),
                  child: _SearchPill(),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _pagePadding(wide)),
                  child: FadeSlideIn(
                    index: 0,
                    child: SectionHeading(
                      kicker: context.tr('collections').toUpperCase(),
                      title: context.tr('categories'),
                      route: '/categories',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 1,
                  child: SizedBox(
                    height: 226,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: _pagePadding(wide),
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: data.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final category = data.categories[i];
                        return _CollectionCard(
                          name: category.name,
                          index: i,
                          onTap: () =>
                              context.push('/products?category=${category.id}'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _EditorialRail(
                  stagger: 2,
                  title: context.tr('new'),
                  kicker: 'NEW SEASON',
                  route: '/new-arrivals',
                  items: data.products,
                ),
                _EditorialRail(
                  stagger: 3,
                  title: context.tr('offers'),
                  kicker: 'UP TO -30%',
                  route: '/offers',
                  items: data.products.reversed.toList(),
                ),
                _EditorialRail(
                  stagger: 4,
                  title: context.tr('bestSellers'),
                  kicker: 'MOST LOVED',
                  route: '/products',
                  items: data.products.skip(2).toList(),
                ),
                _EditorialRail(
                  stagger: 5,
                  title: context.tr('recommended'),
                  kicker: 'CURATED FOR YOU',
                  route: '/products',
                  items: data.products.skip(4).toList(),
                ),
                const SizedBox(height: 40),
                Center(child: GoldDivider(width: 150)),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'MARINA',
                    style: TextStyle(
                      fontFamily: 'Marcellus',
                      fontFamilyFallback: ['Tajawal'],
                      fontSize: 15,
                      letterSpacing: 7,
                      color: p.muted.withValues(alpha: .8),
                    ),
                  ),
                ),
                SizedBox(
                  height: 122,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _pagePadding(double width) => width >= 1200
    ? 48
    : width >= 768
    ? 32
    : 18;

/// Floating glass search seam between cover and sheet.
class _SearchPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Material(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: BorderSide(color: p.line.withValues(alpha: .9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => context.push('/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: p.gold),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  context.tr('search'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Day / night switch for the home cover.
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final effectiveDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    return GestureDetector(
      onTap: () => ref
          .read(themeModeProvider.notifier)
          .set(effectiveDark ? ThemeMode.light : ThemeMode.dark),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
        ),
        child: AnimatedSwitcher(
          duration: MarinaMotion.normal,
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween(begin: .75, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            key: ValueKey(effectiveDark),
            effectiveDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            size: 19,
            color: MarinaColors.goldBright,
          ),
        ),
      ),
    );
  }
}

/// Editorial collection card — a door into its own world.
class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.name,
    required this.onTap,
    required this.index,
  });

  final String name;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gradients = const [
      [Color(0xFF1A2542), Color(0xFF0B1322)],
      [Color(0xFF232C46), Color(0xFF101826)],
      [Color(0xFF1D2A1F), Color(0xFF0C1410)],
    ];
    final pair = gradients[index % gradients.length];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MarinaPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 274,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: pair,
          ),
          border: Border.all(color: MarinaColors.gold.withValues(alpha: .3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59101B2D),
              blurRadius: 26,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -46,
              top: -46,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MarinaColors.gold.withValues(alpha: .22),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 18,
              bottom: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MarinaColors.gold.withValues(alpha: .14),
                    width: 1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLLECTION',
                    style: TextStyle(
                      color: MarinaColors.goldBright,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: MarinaType.isArabic(context) ? 0 : 3.4,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MarinaType.display(
                      context,
                      size: 22,
                      height: 1.22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        context.tr('explore'),
                        style: TextStyle(
                          color: MarinaColors.goldBright,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: MarinaType.isArabic(context) ? 0 : .6,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 15,
                        color: MarinaColors.goldBright,
                      ),
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

/// Editorial product rail with kicker header and staggered entrance.
class _EditorialRail extends StatelessWidget {
  const _EditorialRail({
    required this.stagger,
    required this.kicker,
    required this.title,
    required this.route,
    required this.items,
  });

  final int stagger;
  final String kicker, title, route;
  final List<Product> items;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width;
    return FadeSlideIn(
      index: stagger,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _pagePadding(wide)),
              child: SectionHeading(
                kicker: kicker,
                title: title,
                route: route,
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const SizedBox(height: 170, child: EmptyState())
            else
              SizedBox(
                height: 294,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: _pagePadding(wide)),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.take(12).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => SizedBox(
                    width: wide >= 1000
                        ? 218
                        : wide >= 600
                        ? 196
                        : 170,
                    child: ProductCard(product: items[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.kicker,
    required this.title,
    required this.route,
  });

  final String kicker, title, route;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: MarinaType.kicker(
                  context,
                  color: p.gold,
                  size: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MarinaType.display(context, size: 22),
              ),
            ],
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: () => context.push(route),
          icon: Text(
            context.tr('viewAll'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          label: Icon(
            rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
            size: 15,
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
///  CATALOG / BRANDS / CATEGORIES / SEARCH  (same functionality, styled)
/// ─────────────────────────────────────────────────────────────────────────

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({
    super.key,
    this.titleKey = 'products',
    this.search,
    this.categoryId,
    this.brandId,
    this.offers = false,
    this.newArrivals = false,
  });

  final String titleKey;
  final String? search, categoryId, brandId;
  final bool offers, newArrivals;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String sort = 'newest';
  String? brandId, color, size;
  double? minPrice, maxPrice;

  @override
  void initState() {
    super.initState();
    brandId = widget.brandId;
  }

  @override
  Widget build(BuildContext context) {
    final culture = Localizations.localeOf(context).languageCode;
    final query = _query(
      context,
      search: widget.search,
      categoryId: widget.categoryId,
      brandId: brandId,
      color: color,
      size: size,
      minPrice: minPrice,
      maxPrice: maxPrice,
      offers: widget.offers,
      newArrivals: widget.newArrivals,
      sort: sort,
    );
    final data = ref.watch(productListProvider(query));
    var title = context.tr(widget.titleKey);
    if (brandId != null) {
      final name = ref
          .watch(brandsProvider(culture))
          .value
          ?.where((x) => x.id == brandId)
          .firstOrNull
          ?.name;
      if (name != null) title = name;
    } else if (widget.categoryId != null) {
      final name = ref
          .watch(categoriesProvider(culture))
          .value
          ?.where((x) => x.id == widget.categoryId)
          .firstOrNull
          ?.name;
      if (name != null) title = name;
    }
    return MarinaPage(
      title: title,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('collection').toUpperCase(),
            style: MarinaType.kicker(context, size: 9.5),
          ),
          const SizedBox(height: 2),
          Text(title, style: MarinaType.display(context, size: 20)),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          initialValue: sort,
          icon: const Icon(Icons.sort_rounded),
          onSelected: (value) => setState(() => sort = value),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'newest', child: Text(context.tr('newest'))),
            PopupMenuItem(
              value: 'price_asc',
              child: Text(context.tr('priceLowHigh')),
            ),
            PopupMenuItem(
              value: 'price_desc',
              child: Text(context.tr('priceHighLow')),
            ),
            PopupMenuItem(value: 'name', child: Text(context.tr('name'))),
          ],
        ),
        IconButton(
          tooltip: context.tr('filters'),
          onPressed: _showFilters,
          icon: Badge(
            isLabelVisible:
                brandId != null ||
                color != null ||
                size != null ||
                minPrice != null ||
                maxPrice != null,
            child: const Icon(Icons.tune_rounded),
          ),
        ),
        const SizedBox(width: 4),
      ],
      child: data.when(
        data: (items) => items.isEmpty
            ? const EmptyState(icon: Icons.search_off)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(productListProvider(query).future),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final columns = c.maxWidth >= 1000
                        ? 4
                        : c.maxWidth >= 620
                        ? 3
                        : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 122),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: columns == 2 ? .62 : .58,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => ProductCard(product: items[i]),
                    );
                  },
                ),
              ),
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(productListProvider(query)),
        ),
      ),
    );
  }

  Future<void> _showFilters() async {
    final culture = Localizations.localeOf(context).languageCode;
    final p = MarinaPalette.of(context);
    CatalogFilters options;
    try {
      options = await ref.read(catalogFiltersProvider(culture).future);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiFailureMessage(error, context.tr('retry'))),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final minimum = TextEditingController(text: minPrice?.toString() ?? '');
    final maximum = TextEditingController(text: maxPrice?.toString() ?? '');
    var selectedBrand = brandId;
    var selectedColor = color;
    var selectedSize = size;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('filters'),
                  style: MarinaType.display(context, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('sortFilter'),
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String?>(
                  initialValue: selectedBrand,
                  decoration: InputDecoration(labelText: context.tr('brands')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('all')),
                    ),
                    ...options.brands.map(
                      (x) => DropdownMenuItem(value: x.id, child: Text(x.name)),
                    ),
                  ],
                  onChanged: (value) => selectedBrand = value,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: selectedColor,
                  decoration: InputDecoration(labelText: context.tr('colors')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('all')),
                    ),
                    ...options.colors.map(
                      (x) =>
                          DropdownMenuItem(value: x.code, child: Text(x.name)),
                    ),
                  ],
                  onChanged: (value) => selectedColor = value,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: selectedSize,
                  decoration: InputDecoration(labelText: context.tr('sizes')),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('all')),
                    ),
                    ...options.sizes.map(
                      (x) =>
                          DropdownMenuItem(value: x.code, child: Text(x.name)),
                    ),
                  ],
                  onChanged: (value) => selectedSize = value,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minimum,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('minimumPrice'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maximum,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('maximumPrice'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        selectedBrand = null;
                        selectedColor = null;
                        selectedSize = null;
                        minimum.clear();
                        maximum.clear();
                        update(() {});
                      },
                      child: Text(context.tr('clearFilters')),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: MarinaGoldButton(
                        label: context.tr('apply'),
                        height: 50,
                        onPressed: () => context.pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final minimumValue = double.tryParse(minimum.text);
    final maximumValue = double.tryParse(maximum.text);
    minimum.dispose();
    maximum.dispose();
    if (result == true) {
      setState(() {
        brandId = selectedBrand;
        color = selectedColor;
        size = selectedSize;
        minPrice = minimumValue;
        maxPrice = maximumValue;
      });
    }
  }
}

class BrandsScreen extends ConsumerWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = Localizations.localeOf(context).languageCode;
    final brands = ref.watch(brandsProvider(culture));
    return MarinaPage(
      title: context.tr('brands'),
      child: brands.when(
        loading: () => const LoadingState(),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(brandsProvider(culture))),
        data: (items) => items.isEmpty
            ? const EmptyState(icon: Icons.storefront_outlined)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(brandsProvider(culture).future),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 122),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final brand = items[index];
                    final p = MarinaPalette.of(context);
                    return Material(
                      color: p.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: p.line.withValues(alpha: .9),
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            context.push('/products?brand=${brand.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: p.goldSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 17,
                                  color: p.gold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  brand.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: p.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = Localizations.localeOf(context).languageCode;
    final categories = ref.watch(categoriesProvider(culture));
    return MarinaPage(
      title: context.tr('categories'),
      child: categories.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(categoriesProvider(culture)),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(icon: Icons.category_outlined)
            : RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(categoriesProvider(culture).future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 122),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = MarinaPalette.of(context);
                    return MarinaPressable(
                      onTap: () =>
                          context.push('/products?category=${items[i].id}'),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: p.line.withValues(alpha: .9),
                          ),
                          boxShadow: p.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: p.goldSoft,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: p.gold.withValues(alpha: .3),
                                ),
                              ),
                              child: Icon(
                                marinaCategoryIcon(
                                  items[i].name,
                                  fallbackIndex: i,
                                ),
                                color: p.gold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                items[i].name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 16),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: p.muted.withValues(alpha: .7),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => setState(() => query = value.trim()),
          decoration: InputDecoration(
            hintText: context.tr('search'),
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: p.surface,
          ),
        ),
      ),
      body: query.isEmpty
          ? EmptyState(
              icon: Icons.manage_search_rounded,
              message: context.tr('searchPrompt'),
            )
          : CatalogScreen(titleKey: 'search', search: query),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
///  PRODUCT DETAILS — the editorial lookbook page.
/// ─────────────────────────────────────────────────────────────────────────

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id, this.product});

  final String id;
  final Product? product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<ProductDetailScreen> {
  String? selectedColor;
  String? selectedVariantId;
  int quantity = 1;
  bool adding = false;

  String? _colorLabel(ProductVariant v) =>
      (v.color?.trim().isNotEmpty == true) ? v.color!.trim() : null;

  String? _sizeLabel(ProductVariant v) =>
      (v.size?.trim().isNotEmpty == true) ? v.size!.trim() : null;

  List<String> _colorsOf(ProductDetails product) {
    final out = <String>[];
    for (final v in product.variants) {
      final c = _colorLabel(v);
      if (c != null && !out.contains(c)) out.add(c);
    }
    return out;
  }

  List<ProductVariant> _variantsOf(ProductDetails product, String? color) =>
      color == null
          ? product.variants
          : product.variants
              .where((v) => _colorLabel(v) == color)
              .toList();

  List<String> _sizesOf(ProductDetails product, String? color) {
    final out = <String>[];
    for (final v in _variantsOf(product, color)) {
      final sz = _sizeLabel(v);
      if (sz != null && !out.contains(sz)) out.add(sz);
    }
    return out;
  }

  bool _sizeAvailable(ProductDetails product, String size) =>
      _variantsOf(product, selectedColor)
          .any((v) => _sizeLabel(v) == size && v.available);

  ProductVariant? _variantFor(ProductDetails product, String size) =>
      _variantsOf(product, selectedColor)
          .where((v) => _sizeLabel(v) == size && v.available)
          .firstOrNull;

  ProductVariant? _selected(ProductDetails product) {
    final byId = product.variants
        .where((v) => v.id == selectedVariantId)
        .firstOrNull;
    if (byId != null) return byId;
    final available =
        _variantsOf(product, selectedColor).where((v) => v.available).toList();
    return available.firstOrNull ?? product.variants.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final culture = Localizations.localeOf(context).languageCode;
    final details = ref.watch(
      productDetailsProvider((id: widget.id, culture: culture)),
    );
    return details.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: apiFailureMessage(error, context.tr('retry')),
          onRetry: () => ref.invalidate(
            productDetailsProvider((id: widget.id, culture: culture)),
          ),
        ),
      ),
      data: (product) {
        final p = MarinaPalette.of(context);
        final colors = _colorsOf(product);
        if (selectedColor == null && colors.isNotEmpty) {
          selectedColor = colors.first;
        }
        final sizes = _sizesOf(product, selectedColor);
        final selected = _selected(product);
        final wide = MediaQuery.sizeOf(context).width;
        final rtl = Directionality.of(context) == TextDirection.rtl;

        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 10),
                        children: [
                          // ── Hero gallery ──
                          Stack(
                            children: [
                              _ProductGallery(images: product.images),
                              SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      MarinaIconButton(
                                        icon: rtl
                                            ? Icons.arrow_forward_ios_rounded
                                            : Icons.arrow_back_ios_new_rounded,
                                        dark: true,
                                        onTap: () => context.canPop()
                                            ? context.pop()
                                            : context.go('/home'),
                                      ),
                                      _FavoriteButton(productId: product.id),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ── Floating lookbook panel ──
                          Transform.translate(
                            offset: const Offset(0, -34),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: MarinaSectionCard(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MARINA',
                                      style: MarinaType.kicker(context, size: 10),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.name,
                                      style: MarinaType.display(
                                        context,
                                        size: wide >= 600 ? 27 : 23,
                                        height: 1.24,
                                      ),
                                    ),
                                    if (selected != null) ...[
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          MarinaPrice(
                                            value: selected.price,
                                            large: true,
                                          ),
                                          if (selected.compareAtPrice != null &&
                                              selected.compareAtPrice! >
                                                  selected.price) ...[
                                            const SizedBox(width: 10),
                                            Text(
                                              'SAR ${selected.compareAtPrice!.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: p.muted,
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                    if (product.description.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          height: 1.65,
                                          fontSize: 13.5,
                                          color: p.muted,
                                        ),
                                      ),
                                    ],
                                    // ── Color experience ──
                                    if (colors.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _SelectorLabel(
                                        label: context.tr('color'),
                                        value: selectedColor,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children:
                                            colors.map((colorName) {
                                          final variantsOfColor =
                                              _variantsOf(product, colorName);
                                          final anyAvailable = variantsOfColor
                                              .any((v) => v.available);
                                          final hex = variantsOfColor
                                              .map((v) => v.colorHex)
                                              .firstWhere(
                                                (h) =>
                                                    h?.isNotEmpty == true,
                                                orElse: () => null,
                                              );
                                          final parsed = int.tryParse(
                                            'FF${hex?.replaceAll('#', '') ?? ''}',
                                            radix: 16,
                                          );
                                          final swatchColor = parsed != null
                                              ? Color(parsed)
                                              : p.surfaceSoft;
                                          final isSelected =
                                              selectedColor == colorName;
                                          return MarinaPressable(
                                            onTap: anyAvailable
                                                ? () => setState(() {
                                                    selectedColor = colorName;
                                                    selectedVariantId = null;
                                                    quantity = 1;
                                                  })
                                                : () {},
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            child: Opacity(
                                              opacity: anyAvailable ? 1 : .35,
                                              child: Container(
                                                width: 46,
                                                height: 46,
                                                decoration: BoxDecoration(
                                                  color: swatchColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? p.gold
                                                        : p.line,
                                                    width: isSelected ? 2.4 : 1,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: p.gold
                                                                .withValues(
                                                                    alpha: .35),
                                                            blurRadius: 12,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: isSelected
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        size: 18,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    // ── Size experience ──
                                    if (sizes.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _SelectorLabel(
                                        label: context.tr('size'),
                                        value: null,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 9,
                                        runSpacing: 9,
                                        children: sizes.map((size) {
                                          final available =
                                              _sizeAvailable(product, size);
                                          final isSelected =
                                              selected?._sizeOf == size;
                                          return MarinaPressable(
                                            onTap: available
                                                ? () => setState(() {
                                                    final v = _variantFor(
                                                        product, size);
                                                    if (v != null) {
                                                      selectedVariantId = v.id;
                                                    }
                                                  })
                                                : () {},
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Opacity(
                                              opacity: available ? 1 : .38,
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 18,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? p.gold
                                                      : p.background,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? p.gold
                                                        : p.line,
                                                    width:
                                                        isSelected ? 1.4 : 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  size,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: isSelected
                                                        ? p.onGold
                                                        : p.ink,
                                                    decoration: available
                                                        ? null
                                                        : TextDecoration
                                                            .lineThrough,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    // ── Quantity ──
                                    if (selected != null &&
                                        selected.available) ...[
                                      const SizedBox(height: 24),
                                      _SelectorLabel(
                                        label: context.tr('quantity'),
                                        value: null,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: p.background,
                                          borderRadius:
                                              BorderRadius.circular(17),
                                          border: Border.all(color: p.line),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _StepButton(
                                              icon: Icons.remove_rounded,
                                              onTap: quantity > 1
                                                  ? () => setState(
                                                      () => quantity--)
                                                  : null,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 18),
                                              child: Text(
                                                quantity
                                                    .toString()
                                                    .padLeft(2, '0'),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  letterSpacing: 1,
                                                  color: p.ink,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures()
                                                  ],
                                                ),
                                              ),
                                            ),
                                            _StepButton(
                                              icon: Icons.add_rounded,
                                              onTap:
                                                  quantity <
                                                          (selected
                                                                  .availableQuantity)
                                                      ? () => setState(
                                                          () => quantity++)
                                                      : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: selected.availableQuantity <=
                                                      5
                                                  ? MarinaColors.danger
                                                  : MarinaColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            selected.availableQuantity <= 0
                                                ? context.tr('outOfStock')
                                                : selected.availableQuantity ==
                                                        1
                                                ? context.tr('lastPiece')
                                                : '${selected.availableQuantity} ${context.tr('piecesLeft')}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: p.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // ── Perks ──
                                    const SizedBox(height: 22),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _PerkChip(
                                            icon:
                                                Icons.local_shipping_outlined,
                                            label:
                                                context.tr('freeDelivery'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _PerkChip(
                                            icon:
                                                Icons.assignment_return_outlined,
                                            label: context.tr('easyReturns'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SettingsTile(
                              icon: Icons.reviews_outlined,
                              label: context.tr('reviews'),
                              route: '/product/${product.id}/reviews',
                            ),
                          ),
                          _CompleteTheLook(productId: product.id),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // ── Sticky purchase bar ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border(top: BorderSide(color: p.line)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (quantity > 1)
                                  Text(
                                    'x${quantity.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: p.gold,
                                    ),
                                  ),
                                MarinaPrice(
                                  value: selected == null
                                      ? 0
                                      : selected.price * quantity,
                                  large: true,
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: MarinaGoldButton(
                                label: selected == null || !selected.available
                                    ? context.tr('outOfStock')
                                    : context.tr('addToBag'),
                                icon: Icons.add_shopping_cart_rounded,
                                busy: adding,
                                onPressed: selected == null ||
                                        !selected.available ||
                                        adding
                                    ? null
                                    : () async {
                                  if (!await apiClient.hasSession()) {
                                    if (context.mounted) {
                                      context.push('/login');
                                    }
                                    return;
                                  }
                                  setState(() => adding = true);
                                  try {
                                    for (var i = 0; i < quantity; i++) {
                                      await ref
                                          .read(cartProvider.notifier)
                                          .add(selected.id);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text(context.tr('addToBag')),
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                  } finally {
                                    if (mounted) {
                                      setState(() => adding = false);
                                    }
                                  }
                                },
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
          ),
        );
      },
    );
  }
}

extension _VariantSizeLabel on ProductVariant {
  String? get _sizeOf => (size?.trim().isNotEmpty == true) ? size!.trim() : null;
}

class _SelectorLabel extends StatelessWidget {
  const _SelectorLabel({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: MarinaType.kicker(context, size: 10.5),
        ),
        if (value != null) ...[
          const SizedBox(width: 10),
          Text(
            value!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ],
      ],
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
    borderRadius: BorderRadius.circular(17),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Icon(
        icon,
        size: 17,
        color: onTap == null
            ? MarinaPalette.of(context).muted.withValues(alpha: .5)
            : MarinaPalette.of(context).gold,
      ),
    ),
  );
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: p.goldSoft.withValues(alpha: p.isDark ? .8 : .6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: p.gold.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 15, color: p.gold),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.isDark ? p.gold : p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.images});

  final List<String> images;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 420,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: MarinaColors.midnight),
        child: Icon(
          Icons.checkroom_rounded,
          size: 72,
          color: Colors.white24,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: (c.maxWidth * 1.08).clamp(420.0, 620.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (v) => setState(() => current = v),
              itemBuilder: (_, i) => ColoredBox(
                color: MarinaColors.midnight,
                child: MarinaNetworkImage(
                  url: widget.images[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 96,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.images.length,
                    (i) => AnimatedContainer(
                      duration: MarinaMotion.fast,
                      width: i == current ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == current
                            ? MarinaColors.goldBright
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!apiClient.isAuthenticated) {
      return MarinaIconButton(
        icon: Icons.favorite_border_rounded,
        dark: true,
        onTap: () => context.push('/login'),
      );
    }
    final culture = Localizations.localeOf(context).languageCode;
    final favorites = ref.watch(customerFavoritesProvider(culture));
    final saved = favorites.value?.any((x) => x.id == productId) ?? false;
    return MarinaIconButton(
      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      dark: true,
      onTap: favorites.isLoading
          ? () {}
          : () async {
              try {
                final repository = ref.read(customerRepositoryProvider);
                if (saved) {
                  await repository.removeFavorite(productId);
                } else {
                  await repository.addFavorite(productId);
                }
                ref.invalidate(customerFavoritesProvider(culture));
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
    );
  }
}

class _CompleteTheLook extends ConsumerWidget {
  const _CompleteTheLook({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = Localizations.localeOf(context).languageCode;
    final related = ref.watch(
      relatedProductsProvider((id: productId, culture: culture)),
    );
    final wide = MediaQuery.sizeOf(context).width;
    return related.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : FadeSlideIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: _pagePadding(wide)),
                      child: SectionHeading(
                        kicker: 'STYLE IT WITH',
                        title: context.tr('completeTheLook'),
                        route: '/products',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 294,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: _pagePadding(wide),
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => SizedBox(
                          width: wide >= 1000
                              ? 218
                              : wide >= 600
                              ? 196
                              : 170,
                          child: ProductCard(product: items[i]),
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

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, required this.productId, this.product});

  final String productId;
  final Product? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culture = Localizations.localeOf(context).languageCode;
    final details = ref.watch(
      productDetailsProvider((id: productId, culture: culture)),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: details.when(
        loading: () => const LoadingState(),
        error: (_, _) => product?.image == null
            ? const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 100,
                ),
              )
            : Center(
                child: InteractiveViewer(
                  child: MarinaNetworkImage(
                    url: product!.image!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
        data: (value) => value.images.isEmpty
            ? const Center(
                child: Icon(Icons.checkroom, color: Colors.white, size: 120),
              )
            : PageView.builder(
                itemCount: value.images.length,
                itemBuilder: (_, index) => InteractiveViewer(
                  child: Center(
                    child: MarinaNetworkImage(
                      url: value.images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
