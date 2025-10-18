// // lib/features/marketplace/presentation/providers/marketplace_provider.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:reshare/data/models/user_model.dart';
// import '../../../../data/models/product_model.dart';
// import '../../../../data/repositories/product_repository.dart';
// import '../../../../core/services/cloud_functions_service.dart';
// import '../../../../core/services/share_service.dart';
// import '../../../auth/presentation/providers/auth_provider.dart';

// class MarketplaceProvider with ChangeNotifier {
//   final ProductRepository _productRepository;
//   final CloudFunctionsService _cloudFunctions;
//   final ShareService _shareService;

//   AuthProvider? _authProvider;

//   // État du provider
//   List<ProductModel> _products = [];
//   List<ProductModel> _sponsoredProducts = [];
//   List<ProductModel> _sellerProducts = [];
//   ProductModel? _selectedProduct;
//   bool _isLoading = false;
//   String? _error;
//   String _selectedCategory = 'الكل';
//   ProductType _selectedType = ProductType.cpc;
//   MarketplaceFilter _filter = MarketplaceFilter();

//   MarketplaceProvider({
//     required ProductRepository productRepository,
//     required CloudFunctionsService cloudFunctions,
//     required ShareService shareService,
//   })  : _productRepository = productRepository,
//         _cloudFunctions = cloudFunctions,
//         _shareService = shareService;

//   // Getters
//   List<ProductModel> get products => _products;
//   List<ProductModel> get sponsoredProducts => _sponsoredProducts;
//   List<ProductModel> get sellerProducts => _sellerProducts;
//   ProductModel? get selectedProduct => _selectedProduct;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   String get selectedCategory => _selectedCategory;
//   ProductType get selectedType => _selectedType;
//   MarketplaceFilter get filter => _filter;

//   /// Mettre à jour le provider d'authentification
//   void updateAuth(AuthProvider authProvider) {
//     _authProvider = authProvider;
//     if (authProvider.isAuthenticated) {
//       loadMarketplaceProducts();
//       _loadSellerProducts();
//     }
//   }

//   /// Charger les produits du marketplace
//   Future<void> loadMarketplaceProducts() async {
//     if (_authProvider?.user == null) return;

//     try {
//       _setLoading(true);
//       _clearError();

//       _products = await _productRepository.getActiveProducts(
//         category: _selectedCategory == 'الكل' ? null : _selectedCategory,
//         type: _selectedType,
//       );

//       // Filtrer les produits sponsorisés
//       _sponsoredProducts = _products.where((p) => p.isSponsored).toList();

//       // Appliquer les filtres supplémentaires
//       _applyFilters();

//     } catch (e) {
//       _setError('فشل في تحميل المنتجات: $e');
//     } finally {
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// Charger les produits du vendeur
//   Future<void> _loadSellerProducts() async {
//     try {
//       final user = _authProvider!.user!;
      
//       if (user.userType == UserType.business || user.userType == UserType.admin) {
//         _sellerProducts = await _productRepository.getSellerProducts(user.id);
//       }
//     } catch (e) {
//       print('فشل في تحميل منتجات البائع: $e');
//     }
//   }

//   /// Ajouter un nouveau produit
//   Future<void> addProduct(ProductModel product) async {
//     if (_authProvider?.user == null) return;

//     try {
//       _setLoading(true);
//       _clearError();

//       // Vérifier le solde pour les produits marketplace
//       if (product.isMarketplace && _authProvider!.user!.availableBalance < product.marketplaceFee) {
//         _setError('الرصيد غير كافي لرسوم السوق');
//         return;
//       }

//       await _productRepository.createProduct(product);

//       // Déduire les frais du marketplace via Cloud Function
//       if (product.isMarketplace) {
//         await _productRepository.updateUserBalanceCloud(
//           userId: _authProvider!.user!.id,
//           amount: -product.marketplaceFee,
//           transactionType: 'marketplace_fee',
//           description: 'رسوم عرض المنتج "${product.title}" في السوق',
//         );
//       }

