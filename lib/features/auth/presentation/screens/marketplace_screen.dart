// === lib/features/marketplace/presentation/screens/marketplace_screen.dart ===

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/data/models/marketplace_campaign_model.dart';
import 'package:reshare/features/auth/presentation/providers/marketplace_provider.dart';
import 'package:reshare/presentation/widgets/prodect/product_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _selectedSort = 'featured';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      provider.loadMarketplaceCampaigns();
    });

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Simple scroll listener sans chargement infini
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'سوق الحملات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Consumer<MarketplaceProvider>(
        builder: (context, marketplaceProvider, child) {
          return Column(
            children: [
              // Barre de recherche et filtres
              _buildSearchAndFilterSection(marketplaceProvider),
              
              // En-tête avec stats
              _buildMarketplaceHeader(marketplaceProvider),
              
              // Liste des campagnes avec GridView
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await marketplaceProvider.refreshMarketplaceCampaigns();
                  },
                  child: _buildCampaignsGrid(marketplaceProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterSection(MarketplaceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في الحملات...',
              hintStyle: const TextStyle(fontFamily: 'Tajawal'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        provider.loadMarketplaceCampaigns();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                provider.loadMarketplaceCampaigns();
              } else {
                provider.searchMarketplaceCampaigns(value);
              }
            },
          ),
          const SizedBox(height: 8),

          // Filtres rapides dans une ligne compacte
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // Filtres
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCompactFilterChip(
                        label: 'الكل',
                        selected: _selectedFilter == 'all',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'all');
                          provider.filterCampaigns('all');
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildCompactFilterChip(
                        label: 'مميزة',
                        selected: _selectedFilter == 'featured',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'featured');
                          provider.filterCampaigns('featured');
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildCompactFilterChip(
                        label: 'رائجة',
                        selected: _selectedFilter == 'trending',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'trending');
                          provider.filterCampaigns('trending');
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildCompactFilterChip(
                        label: 'جديدة',
                        selected: _selectedFilter == 'new',
                        onSelected: (_) {
                          setState(() => _selectedFilter = 'new');
                          provider.filterCampaigns('new');
                        },
                      ),
                    ],
                  ),
                ),
                
                // Tri compact
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      items: const [
                        DropdownMenuItem(
                          value: 'featured',
                          child: Text('مميزة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'rating',
                          child: Text('الأعلى تقييماً', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'shares',
                          child: Text('الأكثر مشاركة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'earnings',
                          child: Text('أعلى ربح', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('الأحدث', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSort = value!);
                        provider.sortCampaigns(value!);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontFamily: 'Tajawal',
          fontSize: 12,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.blue : Colors.grey[300]!,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMarketplaceHeader(MarketplaceProvider provider) {
    // Calcul du total des gains basé sur les campagnes disponibles
    double totalEarnings = provider.availableCampaigns.fold(0.0, (sum, campaign) {
      return sum + campaign.participantEarnings;
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactHeaderStat(
            value: provider.availableCampaigns.length.toString(),
            label: 'حملات متاحة',
            icon: Icons.campaign_rounded,
          ),
          _buildCompactHeaderStat(
            value: provider.featuredCampaigns.length.toString(),
            label: 'مميزة',
            icon: Icons.star_rounded,
          ),
          _buildCompactHeaderStat(
            value: provider.trendingCampaigns.length.toString(),
            label: 'رائجة',
            icon: Icons.trending_up_rounded,
          ),
          _buildCompactHeaderStat(
            value: totalEarnings.toStringAsFixed(3),
            label: 'إجمالي الأرباح',
            icon: Icons.attach_money_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeaderStat({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 16),
        ),
        const SizedBox(height: 4),
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
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCampaignsGrid(MarketplaceProvider provider) {
    if (provider.isLoading && provider.availableCampaigns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.availableCampaigns.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: provider.availableCampaigns.length,
      itemBuilder: (context, index) {
        final campaign = provider.availableCampaigns[index];
        return _buildCompactCampaignCard(campaign);
      },
    );
  }

  Widget _buildCompactCampaignCard(MarketplaceCampaignModel campaign) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewCampaignDetails(campaign),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de la campagne
              if (campaign.hasImage)
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: campaign.imageUrl!.startsWith('data:image/')
                        ? Image.memory(
                            base64.decode(campaign.imageUrl!.split(',')[1]),
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            campaign.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.campaign_rounded, color: Colors.grey[400]);
                            },
                          ),
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: Icon(Icons.campaign_rounded, color: Colors.grey[400], size: 40),
                ),
              
              const SizedBox(height: 8),
              
              // Titre
              Text(
                campaign.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Note et participation
              Row(
                children: [
                  Text(
                    '${campaign.ratingText} ⭐',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    campaign.shareCountText,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Gains
              Text(
                '${campaign.participantEarnings.toStringAsFixed(3)} د.ك',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'Tajawal',
                ),
              ),
              
              const Spacer(),
              
              // Boutons d'action compacts
              Row(
                children: [
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      onPressed: () => _shareCampaign(campaign),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      onPressed: () => _viewCampaignDetails(campaign),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد حملات في السوق حالياً',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ارجع لاحقاً للتحقق من الحملات الجديدة',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Tajawal',
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _shareCampaign(MarketplaceCampaignModel campaign) {
    final provider = Provider.of<MarketplaceProvider>(context, listen: false);
    provider.shareMarketplaceCampaign(campaign);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم مشاركة حملة: ${campaign.title}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _contactAdvertiser(MarketplaceCampaignModel campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'التواصل مع ${campaign.advertiserName}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Text(
          'سيتم فتح محادثة مع المعلن لهذه الحملة',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startChatWithAdvertiser(campaign);
            },
            child: const Text('بدء المحادثة', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _startChatWithAdvertiser(MarketplaceCampaignModel campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'جاري فتح محادثة مع ${campaign.advertiserName}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  void _viewCampaignDetails(MarketplaceCampaignModel campaign) {
    final provider = Provider.of<MarketplaceProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CampaignDetailsBottomSheet(
        campaign: campaign,
        provider: provider, // Passer le provider en paramètre
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Bottom Sheet corrigée avec défilement et accès au provider
class CampaignDetailsBottomSheet extends StatelessWidget {
  final MarketplaceCampaignModel campaign;
  final MarketplaceProvider provider;

  const CampaignDetailsBottomSheet({
    super.key, 
    required this.campaign,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête fixe
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image de la campagne
                  if (campaign.hasImage)
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: campaign.imageUrl!.startsWith('data:image/')
                            ? Image.memory(
                                base64.decode(campaign.imageUrl!.split(',')[1]),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                campaign.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  
                  if (campaign.hasImage) const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    campaign.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Tajawal',
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Statistiques améliorées avec les clics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Titre des statistiques
                        const Row(
                          children: [
                            Icon(Icons.analytics_rounded, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'إحصائيات الحملة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Grille des statistiques
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                          children: [
                            _buildStatCard(
                              icon: Icons.touch_app_rounded,
                              title: 'النقرات المحققة',
                              value: _getAchievedClicks(campaign).toString(),
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              icon: Icons.tablet_rounded,
                              title: 'النقرات المستهدفة',
                              value: _getTargetClicks(campaign).toString(),
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              icon: Icons.timelapse_rounded,
                              title: 'النقرات المتبقية',
                              value: _getRemainingClicks(campaign).toString(),
                              color: Colors.orange,
                            ),
                            _buildStatCard(
                              icon: Icons.attach_money_rounded,
                              title: 'ربح النقرة',
                              value: '${campaign.participantEarnings.toStringAsFixed(3)} د.ك',
                              color: Colors.purple,
                            ),
                            _buildStatCard(
                              icon: Icons.star_rounded,
                              title: 'التقييم',
                              value: '${campaign.ratingText} ⭐',
                              color: Colors.amber,
                            ),
                            _buildStatCard(
                              icon: Icons.share_rounded,
                              title: 'المشاركات',
                              value: campaign.shareCountText,
                              color: Colors.red,
                            ),
                          ],
                        ),
                        
                        // Barre de progression des clics
                        const SizedBox(height: 20),
                        _buildClicksProgressBar(campaign),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action (fixes en bas)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.shareMarketplaceCampaign(campaign); // Utiliser le provider passé en paramètre
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('مشاركة', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactAdvertiserFromBottomSheet(context, campaign);
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('تواصل', style: TextStyle(fontFamily: 'Tajawal')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _contactAdvertiserFromBottomSheet(BuildContext context, MarketplaceCampaignModel campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'التواصل مع ${campaign.advertiserName}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Text(
          'سيتم فتح محادثة مع المعلن لهذه الحملة',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startChatWithAdvertiserFromBottomSheet(context, campaign);
            },
            child: const Text('بدء المحادثة', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  void _startChatWithAdvertiserFromBottomSheet(BuildContext context, MarketplaceCampaignModel campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'جاري فتح محادثة مع ${campaign.advertiserName}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClicksProgressBar(MarketplaceCampaignModel campaign) {
    final achievedClicks = _getAchievedClicks(campaign);
    final targetClicks = _getTargetClicks(campaign);
    final progress = targetClicks > 0 ? achievedClicks / targetClicks : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تقدم الحملة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : Colors.blue,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$achievedClicks / $targetClicks',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            Text(
              '${targetClicks - achievedClicks} نقرة متبقية',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Méthodes pour récupérer les données des clics
  int _getAchievedClicks(MarketplaceCampaignModel campaign) {
    return campaign.achievedClicks ?? 0;
  }

  int _getTargetClicks(MarketplaceCampaignModel campaign) {
    return campaign.targetClicks ?? 100;
  }

  int _getRemainingClicks(MarketplaceCampaignModel campaign) {
    final achieved = _getAchievedClicks(campaign);
    final target = _getTargetClicks(campaign);
    return target - achieved;
  }
}