// // lib/features/marketplace/presentation/screens/product_detail_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';
// import 'package:reshare/features/auth/presentation/providers/marketplace_provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import '../../../../core/constants/app_colors.dart';
// import '../../../../data/models/product_model.dart';
// import '../../../../data/models/user_model.dart';


// class ProductDetailScreen extends StatefulWidget {
//   final ProductModel product;

//   const ProductDetailScreen({super.key, required this.product});

//   @override
//   State<ProductDetailScreen> createState() => _ProductDetailScreenState();
// }

// class _ProductDetailScreenState extends State<ProductDetailScreen> {
//   final PageController _imageController = PageController();
//   int _currentImageIndex = 0;
//   bool _isExpanded = false;

//   @override
//   Widget build(BuildContext context) {
//     final marketplaceProvider = Provider.of<MarketplaceProvider>(context);
//     final authProvider = Provider.of<AuthProvider>(context);
//     final isSeller = authProvider.user?.id == widget.product.sellerId;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: _buildAppBar(marketplaceProvider),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Galerie d'images
//             _buildImageGallery(),
            
//             // Informations du produit
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // En-tête avec titre et prix
//                   _buildProductHeader(),
//                   const SizedBox(height: 16),
                  
//                   // Badges et statuts
//                   _buildProductBadges(),
//                   const SizedBox(height: 16),
                  
//                   // Description
//                   _buildProductDescription(),
//                   const SizedBox(height: 20),
                  
//                   // Statistiques
//                   _buildProductStats(),
//                   const SizedBox(height: 20),
                  
//                   // Informations vendeur
//                   _buildSellerInfo(),
//                   const SizedBox(height: 20),
                  
//                   // Actions selon le type d'utilisateur
//                   if (isSeller) 
//                     _buildSellerActions(marketplaceProvider)
//                   else 
//                     _buildBuyerActions(marketplaceProvider, authProvider),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: !isSeller ? _buildBottomBar(marketplaceProvider) : null,
//     );
//   }

//   AppBar _buildAppBar(MarketplaceProvider provider) {
//     return AppBar(
//       title: const Text(
//         'تفاصيل المنتج',
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           fontFamily: 'Tajawal',
//         ),
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.share_rounded),
//           onPressed: () => provider.shareProduct(widget.product),
//           tooltip: 'مشاركة المنتج',
//         ),
//         IconButton(
//           icon: const Icon(Icons.favorite_border_rounded),
//           onPressed: () => _toggleFavorite(),
//           tooltip: 'إضافة إلى المفضلة',
//         ),
//       ],
//     );
//   }

//   Widget _buildImageGallery() {
//     final hasImages = widget.product.images.isNotEmpty;
//     final images = hasImages ? widget.product.images : [''];

//     return Stack(
//       children: [
//         // PageView des images
//         SizedBox(
//           height: 300,
//           child: PageView.builder(
//             controller: _imageController,
//             itemCount: images.length,
//             onPageChanged: (index) => setState(() => _currentImageIndex = index),
//             itemBuilder: (context, index) {
//               return Container(
//                 color: AppColors.background,
//                 child: hasImages 
//                     ? _buildOptimizedImage(images[index])
//                     : _buildPlaceholderImage(),
//               );
//             },
//           ),
//         ),
        
//         // Indicateur d'images
//         if (images.length > 1)
//           Positioned(
//             bottom: 16,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(images.length, (index) {
//                 return Container(
//                   width: 8,
//                   height: 8,
//                   margin: const EdgeInsets.symmetric(horizontal: 4),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _currentImageIndex == index 
//                         ? AppColors.primary 
//                         : Colors.white.withOpacity(0.6),
//                   ),
//                 );
//               }),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildOptimizedImage(String imageUrl) {
//     if (kIsWeb) {
//       return Image.network(
//         imageUrl,
//         fit: BoxFit.cover,
//         loadingBuilder: (context, child, loadingProgress) {
//           if (loadingProgress == null) return child;
//           return Center(
//             child: CircularProgressIndicator(
//               value: loadingProgress.expectedTotalBytes != null
//                   ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                   : null,
//             ),
//           );
//         },
//         errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
//       );
//     } else {
//       return CachedNetworkImage(
//         imageUrl: imageUrl,
//         fit: BoxFit.cover,
//         placeholder: (context, url) => _buildPlaceholderImage(),
//         errorWidget: (context, url, error) => _buildPlaceholderImage(),
//       );
//     }
//   }