//       // Recharger les produits
//       await _loadSellerProducts();
//       await loadMarketplaceProducts();

//       // Envoyer une notification
//       await _cloudFunctions.sendUserNotification(
//         userId: _authProvider!.user!.id,
//         title: 'تم إضافة المنتج بنجاح! 🎉',
//         body: 'منتج "${product.title}" جاهز للعرض',
//         type: 'product_added',
//       );

//     } catch (e) {
//       _setError('فشل في إضافة المنتج: $e');
//     } finally {
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// 🎯 INTERAGIR AVEC UN PRODUIT - AVEC SYSTÈME CLOUD COMPLET
//   Future<Map<String, dynamic>> interactWithProduct({
//     required String productId,
//     required ProductInteractionType interactionType,
//   }) async {
//     if (_authProvider?.user == null) {
//       return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
//     }

//     try {
//       final product = await _productRepository.getProductById(productId);
//       if (product == null) {
//         return {'success': false, 'error': 'المنتج غير موجود'};
//       }

//       // 🔍 Préparer les données pour la détection de fraude
//       final deviceInfo = await _getDeviceInfo();
//       final userLocation = await _getUserLocation();

//       // 📊 Traiter l'interaction via Cloud Functions avec détection de fraude
//       final cloudResult = await _productRepository.recordInteractionCloud(
//         productId: productId,
//         userId: _authProvider!.user!.id,
//         userAgent: deviceInfo['userAgent'] ?? 'Unknown',
//         deviceHash: deviceInfo['deviceHash'] ?? _authProvider!.user!.id,
//         locationData: userLocation,
//       );

//       if (!cloudResult['success']) {
//         return {'success': false, 'error': cloudResult['error'] ?? 'فشل في معالجة التفاعل'};
//       }

//       // 💰 Calculer les gains selon le type d'interaction
//       final earnings = _calculateEarnings(product, interactionType, cloudResult);
//       final requiresReview = cloudResult['requiresManualReview'] == true;
//       final finalEarnings = requiresReview ? 0.0 : earnings;

//       // 📝 Enregistrer l'interaction localement
//       final interaction = ProductInteraction(
//         id: _productRepository.generateInteractionId(),
//         productId: productId,
//         userId: _authProvider!.user!.id,
//         type: interactionType,
//         earnings: finalEarnings,
//         timestamp: DateTime.now(),
//         status: requiresReview ? InteractionStatus.pending : InteractionStatus.approved,
//         metadata: {
//           'productTitle': product.title,
//           'interactionType': interactionType.name,
//           'riskScore': cloudResult['riskScore'],
//           'fraudAnalysis': cloudResult['fraudAnalysis'],
//           'requiresReview': requiresReview,
//           'clickId': cloudResult['clickId'],
//           'cloudResult': cloudResult,
//         },
//       );

//       // 💾 Sauvegarder dans Firestore
//       await _saveInteractionLocally(interaction);

//       // 💳 Mettre à jour le solde si les gains sont approuvés
//       if (finalEarnings > 0 && !requiresReview) {
//         await _productRepository.updateUserBalanceCloud(
//           userId: _authProvider!.user!.id,
//           amount: finalEarnings,
//           transactionType: 'product_interaction',
//           description: 'أرباح من ${_getInteractionTypeName(interactionType)} "${product.title}"',
//         );
//       }

//       // 🔄 Mettre à jour les statistiques du produit
//       await _updateProductStats(product, interactionType);

//       // 🔄 Recharger les données
//       await loadMarketplaceProducts();

//       // 📢 Notification selon le statut
//       await _sendInteractionNotification(product, interactionType, finalEarnings, requiresReview);

//       return {
//         'success': true,
//         'earnings': finalEarnings,
//         'requiresReview': requiresReview,
//         'message': requiresReview 
//             ? 'تم تسجيل التفاعل وسيتم مراجعته قريباً'
//             : 'تهانينا! لقد ربحت ${finalEarnings.toStringAsFixed(2)} دينار',
//       };

