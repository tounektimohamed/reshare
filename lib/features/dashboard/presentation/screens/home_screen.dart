import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:reshare/data/models/click_model.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/campaign_model.dart';
import '../../../../presentation/widgets/campaign/campaign_card.dart';
import '../../../../presentation/widgets/earnings/stats_grid.dart';
import '../providers/dashboard_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialLoadComplete = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
                        child: CampaignCard(campaign: availableCampaigns[index]),
                      );
                    },
                    childCount: availableCampaigns.length > 3 ? 3 : availableCampaigns.length,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 24)),

                // Recent Activity Section
                SliverToBoxAdapter(
                  child: _buildRecentActivity(recentClicks),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 24)),
              ],
            ),
          ),
          
          // 🔥 NOUVEAU: Floating Action Button for quick share
          floatingActionButton: _buildQuickShareButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  // 🔥 Écran de chargement initial
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
              style: TextStyle(
                color: AppColors.primary, 
                fontFamily: 'Tajawal'
              ),
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
          return SizedBox(
            width: 280,
            child: CampaignCard(campaign: campaign),
          );
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
              // Add quick share options here
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