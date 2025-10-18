// // lib/presentation/widgets/marketplace/product_card.dart
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import '../../../core/constants/app_colors.dart';
// import '../../../data/models/product_model.dart';

// class ProductCard extends StatelessWidget {
//   final ProductModel product;
//   final VoidCallback onTap;
//   final VoidCallback onShare;

//   const ProductCard({
//     super.key,
//     required this.product,
//     required this.onTap,
//     required this.onShare,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb;
    
//     return Card(
//       elevation: 2,
//       margin: EdgeInsets.zero,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           decoration: product.isSponsored 
//               ? BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       AppColors.primary.withOpacity(0.05),
//                       AppColors.secondary.withOpacity(0.05),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: AppColors.primary.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 )
//               : null,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // En-tête avec image et informations de base
//                 _buildProductHeader(isWeb),
//                 const SizedBox(height: 12),
                
//                 // Description
//                 _buildProductDescription(),
//                 const SizedBox(height: 12),
                
//                 // Statistiques et actions
//                 _buildProductFooter(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProductHeader(bool isWeb) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Image du produit
//         _buildProductImage(isWeb),
//         const SizedBox(width: 12),
        
//         // Informations de base
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Titre et badge sponsorisé
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       product.title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'Tajawal',
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (product.isSponsored) ...[
//                     const SizedBox(width: 8),
//                     _buildSponsoredBadge(),
//                   ],
//                 ],
//               ),
//               const SizedBox(height: 4),
              
//               // Prix
//               Text(
//                 '${product.price} دينار',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primary,
//                   fontFamily: 'Tajawal',
//                 ),
//               ),
//               const SizedBox(height: 4),
              
//               // Type de produit
//               _buildProductTypeBadge(),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProductImage(bool isWeb) {
//     final hasImage = product.images.isNotEmpty;
//     final imageUrl = hasImage ? product.images.first : '';
    
//     return Container(
//       width: 80,
//       height: 80,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: AppColors.background,
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: hasImage 
//             ? _buildOptimizedImage(imageUrl, isWeb)
//             : _buildPlaceholderImage(),
//       ),
//     );
//   }

//   Widget _buildOptimizedImage(String imageUrl, bool isWeb) {
//     if (isWeb) {
//       return Image.network(
//         imageUrl,
//         fit: BoxFit.cover,
//         width: 80,
//         height: 80,
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
//         width: 80,
//         height: 80,
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
//         size: 32,
//       ),
//     );
//   }

//   Widget _buildSponsoredBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: AppColors.primary),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
//           const SizedBox(width: 4),
//           Text(
//             'ممول',
//             style: TextStyle(
//               fontSize: 10,
//               color: AppColors.primary,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductTypeBadge() {
//     Color color;
//     String text;
    
//     switch (product.type) {
//       case ProductType.cpc:
//         color = AppColors.success;
//         text = 'ربح من النقرات';
//         break;
//       case ProductType.marketplace:
//         color = AppColors.info;
//         text = 'شراء مباشر';
//         break;
//       case ProductType.hybrid:
//         color = AppColors.warning;
//         text = 'مختلط';
//         break;
//     }
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 10,
//           color: color,
//           fontWeight: FontWeight.bold,
//           fontFamily: 'Tajawal',
//         ),
//       ),
//     );
//   }

//   Widget _buildProductDescription() {
//     return Text(
//       product.description,
//       style: TextStyle(
//         fontSize: 14,
//         color: AppColors.textSecondary,
//         fontFamily: 'Tajawal',
//         height: 1.4,
//       ),
//       maxLines: 2,
//       overflow: TextOverflow.ellipsis,
//     );
//   }

//   Widget _buildProductFooter() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // Statistiques
//         _buildProductStats(),
        
//         // Actions
//         _buildActionButtons(),
//       ],
//     );
//   }

//   Widget _buildProductStats() {
//     return Row(
//       children: [
//         // Vues
//         _buildStatItem(
//           icon: Icons.remove_red_eye_rounded,
//           value: product.views,
//           color: AppColors.textSecondary,
//         ),
//         const SizedBox(width: 12),
        
//         // Partages
//         _buildStatItem(
//           icon: Icons.share_rounded,
//           value: product.shares,
//           color: AppColors.textSecondary,
//         ),
        
//         // Clics (pour CPC)
//         if (product.type == ProductType.cpc || product.type == ProductType.hybrid) ...[
//           const SizedBox(width: 12),
//           _buildStatItem(
//             icon: Icons.touch_app_rounded,
//             value: product.achievedClicks,
//             color: AppColors.success,
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildStatItem({
//     required IconData icon,
//     required int value,
//     required Color color,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: color),
//         const SizedBox(width: 4),
//         Text(
//           _formatNumber(value),
//           style: TextStyle(
//             fontSize: 12,
//             color: color,
//             fontFamily: 'Tajawal',
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         // Bouton Partage
//         IconButton(
//           icon: const Icon(Icons.share_rounded),
//           onPressed: onShare,
//           iconSize: 20,
//           color: AppColors.primary,
//           tooltip: 'مشاركة المنتج',
//         ),
        
//         // Bouton Détails
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: AppColors.primary,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Text(
//             'تفاصيل',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatNumber(int number) {
//     if (number < 1000) return number.toString();
//     if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
//     return '${(number / 1000000).toStringAsFixed(1)}M';
//   }
// }