//   Widget _buildPlaceholderImage() {
//     return Container(
//       color: AppColors.background,
//       child: const Icon(
//         Icons.shopping_bag_rounded,
//         color: AppColors.textSecondary,
//         size: 64,
//       ),
//     );
//   }

//   Widget _buildProductHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: Text(
//                 widget.product.title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'Tajawal',
//                 ),
//               ),
//             ),
//             if (widget.product.isSponsored) 
//               _buildSponsoredBadge(),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Text(
//           '${widget.product.price} دينار',
//           style: const TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: AppColors.primary,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSponsoredBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppColors.primary, AppColors.secondary],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: const Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.star_rounded, size: 16, color: Colors.white),
//           SizedBox(width: 4),
//           Text(
//             'ممول',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductBadges() {
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: [
//         // Type de produit
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: _getTypeColor().withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: _getTypeColor()),
//           ),
//           child: Text(
//             _getTypeText(),
//             style: TextStyle(
//               color: _getTypeColor(),
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ),
        
//         // Statut
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: _getStatusColor().withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: _getStatusColor()),
//           ),
//           child: Text(
//             _getStatusText(),
//             style: TextStyle(
//               color: _getStatusColor(),
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ),
        
//         // Catégorie
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: AppColors.info.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.info),
//           ),
//           child: Text(
//             widget.product.category,
//             style: TextStyle(
//               color: AppColors.info,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getTypeColor() {
//     switch (widget.product.type) {
//       case ProductType.cpc:
//         return AppColors.success;
//       case ProductType.marketplace:
//         return AppColors.info;
//       case ProductType.hybrid:
//         return AppColors.warning;
//     }
//   }

//   String _getTypeText() {
//     switch (widget.product.type) {
//       case ProductType.cpc:
//         return 'ربح من النقرات';
//       case ProductType.marketplace:
//         return 'شراء مباشر';
//       case ProductType.hybrid:
//         return 'مختلط';
//     }
//   }

//   Color _getStatusColor() {
//     switch (widget.product.status) {
//       case ProductStatus.active:
//         return AppColors.success;
//       case ProductStatus.pending:
//         return AppColors.warning;
//       case ProductStatus.paused:
//         return AppColors.error;
//       case ProductStatus.sold:
//         return AppColors.info;
//       case ProductStatus.expired:
//         return AppColors.textSecondary;
//     }
//   }

//   String _getStatusText() {
//     switch (widget.product.status) {
//       case ProductStatus.active:
//         return 'نشط';
//       case ProductStatus.pending:
//         return 'قيد المراجعة';
//       case ProductStatus.paused:
//         return 'متوقف';
//       case ProductStatus.sold:
//         return 'تم البيع';
//       case ProductStatus.expired:
//         return 'منتهي';
//     }
//   }

//   Widget _buildProductDescription() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'الوصف',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: () => setState(() => _isExpanded = !_isExpanded),
//           child: Text(
//             widget.product.description,
//             style: TextStyle(
//               fontSize: 16,
//               color: AppColors.textSecondary,
//               fontFamily: 'Tajawal',
//               height: 1.5,
//             ),
//             maxLines: _isExpanded ? null : 3,
//             overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
//           ),
//         ),
//         if (!_isExpanded)
//           Text(
//             '...المزيد',
//             style: TextStyle(
//               color: AppColors.primary,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildProductStats() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.background,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'إحصائيات المنتج',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildStatItem('المشاهدات', widget.product.views, Icons.remove_red_eye_rounded),
//               _buildStatItem('المشاركات', widget.product.shares, Icons.share_rounded),
//               _buildStatItem('الاستفسارات', widget.product.inquiries, Icons.chat_rounded),
//               if (widget.product.type == ProductType.cpc || widget.product.type == ProductType.hybrid)
//                 _buildStatItem('النقرات', widget.product.achievedClicks, Icons.touch_app_rounded),
//             ],
//           ),
          
