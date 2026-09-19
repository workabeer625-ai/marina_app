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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(catalogHomeProvider(culture).future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: MarinaGradients.header(
                      dark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(34),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
                        child: Column(
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
                            const SizedBox(height: 24),
                            Material(
                              color: Colors.white.withValues(alpha: .07),
                              borderRadius: BorderRadius.circular(19),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(19),
                                onTap: () => context.push('/search'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(19),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        color: MarinaColors.goldBright,
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Text(
                                          context.tr('search'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFFB7C9DB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: _pagePadding(MediaQuery.sizeOf(context).width),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    home.when(
                      loading: () =>
                          const SizedBox(height: 520, child: LoadingState()),
                      error: (e, _) => SizedBox(
                        height: 360,
                        child: ErrorState(
                          message: apiFailureMessage(e, context.tr('retry')),
                          onRetry: () =>
                              ref.invalidate(catalogHomeProvider(culture)),
                        ),
                      ),
                      data: (data) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Hero(data: data),
                          const SizedBox(height: 30),
                          SectionHeading(
                            title: context.tr('categories'),
                            route: '/categories',
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 102,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final category = data.categories[i];
                                return _CategoryChip(
                                  label: category.name,
                                  onTap: () => context.push(
                                    '/products?category=${category.id}',
                                  ),
                                  index: i,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ProductRail(
                            title: context.tr('new'),
                            route: '/new-arrivals',
                            items: data.products,
                          ),
                          const SizedBox(height: 28),
                          _ProductRail(
                            title: context.tr('offers'),
                            route: '/offers',
                            items: data.products.reversed.toList(),
                          ),
                          const SizedBox(height: 28),
                          _ProductRail(
                            title: context.tr('bestSellers'),
                            route: '/products',
                            items: data.products.skip(2).toList(),
                          ),
                          const SizedBox(height: 28),
                          _ProductRail(
                            title: context.tr('recommended'),
                            route: '/products',
                            items: data.products.skip(4).toList(),
                          ),
                          const SizedBox(height: 122),
                        ],
                      ),
                    ),
                  ]),
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

double _pagePadding(double width) => width >= 1200
    ? 48
    : width >= 768
    ? 32
    : 16;

/// Day / night switch for the home header.
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.onTap,
    required this.index,
  });

  final String label;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = MarinaPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 78,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: p.isDark ? p.surfaceSoft : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.gold.withValues(alpha: .35)),
                  boxShadow: p.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: MarinaColors.goldDeep.withValues(alpha: .1),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Icon(
                  marinaCategoryIcon(label, fallbackIndex: index),
                  color: p.gold,
                  size: 25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.title,
    required this.route,
    required this.items,
  });

  final String title, route;
  final List<Product> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SectionHeading(title: title, route: route),
      const SizedBox(height: 14),
      if (items.isEmpty)
        const SizedBox(height: 180, child: EmptyState())
      else
        LayoutBuilder(
          builder: (context, c) {
            final cardWidth = c.maxWidth >= 1000
                ? 216.0
                : c.maxWidth >= 600
                ? 194.0
                : 166.0;
            return SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.take(12).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: cardWidth,
                  child: ProductCard(product: items[i]),
                ),
              ),
            );
          },
        ),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data});

  final CatalogHome data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final desktop = c.maxWidth >= 700;
        return Container(
          height: desktop ? 370 : 310,
          decoration: BoxDecoration(
            color: MarinaColors.midnight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: MarinaColors.gold.withValues(alpha: .25)),
            boxShadow: [
              BoxShadow(
                color: MarinaColors.midnight.withValues(alpha: .35),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/visuals/home-hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: desktop
                          ? const [
                              Color(0xFF0A111E),
                              Color(0xE10A111E),
                              Color(0x330A111E),
                            ]
                          : const [
                              Color(0xF70A111E),
                              Color(0x8C0A111E),
                              Color(0x2E0A111E),
                            ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: desktop ? 38 : 24,
                end: desktop ? c.maxWidth * .52 : 24,
                top: 24,
                bottom: 24,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MARINA',
                      style: TextStyle(
                        color: MarinaColors.goldBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing:
                            MarinaType.isArabic(context) ? 0 : 4.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MarinaType.display(
                        context,
                        size: desktop ? 36 : 28,
                        color: Colors.white,
                      ),
                    ),
                    if (data.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC2D0DF),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    MarinaGoldButton(
                      label: context.tr('shop'),
                      icon: Icons.arrow_outward_rounded,
                      height: 50,
                      onPressed: () => context.push('/products'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, required this.route});

  final String title, route;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 18,
          margin: const EdgeInsetsDirectional.only(end: 10),
          decoration: BoxDecoration(
            gradient: MarinaGradients.gold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
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
          .watch(brandsProvider(Localizations.localeOf(context).languageCode))
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
                      padding: const EdgeInsets.all(18),
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
                  padding: const EdgeInsets.all(18),
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
                    return Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            context.push('/products?brand=${brand.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: MarinaPalette.of(context)
                                  .line
                                  .withValues(alpha: .9),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: MarinaPalette.of(context).goldSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 17,
                                  color: MarinaPalette.of(context).gold,
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
                                    color: MarinaPalette.of(context).ink,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: MarinaPalette.of(context).muted,
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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 122),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = MarinaPalette.of(context);
                    return Material(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            context.push('/products?category=${items[i].id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: p.line.withValues(alpha: .9),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: p.goldSoft,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: p.gold.withValues(alpha: .25),
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

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id, this.product});

  final String id;
  final Product? product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<ProductDetailScreen> {
  String? selectedVariantId;
  bool adding = false;

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
        final available = product.variants.where((x) => x.available).toList();
        final selected =
            available.where((x) => x.id == selectedVariantId).firstOrNull ??
            available.firstOrNull;
        final p = MarinaPalette.of(context);
        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        children: [
                          Stack(
                            children: [
                              _ProductGallery(images: product.images),
                              PositionedDirectional(
                                top: 10,
                                start: 10,
                                child: MarinaIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  dark: true,
                                  onTap: () => context.pop(),
                                ),
                              ),
                              PositionedDirectional(
                                top: 10,
                                end: 10,
                                child: _FavoriteButton(productId: product.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          MarinaSectionCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                if (selected != null) ...[
                                  const SizedBox(height: 10),
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
                                      height: 1.6,
                                      fontSize: 14,
                                      color: p.muted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                Text(
                                  context.tr('chooseVariant').toUpperCase(),
                                  style: MarinaType.kicker(context),
                                ),
                                const SizedBox(height: 12),
                                if (product.variants.isEmpty)
                                  Text(context.tr('outOfStock'))
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        product.variants.map((variant) {
                                      final colorHex = int.tryParse(
                                        'FF${variant.colorHex?.replaceAll('#', '') ?? ''}',
                                        radix: 16,
                                      );
                                      final swatch = (colorHex != null &&
                                              variant.colorHex?.isNotEmpty ==
                                                  true)
                                          ? Color(colorHex)
                                          : null;
                                      final label = [
                                        variant.color,
                                        variant.size,
                                      ]
                                          .whereType<String>()
                                          .where((x) => x.isNotEmpty)
                                          .join(' • ');
                                      final isSelected =
                                          selected?.id == variant.id;
                                      return ChoiceChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (swatch != null) ...[
                                              Container(
                                                width: 13,
                                                height: 13,
                                                decoration: BoxDecoration(
                                                  color: swatch,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: p.line,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                            ],
                                            Text(label.isEmpty
                                                ? variant.sku
                                                : label),
                                          ],
                                        ),
                                        selected: isSelected,
                                        onSelected: variant.available
                                            ? (_) => setState(
                                                () => selectedVariantId =
                                                    variant.id,
                                              )
                                            : null,
                                        showCheckmark: false,
                                        labelPadding:
                                            const EdgeInsetsDirectional.only(
                                          start: 12,
                                          end: 14,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SettingsTile(
                            icon: Icons.reviews_outlined,
                            label: context.tr('reviews'),
                            route: '/product/${product.id}/reviews',
                          ),
                          _RelatedProducts(
                            productId: product.id,
                            culture: culture,
                          ),
                        ],
                      ),
                    ),
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
                            if (selected != null) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MarinaPrice(value: selected.price, large: true),
                                ],
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: MarinaGoldButton(
                                label: selected == null
                                    ? context.tr('outOfStock')
                                    : context.tr('addToBag'),
                                icon: Icons.add_shopping_cart_rounded,
                                busy: adding,
                                onPressed:
                                    selected == null || adding ? null : () async {
                                  if (!await apiClient.hasSession()) {
                                    if (context.mounted) context.push('/login');
                                    return;
                                  }
                                  setState(() => adding = true);
                                  try {
                                    await ref
                                        .read(cartProvider.notifier)
                                        .add(selected.id);
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
                                    if (mounted) setState(() => adding = false);
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
    final p = MarinaPalette.of(context);
    if (widget.images.isEmpty) {
      return Container(
        height: 390,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.line),
        ),
        child: Icon(
          Icons.checkroom_rounded,
          size: 72,
          color: p.muted.withValues(alpha: .5),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: (c.maxWidth * .92).clamp(330.0, 520.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (v) => setState(() => current = v),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ColoredBox(
                  color: p.isDark ? p.surfaceSoft : MarinaColors.sand,
                  child: MarinaNetworkImage(
                    url: widget.images[i],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: MarinaColors.midnight.withValues(alpha: .8),
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

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.productId, required this.culture});

  final String productId, culture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(
      relatedProductsProvider((id: productId, culture: culture)),
    );
    return related.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 18,
                      margin: const EdgeInsetsDirectional.only(end: 10),
                      decoration: BoxDecoration(
                        gradient: MarinaGradients.gold,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.tr('related'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 296,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: 176,
                      child: ProductCard(product: items[i]),
                    ),
                  ),
                ),
              ],
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
