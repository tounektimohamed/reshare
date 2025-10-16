import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';

// Providers
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/campaigns/presentation/providers/campaign_provider.dart';
import 'features/earnings/presentation/providers/earnings_provider.dart';
import 'features/referrals/presentation/providers/referral_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await _setupSystemConfig();
  await _initializeFirebase();
  
  runApp(const ReShareApp());
}

Future<void> _setupSystemConfig() async {
  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Configuration de la barre de navigation
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configuration pour le web
    if (Firebase.apps.isNotEmpty) {
      print('✅ Firebase initialized successfully');
      
      // Configuration supplémentaire pour le web
      // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Fallback pour le développement
    _initializeFirebaseFallback();
  }
}

// Fallback pour l'initialisation Firebase en cas d'échec
Future<void> _initializeFirebaseFallback() async {
  try {
    // Tentative d'initialisation avec des options de base
    await Firebase.initializeApp(
      name: 'ReShare',
      options: const FirebaseOptions(
        apiKey: "AIzaSyBoMBq-RE2Yt56Y27DgmSqiOwfuWl40DMk",
        appId: "1:420886163575:web:235f5a62bacdde0c511672",
        messagingSenderId: "420886163575",
        projectId: "reshare-d7d7e",
      ),
    );
    print('✅ Firebase fallback initialization successful');
  } catch (e) {
    print('❌ Firebase fallback also failed: $e');
  }
}

class ReShareApp extends StatelessWidget {
  const ReShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider (indépendant)
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        
        // Dashboard Provider (dépend de AuthProvider)
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, authProvider, dashboardProvider) {
            if (dashboardProvider == null) {
              dashboardProvider = DashboardProvider();
            }
            dashboardProvider.updateAuth(authProvider);
            return dashboardProvider;
          },
        ),
        
        // Campaign Provider (dépend de AuthProvider)
        ChangeNotifierProxyProvider<AuthProvider, CampaignProvider>(
          create: (_) => CampaignProvider(),
          update: (_, authProvider, campaignProvider) {
            if (campaignProvider == null) {
              campaignProvider = CampaignProvider();
            }
            campaignProvider.updateAuth(authProvider);
            return campaignProvider;
          },
        ),
        
        // Earnings Provider (dépend de AuthProvider)
        ChangeNotifierProxyProvider<AuthProvider, EarningsProvider>(
          create: (_) => EarningsProvider(),
          update: (_, authProvider, earningsProvider) {
            if (earningsProvider == null) {
              earningsProvider = EarningsProvider();
            }
            earningsProvider.updateAuth(authProvider);
            return earningsProvider;
          },
        ),
        
        // Referral Provider (dépend de AuthProvider)
        ChangeNotifierProxyProvider<AuthProvider, ReferralProvider>(
          create: (_) => ReferralProvider(),
          update: (_, authProvider, referralProvider) {
            if (referralProvider == null) {
              referralProvider = ReferralProvider();
            }
            referralProvider.updateAuth(authProvider);
            return referralProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ReShare',
        theme: _buildAppTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const App(),
      ),
    );
  }

  // Thème principal de l'application
  ThemeData _buildAppTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF2E7D32),
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Tajawal', // Police adaptée pour l'arabe
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  // Thème sombre
  ThemeData _buildDarkTheme() {
    return ThemeData(
      primaryColor: const Color(0xFF4CAF50),
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Tajawal',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}