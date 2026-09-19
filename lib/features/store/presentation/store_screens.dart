import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
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
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(catalogHomeProvider(culture).future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MarinaColors.navy, MarinaColors.midnight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
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
                                _HeaderAction(
                                  icon: Icons.notifications_none_rounded,
                                  onTap: () => context.push('/notifications'),
                                ),
                                _HeaderAction(
                                  icon: Icons.shopping_bag_outlined,
                                  onTap: () => context.push('/cart'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Material(
                              color: Colors.white.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(17),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(17),
                                onTap: () => context.push('/search'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF8CB6DF),
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
                    const SizedBox(height: 18),
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
                          const SizedBox(height: 28),
                          SectionHeading(
                            title: context.tr('categories'),
                            route: '/categories',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 98,
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
                          const SizedBox(height: 26),
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
                            title: culture == 'ar'
                                ? 'الأكثر مبيعاً'
                                : 'Best sellers',
                            route: '/products',
                            items: data.products.skip(2).toList(),
                          ),
                          const SizedBox(height: 28),
                          _ProductRail(
                            title: culture == 'ar'
                                ? 'مختارات لك'
                                : 'Recommended',
                            route: '/products',
                            items: data.products.skip(4).toList(),
                          ),
                          const SizedBox(height: 34),
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
    );
  }
}

double _pagePadding(double width) => width >= 1200
    ? 48
    : width >= 768
    ? 32
    : 16;

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .09),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon, size: 21),
    ),
  );
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
    const icons = [
      Icons.checkroom_outlined,
      Icons.dry_cleaning_outlined,
      Icons.hiking_outlined,
      Icons.watch_outlined,
      Icons.child_friendly_outlined,
    ];
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 76,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: MarinaColors.navy.withValues(alpha: .06),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(
                  icons[index % icons.length],
                  color: MarinaColors.royal,
                  size: 25,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
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
      const SizedBox(height: 12),
      if (items.isEmpty)
        const SizedBox(height: 180, child: EmptyState())
      else
        LayoutBuilder(
          builder: (context, c) {
            final cardWidth = c.maxWidth >= 1000
                ? 210.0
                : c.maxWidth >= 600
                ? 190.0
                : 164.0;
            return SizedBox(
              height: 285,
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
          height: desktop ? 360 : 300,
          decoration: BoxDecoration(
            color: MarinaColors.midnight,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: MarinaColors.deepRoyal.withValues(alpha: .18),
                blurRadius: 30,
                offset: const Offset(0, 14),
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
                          ? [
                              MarinaColors.navy,
                              MarinaColors.navy.withValues(alpha: .88),
                              Colors.transparent,
                            ]
                          : [
                              MarinaColors.navy.withValues(alpha: .97),
                              MarinaColors.navy.withValues(alpha: .55),
                              MarinaColors.navy.withValues(alpha: .18),
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
                    Container(width: 34, height: 3, color: MarinaColors.royal),
                    const SizedBox(height: 15),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: desktop ? 36 : 29,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
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
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => context.push('/products'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(context.tr('shop')),
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: () => context.push(route),
        child: Text(
          context.tr('viewAll'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
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
    return MarinaPage(
      title: context.tr(widget.titleKey),
      actions: [
        PopupMenuButton<String>(
          initialValue: sort,
          icon: const Icon(Icons.sort),
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
            child: const Icon(Icons.tune),
          ),
        ),
      ],
      child: data.when(
        data: (items) => items.isEmpty
            ? const EmptyState(icon: Icons.search_off)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(productListProvider(query).future),
                child: GridView.builder(
                  padding: const EdgeInsets.all(18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .62,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(product: items[i]),
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
            24,
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
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
                const SizedBox(height: 18),
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
                    FilledButton(
                      onPressed: () => context.pop(true),
                      child: Text(context.tr('apply')),
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: MarinaTheme.sand,
                      child: Icon(Icons.storefront_outlined),
                    ),
                    title: Text(items[index].name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/products?brand=${items[index].id}'),
                  ),
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
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: const CircleAvatar(
                      radius: 28,
                      backgroundColor: MarinaTheme.sand,
                      child: Icon(Icons.checkroom),
                    ),
                    title: Text(
                      items[i].name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/products?category=${items[i].id}'),
                  ),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: TextField(
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => setState(() => query = value.trim()),
        decoration: InputDecoration(
          hintText: context.tr('search'),
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    ),
    body: query.isEmpty
        ? EmptyState(
            icon: Icons.manage_search,
            message: context.tr('searchPrompt'),
          )
        : CatalogScreen(titleKey: 'search', search: query),
  );
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
        return Scaffold(
          backgroundColor: MarinaColors.nearWhite,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              _FavoriteButton(productId: product.id),
                            ],
                          ),
                          _ProductGallery(images: product.images),
                          const SizedBox(height: 18),
                          MarinaSectionCard(
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
                                  const SizedBox(height: 8),
                                  MarinaPrice(
                                    value: selected.price,
                                    large: true,
                                  ),
                                ],
                                if (product.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    product.description,
                                    style: const TextStyle(
                                      height: 1.55,
                                      color: MarinaColors.muted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                Text(
                                  context.tr('chooseVariant'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: MarinaColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (product.variants.isEmpty)
                                  Text(context.tr('outOfStock'))
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: product.variants.map((variant) {
                                      final label =
                                          [variant.color, variant.size]
                                              .whereType<String>()
                                              .where((x) => x.isNotEmpty)
                                              .join(' • ');
                                      return ChoiceChip(
                                        label: Text(
                                          label.isEmpty ? variant.sku : label,
                                        ),
                                        selected: selected?.id == variant.id,
                                        selectedColor: MarinaColors.royal,
                                        backgroundColor: MarinaColors.nearWhite,
                                        labelStyle: TextStyle(
                                          color: selected?.id == variant.id
                                              ? Colors.white
                                              : MarinaColors.navy,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        side: BorderSide(
                                          color: selected?.id == variant.id
                                              ? MarinaColors.royal
                                              : MarinaColors.line,
                                        ),
                                        onSelected: variant.available
                                            ? (_) => setState(
                                                () => selectedVariantId =
                                                    variant.id,
                                              )
                                            : null,
                                        showCheckmark: false,
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
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: MarinaTheme.line),
                        ),
                      ),
                      child: FilledButton(
                        onPressed: selected == null || adding
                            ? null
                            : () async {
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.tr('addToBag')),
                                      ),
                                    );
                                  }
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
                                } finally {
                                  if (mounted) setState(() => adding = false);
                                }
                              },
                        child: adding
                            ? const CircularProgressIndicator()
                            : Text(
                                selected == null
                                    ? context.tr('outOfStock')
                                    : '${context.tr('addToBag')} • SAR ${selected.price.toStringAsFixed(2)}',
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
    if (widget.images.isEmpty) {
      return Container(
        height: 390,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.image_outlined,
          size: 72,
          color: MarinaColors.deepRoyal,
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
                  color: Colors.white,
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
                    color: MarinaColors.navy.withValues(alpha: .78),
                    borderRadius: BorderRadius.circular(20),
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
                              ? MarinaColors.royal
                              : Colors.white54,
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
      return IconButton(
        onPressed: () => context.push('/login'),
        icon: const Icon(Icons.favorite_border),
      );
    }
    final culture = Localizations.localeOf(context).languageCode;
    final favorites = ref.watch(customerFavoritesProvider(culture));
    final saved = favorites.value?.any((x) => x.id == productId) ?? false;
    return IconButton(
      onPressed: favorites.isLoading
          ? null
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
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
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
                const SizedBox(height: 22),
                Text(
                  context.tr('related'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: 170,
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