//     } catch (e) {
//       final errorMsg = 'فشل في تسجيل التفاعل: $e';
//       _setError(errorMsg);
//       return {'success': false, 'error': errorMsg};
//     }
//   }

//   /// 💾 SAUVEGARDER L'INTERACTION LOCALEMENT
//   Future<void> _saveInteractionLocally(ProductInteraction interaction) async {
//     try {
//       await _productRepository.recordInteraction(interaction);
//     } catch (e) {
//       print('⚠️ Failed to save interaction locally: $e');
//     }
//   }

//   /// 📊 METTRE À JOUR LES STATISTIQUES DU PRODUIT
//   Future<void> _updateProductStats(ProductModel product, ProductInteractionType interactionType) async {
//     try {
//       ProductModel updatedProduct = product;

//       switch (interactionType) {
//         case ProductInteractionType.view:
//           updatedProduct = product.incrementViews();
//           break;
//         case ProductInteractionType.share:
//           updatedProduct = product.incrementShares();
//           break;
//         case ProductInteractionType.inquiry:
//           updatedProduct = product.incrementInquiries();
//           break;
//         case ProductInteractionType.purchase:
//           updatedProduct = product.copyWith(status: ProductStatus.sold);
//           break;
//       }

//       // Incrémenter les clics pour les produits CPC
//       if (product.type == ProductType.cpc || product.type == ProductType.hybrid) {
//         updatedProduct = updatedProduct.incrementClicks();
//       }

//       await _productRepository.updateProduct(updatedProduct);
//     } catch (e) {
//       print('⚠️ Failed to update product stats: $e');
//     }
//   }

//   /// 🔗 PARTAGER UN PRODUIT - AVEC SYSTÈME CLOUD COMPLET
//   Future<Map<String, dynamic>> shareProduct(ProductModel product) async {
//     if (_authProvider?.user == null) {
//       return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
//     }

//     try {
//       // 📍 Obtenir la localisation de l'utilisateur
//       final userLocation = await _getUserLocation();

//       // 🔗 Générer un lien de partage tracké via Cloud Functions
//       final shareResult = await _productRepository.shareProduct(
//         productId: product.id,
//         userId: _authProvider!.user!.id,
//         userLocation: userLocation['city'] ?? 'Unknown',
//       );

//       if (!shareResult['success']) {
//         return {'success': false, 'error': 'فشل في إنشاء رابط المشاركة'};
//       }

//       // 🔗 Partager le produit via le service de partage
//       final shareLink = shareResult['shareLink'] ?? 'https://reshare.tn/product/${product.id}';
      
//       final shared = await _shareService.shareProduct(
//         title: product.title,
//         description: product.description,
//         price: product.price,
//         shareLink: shareLink,
//       );

//       if (shared) {
//         // 📝 Enregistrer le partage comme interaction
//         final interactionResult = await interactWithProduct(
//           productId: product.id,
//           interactionType: ProductInteractionType.share,
//         );

//         return {
//           'success': true,
//           'shared': true,
//           'interactionResult': interactionResult,
//           'shareLink': shareLink,
//         };
//       } else {
//         return {'success': false, 'error': 'لم يتم إكمال المشاركة'};
//       }

//     } catch (e) {
//       final errorMsg = 'فشل في مشاركة المنتج: $e';
//       _setError(errorMsg);
//       return {'success': false, 'error': errorMsg};
//     }
//   }

//   /// 👁️ ENREGISTRER UNE VUE - SIMPLIFIÉ
//   Future<Map<String, dynamic>> viewProduct(String productId) async {
//     return await interactWithProduct(
//       productId: productId,
//       interactionType: ProductInteractionType.view,
//     );
//   }

//   /// 💬 ENREGISTRER UNE DEMANDE D'INFORMATION
//   Future<Map<String, dynamic>> inquireAboutProduct(String productId) async {
//     return await interactWithProduct(
//       productId: productId,
//       interactionType: ProductInteractionType.inquiry,
//     );
//   }

//   /// 🛒 ENREGISTRER UN ACHAT
//   Future<Map<String, dynamic>> purchaseProduct(String productId) async {
//     return await interactWithProduct(
//       productId: productId,
//       interactionType: ProductInteractionType.purchase,
//     );
//   }

