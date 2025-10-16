import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:reshare/data/models/click_model.dart';
import 'package:reshare/data/models/user_model.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../../presentation/widgets/campaign/campaign_card.dart';
import '../../../../presentation/widgets/earnings/stats_grid.dart';
import '../providers/dashboard_provider.dart';
import 'package:reshare/core/services/cloud_functions_service.dart';
import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout pour Timestamp

class ADHomeScreen extends StatefulWidget {
  const ADHomeScreen({super.key});

  @override
  State<ADHomeScreen> createState() => _ADHomeScreenState();
}

class _ADHomeScreenState extends State<ADHomeScreen> {
  bool _initialLoadComplete = false;
  bool _isRefreshing = false;
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  double? _platformEarnings;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadPlatformEarnings();
  }

  Future<void> _loadPlatformEarnings() async {
    try {
      final result = await _cloudFunctions.getPlatformEarnings();
      if (result['success'] == true) {
        setState(() {
          _platformEarnings =
              double.tryParse(result['platformEarnings']) ?? 0.0;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load platform earnings: $e');
    }
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      try {
        await provider.loadDashboardData();
      } catch (e) {
        print('❌ Error in initial load: $e');
      }

      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      await provider.refreshDashboard();
    } catch (e) {
      print('❌ Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// ✅ VALIDER UN CLIC MANUELLEMENT
  Future<void> _approveClick(String clickId, {double? adjustedEarnings}) async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) return;

      final result = await _cloudFunctions.approveClick(
        clickId: clickId,
        adminId: authProvider.user!.id,
        adjustedEarnings: adjustedEarnings,
        notes: 'تمت الموافقة من لوحة التحكم',
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('تمت الموافقة على النقرة بنجاح');
        // Recharger les données
        _refreshData();
      } else {
        _showErrorSnackBar(result['error'] ?? 'فشل في الموافقة على النقرة');
      }
    } catch (e) {
      _showErrorSnackBar('فشل في معالجة الطلب: $e');
    }
  }

  /// 🚨 REFUSER UN CLIC MANUELLEMENT
  Future<void> _rejectClick(String clickId, String reason) async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) return;

      final result = await _cloudFunctions.rejectClick(
        clickId: clickId,
        adminId: authProvider.user!.id,
        reason: reason,
        evidence: 'رفض من لوحة التحكم الرئيسية',
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('تم رفض النقرة بنجاح');
        // Recharger les données
        _refreshData();
      } else {
        _showErrorSnackBar(result['error'] ?? 'فشل في رفض النقرة');
      }
    } catch (e) {
      _showErrorSnackBar('فشل في معالجة الطلب: $e');
    }
  }

  /// 📋 OBTENIR LES CLICS EN ATTENTE DE RÉVISION
  Future<void> _loadPendingClicks() async {
    try {
      final result = await _cloudFunctions.getPendingClicks(limit: 50, page: 1);

      if (result['success'] == true) {
        final pendingClicks = result['clicks'] ?? [];
        _showPendingClicksDialog(pendingClicks);
      } else {
        _showErrorSnackBar('فشل في تحميل النقرات المعلقة');
        // Fallback: montrer une liste vide
        _showPendingClicksDialog([]);
      }
    } catch (e) {
      print('Fallback for getPendingClicks: $e');
      _showErrorSnackBar('فشل في تحميل النقرات المعلقة: $e');
      // Fallback: montrer une liste vide
      _showPendingClicksDialog([]);
    }
  }

  /// 🎯 AFFICHER LES STATISTIQUES DE FRAUDE (avec fallback)
  Future<void> _showFraudStats() async {
    try {
      final result = await _cloudFunctions.getFraudDetectionStats();

      if (result['success'] == true) {
        final stats = result['stats'] ?? {};
        _showFraudStatsDialog(stats);
      } else {
        _showErrorSnackBar('فشل في تحميل إحصائيات الكشف عن الاحتيال');
        // Fallback: stats vides
        _showFraudStatsDialog({});
      }
    } catch (e) {
      print('Fallback for getFraudDetectionStats: $e');
      _showErrorSnackBar('فشل في تحميل الإحصائيات: $e');
      // Fallback: stats vides
      _showFraudStatsDialog({});
    }
  }

  /// 🔄 METTRE À JOUR LE STATUT D'UN CLIC
  Future<void> _updateClickStatus(
    String clickId,
    String newStatus, {
    String? reason,
    double? adjustedEarnings,
  }) async {
    try {
      final result = await _cloudFunctions.updateClickStatus(
        clickId: clickId,
        newStatus: newStatus,
        reason: reason ?? 'تم التحديث من لوحة التحكم',
        adjustedEarnings: adjustedEarnings,
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('تم تحديث حالة النقرة بنجاح');
        _refreshData();
      } else {
        _showErrorSnackBar(result['error'] ?? 'فشل في تحديث حالة النقرة');
      }
    } catch (e) {
      _showErrorSnackBar('فشل في تحديث حالة النقرة: $e');
    }
  }

  /// 🎯 AFFICHER LA DIALOGUE DES CLICS EN ATTENTE
  void _showPendingClicksDialog(List<dynamic> pendingClicks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'النقرات المعلقة للمراجعة',
          style: TextStyle(fontFamily: 'Tajawal'),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pendingClicks.length,
            itemBuilder: (context, index) {
              final click = pendingClicks[index];
              return _buildPendingClickItem(click);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  /// 🏗️ CONSTRUIRE UN ÉLÉMENT DE CLIC EN ATTENTE
  Widget _buildPendingClickItem(Map<String, dynamic> click) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.pending_rounded,
            color: AppColors.warning,
            size: 20,
          ),
        ),
        title: Text(
          click['campaignTitle'] ?? 'حملة غير معروفة',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المستخدم: ${click['participantName'] ?? 'مستخدم مجهول'}',
              style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal'),
            ),
            Text(
              'مستوى الخطورة: ${_getRiskLevelText(click['participantRiskLevel'])}',
              style: TextStyle(
                fontSize: 12,
                color: _getRiskLevelColor(click['participantRiskLevel']),
                fontFamily: 'Tajawal',
              ),
            ),
            if (click['fraudFlags'] != null &&
                (click['fraudFlags'] as List).isNotEmpty)
              Text(
                'إشارات: ${(click['fraudFlags'] as List).join(', ')}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontFamily: 'Tajawal',
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 NOUVEAU: BOUTON DÉTAILS
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.blue),
              onPressed: () => _showClickDetailsDialog(click),
              tooltip: 'تفاصيل النقرة',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _showApproveDialog(click['id']),
              tooltip: 'موافقة',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _showRejectDialog(click['id']),
              tooltip: 'رفض',
            ),
          ],
        ),
        // 🔥 NOUVEAU: APPUI LONG POUR DÉTAILS
        onLongPress: () => _showClickDetailsDialog(click),
      ),
    );
  }

  /// 🎯 DIALOGUE DE DÉTAILS DU CLIC - NOUVEAU
  void _showClickDetailsDialog(Map<String, dynamic> click) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تفاصيل النقرة',
          style: TextStyle(fontFamily: 'Tajawal'),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildClickDetailRow(
                icon: '🆔',
                label: 'ID de clic',
                value: click['id'] ?? 'غير متوفر',
              ),
              _buildClickDetailRow(
                icon: '🕒',
                label: 'Date du clic',
                value: _formatClickDate(click['clickedAt']),
              ),
              _buildClickDetailRow(
                icon: '👤',
                label: 'Utilisateur',
                value: click['participantName'] ?? 'مستخدم مجهول',
              ),
              _buildClickDetailRow(
                icon: '📣',
                label: 'Campagne',
                value: click['campaignTitle'] ?? 'حملة غير معروفة',
              ),
              _buildClickDetailRow(
                icon: '💰',
                label: 'Gain utilisateur',
                value: '${(click['earnings'] ?? 0).toStringAsFixed(3)} د',
              ),
              _buildClickDetailRow(
                icon: '🪙',
                label: 'Gain plateforme',
                value: '${(click['platformEarnings'] ?? 0).toStringAsFixed(3)} د',
              ),
              _buildClickDetailRow(
                icon: '📱',
                label: 'User Agent',
                value: click['userAgent'] ?? 'غير معروف',
              ),
              _buildClickDetailRow(
                icon: '🌍',
                label: 'Adresse IP',
                value: click['ip'] ?? 'غير متوفر',
              ),
              _buildClickDetailRow(
                icon: '📅',
                label: 'Délai de libération',
                value: _formatReleaseTime(click['releaseEligibleAt']),
              ),
              _buildClickDetailRow(
                icon: '⚠️',
                label: 'Statut de vérification',
                value: _getVerificationStatusText(click['status']),
                statusColor: _getStatusColor(click['status']),
              ),
              
              // 🔥 SECTION STATUT DE RISQUE
              if (click['participantRiskLevel'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRiskLevelColor(click['participantRiskLevel']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getRiskLevelColor(click['participantRiskLevel']).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: _getRiskLevelColor(click['participantRiskLevel']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مستوى الخطورة',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getRiskLevelColor(click['participantRiskLevel']),
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            Text(
                              _getRiskLevelText(click['participantRiskLevel']),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 🔥 SECTION INDICATEURS DE FRAUDE
              if (click['fraudFlags'] != null && (click['fraudFlags'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'إشارات مشبوهة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (click['fraudFlags'] as List).map((flag) {
                          return Chip(
                            label: Text(
                              flag.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            backgroundColor: Colors.red.withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // 🔥 BOUTON FERMER
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إغلاق',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          
          // 🔥 BOUTONS D'ACTION SI EN ATTENTE
          if (click['status'] == 'pending' || click['status'] == 'suspicious') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialogue de détails
                _showRejectDialog(click['id']);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(
                'رفض',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialogue de détails
                _showApproveDialog(click['id']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'موافقة',
                style: TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🏗️ CONSTRUIRE UNE LIGNE DE DÉTAIL DU CLIC - NOUVEAU
  Widget _buildClickDetailRow({
    required String icon,
    required String label,
    required String value,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Label et valeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor ?? Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 FORMATER LA DATE DU CLIC - NOUVEAU
  String _formatClickDate(dynamic clickedAt) {
    try {
      if (clickedAt == null) return 'غير متوفر';
      
      DateTime date;
      if (clickedAt is Timestamp) {
        date = clickedAt.toDate();
      } else if (clickedAt is DateTime) {
        date = clickedAt;
      } else if (clickedAt is String) {
        date = DateTime.parse(clickedAt);
      } else {
        return 'غير متوفر';
      }
      
      final format = DateFormat('dd MMMM yyyy à HH:mm:ss', 'fr');
      return format.format(date);
    } catch (e) {
      return 'غير متوفر';
    }
  }

  /// ⏰ FORMATER LE TEMPS DE LIBÉRATION - NOUVEAU
  String _formatReleaseTime(dynamic releaseEligibleAt) {
    try {
      if (releaseEligibleAt == null) return 'غير محدد';
      
      DateTime releaseDate;
      if (releaseEligibleAt is Timestamp) {
        releaseDate = releaseEligibleAt.toDate();
      } else if (releaseEligibleAt is DateTime) {
        releaseDate = releaseEligibleAt;
      } else {
        return 'غير محدد';
      }
      
      final now = DateTime.now();
      final difference = releaseDate.difference(now);
      
      if (difference.inMinutes < 0) {
        return 'منتهي';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ساعة';
      } else {
        return '${difference.inDays} يوم';
      }
    } catch (e) {
      return 'غير محدد';
    }
  }

  /// 📋 OBTENIR LE TEXTE DU STATUT DE VÉRIFICATION - NOUVEAU
  String _getVerificationStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'valid':
        return 'مقبول';
      case 'suspicious':
        return 'مشبوه';
      case 'invalid':
        return 'مرفوض';
      case 'fraud':
        return 'احتيالي';
      default:
        return 'غير معروف';
    }
  }

  /// 🎨 OBTAINIR LA COULEUR DU STATUT - NOUVEAU
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'valid':
        return Colors.green;
      case 'suspicious':
        return Colors.orange;
      case 'invalid':
        return Colors.red;
      case 'fraud':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 🔥 NOUVEAU: AFFICHER TOUS LES CLICS AVEC FILTRES
  void _showAllClicksManagement() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'إدارة جميع النقرات',
              style: TextStyle(fontFamily: 'Tajawal'),
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 FILTRES
                  _buildClickFilters(),
                  const SizedBox(height: 16),
                  
                  // 🔥 LISTE DES CLICS
                  Expanded(
                    child: _buildAllClicksList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🏗️ CONSTRUIRE LES FILTRES - NOUVEAU
  Widget _buildClickFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'تصفية النقرات',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('في الانتظار'),
                onSelected: (_) {},
                selected: false,
              ),
              FilterChip(
                label: const Text('مقبول'),
                onSelected: (_) {},
                selected: false,
              ),
              FilterChip(
                label: const Text('مشبوه'),
                onSelected: (_) {},
                selected: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏗️ CONSTRUIRE LA LISTE DE TOUS LES CLICS - NOUVEAU
  Widget _buildAllClicksList() {
    return FutureBuilder(
      future: _cloudFunctions.getPendingClicks(limit: 100, page: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في التحميل: ${snapshot.error}'),
          );
        }

        final result = snapshot.data;
        if (result == null || result['success'] != true) {
          return const Center(
            child: Text('لا توجد نقرات للعرض'),
          );
        }

        final clicks = result['clicks'] ?? [];

        if (clicks.isEmpty) {
          return const Center(
            child: Text('لا توجد نقرات للعرض'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: clicks.length,
          itemBuilder: (context, index) {
            final click = clicks[index];
            return _buildPendingClickItem(click);
          },
        );
      },
    );
  }

  // ✅ DIALOGUE DE CONFIRMATION POUR L'APPROBATION (EXISTANT)
  void _showApproveDialog(String clickId) {
    double adjustedEarnings = 0.06; // Valeur par défaut

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'موافقة على النقرة',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'هل تريد الموافقة على هذه النقرة؟',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'المكاسب:',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: adjustedEarnings.toStringAsFixed(3),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null) {
                          setState(() {
                            adjustedEarnings = parsed;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        suffixText: 'دينار',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveClick(clickId, adjustedEarnings: adjustedEarnings);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'موافقة',
                style: TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 DIALOGUE DE CONFIRMATION POUR LE REJET (EXISTANT)
  void _showRejectDialog(String clickId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'رفض النقرة',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'حدد سبب الرفض:',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                border: OutlineInputBorder(),
                hintText: 'أدخل سبب رفض النقرة...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _rejectClick(clickId, reasonController.text.trim());
              } else {
                _showErrorSnackBar('يرجى إدخال سبب الرفض');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'رفض',
              style: TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 AFFICHER LES STATISTIQUES DE FRAUDE

  /// 📊 DIALOGUE DES STATISTIQUES DE FRAUDE (EXISTANT)
  void _showFraudStatsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إحصائيات الكشف عن الاحتيال',
          style: TextStyle(fontFamily: 'Tajawal'),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFraudStatItem(
                'إجمالي النقرات',
                stats['totalClicks']?.toString() ?? '0',
              ),
              _buildFraudStatItem(
                'النقرات الصالحة',
                stats['validClicks']?.toString() ?? '0',
              ),
              _buildFraudStatItem(
                'النقرات المشبوهة',
                stats['suspiciousClicks']?.toString() ?? '0',
              ),
              _buildFraudStatItem(
                'النقرات الاحتيالية',
                stats['fraudulentClicks']?.toString() ?? '0',
              ),
              _buildFraudStatItem(
                'معدل الاحتيال',
                '${stats['fraudRate']?.toString() ?? '0'}%',
              ),
              _buildFraudStatItem(
                'متوسط درجة الخطورة',
                stats['avgRiskScore']?.toString() ?? '0',
              ),
              _buildFraudStatItem(
                'المراجعات اليدوية',
                stats['manualReviews']?.toString() ?? '0',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudStatItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Tajawal')),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires (EXISTANTES)
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'عالي';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return 'غير معروف';
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 🔥 NOUVELLE SECTION ADMIN AVEC BOUTON SUPPLEMENTAIRE
  Widget _buildAdminSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أدوات المدير 🛠️',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAdminActionItem(
                  icon: Icons.pending_actions_rounded,
                  title: 'المراجعات المعلقة',
                  color: AppColors.warning,
                  onTap: _loadPendingClicks,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdminActionItem(
                  icon: Icons.analytics_rounded,
                  title: 'إحصائيات الاحتيال',
                  color: AppColors.error,
                  onTap: _showFraudStats,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdminActionItem(
                  icon: Icons.security_rounded,
                  title: 'إدارة المخاطر',
                  color: AppColors.primary,
                  onTap: () {
                    _showRiskManagementOptions();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 🔥 NOUVEAU BOUTON POUR LA GESTION COMPLÈTE DES CLICS
          Row(
            children: [
              Expanded(
                child: _buildAdminActionItem(
                  icon: Icons.list_alt_rounded,
                  title: 'إدارة النقرات',
                  color: Colors.blue,
                  onTap: _showAllClicksManagement,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRiskManagementOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إدارة المخاطر والاحتيال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 16),
              _buildRiskManagementOption(
                icon: Icons.list_alt_rounded,
                title: 'تقرير الاحتيال التفصيلي',
                onTap: () {
                  Navigator.pop(context);
                  _generateDetailedFraudReport();
                },
              ),
              _buildRiskManagementOption(
                icon: Icons.block_rounded,
                title: 'حظر عناوين IP',
                onTap: () {
                  Navigator.pop(context);
                  _showIPManagement();
                },
              ),
              _buildRiskManagementOption(
                icon: Icons.settings_rounded,
                title: 'إعدادات الكشف',
                onTap: () {
                  Navigator.pop(context);
                  _showDetectionSettings();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskManagementOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontFamily: 'Tajawal')),
      onTap: onTap,
    );
  }

  Future<void> _generateDetailedFraudReport() async {
    try {
      final result = await _cloudFunctions.getFraudReports();
      if (result['success'] == true) {
        _showDetailedReport(result);
      } else {
        _showErrorSnackBar('فشل في إنشاء التقرير');
      }
    } catch (e) {
      _showErrorSnackBar('فشل في إنشاء التقرير: $e');
    }
  }

  void _showDetailedReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تقرير الاحتيال التفصيلي',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الفترة: ${report['period']}',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              Text(
                'إجمالي النقرات: ${report['totalClicks']}',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              Text(
                'معدل الاحتيال: ${report['fraudRate']}%',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _showIPManagement() {
    _showSuccessSnackBar('إدارة عناوين IP - قريباً');
  }

  void _showDetectionSettings() {
    _showSuccessSnackBar('إعدادات الكشف - قريباً');
  }

  // 🔥 Écran de chargement initial (EXISTANT)
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWelcomeSectionShimmer(),
            const SizedBox(height: 24),
            _buildQuickStatsShimmer(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildEarningsOverviewShimmer(),
            const SizedBox(height: 24),
            _buildCampaignsShimmer(),
          ],
        ),
      ),
    );
  }

  // Les méthodes existantes restent inchangées...
  Widget _buildWelcomeSection(DashboardProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'استمر في المشاركة لزيادة أرباحك',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 16),
                _buildDailyGoalProgress(provider),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSectionShimmer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير! ☀️';
    } else if (hour < 18) {
      return 'مساء الخير! 🌤️';
    } else {
      return 'مساء الخير! 🌙';
    }
  }

  Widget _buildDailyGoalProgress(DashboardProvider provider) {
    final todayClicks = provider.stats.weeklyClicks;
    final goalProgress = (todayClicks / 5.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              if (goalProgress > 0)
                Container(
                  width: 16 * goalProgress,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            'الهدف اليومي: $todayClicks/5 نقرات',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.account_balance_wallet_rounded,
            value: '${stats.availableBalance.toStringAsFixed(3)} د',
            label: 'الرصيد المتاح',
            color: AppColors.success,
          ),
          _buildStatItem(
            icon: Icons.pending_actions_rounded,
            value: '${stats.pendingBalance.toStringAsFixed(3)} د',
            label: 'في الانتظار',
            color: AppColors.warning,
          ),
          _buildStatItem(
            icon: Icons.attach_money_rounded,
            value: '${stats.totalEarnings.toStringAsFixed(3)} د',
            label: 'إجمالي الأرباح',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItemShimmer(),
          _buildStatItemShimmer(),
          _buildStatItemShimmer(),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItemShimmer() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات السريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.campaign_rounded,
                title: 'الحملات',
                subtitle: 'شارك واربح',
                color: AppColors.primary,
                onTap: () {
                  // Navigate to campaigns
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.people_alt_rounded,
                title: 'الإحالات',
                subtitle: 'ادعُ أصدقاءك',
                color: AppColors.secondary,
                onTap: () {
                  // Navigate to referrals
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.attach_money_rounded,
                title: 'سحب الأموال',
                subtitle: 'احصل على أرباحك',
                color: AppColors.success,
                onTap: () {
                  // Navigate to withdrawal
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Tajawal',
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsOverview(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ملخص الأرباح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Tajawal',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'هذا الأسبوع',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Aperçu des soldes
          _buildBalanceOverview(stats),
          const SizedBox(height: 16),

          // Stats hebdomadaires
          Row(
            children: [
              _buildEarningStat(
                value: '${stats.weeklyEarnings.toStringAsFixed(3)} د',
                label: 'أرباح هذا الأسبوع',
                change: stats.weeklyGrowth,
              ),
              const SizedBox(width: 20),
              _buildEarningStat(
                value: stats.weeklyClicks.toString(),
                label: 'نقرات هذا الأسبوع',
                change: stats.weeklyClicks > 0 ? 12.5 : 0.0,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Grid
          StatsGrid(stats: stats),
        ],
      ),
    );
  }

  Widget _buildEarningsOverviewShimmer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildEarningStatShimmer()),
              const SizedBox(width: 20),
              Expanded(child: _buildEarningStatShimmer()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningStat({
    required String value,
    required String label,
    required double change,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                change >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: change >= 0 ? AppColors.success : AppColors.error,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${change.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: change >= 0 ? AppColors.success : AppColors.error,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningStatShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceOverview(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBalanceItem(
            title: 'المتاح للسحب',
            amount: stats.availableBalance,
            color: AppColors.success,
          ),
          Container(height: 40, width: 1, color: AppColors.outline),
          _buildBalanceItem(
            title: 'قيد المراجعة',
            amount: stats.pendingBalance,
            color: AppColors.warning,
          ),
          Container(height: 40, width: 1, color: AppColors.outline),
          _buildBalanceItem(
            title: 'الإجمالي',
            amount: stats.totalEarnings,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required String title,
    required double amount,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(3)} د',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'عرض الكل',
              style: TextStyle(color: AppColors.primary, fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCampaigns(List<CampaignModel> campaigns) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: campaigns.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return SizedBox(width: 280, child: CampaignCard(campaign: campaign));
        },
      ),
    );
  }

  Widget _buildAvailableCampaigns(
    List<CampaignModel> campaigns,
    DashboardProvider provider,
  ) {
    if (provider.isLoading && campaigns.isEmpty) {
      return _buildLoadingCampaigns();
    }

    if (campaigns.isEmpty) {
      return _buildEmptyCampaigns();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: campaigns
            .take(3)
            .map(
              (campaign) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CampaignCard(campaign: campaign),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLoadingCampaigns() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _CampaignShimmer(),
          SizedBox(height: 12),
          _CampaignShimmer(),
          SizedBox(height: 12),
          _CampaignShimmer(),
        ],
      ),
    );
  }

  Widget _buildCampaignsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _CampaignShimmer(),
              SizedBox(height: 12),
              _CampaignShimmer(),
              SizedBox(height: 12),
              _CampaignShimmer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCampaigns() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حملات متاحة حالياً',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ارجع لاحقاً للتحقق من الحملات الجديدة',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<ClickModel> recentClicks) {
    final displayedClicks = recentClicks.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النشاط الحديث',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),

          if (displayedClicks.isEmpty)
            _buildEmptyActivity()
          else
            Column(
              children: displayedClicks
                  .map((click) => _buildActivityItem(click))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ClickModel click) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getClickStatusColor(click.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _getClickStatusIcon(click.status),
              color: _getClickStatusColor(click.status),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  click.campaignTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTime(click.clickedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${click.earnings.toStringAsFixed(3)} د',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Column(
      children: [
        Icon(
          Icons.history_rounded,
          size: 64,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'لا يوجد نشاط حديث',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سيظهر نشاطك هنا عند مشاركة الحملات',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.7),
            fontFamily: 'Tajawal',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickShareButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Quick share functionality
        _showQuickShareOptions();
      },
      icon: const Icon(Icons.share_rounded),
      label: const Text(
        'مشاركة سريعة',
        style: TextStyle(fontFamily: 'Tajawal'),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }

  void _showQuickShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مشاركة سريعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر حملة للمشاركة السريعة...',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Color _getClickStatusColor(ClickStatus status) {
    switch (status) {
      case ClickStatus.valid:
        return AppColors.success;
      case ClickStatus.pending:
        return AppColors.warning;
      case ClickStatus.suspicious:
        return AppColors.warning;
      case ClickStatus.invalid:
        return AppColors.error;
      case ClickStatus.fraud:
        return AppColors.error;
    }
  }

  IconData _getClickStatusIcon(ClickStatus status) {
    switch (status) {
      case ClickStatus.valid:
        return Icons.check_circle_rounded;
      case ClickStatus.pending:
        return Icons.pending_rounded;
      case ClickStatus.suspicious:
        return Icons.warning_rounded;
      case ClickStatus.invalid:
        return Icons.cancel_rounded;
      case ClickStatus.fraud:
        return Icons.block_rounded;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final stats = dashboardProvider.stats;
        final availableCampaigns = dashboardProvider.availableCampaigns;
        final recommendedCampaigns = dashboardProvider.recommendedCampaigns;
        final recentClicks = dashboardProvider.recentClicks;

        // 🔥 CORRECTION: Afficher le loading initial
        if (!_initialLoadComplete && !dashboardProvider.isLoading) {
          return _buildLoadingScreen();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header Sections
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(dashboardProvider),
                      const SizedBox(height: 24),
                      if (_platformEarnings != null) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '💰 أرباح المنصّة: ${_platformEarnings!.toStringAsFixed(3)} د',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Quick Stats
                      _buildQuickStats(stats),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Earnings Overview
                      _buildEarningsOverview(stats),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Recommended Campaigns Section
                if (recommendedCampaigns.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'الحملات الموصى بها 🔥',
                      onSeeAll: () {
                        // Navigate to campaigns with recommended filter
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: _buildRecommendedCampaigns(recommendedCampaigns),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                ],

                // Available Campaigns Section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'الحملات المتاحة',
                    onSeeAll: () {
                      // Navigate to all campaigns
                    },
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 16)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 12,
                          left: 16,
                          right: 16,
                        ),
                        child: CampaignCard(
                          campaign: availableCampaigns[index],
                        ),
                      );
                    },
                    childCount: availableCampaigns.length > 3
                        ? 3
                        : availableCampaigns.length,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 24)),

                // Recent Activity Section
                SliverToBoxAdapter(child: _buildRecentActivity(recentClicks)),
                SliverToBoxAdapter(child: const SizedBox(height: 24)),

                // 🔥 NOUVEAU: Section Admin pour la gestion des clics
                if (context.read<AuthProvider>().user?.userType ==
                    UserType.admin) ...[
                  SliverToBoxAdapter(child: _buildAdminSection()),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                ],
              ],
            ),
          ),

          // 🔥 NOUVEAU: Floating Action Button for quick share
          floatingActionButton: _buildQuickShareButton(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}

class _CampaignShimmer extends StatelessWidget {
  const _CampaignShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}