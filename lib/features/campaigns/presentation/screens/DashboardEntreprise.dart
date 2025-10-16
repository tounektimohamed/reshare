import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/campaigns/presentation/screens/create_campaign_with_image_screen.dart';
import 'package:reshare/presentation/widgets/campaign/cr%C3%A9ationcampagne.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/services/cloud_functions_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService();
  String _selectedTimeRange = '7days';
  List<CampaignData> _campaigns = [];
  BusinessStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _cloudFunctions.getBusinessCampaigns();
        if (!mounted) return;

        if (result['success'] == true) {
          final campaignsData = (result['campaigns'] as List?) ?? [];
          final statsData = result['stats'];

          setState(() {
            _campaigns = campaignsData
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (data) => CampaignData.fromMap(
                    Map<String, dynamic>.from(
                      data.map((key, value) => MapEntry(key.toString(), value)),
                    ),
                  ),
                )
                .toList();
            _stats = statsData is Map<String, dynamic>
                ? BusinessStats.fromMap(statsData)
                : null;
          });
        } else {
          setState(() {
            _campaigns = [];
            _stats = null;
            _errorMessage = result['message']?.toString();
          });
        }
      } catch (e) {
        print('Error loading campaigns: $e');
        if (!mounted) return;
        setState(() {
          _campaigns = [];
          _stats = null;
          _errorMessage = 'حدث خطأ أثناء تحميل إحصائيات الحملات';
        });
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _campaigns = [];
        _stats = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('لوحة تحكم الحملات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateCampaignWithImageScreen(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCampaigns,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(_errorMessage!),
              ],
              if (_campaigns.isEmpty && !_isLoading && _errorMessage == null)
                _buildEmptyState(),
              if (_campaigns.isNotEmpty) ...[
                // Filtres
                _buildFilters(),
                const SizedBox(height: 16),

                // Statistiques rapides
                _buildQuickStats(),
                const SizedBox(height: 16),

                // Graphiques de performance
                _buildPerformanceCharts(),
                const SizedBox(height: 16),

                // Liste des campagnes
                _buildCampaignsList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTimeRange,
                decoration: const InputDecoration(
                  labelText: 'الفترة الزمنية',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '7days', child: Text('آخر 7 أيام')),
                  DropdownMenuItem(value: '30days', child: Text('آخر 30 يوم')),
                  DropdownMenuItem(value: '90days', child: Text('آخر 90 يوم')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTimeRange = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = _stats;
    final totalSpent =
        stats?.totalSpent ??
        _campaigns.fold(0.0, (sum, campaign) => sum! + campaign.spent);
    final totalBudget =
        stats?.totalBudget ??
        _campaigns.fold(0.0, (sum, campaign) => sum! + campaign.budget);
    final totalClicks = stats != null
        ? stats.totalClicks.toInt()
        : _campaigns.fold(0, (sum, campaign) => sum + campaign.totalClicks);
    final activeCampaigns =
        stats?.activeCampaigns ?? _campaigns.where((c) => c.isActive).length;
    final totalCampaigns = stats?.totalCampaigns ?? _campaigns.length;
    final averageCtr = (stats?.averageCTR ?? _calculateAverageCTR()).toDouble();
    final budgetUtilization =
        stats?.budgetUtilization ??
        ((totalBudget ?? 0) > 0 ? ((totalSpent ?? 0) / (totalBudget ?? 1)) * 100 : 0);

    return Column(
      children: [
        const Text(
          'نظرة عامة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'إجمالي الإنفاق',
              '${totalSpent?.toStringAsFixed(0) ?? '0'} د',
              (totalBudget != null && totalBudget > 0)
                  ? 'من ${totalBudget!.toStringAsFixed(0)} د ميزانية'
                  : 'عبر جميع الحملات',
              Colors.blue,
              Icons.attach_money,
            ),
            _buildStatCard(
              'إجمالي النقرات',
              totalClicks.toString(),
              'نقرة موثوقة',
              Colors.green,
              Icons.touch_app,
            ),
            _buildStatCard(
              'الحملات النشطة',
              activeCampaigns.toString(),
              'من $totalCampaigns',
              Colors.orange,
              Icons.campaign,
            ),
            _buildStatCard(
              'استهلاك الميزانية',
              '${budgetUtilization.toStringAsFixed(1)}%',
              'متوسط CTR: ${averageCtr.toStringAsFixed(1)}%',
              Colors.purple,
              Icons.insights,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts() {
    if (_campaigns.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'لا توجد بيانات لعرضها',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أداء الحملات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                series: <CartesianSeries<CampaignData, String>>[
                  ColumnSeries<CampaignData, String>(
                    dataSource: _campaigns.take(5).toList(),
                    xValueMapper: (CampaignData data, _) =>
                        data.title.length > 10
                        ? '${data.title.substring(0, 10)}...'
                        : data.title,
                    yValueMapper: (CampaignData data, _) => data.ctr,
                    name: 'CTR %',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsList() {
    if (_campaigns.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.campaign, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'لا توجد حملات حالياً',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'أنشئ حملتك الأولى لتبدأ في جلب النقرات',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حملاتك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._campaigns
                .map((campaign) => _buildCampaignItem(campaign))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignItem(CampaignData campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Image de la campagne
            if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: campaign.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Contenu de la campagne
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut de la campagne
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: campaign.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      campaign.isActive ? Icons.play_arrow : Icons.pause,
                      color: campaign.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Détails de la campagne
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'النقرات: ${campaign.totalClicks} • CTR: ${campaign.ctr.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: campaign.budget > 0
                              ? (campaign.spent / campaign.budget)
                                    .clamp(0.0, 1.0)
                                    .toDouble()
                              : 0,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${campaign.spent.toStringAsFixed(0)} د',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'من ${campaign.budget.toStringAsFixed(0)} د',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCampaignDetails(CampaignData campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(campaign.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de la campagne dans les détails
              if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: campaign.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              _buildDetailRow('الحالة', campaign.isActive ? 'نشطة' : 'متوقفة'),
              _buildDetailRow(
                'الميزانية',
                '${campaign.budget.toStringAsFixed(0)} د',
              ),
              _buildDetailRow(
                'المُنفق',
                '${campaign.spent.toStringAsFixed(0)} د',
              ),
              _buildDetailRow('النقرات', campaign.totalClicks.toString()),
              _buildDetailRow('CTR', '${campaign.ctr.toStringAsFixed(1)}%'),
              _buildDetailRow(
                'الباقي',
                '${(campaign.budget - campaign.spent).toStringAsFixed(0)} د',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  double _calculateAverageCTR() {
    if (_campaigns.isEmpty) return 0.0;
    return _campaigns.map((c) => c.ctr).reduce((a, b) => a + b) /
        _campaigns.length;
  }

  Widget _buildErrorBanner(String message) {
    return Card(
      color: Colors.red.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد بيانات حملات بعد',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCampaignScreen(),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('أنشئ حملتك الأولى'),
            ),
          ],
        ),
      ),
    );
  }
}

class CampaignData {
  final String id;
  final String title;
  final double budget;
  final double spent;
  final int totalClicks;
  final bool isActive;
  final double ctr;
  final String? imageUrl; // Nouveau champ pour l'image

  CampaignData({
    required this.id,
    required this.title,
    required this.budget,
    required this.spent,
    required this.totalClicks,
    required this.isActive,
    required this.ctr,
    this.imageUrl, // Nouveau champ optionnel
  });

  factory CampaignData.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final clicksValue = map['achievedClicks'] ?? map['totalClicks'] ?? 0;

    return CampaignData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      budget: _toDouble(map['budget']),
      spent: _toDouble(map['spent']),
      totalClicks: _toInt(clicksValue),
      isActive: map['isActive'] == true,
      ctr: _toDouble(map['ctr']),
      imageUrl: map['imageUrl']?.toString(), // Récupération de l'URL de l'image
    );
  }
}

class BusinessStats {
  final int totalCampaigns;
  final int activeCampaigns;
  final double totalSpent;
  final double totalBudget;
  final double totalClicks;
  final double averageCTR;
  final double budgetUtilization;

  BusinessStats({
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.totalSpent,
    required this.totalBudget,
    required this.totalClicks,
    required this.averageCTR,
    required this.budgetUtilization,
  });

  factory BusinessStats.fromMap(Map<String, dynamic> map) {
    num _toNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return BusinessStats(
      totalCampaigns: _toNum(map['totalCampaigns']).toInt(),
      activeCampaigns: _toNum(map['activeCampaigns']).toInt(),
      totalSpent: _toNum(map['totalSpent']).toDouble(),
      totalBudget: _toNum(map['totalBudget']).toDouble(),
      totalClicks: _toNum(map['totalClicks']).toDouble(),
      averageCTR: _toNum(map['averageCTR']).toDouble(),
      budgetUtilization: _toNum(map['budgetUtilization']).toDouble(),
    );
  }
}
