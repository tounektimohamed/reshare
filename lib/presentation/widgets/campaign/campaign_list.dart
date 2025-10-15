import 'package:flutter/material.dart';

import '../../../../data/models/campaign_model.dart';
import 'campaign_card.dart';

class CampaignList extends StatelessWidget {
  final List<CampaignModel> campaigns;

  const CampaignList({super.key, required this.campaigns});

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد حملات متاحة حالياً',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: campaigns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return CampaignCard(campaign: campaigns[index]);
      },
    );
  }
}