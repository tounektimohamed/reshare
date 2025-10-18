// // lib/data/models/product_model.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProductModel {
//   final String id;
//   final String sellerId;
//   final String title;
//   final String description;
//   final double price;
//   final List<String> images;
//   final String category;
//   final ProductStatus status;
//   final ProductType type;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
  
//   // Champs CPC
//   final double? cpcBudget;
//   final int? targetClicks;
//   final int achievedClicks;
//   final double cpcRate;
  
//   // Champs Marketplace
//   final bool isMarketplace;
//   final double marketplaceFee;
  
//   // Champs Sponsoring
//   final SponsoringTier? sponsoringTier;
//   final DateTime? sponsoringExpiry;
  
//   // Statistiques
//   final int views;
//   final int shares;
//   final int inquiries;
//   final bool isActive;

//   ProductModel({
//     required this.id,
//     required this.sellerId,
//     required this.title,
//     required this.description,
//     required this.price,
//     required this.images,
//     required this.category,
//     this.status = ProductStatus.pending,
//     this.type = ProductType.cpc,
//     required this.createdAt,
//     this.updatedAt,
//     this.cpcBudget,
//     this.targetClicks,
//     this.achievedClicks = 0,
//     this.cpcRate = 0.06,
//     this.isMarketplace = false,
//     this.marketplaceFee = 2.0,
//     this.sponsoringTier,
//     this.sponsoringExpiry,
//     this.views = 0,
//     this.shares = 0,
//     this.inquiries = 0,
//     this.isActive = true,
//   });

//   factory ProductModel.fromMap(Map<String, dynamic> map) {
//     return ProductModel(
//       id: map['id'] ?? '',
//       sellerId: map['sellerId'] ?? '',
//       title: map['title'] ?? '',
//       description: map['description'] ?? '',
//       price: (map['price'] ?? 0).toDouble(),
//       images: List<String>.from(map['images'] ?? []),
//       category: map['category'] ?? '',
//       status: _parseProductStatus(map['status']),
//       type: _parseProductType(map['type']),
//       createdAt: _parseDateTime(map['createdAt']),
//       updatedAt: _parseDateTime(map['updatedAt']),
//       cpcBudget: (map['cpcBudget'] ?? 0).toDouble(),
//       targetClicks: map['targetClicks'] ?? 0,
//       achievedClicks: map['achievedClicks'] ?? 0,
//       cpcRate: (map['cpcRate'] ?? 0.06).toDouble(),
//       isMarketplace: map['isMarketplace'] ?? false,
//       marketplaceFee: (map['marketplaceFee'] ?? 2.0).toDouble(),
//       sponsoringTier: _parseSponsoringTier(map['sponsoringTier']),
//       sponsoringExpiry: _parseDateTime(map['sponsoringExpiry']),
//       views: map['views'] ?? 0,
//       shares: map['shares'] ?? 0,
//       inquiries: map['inquiries'] ?? 0,
//       isActive: map['isActive'] ?? true,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'sellerId': sellerId,
//       'title': title,
//       'description': description,
//       'price': price,
//       'images': images,
//       'category': category,
//       'status': status.index,
//       'type': type.index,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt?.toIso8601String(),
//       'cpcBudget': cpcBudget,
//       'targetClicks': targetClicks,
//       'achievedClicks': achievedClicks,
//       'cpcRate': cpcRate,
//       'isMarketplace': isMarketplace,
//       'marketplaceFee': marketplaceFee,
//       'sponsoringTier': sponsoringTier?.index,
//       'sponsoringExpiry': sponsoringExpiry?.toIso8601String(),
//       'views': views,
//       'shares': shares,
//       'inquiries': inquiries,
//       'isActive': isActive,
//     };
//   }

//   // Getters calculés
//   int get remainingClicks => (targetClicks ?? 0) - achievedClicks;
//   double get totalSpent => achievedClicks * cpcRate;
//   double get remainingBudget => (cpcBudget ?? 0) - totalSpent;
//   bool get isSponsored => sponsoringTier != null && 
//       (sponsoringExpiry == null || sponsoringExpiry!.isAfter(DateTime.now()));
//   double get participantEarnings => cpcRate * 0.6;
//   double get platformEarnings => cpcRate * 0.4;

//   // Méthodes de parsing
//   static ProductStatus _parseProductStatus(dynamic status) {
//     if (status == null) return ProductStatus.pending;
//     if (status is int) return ProductStatus.values[status];
//     if (status is String) {
//       switch (status.toLowerCase()) {
//         case 'active': return ProductStatus.active;
//         case 'paused': return ProductStatus.paused;
//         case 'sold': return ProductStatus.sold;
//         case 'expired': return ProductStatus.expired;
//         default: return ProductStatus.pending;
//       }
//     }
//     return ProductStatus.pending;
//   }

//   static ProductType _parseProductType(dynamic type) {
//     if (type == null) return ProductType.cpc;
//     if (type is int) return ProductType.values[type];
//     if (type is String) {
//       switch (type.toLowerCase()) {
//         case 'marketplace': return ProductType.marketplace;
//         case 'hybrid': return ProductType.hybrid;
//         default: return ProductType.cpc;
//       }
//     }
//     return ProductType.cpc;
//   }