//   /// 💎 ACHETER UN SPONSORING
//   Future<Map<String, dynamic>> purchaseSponsoring({
//     required String productId,
//     required SponsoringTier tier,
//     required int days,
//   }) async {
//     if (_authProvider?.user == null) {
//       return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};
//     }

//     try {
//       _setLoading(true);
//       _clearError();

//       final amount = _getSponsoringPrice(tier, days);
      
//       // Vérifier le solde
//       if (_authProvider!.user!.availableBalance < amount) {
//         return {'success': false, 'error': 'الرصيد غير كافي لشراء التمويل'};
//       }

//       // 💳 Acheter le sponsoring
//       await _productRepository.purchaseSponsoring(
//         productId: productId,
//         tier: tier,
//         days: days,
//         amount: amount,
//       );

//       // 💰 Déduire le montant via Cloud Function
//       await _productRepository.updateUserBalanceCloud(
//         userId: _authProvider!.user!.id,
//         amount: -amount,
//         transactionType: 'sponsoring_purchase',
//         description: 'شراء تمويل ${_getTierName(tier)} لمدة $days أيام',
//       );

//       // 🔄 Recharger les produits
//       await _loadSellerProducts();
//       await loadMarketplaceProducts();

//       // 📢 Notification
//       await _cloudFunctions.sendUserNotification(
//         userId: _authProvider!.user!.id,
//         title: 'تم شراء التمويل بنجاح! 🎊',
//         body: 'منتجك سيظهر في المقدمة لمدة $days أيام',
//         type: 'sponsoring_purchased',
//       );

//       return {
//         'success': true,
//         'amount': amount,
//         'days': days,
//         'tier': _getTierName(tier),
//         'message': 'تم شراء التمويل بنجاح!',
//       };

//     } catch (e) {
//       final errorMsg = 'فشل في شراء التمويل: $e';
//       _setError(errorMsg);
//       return {'success': false, 'error': errorMsg};
//     } finally {
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// 📈 OBTENIR LES STATISTIQUES DU MARCHÉ
//   Future<Map<String, dynamic>> getMarketplaceStats() async {
//     try {
//       final platformEarnings = await _cloudFunctions.getPlatformEarnings();
//       final totalInteractions = await _productRepository.getTotalInteractions();

//       return {
//         'success': true,
//         'stats': {
//           'totalProducts': _products.length,
//           'sponsoredProducts': _sponsoredProducts.length,
//           'sellerProducts': _sellerProducts.length,
//           'platformEarnings': platformEarnings['totalEarnings'] ?? 0,
//           'totalInteractions': totalInteractions['totalInteractions'] ?? 0,
//           'pendingInteractions': totalInteractions['pendingInteractions'] ?? 0,
//           'approvedEarnings': totalInteractions['approvedEarnings'] ?? 0,
//         },
//       };
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e.toString(),
//         'stats': {
//           'totalProducts': _products.length,
//           'sponsoredProducts': _sponsoredProducts.length,
//           'sellerProducts': _sellerProducts.length,
//         },
//       };
//     }
//   }

//   /// 🔍 RECHERCHER DES PRODUITS
//   Future<List<ProductModel>> searchProducts({
//     required String query,
//     String? category,
//     double? minPrice,
//     double? maxPrice,
//   }) async {
//     try {
//       _setLoading(true);
      
//       final results = await _productRepository.searchProducts(
//         query: query,
//         category: category,
//         minPrice: minPrice,
//         maxPrice: maxPrice,
//       );

//       return results;
//     } catch (e) {
//       _setError('فشل في البحث: $e');
//       return [];
//     } finally {
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// 🏷️ CHANGER LA CATÉGORIE
//   Future<void> changeCategory(String category) async {
//     _selectedCategory = category;
//     await loadMarketplaceProducts();
//   }

//   /// 🔄 CHANGER LE TYPE
//   Future<void> changeType(ProductType type) async {
//     _selectedType = type;
//     await loadMarketplaceProducts();
//   }

