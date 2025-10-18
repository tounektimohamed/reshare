// // lib/data/repositories/product_repository.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import 'package:reshare/core/services/cloud_functions_service.dart';
// import '../models/product_model.dart';

// class ProductRepository {
//   final FirebaseFirestore _firestore;
//   final Uuid _uuid;
//   final CloudFunctionsService _cloud = CloudFunctionsService();

//   ProductRepository({
//     FirebaseFirestore? firestore,
//     Uuid? uuid,
//   })  : _firestore = firestore ?? FirebaseFirestore.instance,
//         _uuid = uuid ?? Uuid();

//   CollectionReference get _productsCollection =>
//       _firestore.collection('products');
//   CollectionReference get _interactionsCollection =>
//       _firestore.collection('product_interactions');
//   CollectionReference get _sponsoringCollection =>
//       _firestore.collection('sponsoring_orders');

//   // ===============================================================
//   // 🔥 CRÉER UN PRODUIT
//   // ===============================================================
//   Future<ProductModel> createProduct(ProductModel product) async {
//     try {
//       await _productsCollection.doc(product.id).set(product.toMap());
//       return product;
//     } catch (e) {
//       throw Exception('فشل في إنشاء المنتج: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 OBTENIR LES PRODUITS ACTIFS
//   // ===============================================================
//   Future<List<ProductModel>> getActiveProducts({
//     String? category,
//     ProductType? type,
//     bool includeSponsored = true,
//     int limit = 20,
//   }) async {
//     try {
//       Query query = _productsCollection
//           .where('isActive', isEqualTo: true)
//           .where('status', isEqualTo: ProductStatus.active.index);

//       if (category != null) {
//         query = query.where('category', isEqualTo: category);
//       }

//       if (type != null) {
//         query = query.where('type', isEqualTo: type.index);
//       }

//       final snapshot = await query.limit(limit).get();

//       var products = snapshot.docs
//           .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();

//       if (includeSponsored) {
//         products.sort((a, b) {
//           if (a.isSponsored && !b.isSponsored) return -1;
//           if (!a.isSponsored && b.isSponsored) return 1;
//           return b.createdAt.compareTo(a.createdAt);
//         });
//       }

//       return products;
//     } catch (e) {
//       throw Exception('فشل في جلب المنتجات: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 OBTENIR LES PRODUITS D’UN VENDEUR
//   // ===============================================================
//   Future<List<ProductModel>> getSellerProducts(String sellerId) async {
//     try {
//       final snapshot = await _productsCollection
//           .where('sellerId', isEqualTo: sellerId)
//           .orderBy('createdAt', descending: true)
//           .get();

//       return snapshot.docs
//           .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       throw Exception('فشل في جلب منتجات البائع: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 OBTENIR UN PRODUIT PAR ID
//   // ===============================================================
//   Future<ProductModel?> getProductById(String productId) async {
//     try {
//       final doc = await _productsCollection.doc(productId).get();
//       if (doc.exists) {
//         return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
//       }
//       return null;
//     } catch (e) {
//       throw Exception('فشل في جلب المنتج: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 METTRE À JOUR UN PRODUIT
//   // ===============================================================
//   Future<void> updateProduct(ProductModel product) async {
//     try {
//       await _productsCollection.doc(product.id).update(product.toMap());
//     } catch (e) {
//       throw Exception('فشل في تحديث المنتج: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 ENREGISTRER UNE INTERACTION AVEC CLOUD FUNCTIONS
//   // ===============================================================
//   Future<Map<String, dynamic>> recordInteractionCloud({
//     required String productId,
//     required String userId,
//     required String userAgent,
//     required String deviceHash,
//     required Map<String, dynamic>? locationData,
//   }) async {
//     try {
//       // Utilise clickHandler → processClickWithFraudDetection
//       final result = await _cloud.processClickWithFraudDetection(
//         trackingId: productId,
//         ipAddress: '192.168.1.10', // à remplacer par la vraie IP
//         userAgent: userAgent,
//         deviceHash: deviceHash,
//         locationData: locationData,
//       );