//   static SponsoringTier? _parseSponsoringTier(dynamic tier) {
//     if (tier == null) return null;
//     if (tier is int) return SponsoringTier.values[tier];
//     if (tier is String) {
//       switch (tier.toLowerCase()) {
//         case 'top_product': return SponsoringTier.topProduct;
//         case 'boost_visibility': return SponsoringTier.boostVisibility;
//         case 'banner_display': return SponsoringTier.bannerDisplay;
//         default: return null;
//       }
//     }
//     return null;
//   }

//   static DateTime _parseDateTime(dynamic value) {
//     if (value == null) return DateTime.now();
//     if (value is DateTime) return value;
//     if (value is Timestamp) return value.toDate();
//     if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
//     if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
//     return DateTime.now();
//   }

//   // Méthodes utilitaires
//   ProductModel copyWith({
//     String? id,
//     String? sellerId,
//     String? title,
//     String? description,
//     double? price,
//     List<String>? images,
//     String? category,
//     ProductStatus? status,
//     ProductType? type,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     double? cpcBudget,
//     int? targetClicks,
//     int? achievedClicks,
//     double? cpcRate,
//     bool? isMarketplace,
//     double? marketplaceFee,
//     SponsoringTier? sponsoringTier,
//     DateTime? sponsoringExpiry,
//     int? views,
//     int? shares,
//     int? inquiries,
//     bool? isActive,
//   }) {
//     return ProductModel(
//       id: id ?? this.id,
//       sellerId: sellerId ?? this.sellerId,
//       title: title ?? this.title,
//       description: description ?? this.description,
//       price: price ?? this.price,
//       images: images ?? this.images,
//       category: category ?? this.category,
//       status: status ?? this.status,
//       type: type ?? this.type,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       cpcBudget: cpcBudget ?? this.cpcBudget,
//       targetClicks: targetClicks ?? this.targetClicks,
//       achievedClicks: achievedClicks ?? this.achievedClicks,
//       cpcRate: cpcRate ?? this.cpcRate,
//       isMarketplace: isMarketplace ?? this.isMarketplace,
//       marketplaceFee: marketplaceFee ?? this.marketplaceFee,
//       sponsoringTier: sponsoringTier ?? this.sponsoringTier,
//       sponsoringExpiry: sponsoringExpiry ?? this.sponsoringExpiry,
//       views: views ?? this.views,
//       shares: shares ?? this.shares,
//       inquiries: inquiries ?? this.inquiries,
//       isActive: isActive ?? this.isActive,
//     );
//   }

//   // Pour activer le sponsoring
//   ProductModel withSponsoring(SponsoringTier tier, int days) {
//     return copyWith(
//       sponsoringTier: tier,
//       sponsoringExpiry: DateTime.now().add(Duration(days: days)),
//     );
//   }

//   // Pour incrémenter les statistiques
//   ProductModel incrementViews() {
//     return copyWith(views: views + 1);
//   }

//   ProductModel incrementShares() {
//     return copyWith(shares: shares + 1);
//   }

//   ProductModel incrementInquiries() {
//     return copyWith(inquiries: inquiries + 1);
//   }

//   ProductModel incrementClicks() {
//     return copyWith(achievedClicks: achievedClicks + 1);
//   }
// }

// enum ProductStatus {
//   pending,
//   active,
//   paused,
//   sold,
//   expired,
// }

// enum ProductType {
//   cpc,
//   marketplace,
//   hybrid,
// }

// enum SponsoringTier {
//   topProduct,      // 20 DT
//   boostVisibility, // 15 DT
//   bannerDisplay,   // 30 DT
// }

// class ProductInteraction {
//   final String id;
//   final String productId;
//   final String userId;
//   final ProductInteractionType type;
//   final double earnings;
//   final DateTime timestamp;
//   final Map<String, dynamic>? metadata;

//   ProductInteraction({
//     required this.id,
//     required this.productId,
//     required this.userId,
//     required this.type,
//     required this.earnings,
//     required this.timestamp,
//     this.metadata, required status,
//   });

//   factory ProductInteraction.fromMap(Map<String, dynamic> map) {
//     return ProductInteraction(
//       id: map['id'] ?? '',
//       productId: map['productId'] ?? '',
//       userId: map['userId'] ?? '',
//       type: _parseInteractionType(map['type']),
//       earnings: (map['earnings'] ?? 0).toDouble(),
//       timestamp: DateTime.parse(map['timestamp']),
//       metadata: map['metadata'] != null 
//           ? Map<String, dynamic>.from(map['metadata'])
//           : null,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'productId': productId,
//       'userId': userId,
//       'type': type.index,
//       'earnings': earnings,
//       'timestamp': timestamp.toIso8601String(),
//       'metadata': metadata,
//     };
//   }

//   static ProductInteractionType _parseInteractionType(dynamic type) {
//     if (type == null) return ProductInteractionType.view;
//     if (type is int) return ProductInteractionType.values[type];
//     if (type is String) {
//       switch (type.toLowerCase()) {
//         case 'share': return ProductInteractionType.share;
//         case 'inquiry': return ProductInteractionType.inquiry;
//         case 'purchase': return ProductInteractionType.purchase;
//         default: return ProductInteractionType.view;
//       }
//     }
//     return ProductInteractionType.view;
//   }
// }

// enum ProductInteractionType {
//   view,     // Vue simple
//   share,    // Partage
//   inquiry,  // Demande d'information
//   purchase, // Achat
// }