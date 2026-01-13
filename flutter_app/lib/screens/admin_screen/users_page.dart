import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/pages/Contact.dart';
import 'package:flutter_app/pages/Notifications.dart';
import 'package:flutter_app/pages/Profile.dart';
import 'package:flutter_app/providers/RefrechProvider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/providers/theme_provider.dart';
import 'package:flutter_app/screens/admin_screen/admin_screen.dart';
import 'package:flutter_app/screens/admin_screen/cities_page.dart';
import 'package:flutter_app/screens/admin_screen/contact_page.dart';
import 'package:flutter_app/screens/admin_screen/customers.dart';
import 'package:flutter_app/screens/admin_screen/drivers.dart';
import 'package:flutter_app/screens/admin_screen/manage_users.dart';
import 'package:flutter_app/screens/admin_screen/super_admins.dart';
import 'package:flutter_app/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/services/auth_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with TickerProviderStateMixin { // Changé à TickerProviderStateMixin
  late TabController _tabController;
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  int _userLevel = 0;
  bool _isLoading = true;

  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;

  bool _isRefreshing = false;


  @override
  void initState() {
    super.initState();
    // Initialiser avec 0 onglets temporairement
    _tabController = TabController(length: 0, vsync: this);
    _getUserLevel();
  }

  // Méthode pour récupérer le niveau de l'utilisateur
  void _getUserLevel() async {
    try {
      int? level = await AuthService.getUserLevel();

      setState(() {
        _userLevel = level ?? 0;
        _isLoading = false;
      });

      // Recréer le TabController avec la bonne longueur
      _recreateTabController();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _userLevel = 0;
      });
      _recreateTabController();
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {

      _refreshTabPages();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'actualisation'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  void _recreateTabController() {
    // Dispose l'ancien controller
    _tabController.dispose();

    // Crée un nouveau controller avec la bonne longueur
    int length = 0;
    if (_userLevel == 9) {
      length = 4;
    } else if (_userLevel == 2) {
      length = 2;
    }

    _tabController = TabController(length: length, vsync: this);

    // Force le rebuild
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  List<Tab> _buildTabs(AppLocalizations appLocalizations) {
    if (_userLevel == 9) {
      return [
        Tab(text: appLocalizations.superAdmins),
        Tab(text: appLocalizations.userManagement),
        Tab(text: appLocalizations.drivers),
        Tab(text: appLocalizations.customers),
      ];
    } else if (_userLevel == 2) {
      return [
        Tab(text: appLocalizations.drivers),
        Tab(text: appLocalizations.customers),
      ];
    } else {
      return [];
    }
  }

  List<Widget> _buildTabViews() {
    if (_userLevel == 9) {
      return const [
        SuperAdminsPage(),
        UserManagementsPage(),
        DriverPage(),
        CustomersPage(),
      ];
    } else if (_userLevel == 2) {
      return const [
        DriverPage(),
        CustomersPage(),
      ];
    } else {
      return [];
    }
  }


  void _refreshTabPages() {
    Provider.of<RefreshProvider>(context, listen: false).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    Provider.of<RefreshProvider>(context, listen: false).setRefreshCallback(_refreshData);



    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final appLocalizations = AppLocalizations.of(context)!;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
              ),
            ),
          );
        }


        if (_userLevel != 9 && _userLevel != 2) {
          return Scaffold(
            appBar: AppBar(
              title: Text(appLocalizations.accessDenied),
              backgroundColor: theme.appBarTheme.backgroundColor,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: _primaryRed,
                    ),
                    SizedBox(height: 20),
                    Text(
                      appLocalizations.accessDenied,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      appLocalizations.insufficientPermissions,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminPage()),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(appLocalizations.backToHome),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(

          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'images/logo.png',
                  height: 30,
                  color: isDarkMode ? Colors.white : null,
                  colorBlendMode: BlendMode.srcIn,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                      tooltip: appLocalizations.refresh,
                      onPressed: _refreshData,
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return IconButton(
                          icon: Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          onPressed: () {
                            final newThemeMode = themeProvider.themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                            themeProvider.setThemeMode(newThemeMode);
                          },
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.menu, color: AppColors.primary),
                      color: isDarkMode ? const Color(0xFF161B22) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'cities') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CitiesPage()),
                          );
                        } else if (value == 'contacts') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ContactsPage()),
                          );                        }
                      },
                      itemBuilder: (BuildContext context) => [
                         PopupMenuItem(
                          value: 'cities',
                          child: Text(appLocalizations.citiesPage),
                        ),
                         PopupMenuItem(
                          value: 'contacts',
                          child: Text(appLocalizations.contactsPage),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications,
                          color: AppColors.primary,
                          size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            bottom: (_userLevel == 9 || _userLevel == 2) && _tabController.length > 0
                ? PreferredSize(
              preferredSize: const Size.fromHeight(48.0),
              child: Container(
                color: theme.appBarTheme.backgroundColor,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: _primaryRed,
                  labelColor: _primaryRed,
                  unselectedLabelColor:
                  isDarkMode ? Colors.grey[400] : Colors.black54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  tabs: _buildTabs(appLocalizations),
                ),
              ),
            )
                : null,
          ),

          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 10 : 20,
                  vertical: isLandscape ? 8 : 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isLandscape ? 6 : 10),
                      child: Icon(
                        Icons.people_rounded,
                        color: primaryRed,
                        size: isLandscape ? 24 : 30,
                      ),
                    ),
                    SizedBox(width: isLandscape ? 12 : 16),
                    Expanded(
                      child: Text(
                        appLocalizations.userManagement.toUpperCase(),
                        style: TextStyle(
                          fontSize: isLandscape ? 10 : 12,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _tabController.length > 0
                    ? TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(),
                )
                    : Center(
                  child: Text(
                    "appLocalizations.noAccess",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: EdgeInsets.only(
                left: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
                right: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
                bottom: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
              ),
              height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 65),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                    const Color(0xFF161B22).withOpacity(0.95),
                    const Color(0xFF161B22),
                  ]
                      : [
                    Colors.white.withOpacity(0.95),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF30363D).withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? const Color(0xFF161B22).withOpacity(0.4)
                        : Colors.white.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: BottomNavigationBar(
                    currentIndex: 1,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: primaryRed,
                    unselectedItemColor: isDarkMode
                        ? const Color(0xFFB1BAC4)
                        : Colors.grey[400],
                    selectedFontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12),
                    unselectedFontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 11),
                    type: BottomNavigationBarType.fixed,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.home_rounded,
                          size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                        ),
                        label: appLocalizations.home,
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.people_rounded,
                          size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                        ),
                        label: appLocalizations.users,
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.person_rounded,
                          size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                        ),
                        label: appLocalizations.profile,
                      ),
                    ],
                    onTap: (index) {
                      switch (index) {
                        case 0:
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminPage()),
                                (route) => false,
                          );
                          break;
                        case 1:
                          break;
                        case 2:
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                                (route) => false,
                          );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}