// // lib/features/marketplace/presentation/screens/marketplace_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:reshare/core/constants/app_colors.dart';
// import 'package:reshare/data/models/product_model.dart';
// import 'package:reshare/presentation/widgets/prodect/ProductDetailScreen.dart';
// import 'package:reshare/presentation/widgets/prodect/add_product_screen.dart';
// import 'package:reshare/presentation/widgets/prodect/product_card.dart' show ProductCard;
// import 'package:reshare/presentation/widgets/prodect/sponsored_section.dart';

// import '../providers/marketplace_provider.dart';


// class MarketplaceScreen extends StatefulWidget {
//   const MarketplaceScreen({super.key});

//   @override
//   State<MarketplaceScreen> createState() => _MarketplaceScreenState();
// }

// class _MarketplaceScreenState extends State<MarketplaceScreen> {
//   final _scrollController = ScrollController();
//   final _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels ==
//         _scrollController.position.maxScrollExtent) {
//       // Charger plus de produits
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: _buildAppBar(),
//       body: Consumer<MarketplaceProvider>(
//         builder: (context, marketplaceProvider, child) {
//           return Column(
//             children: [
//               // Section Recherche et Filtres
//               _buildSearchSection(marketplaceProvider),
              
//               // Section Produits Sponsorisés
//               if (marketplaceProvider.sponsoredProducts.isNotEmpty)
//                 SponsoredSection(products: marketplaceProvider.sponsoredProducts),
              
//               // En-tête des produits
//               _buildProductsHeader(marketplaceProvider),
              
//               // Liste des produits
//               Expanded(
//                 child: _buildProductsList(marketplaceProvider),
//               ),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: _buildFloatingActionButton(),
//     );
//   }

//   AppBar _buildAppBar() {
//     return AppBar(
//       title: const Text(
//         'سوق ReShare',
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           fontFamily: 'Tajawal',
//         ),
//       ),
//       backgroundColor: Colors.white,
//       foregroundColor: AppColors.textPrimary,
//       elevation: 1,
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.filter_list_rounded),
//           onPressed: _showFilterDialog,
//           tooltip: 'تصفية المنتجات',
//         ),
//         IconButton(
//           icon: const Icon(Icons.category_rounded),
//           onPressed: _showCategoriesDialog,
//           tooltip: 'التصنيفات',
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchSection(MarketplaceProvider provider) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.white,
//       child: Column(
//         children: [
//           // Barre de recherche
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'ابحث عن منتج...',
//               prefixIcon: const Icon(Icons.search_rounded),
//               suffixIcon: IconButton(
//                 icon: const Icon(Icons.clear_rounded),
//                 onPressed: () {
//                   _searchController.clear();
//                   _performSearch('');
//                 },
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               filled: true,
//               fillColor: AppColors.background,
//             ),
//             onChanged: (value) => _performSearch(value),
//           ),
//           const SizedBox(height: 12),
          
