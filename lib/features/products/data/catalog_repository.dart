import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/product.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
  });
  final String id, name, slug;
  final String? parentId;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
        parentId: json['parentId']?.toString(),
      );
}

class CatalogBrand {
  const CatalogBrand({
    required this.id,
    required this.name,
    required this.slug,
  });
  final String id, name, slug;

  factory CatalogBrand.fromJson(Map<String, dynamic> json) => CatalogBrand(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    slug: (json['slug'] ?? '').toString(),
  );
}

class CatalogOption {
  const CatalogOption({required this.code, required this.name});
  final String code, name;

  factory CatalogOption.fromJson(Map<String, dynamic> json) => CatalogOption(
    code: (json['code'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
  );
}

class CatalogFilters {
  const CatalogFilters({
    required this.brands,
    required this.colors,
    required this.sizes,
  });
  final List<CatalogBrand> brands;
  final List<CatalogOption> colors, sizes;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.price,
    required this.available,
    required this.availableQuantity,
    this.compareAtPrice,
    this.color,
    this.colorHex,
    this.size,
  });
  final String id, sku;
  final String? color, colorHex, size;
  final double price;
  final double? compareAtPrice;
  final bool available;
  final int availableQuantity;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'].toString(),
    sku: (json['sku'] ?? '').toString(),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
    color: json['color']?.toString(),
    colorHex: json['colorHex']?.toString(),
    size: json['size']?.toString(),
    available: json['available'] == true,
    availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
  );
}

class ProductDetails {
  const ProductDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.variants,
  });
  final String id, name, description;
  final List<String> images;
  final List<ProductVariant> variants;

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
    id: json['id'].toString(),
    name: (json['name'] ?? '').toString(),
    description: (json['description'] ?? '')
        .toString()
        .replaceAll('; fictional MARINA development data.', '.')
        .replaceAll(' ضمن بيانات مارينا التجريبية.', '.'),
    images: (json['images'] as List? ?? const [])
        .map((x) => (x as Map<String, dynamic>)['url']?.toString() ?? '')
        .where((x) => x.isNotEmpty)
        .toList(),
    variants: (json['variants'] as List? ?? const [])
        .map((x) => ProductVariant.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

class CatalogHome {
  const CatalogHome({
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.products,
  });
  final String title, subtitle;
  final List<CatalogCategory> categories;
  final List<Product> products;

  factory CatalogHome.fromJson(Map<String, dynamic> json) {
    final hero = json['hero'] as Map<String, dynamic>? ?? const {};
    return CatalogHome(
      title: (hero['title'] ?? '').toString(),
      subtitle: (hero['subtitle'] ?? '').toString(),
      categories: (json['categories'] as List? ?? const [])
          .map((x) => CatalogCategory.fromJson(x as Map<String, dynamic>))
          .toList(),
      products: (json['products'] as List? ?? const [])
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}

typedef CatalogQuery = ({
  String culture,
  String? search,
  String? categoryId,
  String? brandId,
  String? color,
  String? size,
  double? minPrice,
  double? maxPrice,
  bool offers,
  bool newArrivals,
  String sort,
});

class CatalogRepository {
  CatalogRepository(this.client);
  final ApiClient client;

  Future<List<Product>> products(CatalogQuery query) async {
    final items = <Product>[];
    var page = 1;
    var totalPages = 1;
    do {
      final response = await client.dio.get(
        '/catalog/products',
        queryParameters: {
          'culture': query.culture,
          if (query.search?.trim().isNotEmpty == true)
            'search': query.search!.trim(),
          if (query.categoryId != null) 'categoryId': query.categoryId,
          if (query.brandId != null) 'brandId': query.brandId,
          if (query.color != null) 'color': query.color,
          if (query.size != null) 'size': query.size,
          if (query.minPrice != null) 'minPrice': query.minPrice,
          if (query.maxPrice != null) 'maxPrice': query.maxPrice,
          if (query.offers) 'offers': true,
          if (query.newArrivals) 'newArrivals': true,
          'sort': query.sort,
          'page': page,
          'pageSize': 50,
        },
      );
      final data = response.data as Map<String, dynamic>;
      items.addAll(
        (data['items'] as List? ?? const []).map(
          (x) => Product.fromJson(x as Map<String, dynamic>),
        ),
      );
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      page++;
    } while (page <= totalPages);
    return items;
  }

  Future<CatalogHome> home(String culture) async => CatalogHome.fromJson(
    (await client.dio.get(
          '/catalog/home',
          queryParameters: {'culture': culture},
        )).data
        as Map<String, dynamic>,
  );

  Future<List<CatalogCategory>> categories(String culture) async =>
      ((await client.dio.get(
                '/catalog/categories',
                queryParameters: {'culture': culture},
              )).data
              as List)
          .map((x) => CatalogCategory.fromJson(x as Map<String, dynamic>))
          .toList();

  Future<ProductDetails> details(String id, String culture) async =>
      ProductDetails.fromJson(
        (await client.dio.get(
              '/catalog/products/$id',
              queryParameters: {'culture': culture},
            )).data
            as Map<String, dynamic>,
      );

  Future<List<Product>> related(String id, String culture) async =>
      ((await client.dio.get(
                '/catalog/products/$id/related',
                queryParameters: {'culture': culture},
              )).data
              as List)
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList();

  Future<List<CatalogBrand>> brands(String culture) async =>
      ((await client.dio.get(
                '/catalog/brands',
                queryParameters: {'culture': culture},
              )).data
              as List)
          .map((x) => CatalogBrand.fromJson(x as Map<String, dynamic>))
          .toList();

  Future<CatalogFilters> filters(String culture) async {
    final responses = await Future.wait([
      client.dio.get('/catalog/brands', queryParameters: {'culture': culture}),
      client.dio.get('/catalog/options', queryParameters: {'culture': culture}),
    ]);
    final options = responses.last.data as Map<String, dynamic>;
    return CatalogFilters(
      brands: (responses.first.data as List)
          .map((x) => CatalogBrand.fromJson(x as Map<String, dynamic>))
          .toList(),
      colors: (options['colors'] as List? ?? const [])
          .map((x) => CatalogOption.fromJson(x as Map<String, dynamic>))
          .toList(),
      sizes: (options['sizes'] as List? ?? const [])
          .map((x) => CatalogOption.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}

final catalogRepositoryProvider = Provider((_) => CatalogRepository(apiClient));
final catalogHomeProvider = FutureProvider.family<CatalogHome, String>(
  (ref, culture) => ref.watch(catalogRepositoryProvider).home(culture),
);
final categoriesProvider = FutureProvider.family<List<CatalogCategory>, String>(
  (ref, culture) => ref.watch(catalogRepositoryProvider).categories(culture),
);
final brandsProvider = FutureProvider.family<List<CatalogBrand>, String>(
  (ref, culture) => ref.watch(catalogRepositoryProvider).brands(culture),
);
final catalogFiltersProvider = FutureProvider.family<CatalogFilters, String>(
  (ref, culture) => ref.watch(catalogRepositoryProvider).filters(culture),
);
final productListProvider = FutureProvider.family<List<Product>, CatalogQuery>(
  (ref, query) => ref.watch(catalogRepositoryProvider).products(query),
);
final productDetailsProvider =
    FutureProvider.family<ProductDetails, ({String id, String culture})>(
      (ref, value) =>
          ref.watch(catalogRepositoryProvider).details(value.id, value.culture),
    );
final relatedProductsProvider =
    FutureProvider.family<List<Product>, ({String id, String culture})>(
      (ref, value) =>
          ref.watch(catalogRepositoryProvider).related(value.id, value.culture),
    );
