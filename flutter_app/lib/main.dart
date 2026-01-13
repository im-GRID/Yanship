
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/DriverProvider.dart';
import 'package:flutter_app/providers/RefrechProvider.dart';
import 'package:flutter_app/providers/shipment_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_app/providers/AdminFormProvider.dart';
import 'package:flutter_app/providers/CustomerFormProvider.dart';
import 'package:flutter_app/providers/DriverFormProvider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/providers/theme_provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/pages/WelcomePage.dart';
import 'package:flutter_app/pages/HomePage.dart';
import 'package:flutter_app/pages/DriverHomePage.dart';
import 'package:flutter_app/screens/admin_screen/admin_screen.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/push_notification_service.dart';
import 'package:flutter_app/services/permission_service.dart';
import 'package:flutter_app/providers/order_provider.dart';
import 'package:flutter_app/providers/notification_provider.dart';
import 'package:flutter_app/providers/invoice_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Initialize the notification service
  await LocalNotificationService.initialize();

  // Check and request notification permissions at app startup
  final notificationsEnabled = await LocalNotificationService.areNotificationsEnabled();
  if (!notificationsEnabled) {
    await LocalNotificationService.requestPermissions();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RefreshProvider()),

        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider(create: (context) => ShipmentProvider()),
        ChangeNotifierProvider(create: (context) => DriversProvider()),

        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => CustomerFormProvider()),
        ChangeNotifierProvider(create: (_) => DriverFormProvider()),
        ChangeNotifierProvider(create: (_) => AdminFormProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'Yanship Delivery App',
            locale: languageProvider.currentLocale,
            supportedLocales: LanguageProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // Enable RTL for Arabic
              if (languageProvider.isRTL) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                );
              }
              return child!;
            },
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              cardColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF8FAFC),
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
              dividerColor: const Color(0xFFE2E8F0),
              shadowColor: Colors.black,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0D1117), // GitHub-like dark
              cardColor: const Color(0xFF161B22), // Better contrast for cards
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0D1117),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              dividerColor: const Color(0xFF30363D), // More visible borders
              shadowColor: Colors.black87,
              // Enhanced text theme for readability

              textTheme: const TextTheme(
                titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600), // Pure white for titles
                titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500), // White for subtitles
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white), // White body text
                bodySmall: TextStyle(color: Color(0xFF8B949E)), // Grey for secondary text
              ),
              // Enhanced input decoration theme
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFF8B949E), // Grey input background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF30363D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF30363D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF3182CE), width: 2),
                ),
                labelStyle: TextStyle(color: Colors.white),
                hintStyle: TextStyle(color: Color(0xFF8B949E)),
              ),
              tabBarTheme: TabBarThemeData(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: Color(0xFF8B949E),
                ),
                indicatorColor: Color(0xFFE53E3E), // <-- Rouge primaire pour le trait
                labelColor: Color(0xFFE53E3E),     // <-- Rouge primaire pour l’onglet actif
              ),



            ),
            themeMode: themeProvider.themeMode,
            home: AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    // Request permissions on app start
    Future.delayed(const Duration(milliseconds: 1500), () {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (!_permissionsRequested && mounted) {
      _permissionsRequested = true;
      try {
        // Only show permission request if:
        // 1. App doesn't have notification permission
        // 2. Permission wasn't previously denied by user
        final hasPermission = await PermissionService.hasNotificationPermission();
        final wasPermissionDenied = await PermissionService.wasNotificationPermissionDenied();
        
        print('📱 Notification permission status: hasPermission=$hasPermission, wasPermissionDenied=$wasPermissionDenied');
        
        if (!hasPermission && !wasPermissionDenied) {
          await PermissionService.requestNotificationPermission(context);
        } else if (!hasPermission && wasPermissionDenied) {
          print('🔕 Notification permission was previously denied, not showing panel again');
        } else {
          print('✅ Notification permission already granted');
        }
      } catch (e) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  Future<void> _startNotificationServiceIfLoggedIn() async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        await LocalNotificationService.startService(token);
        print('✅ Notification service started after app restart');
      }
    } catch (e) {
      print('❌ Error starting notification service after app restart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        if (snapshot.data == true) {
          // User is logged in, start notification service and go to appropriate home page
          _startNotificationServiceIfLoggedIn();
          return HomeWrapper();
        } else {
          // User is not logged in, stop any running notification service and show welcome page
          LocalNotificationService.stopService();
          return WelcomePage();
        }
      },
    );
  }
}

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: AuthService.getUserLevel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        final userLevel = snapshot.data;
        print('📱 User level retrieved: $userLevel');
        
        // Navigate to appropriate page based on user level
        Widget targetPage;
        switch (userLevel) {
          case 9: // Admin
            print('🔧 Navigating to Admin page');
            targetPage = AdminPage();
            break;
          case 2: // User Management
            print('👥 Navigating to Selection screen');
            targetPage = AdminPage();
            break;
          case 3: // Driver
            print('🚗 Navigating to Driver page');
            // Get driver ID from user data
            return FutureBuilder<Map<String, dynamic>?>(
              future: AuthService.getCurrentUser(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return SplashScreen();
                }
                final user = userSnapshot.data;
                final driverId = user?['id']?.toString() ?? ''; // No fallback, handle empty case in DriverHomePage
                print('🚗 Driver ID: $driverId');
                return DriverHomePage(driverId: driverId);
              },
            );
          case 1: // Client
            print('👤 Navigating to Customer page');
            targetPage = HomePage();
            break;
          default:
            // If no user level found or invalid level, try to get it from user data as fallback
            print('⚠️ Invalid or missing user level: $userLevel, checking user data...');
            return FutureBuilder<Map<String, dynamic>?>(
              future: AuthService.getCurrentUser(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return SplashScreen();
                }
                final user = userSnapshot.data;
                final fallbackUserLevel = user?['userlevel'] ?? user?['userLevel'];
                
                if (fallbackUserLevel != null) {
                  print('🔄 Found user level in user data: $fallbackUserLevel');
                  // Recursive call with the found user level
                  switch (fallbackUserLevel) {
                    case 9:
                      return AdminPage();
                    case 2:
                      return AdminPage();
                    case 3:
                      final driverId = user?['id']?.toString() ?? '57';
                      return DriverHomePage(driverId: driverId);
                    case 1:
                      return HomePage();
                    default:
                      print('❌ Still invalid user level, logging out');
                      AuthService.logout();
                      return WelcomePage();
                  }
                } else {
                  print('❌ No user level found anywhere, logging out');
                  AuthService.logout();
                  return WelcomePage();
                }
              },
            );
        }

        return targetPage;
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Add a small delay for smooth transition
    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      // Always show welcome screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            SizedBox(
              width: 100,
              height: 100,
              child: Image.asset(
              'images/logo.png',
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                Icons.local_shipping_rounded,
                size: 90,
                color: Colors.red.shade600,
                );
              },
              ),
            ),
            SizedBox(height: 24),

            SizedBox(height: 8),
            Text(
              'Your trusted delivery partner',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 40),
            // Loading Indicator
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