//           // Filtres rapides
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _buildFilterChip('الكل', provider.selectedCategory == 'الكل', 
//                     () => _changeCategory('الكل', provider)),
//                 const SizedBox(width: 8),
//                 _buildFilterChip('CPC', provider.selectedType == ProductType.cpc, 
//                     () => _changeType(ProductType.cpc, provider)),
//                 const SizedBox(width: 8),
//                 _buildFilterChip('السوق', provider.selectedType == ProductType.marketplace, 
//                     () => _changeType(ProductType.marketplace, provider)),
//                 const SizedBox(width: 8),
//                 _buildFilterChip('ممول', provider.filter.sponsoredOnly, 
//                     () => _toggleSponsoredFilter(provider)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
//     return FilterChip(
//       label: Text(
//         label,
//         style: TextStyle(
//           color: selected ? Colors.white : AppColors.textPrimary,
//           fontFamily: 'Tajawal',
//         ),
//       ),
//       selected: selected,
//       onSelected: (_) => onTap(),
//       backgroundColor: Colors.white,
//       selectedColor: AppColors.primary,
//       checkmarkColor: Colors.white,
//       side: BorderSide(
//         color: selected ? AppColors.primary : AppColors.outline,
//       ),
//     );
//   }

//   Widget _buildProductsHeader(MarketplaceProvider provider) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       color: Colors.white,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '${provider.products.length} منتج',
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//           PopupMenuButton<ProductSort>(
//             onSelected: (sort) => _changeSort(sort, provider),
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: ProductSort.newest,
//                 child: Text('الأحدث'),
//               ),
//               const PopupMenuItem(
//                 value: ProductSort.priceLow,
//                 child: Text('الأقل سعراً'),
//               ),
//               const PopupMenuItem(
//                 value: ProductSort.priceHigh,
//                 child: Text('الأعلى سعراً'),
//               ),
//               const PopupMenuItem(
//                 value: ProductSort.mostViewed,
//                 child: Text('الأكثر مشاهدة'),
//               ),
//             ],
//             child: Row(
//               children: [
//                 Text(
//                   _getSortText(provider.filter.sortBy),
//                   style: TextStyle(
//                     color: AppColors.textSecondary,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//                 const Icon(Icons.arrow_drop_down_rounded),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductsList(MarketplaceProvider provider) {
//     if (provider.isLoading && provider.products.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (provider.products.isEmpty) {
//       return _buildEmptyState(provider);
//     }

//     return RefreshIndicator(
//       onRefresh: () => provider.refreshMarketplace(),
//       child: ListView.builder(
//         controller: _scrollController,
//         padding: const EdgeInsets.all(16),
//         itemCount: provider.products.length,
//         itemBuilder: (context, index) {
//           final product = provider.products[index];
//           return Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             child: ProductCard(
//               product: product,
//               onTap: () => _navigateToProductDetail(product),
//               onShare: () => provider.shareProduct(product),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState(MarketplaceProvider provider) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.shopping_bag_rounded,
//             size: 80,
//             color: AppColors.textSecondary.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'لا توجد منتجات متاحة',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             provider.selectedType == ProductType.cpc 
//                 ? 'سيظهر هنا المنتجات التي يمكنك الربح من مشاركتها'
//                 : 'سيظهر هنا المنتجات المتاحة للشراء المباشر',
//             style: TextStyle(
//               color: AppColors.textSecondary,
//               fontFamily: 'Tajawal',
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () => provider.refreshMarketplace(),
//             child: const Text('تحديث', style: TextStyle(fontFamily: 'Tajawal')),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFloatingActionButton() {
//     return FloatingActionButton(
//       onPressed: _navigateToAddProduct,
//       backgroundColor: AppColors.primary,
//       foregroundColor: Colors.white,
//       child: const Icon(Icons.add_rounded),
//     );
//   }

//   // Méthodes d'interaction
//   void _performSearch(String query) {
//     final provider = Provider.of<MarketplaceProvider>(context, listen: false);
//     // Implémenter la recherche
//   }

//   void _changeCategory(String category, MarketplaceProvider provider) {
//     provider.changeCategory(category);
//   }

//   void _changeType(ProductType type, MarketplaceProvider provider) {
//     provider.changeType(type);
//   }

//   void _toggleSponsoredFilter(MarketplaceProvider provider) {
//     final newFilter = provider.filter.copyWith(
//       sponsoredOnly: !provider.filter.sponsoredOnly,
//     );
//     provider.filterProducts(newFilter);
//   }

//   void _changeSort(ProductSort sort, MarketplaceProvider provider) {
//     final newFilter = provider.filter.copyWith(sortBy: sort);
//     provider.filterProducts(newFilter);
//   }

//   void _navigateToProductDetail(ProductModel product) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ProductDetailScreen(product: product),
//       ),
//     );
//   }

//   void _navigateToAddProduct() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AddProductScreen(),
//       ),
//     );
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => const FilterDialog(),
//     );
//   }

//   void _showCategoriesDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => const CategoriesDialog(),
//     );
//   }

//   String _getSortText(ProductSort sort) {
//     switch (sort) {
//       case ProductSort.newest:
//         return 'الأحدث';
//       case ProductSort.priceLow:
//         return 'الأقل سعراً';
//       case ProductSort.priceHigh:
//         return 'الأعلى سعراً';
//       case ProductSort.mostViewed:
//         return 'الأكثر مشاهدة';
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
// }

// // Dialog de filtres avancés
// class FilterDialog extends StatefulWidget {
//   const FilterDialog({super.key});

//   @override
//   State<FilterDialog> createState() => _FilterDialogState();
// }

// class _FilterDialogState extends State<FilterDialog> {
//   double _minPrice = 0;
//   double _maxPrice = 1000;
//   bool _sponsoredOnly = false;

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<MarketplaceProvider>(context, listen: false);

//     return AlertDialog(
//       title: const Text('تصفية المنتجات', style: TextStyle(fontFamily: 'Tajawal')),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Prix minimum
//           ListTile(
//             leading: const Icon(Icons.attach_money_rounded),
//             title: Text('الحد الأدنى للسعر: ${_minPrice.toInt()} د', 
//                 style: const TextStyle(fontFamily: 'Tajawal')),
//             subtitle: Slider(
//               value: _minPrice,
//               min: 0,
//               max: 500,
//               onChanged: (value) => setState(() => _minPrice = value),
//             ),
//           ),
          
//           // Prix maximum
//           ListTile(
//             leading: const Icon(Icons.attach_money_rounded),
//             title: Text('الحد الأقصى للسعر: ${_maxPrice.toInt()} د', 
//                 style: const TextStyle(fontFamily: 'Tajawal')),
//             subtitle: Slider(
//               value: _maxPrice,
//               min: 0,
//               max: 1000,
//               onChanged: (value) => setState(() => _maxPrice = value),
//             ),
//           ),
          
//           // Produits sponsorisés seulement
//           SwitchListTile(
//             title: const Text('المنتجات الممولة فقط', style: TextStyle(fontFamily: 'Tajawal')),
//             value: _sponsoredOnly,
//             onChanged: (value) => setState(() => _sponsoredOnly = value),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             final newFilter = provider.filter.copyWith(
//               minPrice: _minPrice,
//               maxPrice: _maxPrice,
//               sponsoredOnly: _sponsoredOnly,
//             );
//             provider.filterProducts(newFilter);
//             Navigator.pop(context);
//           },
//           child: const Text('تطبيق', style: TextStyle(fontFamily: 'Tajawal')),
//         ),
//       ],
//     );
//   }
// }

// // Dialog des catégories
// class CategoriesDialog extends StatelessWidget {
//   const CategoriesDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<MarketplaceProvider>(context, listen: false);
//     final categories = [
//       'الكل', 'الإلكترونيات', 'الملابس والأزياء', 'المنزل والحديقة',
//       'الجمال والعناية', 'الرياضة والترفيه', 'السيارات', 'الكتب والتعليم',
//       'الأغذية', 'الصحة', 'الأطفال', 'الهدايا', 'أخرى'
//     ];

//     return AlertDialog(
//       title: const Text('التصنيفات', style: TextStyle(fontFamily: 'Tajawal')),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: categories.length,
//           itemBuilder: (context, index) {
//             final category = categories[index];
//             return ListTile(
//               title: Text(category, style: const TextStyle(fontFamily: 'Tajawal')),
//               trailing: provider.selectedCategory == category 
//                   ? const Icon(Icons.check_rounded, color: AppColors.primary)
//                   : null,
//               onTap: () {
//                 provider.changeCategory(category);
//                 Navigator.pop(context);
//               },
//             );
//           },
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
//         ),
//       ],
//     );
//   }
// }