//   /// ⚙️ FILTRER LES PRODUITS
//   Future<void> filterProducts(MarketplaceFilter newFilter) async {
//     try {
//       _setLoading(true);
//       _filter = newFilter;
//       _applyFilters();
//     } catch (e) {
//       _setError('فشل في تصفية المنتجات: $e');
//     } finally {
//       _setLoading(false);
//       notifyListeners();
//     }
//   }

//   /// 🔄 ACTUALISER LES DONNÉES
//   Future<void> refreshMarketplace() async {
//     await loadMarketplaceProducts();
//     await _loadSellerProducts();
//   }

//   // ===============================================================
//   // MÉTHODES PRIVÉES - HELPERS
//   // ===============================================================

//   /// 💰 CALCULER LES GAINS
//   double _calculateEarnings(
//     ProductModel product, 
//     ProductInteractionType interactionType,
//     Map<String, dynamic> cloudResult,
//   ) {
//     double baseEarnings = 0.0;
    
//     switch (interactionType) {
//       case ProductInteractionType.view:
//         baseEarnings = product.participantEarnings * 0.5;
//         break;
//       case ProductInteractionType.share:
//         baseEarnings = product.participantEarnings;
//         break;
//       case ProductInteractionType.inquiry:
//         baseEarnings = product.participantEarnings * 0.8;
//         break;
//       case ProductInteractionType.purchase:
//         baseEarnings = product.participantEarnings * 2.0;
//         break;
//     }

//     final riskScore = cloudResult['riskScore'] ?? 0;
//     final riskMultiplier = 1.0 - (riskScore / 200.0);
    
//     return baseEarnings * riskMultiplier.clamp(0.5, 1.0);
//   }

//   /// 📱 OBTENIR LES INFORMATIONS DU DISPOSITIF
//   Future<Map<String, dynamic>> _getDeviceInfo() async {
//     final window = WidgetsBinding.instance.window;
    
//     return {
//       'userAgent': 'ReShare-Mobile-App',
//       'deviceHash': _authProvider?.user?.id ?? 'unknown',
//       'screenResolution': '${window.physicalSize.width}x${window.physicalSize.height}',
//       'platform': Platform.operatingSystem,
//       'platformVersion': Platform.operatingSystemVersion,
//       'appVersion': '1.0.0',
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     };
//   }

//   /// 📍 OBTENIR LA LOCALISATION (SIMULÉE)
//   Future<Map<String, dynamic>> _getUserLocation() async {
//     return {
//       'city': 'Tunis',
//       'country': 'Tunisia',
//       'latitude': 36.8065,
//       'longitude': 10.1815,
//       'accuracy': 100.0,
//     };
//   }

//   /// 📢 ENVOYER UNE NOTIFICATION D'INTERACTION
//   Future<void> _sendInteractionNotification(
//     ProductModel product,
//     ProductInteractionType interactionType,
//     double earnings,
//     bool requiresReview,
//   ) async {
//     final title = requiresReview ? 'تفاعل قيد المراجعة ⏳' : 'تهانينا! 🎊';
//     final body = requiresReview 
//         ? 'سيتم مراجعة ${_getInteractionTypeName(interactionType)} مع "${product.title}" قريباً'
//         : 'لقد ربحت ${earnings.toStringAsFixed(2)} د من ${_getInteractionTypeName(interactionType)} "${product.title}"';

//     await _cloudFunctions.sendUserNotification(
//       userId: _authProvider!.user!.id,
//       title: title,
//       body: body,
//       type: requiresReview ? 'interaction_pending' : 'interaction_rewarded',
//     );
//   }

//   /// 🏷️ NOM DU TYPE D'INTERACTION
//   String _getInteractionTypeName(ProductInteractionType type) {
//     switch (type) {
//       case ProductInteractionType.view:
//         return 'مشاهدة';
//       case ProductInteractionType.share:
//         return 'مشاركة';
//       case ProductInteractionType.inquiry:
//         return 'استفسار';
//       case ProductInteractionType.purchase:
//         return 'شراء';
//     }
//   }