//           // Informations CPC supplémentaires
//           if (widget.product.type == ProductType.cpc || widget.product.type == ProductType.hybrid) ...[
//             const SizedBox(height: 16),
//             _buildCPCInfo(),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, int value, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: AppColors.primary, size: 24),
//         const SizedBox(height: 4),
//         Text(
//           _formatNumber(value),
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: AppColors.textSecondary,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCPCInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'معلومات الإشهار',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text('معدل النقرة:', style: TextStyle(fontFamily: 'Tajawal')),
//             Text('${widget.product.cpcRate} د', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text('النقرات المحققة:', style: TextStyle(fontFamily: 'Tajawal')),
//             Text('${widget.product.achievedClicks}/${widget.product.targetClicks}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text('الميزانية المتبقية:', style: TextStyle(fontFamily: 'Tajawal')),
//             Text('${widget.product.remainingBudget.toStringAsFixed(2)} د', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
//           ],
//         ),
//         const SizedBox(height: 8),
//         LinearProgressIndicator(
//           value: widget.product.targetClicks! > 0 
//               ? widget.product.achievedClicks / widget.product.targetClicks!
//               : 0,
//           backgroundColor: AppColors.background,
//           color: AppColors.primary,
//         ),
//       ],
//     );
//   }

//   Widget _buildSellerInfo() {
//     // En attendant l'intégration des données du vendeur
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.background,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           const CircleAvatar(
//             radius: 24,
//             backgroundColor: AppColors.primary,
//             child: Icon(Icons.store_rounded, color: Colors.white),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'البائع',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//                 Text(
//                   'متجر ${widget.product.category}',
//                   style: TextStyle(
//                     color: AppColors.textSecondary,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.chat_rounded),
//             onPressed: _contactSeller,
//             color: AppColors.primary,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSellerActions(MarketplaceProvider provider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Text(
//           'إدارة المنتج',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//         const SizedBox(height: 12),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             ElevatedButton.icon(
//               onPressed: _editProduct,
//               icon: const Icon(Icons.edit_rounded),
//               label: const Text('تعديل', style: TextStyle(fontFamily: 'Tajawal')),
//             ),
//             ElevatedButton.icon(
//               onPressed: () => _toggleProductStatus(provider),
//               icon: Icon(widget.product.status == ProductStatus.active 
//                   ? Icons.pause_rounded 
//                   : Icons.play_arrow_rounded),
//               label: Text(
//                 widget.product.status == ProductStatus.active ? 'إيقاف' : 'تفعيل',
//                 style: const TextStyle(fontFamily: 'Tajawal'),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: widget.product.status == ProductStatus.active 
//                     ? AppColors.warning 
//                     : AppColors.success,
//               ),
//             ),
//             OutlinedButton.icon(
//               onPressed: () => _showSponsoringDialog(provider),
//               icon: const Icon(Icons.rocket_launch_rounded),
//               label: const Text('تمويل', style: TextStyle(fontFamily: 'Tajawal')),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildBuyerActions(MarketplaceProvider provider, AuthProvider authProvider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Text(
//           'خيارات المشاركة',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//         const SizedBox(height: 12),
        
//         if (widget.product.type == ProductType.cpc || widget.product.type == ProductType.hybrid) 
//           _buildCPCActions(provider, authProvider),
        
//         if (widget.product.type == ProductType.marketplace || widget.product.type == ProductType.hybrid)
//           _buildMarketplaceActions(provider),
//       ],
//     );
//   }

//   Widget _buildCPCActions(MarketplaceProvider provider, AuthProvider authProvider) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppColors.success.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.success),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.attach_money_rounded, color: AppColors.success),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'اربح ${widget.product.participantEarnings.toStringAsFixed(2)} د لكل نقرة صالحة',
//                   style: const TextStyle(
//                     color: AppColors.success,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () => _shareProduct(provider),
//                 icon: const Icon(Icons.share_rounded),
//                 label: const Text('مشاركة المنتج', style: TextStyle(fontFamily: 'Tajawal')),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             IconButton(
//               onPressed: () => _viewProduct(provider, authProvider),
//               icon: const Icon(Icons.remove_red_eye_rounded),
//               style: IconButton.styleFrom(
//                 backgroundColor: AppColors.info,
//                 foregroundColor: Colors.white,
//               ),
//               tooltip: 'سجل مشاهدة واربح',
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMarketplaceActions(MarketplaceProvider provider) {
//     return Column(
//       children: [
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _contactSeller,
//                 icon: const Icon(Icons.chat_rounded),
//                 label: const Text('تواصل مع البائع', style: TextStyle(fontFamily: 'Tajawal')),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.info,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             ElevatedButton.icon(
//               onPressed: () => _purchaseProduct(provider),
//               icon: const Icon(Icons.shopping_cart_rounded),
//               label: const Text('شراء الآن', style: TextStyle(fontFamily: 'Tajawal')),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.success,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildBottomBar(MarketplaceProvider provider) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Prix
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'السعر',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: AppColors.textSecondary,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//                 Text(
//                   '${widget.product.price} دينار',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primary,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Actions principales
//           if (widget.product.type == ProductType.cpc || widget.product.type == ProductType.hybrid)
//             ElevatedButton.icon(
//               onPressed: () => _shareProduct(provider),
//               icon: const Icon(Icons.share_rounded),
//               label: const Text('مشاركة وربح', style: TextStyle(fontFamily: 'Tajawal')),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               ),
//             ),
          
//           if (widget.product.type == ProductType.marketplace || widget.product.type == ProductType.hybrid)
//             ElevatedButton.icon(
//               onPressed: () => _purchaseProduct(provider),
//               icon: const Icon(Icons.shopping_cart_rounded),
//               label: const Text('شراء', style: TextStyle(fontFamily: 'Tajawal')),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.success,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // Méthodes d'interaction
//   void _shareProduct(MarketplaceProvider provider) async {
//     try {
//       await provider.interactWithProduct(
//         productId: widget.product.id,
//         interactionType: ProductInteractionType.share,
//       );
      
//       // Partager le produit
//       await provider.shareProduct(widget.product);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'تم تسجيل المشاركة وربحت ${widget.product.participantEarnings.toStringAsFixed(2)} د',
//             style: const TextStyle(fontFamily: 'Tajawal'),
//           ),
//           backgroundColor: AppColors.success,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('فشل في المشاركة: $e', style: const TextStyle(fontFamily: 'Tajawal')),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   void _viewProduct(MarketplaceProvider provider, AuthProvider authProvider) async {
//     if (authProvider.user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('يجب تسجيل الدخول أولاً', style: TextStyle(fontFamily: 'Tajawal')),
//           backgroundColor: AppColors.warning,
//         ),
//       );
//       return;
//     }

//     try {
//       await provider.interactWithProduct(
//         productId: widget.product.id,
//         interactionType: ProductInteractionType.view,
//       );
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'تم تسجيل المشاهدة وربحت ${(widget.product.participantEarnings * 0.5).toStringAsFixed(2)} د',
//             style: const TextStyle(fontFamily: 'Tajawal'),
//           ),
//           backgroundColor: AppColors.success,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('فشل في تسجيل المشاهدة: $e', style: const TextStyle(fontFamily: 'Tajawal')),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   void _contactSeller() async {
//     const phoneNumber = '+21612345678'; // Numéro exemple
//     final url = 'https://wa.me/$phoneNumber?text=مرحبا، أنا مهتم بالمنتج: ${widget.product.title}';
    
//     try {
//       if (await canLaunchUrl(Uri.parse(url))) {
//         await launchUrl(Uri.parse(url));
//       } else {
//         throw 'Could not launch $url';
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('فشل في فتح الواتساب: $e', style: const TextStyle(fontFamily: 'Tajawal')),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   void _purchaseProduct(MarketplaceProvider provider) async {
//     try {
//       await provider.interactWithProduct(
//         productId: widget.product.id,
//         interactionType: ProductInteractionType.purchase,
//       );
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('تم تسجيل عملية الشراء بنجاح', style: TextStyle(fontFamily: 'Tajawal')),
//           backgroundColor: AppColors.success,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('فشل في عملية الشراء: $e', style: const TextStyle(fontFamily: 'Tajawal')),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   void _toggleFavorite() {
//     // Implémenter la logique des favoris
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('تمت الإضافة إلى المفضلة', style: TextStyle(fontFamily: 'Tajawal')),
//       ),
//     );
//   }

//   void _editProduct() {
//     // Navigation vers l'écran d'édition
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('فتح صفحة التعديل', style: TextStyle(fontFamily: 'Tajawal')),
//       ),
//     );
//   }

//   void _toggleProductStatus(MarketplaceProvider provider) {
//     // Implémenter le changement de statut
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           widget.product.status == ProductStatus.active 
//               ? 'تم إيقاف المنتج' 
//               : 'تم تفعيل المنتج',
//           style: const TextStyle(fontFamily: 'Tajawal'),
//         ),
//       ),
//     );
//   }

//   void _showSponsoringDialog(MarketplaceProvider provider) {
//     showDialog(
//       context: context,
//       builder: (context) => SponsoringDialog(
//         product: widget.product,
//         onPurchase: (tier, days) {
//           provider.purchaseSponsoring(
//             productId: widget.product.id,
//             tier: tier,
//             days: days,
//           );
//         },
//       ),
//     );
//   }

//   String _formatNumber(int number) {
//     if (number < 1000) return number.toString();
//     if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
//     return '${(number / 1000000).toStringAsFixed(1)}M';
//   }

//   @override
//   void dispose() {
//     _imageController.dispose();
//     super.dispose();
//   }
// }

// // Dialog pour l'achat de sponsoring
// class SponsoringDialog extends StatefulWidget {
//   final ProductModel product;
//   final Function(SponsoringTier, int) onPurchase;

//   const SponsoringDialog({
//     super.key,
//     required this.product,
//     required this.onPurchase,
//   });

//   @override
//   State<SponsoringDialog> createState() => _SponsoringDialogState();
// }

// class _SponsoringDialogState extends State<SponsoringDialog> {
//   SponsoringTier _selectedTier = SponsoringTier.boostVisibility;
//   int _selectedDays = 7;

//   final Map<SponsoringTier, Map<String, dynamic>> _tiers = {
//     SponsoringTier.topProduct: {
//       'title': 'منتج مميز',
//       'price': 20.0,
//       'features': ['ظهور في الأعلى', 'لون مميز', 'أولوية في البحث'],
//       'icon': Icons.star_rounded,
//       'color': AppColors.warning,
//     },
//     SponsoringTier.boostVisibility: {
//       'title': 'تعزيز الظهور',
//       'price': 15.0,
//       'features': ['زيادة في المشاهدات', 'ظهور في القسم الممول'],
//       'icon': Icons.rocket_launch_rounded,
//       'color': AppColors.primary,
//     },
//     SponsoringTier.bannerDisplay: {
//       'title': 'عرض بانر',
//       'price': 30.0,
//       'features': ['بانر في الصفحة الرئيسية', 'أقصى ظهور', 'أولوية مطلقة'],
//       'icon': Icons.campaign_rounded,
//       'color': AppColors.success,
//     },
//   };

//   @override
//   Widget build(BuildContext context) {
//     final selectedTierInfo = _tiers[_selectedTier]!;

//     return AlertDialog(
//       title: const Text('تمويل المنتج', style: TextStyle(fontFamily: 'Tajawal')),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Sélection du type de sponsoring
//             const Text(
//               'اختر نوع التمويل',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Options de sponsoring
//             ..._tiers.entries.map((entry) {
//               final tier = entry.key;
//               final info = entry.value;
//               final isSelected = _selectedTier == tier;
              
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: ListTile(
//                   leading: Icon(info['icon'], color: info['color']),
//                   title: Text(info['title'], style: const TextStyle(fontFamily: 'Tajawal')),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('${info['price']} دينار', style: const TextStyle(fontFamily: 'Tajawal')),
//                       ...(info['features'] as List<String>).map((feature) => 
//                         Text('• $feature', style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal'))
//                       ).toList(),
//                     ],
//                   ),
//                   trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
//                   tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: BorderSide(
//                       color: isSelected ? AppColors.primary : AppColors.outline,
//                     ),
//                   ),
//                   onTap: () => setState(() => _selectedTier = tier),
//                 ),
//               );
//             }).toList(),
            
//             const SizedBox(height: 16),
            
//             // Sélection de la durée
//             const Text(
//               'مدة التمويل',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 8),
//             SegmentedButton<int>(
//               segments: const [
//                 ButtonSegment(value: 7, label: Text('7 أيام', style: TextStyle(fontFamily: 'Tajawal'))),
//                 ButtonSegment(value: 14, label: Text('14 يوم', style: TextStyle(fontFamily: 'Tajawal'))),
//                 ButtonSegment(value: 30, label: Text('30 يوم', style: TextStyle(fontFamily: 'Tajawal'))),
//               ],
//               selected: {_selectedDays},
//               onSelectionChanged: (Set<int> newSelection) {
//                 setState(() => _selectedDays = newSelection.first);
//               },
//             ),
            
//             const SizedBox(height: 16),
            
//             // Résumé du prix
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: AppColors.background,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('المبلغ الإجمالي:', style: TextStyle(fontFamily: 'Tajawal')),
//                   Text(
//                     '${(selectedTierInfo['price'] * _selectedDays / 7).toStringAsFixed(2)} دينار',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primary,
//                       fontFamily: 'Tajawal',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             widget.onPurchase(_selectedTier, _selectedDays);
//             Navigator.pop(context);
//           },
//           child: const Text('شراء التمويل', style: TextStyle(fontFamily: 'Tajawal')),
//         ),
//       ],
//     );
//   }
// }