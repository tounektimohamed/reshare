import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/data/models/user_model.dart';
import 'package:reshare/features/campaigns/presentation/screens/DashboardEntreprise.dart';
import 'package:reshare/features/campaigns/presentation/screens/campaigns_screen.dart';
import 'package:reshare/features/dashboard/presentation/screens/home_screen.dart';
import 'package:reshare/features/dashboard/presentation/screens/profile_screen.dart';
import 'package:reshare/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:reshare/features/referrals/presentation/screens/referrals_screen.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Obtenir les écrans selon le rôle de l'utilisateur
        final screens = _getScreensForUserType(authProvider.user?.userType);
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(screens),
          body: screens[_currentIndex],
          bottomNavigationBar: _buildBottomNavigationBar(screens),
        );
      },
    );
  }

  // Obtenir les écrans selon le type d'utilisateur
 // Dans la méthode _getScreensForUserType du DashboardScreen
List<Widget> _getScreensForUserType(UserType? userType) {
  switch (userType) {
    case UserType.business:
      return [
        const CompanyDashboardScreen(), // Remplace HomeScreen par CompanyDashboardScreen
        const CampaignsScreen(),
        const EarningsScreen(),
        const ProfileScreen(),
      ];
    case UserType.admin:
      return [
        const HomeScreen(),
        const CampaignsScreen(),
        const EarningsScreen(),
        const ProfileScreen(),
      ];
    case UserType.participant:
    default:
      return [
        const HomeScreen(),
        const CampaignsScreen(),
        const EarningsScreen(),
        const ReferralsScreen(),
        const ProfileScreen(),
      ];
  }
}
  // Obtenir les labels selon le type d'utilisateur
  List<String> _getTitlesForUserType(UserType? userType) {
    switch (userType) {
      case UserType.business:
        return [
          AppStrings.dashboard,
          AppStrings.campaigns,
          AppStrings.earnings,
          AppStrings.profile,
        ];
      case UserType.admin:
        return [
          AppStrings.dashboard,
          'إدارة الحملات',
          AppStrings.earnings,
          AppStrings.profile,
        ];
      case UserType.participant:
      default:
        return [
          AppStrings.dashboard,
          AppStrings.campaigns,
          AppStrings.earnings,
          AppStrings.referrals,
          AppStrings.profile,
        ];
    }
  }

  AppBar? _buildAppBar(List<Widget> screens) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final titles = _getTitlesForUserType(authProvider.user?.userType);

    return AppBar(
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 1,
      actions: _buildAppBarActions(authProvider.user?.userType),
    );
  }

  List<Widget>? _buildAppBarActions(UserType? userType) {
    switch (_currentIndex) {
      case 0: // Home
        return [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ];
      case 1: // Campaigns
        final actions = <Widget>[
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Show search
            },
          ),
        ];

        // Ajouter le bouton de création pour les businesses et admins
        if (userType == UserType.business || userType == UserType.admin) {
          actions.add(
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                // Navigate to create campaign
              },
            ),
          );
        } else {
          actions.add(
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () {
                // Show filters
              },
            ),
          );
        }

        return actions;
      case 2: // Earnings
        return [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              // Show transaction history
            },
          ),
        ];
      default:
        return null;
    }
  }

  Widget _buildBottomNavigationBar(List<Widget> screens) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
        ),
        items: _getBottomNavItems(authProvider.user?.userType),
      ),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems(UserType? userType) {
    switch (userType) {
      case UserType.business:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_filled),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_rounded),
            activeIcon: Icon(Icons.campaign),
            label: 'الحملات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            activeIcon: Icon(Icons.attach_money),
            label: 'الأرباح',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person),
            label: 'الملف',
          ),
        ];
      case UserType.admin:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard),
            label: 'لوحة التحكم',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_rounded),
            activeIcon: Icon(Icons.manage_accounts),
            label: 'إدارة الحملات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            activeIcon: Icon(Icons.analytics),
            label: 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person),
            label: 'الملف',
          ),
        ];
      case UserType.participant:
      default:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_filled),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_rounded),
            activeIcon: Icon(Icons.campaign),
            label: 'الحملات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            activeIcon: Icon(Icons.attach_money),
            label: 'الأرباح',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            activeIcon: Icon(Icons.people_alt),
            label: 'الإحالات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person),
            label: 'الملف',
          ),
        ];
    }
  }
}