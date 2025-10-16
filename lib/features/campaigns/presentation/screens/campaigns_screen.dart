import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/data/models/campaign_model.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../presentation/widgets/campaign/campaign_card.dart';
import '../../../../presentation/widgets/campaign/campaign_list.dart';
import '../providers/campaign_provider.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final TextEditingController _searchController = TextEditingController();
  CampaignType? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CampaignProvider>(context, listen: false);
      provider.loadCampaigns();
    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignProvider>(
      builder: (context, campaignProvider, child) {
        return Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilterSection(campaignProvider),
            
            // Campaigns List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await campaignProvider.refreshCampaigns();
                },
                child: campaignProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : campaignProvider.campaigns.isEmpty
                        ? _buildEmptyState()
                        : CampaignList(campaigns: campaignProvider.campaigns),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilterSection(CampaignProvider campaignProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في الحملات...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        campaignProvider.loadCampaigns();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                campaignProvider.loadCampaigns();
              } else {
                campaignProvider.searchCampaigns(value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  selected: _selectedType == null,
                  onSelected: (_) {
                    setState(() => _selectedType = null);
                    campaignProvider.loadCampaigns();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'مفتوحة',
                  selected: _selectedType == CampaignType.open,
                  onSelected: (_) {
                    setState(() => _selectedType = CampaignType.open);
                    campaignProvider.loadCampaigns(type: CampaignType.open);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'إقليمية',
                  selected: _selectedType == CampaignType.regional,
                  onSelected: (_) {
                    setState(() => _selectedType = CampaignType.regional);
                    campaignProvider.loadCampaigns(type: CampaignType.regional);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'دقيقة',
                  selected: _selectedType == CampaignType.precise,
                  onSelected: (_) {
                    setState(() => _selectedType = CampaignType.precise);
                    campaignProvider.loadCampaigns(type: CampaignType.precise);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontFamily: 'Tajawal',
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.outline,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد حملات متاحة حالياً',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 10),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}