//       if (result['success'] == true) {
//         return result;
//       } else {
//         return {'success': false, 'error': 'Échec du traitement du clic'};
//       }
//     } catch (e) {
//       throw Exception('فشل في تسجيل التفاعل عبر السحابة: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 GÉNÉRER UN LIEN DE PARTAGE TRACKÉ (CLOUD)
//   // ===============================================================
//   Future<Map<String, dynamic>> generateProductShareLink({
//     required String productId,
//     required String userId,
//   }) async {
//     try {
//       return await _cloud.generateTrackingLink(
//         campaignId: productId,
//         participantId: userId,
//       );
//     } catch (e) {
//       throw Exception('فشل في توليد رابط التتبع: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 METTRE À JOUR LE SOLDE (Cloud)
//   // ===============================================================
//   Future<void> updateUserBalanceCloud({
//     required String userId,
//     required double amount,
//     required String transactionType,
//     required String description,
//   }) async {
//     try {
//       await _cloud.updateUserBalance(
//         userId: userId,
//         amount: amount,
//         transactionType: transactionType,
//         description: description,
//       );
//     } catch (e) {
//       throw Exception('فشل في تحديث الرصيد عبر السحابة: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 PARTAGER UN PRODUIT (Cloud Function shareCampaign)
//   // ===============================================================
//   Future<Map<String, dynamic>> shareProduct({
//     required String productId,
//     required String userId,
//     required String userLocation,
//   }) async {
//     try {
//       return await _cloud.shareCampaign(
//         campaignId: productId,
//         userId: userId,
//         userLocation: userLocation,
//       );
//     } catch (e) {
//       throw Exception('فشل في مشاركة المنتج عبر السحابة: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 COMMANDER UN SPONSORING
//   // ===============================================================
//   Future<void> purchaseSponsoring({
//     required String productId,
//     required SponsoringTier tier,
//     required int days,
//     required double amount,
//   }) async {
//     try {
//       final orderId = _uuid.v4();

//       await _sponsoringCollection.doc(orderId).set({
//         'id': orderId,
//         'productId': productId,
//         'tier': tier.index,
//         'days': days,
//         'amount': amount,
//         'purchasedAt': DateTime.now().toIso8601String(),
//         'expiresAt':
//             DateTime.now().add(Duration(days: days)).toIso8601String(),
//       });

//       final product = await getProductById(productId);
//       if (product != null) {
//         final updatedProduct = product.withSponsoring(tier, days);
//         await updateProduct(updatedProduct);
//       }
//     } catch (e) {
//       throw Exception('فشل في شراء التمويل: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 RECHERCHE PRODUITS
//   // ===============================================================
//   Future<List<ProductModel>> searchProducts({
//     required String query,
//     String? category,
//     double? minPrice,
//     double? maxPrice,
//     int limit = 20,
//   }) async {
//     try {
//       final allProducts = await getActiveProducts(limit: 100);

//       var filtered = allProducts.where((p) {
//         final matchQuery = p.title.toLowerCase().contains(query.toLowerCase()) ||
//             p.description.toLowerCase().contains(query.toLowerCase());
//         final matchCat = category == null || p.category == category;
//         final matchPrice = (minPrice == null || p.price >= minPrice) &&
//             (maxPrice == null || p.price <= maxPrice);

//         return matchQuery && matchCat && matchPrice;
//       }).toList();

//       return filtered.take(limit).toList();
//     } catch (e) {
//       throw Exception('فشل في البحث عن المنتجات: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 CATÉGORIES
//   // ===============================================================
//   Future<List<String>> getCategories() async {
//     try {
//       return [
//         'الإلكترونيات',
//         'الملابس والأزياء',
//         'المنزل والحديقة',
//         'الجمال والعناية',
//         'الرياضة والترفيه',
//         'السيارات',
//         'الكتب والتعليم',
//         'الأغذية',
//         'الصحة',
//         'الأطفال',
//         'الهدايا',
//         'أخرى',
//       ];
//     } catch (e) {
//       return [];
//     }
//   }

//   // ===============================================================
//   // 🔥 STATISTIQUES PRODUIT (locale ou cloud)
//   // ===============================================================
//   Future<Map<String, dynamic>> getProductStats(String productId) async {
//     try {
//       final interactions = await _interactionsCollection
//           .where('productId', isEqualTo: productId)
//           .get();

//       final totalEarnings = interactions.docs.fold(0.0, (sum, doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return sum + (data['earnings'] ?? 0).toDouble();
//       });

//       final views = interactions.docs
//           .where((d) => d.data()['type'] == ProductInteractionType.view.index)
//           .length;

//       final shares = interactions.docs
//           .where((d) => d.data()['type'] == ProductInteractionType.share.index)
//           .length;

//       final inquiries = interactions.docs
//           .where((d) => d.data()['type'] == ProductInteractionType.inquiry.index)
//           .length;

//       return {
//         'totalEarnings': totalEarnings,
//         'views': views,
//         'shares': shares,
//         'inquiries': inquiries,
//         'conversionRate': views > 0 ? (inquiries / views) * 100 : 0,
//       };
//     } catch (e) {
//       throw Exception('فشل في جلب الإحصائيات: $e');
//     }
//   }

//   // ===============================================================
//   // 🔥 GÉNÉRER ID UNIQUE
//   // ===============================================================
//   String generateProductId() {
//     return _uuid.v4();
//   }
// }
