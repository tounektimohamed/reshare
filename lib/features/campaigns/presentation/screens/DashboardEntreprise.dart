import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/auth/presentation/providers/marketplace_provider.dart';
import 'package:reshare/features/auth/presentation/screens/marketplace_screen.dart';
import 'package:reshare/features/campaigns/presentation/screens/create_campaign_with_image_screen.dart';
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

        // AJOUTER CE DEBUG POUR VOIR LES DONNÉES
        print('Résultat API: $result');
        if (result['campaigns'] != null) {
          print('Nombre de campagnes: ${result['campaigns'].length}');
          for (var i = 0; i < result['campaigns'].length; i++) {
            print('Campagne $i: ${result['campaigns'][i]}');
          }
        }

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

          // AJOUTER CE DEBUG POUR VOIR LE TRI
          final marketplaceCampaigns = _campaigns
              .where((c) => c.campaignType == 'marketplace')
              .toList();
          final adsCampaigns = _campaigns
              .where((c) => c.campaignType != 'marketplace')
              .toList();
          print('Campagnes Marketplace: ${marketplaceCampaigns.length}');
          print('Campagnes Ads: ${adsCampaigns.length}');
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
    final marketplaceCampaigns = _campaigns
        .where((c) => c.campaignType == 'marketplace')
        .toList();
    final adsCampaigns = _campaigns
        .where((c) => c.campaignType != 'marketplace')
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('لوحة تحكم الحملات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // BOUTON MARKETPLACE
          IconButton(
            icon: const Icon(Icons.store_rounded),
            onPressed: () => _navigateToMarketplace(context),
            tooltip: 'سوق الحملات',
          ),
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
                // Bannière Marketplace
                _buildMarketplaceBanner(context),
                const SizedBox(height: 16),

                // NOUVEAU: Statistiques séparées Ads vs Marketplace
                _buildCampaignTypeStats(adsCampaigns, marketplaceCampaigns),
                const SizedBox(height: 16),

                // Filtres
                _buildFilters(),
                const SizedBox(height: 16),

                // Statistiques rapides
                _buildQuickStats(),
                const SizedBox(height: 16),

                // Graphiques de performance
                _buildPerformanceCharts(),
                const SizedBox(height: 16),

                // NOUVEAU: Liste séparée des campagnes Ads et Marketplace
                _buildCampaignsByType(adsCampaigns, marketplaceCampaigns),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // NOUVELLE MÉTHODE: Statistiques par type de campagne
  Widget _buildCampaignTypeStats(
    List<CampaignData> adsCampaigns,
    List<CampaignData> marketplaceCampaigns,
  ) {
    final totalAdsBudget = adsCampaigns.fold(
      0.0,
      (sum, campaign) => sum + campaign.budget,
    );
    final totalMarketplaceBudget = marketplaceCampaigns.fold(
      0.0,
      (sum, campaign) => sum + campaign.budget,
    );
    final totalAdsSpent = adsCampaigns.fold(
      0.0,
      (sum, campaign) => sum + campaign.spent,
    );
    final totalMarketplaceSpent = marketplaceCampaigns.fold(
      0.0,
      (sum, campaign) => sum + campaign.spent,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات حسب نوع الحملة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Campagnes Ads
                Expanded(
                  child: _buildTypeStatCard(
                    title: 'إعلانات عادية',
                    campaignCount: adsCampaigns.length,
                    totalBudget: totalAdsBudget,
                    totalSpent: totalAdsSpent,
                    color: Colors.blue,
                    icon: Icons.ads_click,
                  ),
                ),
                const SizedBox(width: 12),
                // Campagnes Marketplace
                Expanded(
                  child: _buildTypeStatCard(
                    title: 'سوق الحملات',
                    campaignCount: marketplaceCampaigns.length,
                    totalBudget: totalMarketplaceBudget,
                    totalSpent: totalMarketplaceSpent,
                    color: Colors.green,
                    icon: Icons.store,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeStatCard({
    required String title,
    required int campaignCount,
    required double totalBudget,
    required double totalSpent,
    required Color color,
    required IconData icon,
  }) {
    final utilization = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$campaignCount حملة',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalBudget.toStringAsFixed(0)} د ميزانية',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '${utilization.toStringAsFixed(1)}% استهلاك',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Bannière Marketplace
  Widget _buildMarketplaceBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToMarketplace(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.blue.shade600, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سوق الحملات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    'اكتشف الحملات الرائجة واربح أكثر',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'استكشف',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation vers Marketplace
  void _navigateToMarketplace(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) =>
              MarketplaceProvider()
                ..updateAuth(Provider.of<AuthProvider>(context, listen: false)),
          child: const MarketplaceScreen(),
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
        ((totalBudget! > 0) ? (totalSpent! / totalBudget!) * 100 : 0);

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
              '${totalSpent?.toStringAsFixed(0)} د',
              (totalBudget! > 0)
                  ? 'من ${totalBudget.toStringAsFixed(0)} د ميزانية'
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

  // NOUVELLE MÉTHODE: Liste séparée par type de campagne
  Widget _buildCampaignsByType(
    List<CampaignData> adsCampaigns,
    List<CampaignData> marketplaceCampaigns,
  ) {
    return Column(
      children: [
        // Campagnes Ads
        if (adsCampaigns.isNotEmpty) ...[
          _buildCampaignsSection(
            title: 'حملات الإعلانات العادية',
            campaigns: adsCampaigns,
            icon: Icons.ads_click,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
        ],

        // Campagnes Marketplace
        if (marketplaceCampaigns.isNotEmpty) ...[
          _buildCampaignsSection(
            title: 'حملات السوق',
            campaigns: marketplaceCampaigns,
            icon: Icons.store,
            color: Colors.green,
            showMarketplaceBadge: true,
          ),
          const SizedBox(height: 16),
        ],

        // Si aucune campagne
        if (adsCampaigns.isEmpty && marketplaceCampaigns.isEmpty)
          _buildEmptyCampaignsState(),
      ],
    );
  }

  Widget _buildCampaignsSection({
    required String title,
    required List<CampaignData> campaigns,
    required IconData icon,
    required Color color,
    bool showMarketplaceBadge = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (showMarketplaceBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.green, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'سوق',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...campaigns
                .map(
                  (campaign) =>
                      _buildCampaignItem(campaign, showMarketplaceBadge),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignItem(CampaignData campaign, bool isMarketplace) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: isMarketplace
              ? Border.all(color: Colors.green.withOpacity(0.3))
              : null,
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
                      child: const Center(child: CircularProgressIndicator()),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                campaign.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMarketplace)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'سوق',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMarketplace ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${campaign.spent.toStringAsFixed(0)} د',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isMarketplace
                                    ? Colors.green
                                    : Colors.blue,
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

  Widget _buildEmptyCampaignsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.campaign, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد حملات حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'أنشئ حملتك الأولى لتبدأ في جلب النقرات',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Boutons d'action améliorés
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateCampaignWithImageScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('أنشئ حملتك الأولى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _navigateToMarketplace(context),
                  icon: const Icon(Icons.store_rounded),
                  label: const Text('استكشف السوق'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            // Boutons d'action améliorés
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateCampaignWithImageScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('أنشئ حملتك الأولى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _navigateToMarketplace(context),
                  icon: const Icon(Icons.store_rounded),
                  label: const Text('استكشف السوق'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageCTR() {
    if (_campaigns.isEmpty) return 0.0;
    return _campaigns.map((c) => c.ctr).reduce((a, b) => a + b) /
        _campaigns.length;
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
  final String? imageUrl;
  final String? campaignType; // NOUVEAU: Type de campagne

  CampaignData({
    required this.id,
    required this.title,
    required this.budget,
    required this.spent,
    required this.totalClicks,
    required this.isActive,
    required this.ctr,
    this.imageUrl,
    this.campaignType, // NOUVEAU
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
      imageUrl: map['imageUrl']?.toString(),
      campaignType: map['campaignType']?.toString(), // NOUVEAU
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