//   /// 💰 PRIX DU SPONSORING
//   double _getSponsoringPrice(SponsoringTier tier, int days) {
//     double basePrice;
//     switch (tier) {
//       case SponsoringTier.topProduct:
//         basePrice = 20.0;
//         break;
//       case SponsoringTier.boostVisibility:
//         basePrice = 15.0;
//         break;
//       case SponsoringTier.bannerDisplay:
//         basePrice = 30.0;
//         break;
//     }
    
//     return basePrice * (days / 7);
//   }

//   /// 🏆 NOM DU TIER
//   String _getTierName(SponsoringTier tier) {
//     switch (tier) {
//       case SponsoringTier.topProduct:
//         return 'منتج مميز';
//       case SponsoringTier.boostVisibility:
//         return 'تعزيز الظهور';
//       case SponsoringTier.bannerDisplay:
//         return 'عرض بانر';
//     }
//   }

//   /// ⚙️ APPLIQUER LES FILTRES
//   void _applyFilters() {
//     List<ProductModel> filtered = List.from(_products);

//     if (_filter.minPrice != null) {
//       filtered = filtered.where((p) => p.price >= _filter.minPrice!).toList();
//     }

//     if (_filter.maxPrice != null) {
//       filtered = filtered.where((p) => p.price <= _filter.maxPrice!).toList();
//     }

//     if (_filter.sponsoredOnly) {
//       filtered = filtered.where((p) => p.isSponsored).toList();
//     }

//     if (_filter.cpcOnly) {
//       filtered = filtered.where((p) => p.type == ProductType.cpc).toList();
//     }

//     if (_filter.marketplaceOnly) {
//       filtered = filtered.where((p) => p.isMarketplace).toList();
//     }

//     switch (_filter.sortBy) {
//       case ProductSort.newest:
//         filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//         break;
//       case ProductSort.priceLow:
//         filtered.sort((a, b) => a.price.compareTo(b.price));
//         break;
//       case ProductSort.priceHigh:
//         filtered.sort((a, b) => b.price.compareTo(a.price));
//         break;
//       case ProductSort.mostViewed:
//         filtered.sort((a, b) => b.views.compareTo(a.views));
//         break;
//     }

//     _products = filtered;
//   }

//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     if (loading) _clearError();
//   }

//   void _setError(String error) {
//     _error = error;
//   }

//   void _clearError() {
//     _error = null;
//   }
// }

// class MarketplaceFilter {
//   final double? minPrice;
//   final double? maxPrice;
//   final bool sponsoredOnly;
//   final bool cpcOnly;
//   final bool marketplaceOnly;
//   final ProductSort sortBy;

//   MarketplaceFilter({
//     this.minPrice,
//     this.maxPrice,
//     this.sponsoredOnly = false,
//     this.cpcOnly = false,
//     this.marketplaceOnly = false,
//     this.sortBy = ProductSort.newest,
//   });

//   bool get hasFilters {
//     return minPrice != null ||
//         maxPrice != null ||
//         sponsoredOnly ||
//         cpcOnly ||
//         marketplaceOnly ||
//         sortBy != ProductSort.newest;
//   }

//   MarketplaceFilter copyWith({
//     double? minPrice,
//     double? maxPrice,
//     bool? sponsoredOnly,
//     bool? cpcOnly,
//     bool? marketplaceOnly,
//     ProductSort? sortBy,
//   }) {
//     return MarketplaceFilter(
//       minPrice: minPrice ?? this.minPrice,
//       maxPrice: maxPrice ?? this.maxPrice,
//       sponsoredOnly: sponsoredOnly ?? this.sponsoredOnly,
//       cpcOnly: cpcOnly ?? this.cpcOnly,
//       marketplaceOnly: marketplaceOnly ?? this.marketplaceOnly,
//       sortBy: sortBy ?? this.sortBy,
//     );
//   }
// }

// enum ProductSort {
//   newest,
//   priceLow,
//   priceHigh,
//   mostViewed,
// }