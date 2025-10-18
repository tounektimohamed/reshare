// // lib/presentation/widgets/marketplace/sponsored_section.dart
// import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../data/models/product_model.dart';
// import 'product_card.dart';

// class SponsoredSection extends StatelessWidget {
//   final List<ProductModel> products;

//   const SponsoredSection({super.key, required this.products});

//   @override
//   Widget build(BuildContext context) {
//     if (products.isEmpty) return const SizedBox.shrink();

//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // En-tête section sponsorisée
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'منتجات ممولة',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     fontFamily: 'Tajawal',
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: AppColors.warning.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     products.length.toString(),
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: AppColors.warning,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'Tajawal',
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
          
//           // Liste horizontale des produits sponsorisés
//           SizedBox(
//             height: 220,
//             child: ListView.separated(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               scrollDirection: Axis.horizontal,
//               itemCount: products.length,
//               separatorBuilder: (context, index) => const SizedBox(width: 12),
//               itemBuilder: (context, index) {
//                 final product = products[index];
//                 return SizedBox(
//                   width: 280,
//                   child: SponsoredProductCard(product: product),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SponsoredProductCard extends StatelessWidget {
//   final ProductModel product;

//   const SponsoredProductCard({super.key, required this.product});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               AppColors.primary.withOpacity(0.05),
//               AppColors.secondary.withOpacity(0.05),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: AppColors.primary.withOpacity(0.2),
//             width: 1,
//           ),
//         ),
//         child: Stack(
//           children: [
//             // Contenu principal
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Badge sponsorisé
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.primary,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.star_rounded, size: 12, color: Colors.white),
//                         SizedBox(width: 4),
//                         Text(
//                           'ممول',
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Tajawal',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   // Image du produit
//                   Center(
//                     child: Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         color: Colors.white,
//                       ),
//                       child: product.images.isNotEmpty
//                           ? ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.network(
//                                 product.images.first,
//                                 fit: BoxFit.cover,
//                               ),
//                             )
//                           : const Icon(
//                               Icons.shopping_bag_rounded,
//                               color: AppColors.textSecondary,
//                               size: 32,
//                             ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
                  
//                   // Titre
//                   Text(
//                     product.title,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'Tajawal',
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
                  
//                   // Prix
//                   Text(
//                     '${product.price} دينار',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primary,
//                       fontFamily: 'Tajawal',
//                     ),
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Bouton action
//                   Container(
//                     width: double.infinity,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Center(
//                       child: Text(
//                         'عرض التفاصيل',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: 'Tajawal',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }