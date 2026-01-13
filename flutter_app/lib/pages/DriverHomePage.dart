import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_config.dart';
import 'package:provider/provider.dart';
//import 'dart:io';
import 'package:flutter_app/pages/OrderDetailsPage.dart';
import 'package:flutter_app/pages/DashboardPage.dart';
import 'package:flutter_app/pages/HistoryPage.dart';
import 'package:flutter_app/pages/ProfilePage.dart';
import 'package:flutter_app/pages/SettingsPage.dart';
import 'package:flutter_app/pages/InvoicesPage.dart';
import 'package:flutter_app/providers/theme_provider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'Login.dart';

// Removed global _scaffoldKey to prevent duplicate key issues

class DriverHomePage extends StatefulWidget {
  final String driverId;

  const DriverHomePage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final String _baseUrl = ApiConfig.resolveBaseUrl();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'All';
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonAnimation;

  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  static const Color _accentGreen = Color(0xFF38A169);
  static const Color _softGrey = Color(0xFFF7FAFC);
  static const Color _darkGrey = Color(0xFF2D3748);
  static const Color _borderColor = Color(0xFFE2E8F0);

  // Dark mode colors
  static const Color _darkSoftGrey = Color(0xFF1A202C);
  static const Color _darkCardColor = Color(0xFF2D3748);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    // Defer network call until after first frame so Localizations/Inherited widgets are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonController.dispose();
    _searchController.dispose();
    // Cancel any pending timers or animations here
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    final localizations = AppLocalizations.of(context);
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/missions?driverId=${widget.driverId}'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
        setState(() {
            _orders = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
        });
        } else {
          _showSnackBar('${localizations?.error ?? "Error"}: ${data['message']}', isError: true);
        }
      } else {
        _showSnackBar(localizations?.error ?? 'Connection error', isError: true);
      }
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _primaryRed : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    
    return _orders.where((order) {
      switch (_filterType) {
        case 'Status':
          return (order['status_name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        case 'Client':
          return (order['receiver_name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (order['person_receives'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        case 'Order':
          final searchQuery = _searchQuery.toLowerCase();
          return (order['order_no']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                 (order['order_prefix']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                 (order['order_encoded']?.toString().toLowerCase().contains(searchQuery) ?? false);
        default:
          final searchQuery = _searchQuery.toLowerCase();
          return (order['order_no']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                 (order['order_prefix']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                 (order['order_encoded']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                 (order['receiver_name']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                 (order['status_name']?.toString().toLowerCase().contains(searchQuery) ?? false);
      }
    }).toList();
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // Afficher la boîte de dialogue de changement de statut
  void _showStatusChangeDialog(BuildContext context, int orderId, String currentStatus) {
    final localizations = AppLocalizations.of(context);
    final List<Map<String, dynamic>> statusOptions = [
      {'id': 25, 'name': 'Picked up'},
      {'id': 28, 'name': 'Delivered'},
      {'id': 29, 'name': 'No answer'},
      {'id': 5, 'name': 'Rejected'},
      {'id': 3, 'name': 'Cancelled'},
      {'id': 26, 'name': 'Reported'},
    ];

    // Filtrer pour ne pas montrer le statut actuel
    final availableStatuses = statusOptions.where((status) => status['name'] != currentStatus).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations?.changeStatus ?? 'Change Status'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableStatuses.length,
              itemBuilder: (context, index) {
                final status = availableStatuses[index];
                return ListTile(
                  title: Text(_getLocalizedStatus(status['name'])),
                  onTap: () {
                    Navigator.of(context).pop();
                    _updateOrderStatus(orderId, status['name']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);
    
    return Drawer(
      child: Container(
        color: isDark ? _darkCardColor : Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryBlue,
                    _primaryBlue.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations?.appTitle ?? 'YanShip Driver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${localizations?.driverHome ?? "Driver"} ID: ${widget.driverId}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 20),
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: localizations?.driverHome ?? 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                    isSelected: _currentIndex == 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 1);
                    },
                    isSelected: _currentIndex == 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: localizations?.history ?? 'History',
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                      });
                      Navigator.pop(context);
                    },
                    isSelected: _currentIndex == 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt,
                    title: localizations?.invoices ?? 'Invoices',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 3);
                    },
                    isSelected: _currentIndex == 3,
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: localizations?.profile ?? 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 4);
                    },
                    isSelected: _currentIndex == 4,
                  ),
                  const Divider(height: 40),
                  
                  // Language Selection
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: isDark ? Colors.white : _darkGrey,
                    ),
                    title: Text(
                      localizations?.language ?? 'Language',
                      style: TextStyle(
                        color: isDark ? Colors.white : _darkGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: DropdownButton<Locale>(
                      value: languageProvider.currentLocale,
                      dropdownColor: isDark ? _darkCardColor : Colors.white,
                      underline: Container(),
                      items: LanguageProvider.supportedLocales.map((Locale locale) {
                        return DropdownMenuItem<Locale>(
                          value: locale,
                          child: Text(
                            languageProvider.getLanguageName(locale.languageCode),
                            style: TextStyle(
                              color: isDark ? Colors.white : _darkGrey,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Locale? locale) {
                        if (locale != null) {
                          languageProvider.changeLanguage(locale);
                        }
                      },
                    ),
                  ),
                  // Dans _buildNavigationDrawer(), après les autres items du menu
                 /* _buildDrawerItem(
                    icon: Icons.receipt,
                    title: 'Factures',
                    onTap: () {
                      Navigator.pop(context);
                        _openDriverInvoices();
                      },
                  ),*/
                  // Dark Mode Toggle
                  ListTile(
                    leading: Icon(
                      themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.white : _darkGrey,
                    ),
                    title: Text(
                      localizations?.theme ?? 'Theme',
                      style: TextStyle(
                        color: isDark ? Colors.white : _darkGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDark,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeColor: _primaryBlue,
                    ),
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: localizations?.settings ?? 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                    textColor: _primaryRed,
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'YanShip Delivery v1.0.0',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = textColor ?? _primaryBlue;
    final defaultColor = isDark ? Colors.white : _darkGrey;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? selectedColor : (textColor ?? defaultColor),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? selectedColor : (textColor ?? defaultColor),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: selectedColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: _primaryRed),
            SizedBox(width: 12),
            Text(localizations?.logout ?? 'Logout'),
          ],
        ),
        content: Text(localizations?.areYouSureLogout ?? 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations?.cancel ?? 'Cancel',
              style: TextStyle(color: Colors.grey)
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Call AuthService logout to clear token and user data
              await AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              ),
            ),
            child: Text(
              localizations?.logout ?? 'Logout',
              style: TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF4A5568) : _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : _darkGrey),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : _darkGrey.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : _darkGrey.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF4A5568) : _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          dropdownColor: isDark ? _darkCardColor : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : _darkGrey),
          items: ['All', 'Status', 'Client', 'Order'].map((String value) {
            String displayValue = value;
            switch (value) {
              case 'Status':
                displayValue = localizations?.orderStatus ?? 'Status';
                break;
              case 'Client':
                displayValue = localizations?.customerName ?? 'Client';
                break;
              case 'Order':
                displayValue = localizations?.orders ?? 'Order';
                break;
              default:
                displayValue = 'All';
            }
            return DropdownMenuItem<String>(
              value: value,
              child: Text(displayValue),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _filterType = newValue!;
            });
          },
        ),
      ),
    );
  }

  IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'confirmed':
        return Icons.verified;
      case 'picked up':
        return Icons.local_shipping;
      case 'in transit':
        return Icons.directions_car;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'attempted delivery':
        return Icons.schedule;
      case 'returned':
        return Icons.undo;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return _accentGreen;
      case 'confirmed':
        return Colors.amber;
      case 'picked up':
      case 'in transit':
      case 'out for delivery':
        return _primaryBlue;
      case 'attempted delivery':
        return Colors.orange;
      case 'returned':
        return Colors.purple;
      case 'cancelled':
      case 'rejected':
        return _primaryRed;
      default:
        return _darkGrey;
    }
  }

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? _darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Icon(
                      Icons.local_shipping,
                      color: _primaryBlue,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.appTitle ?? 'YanShip Driver',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        '${localizations?.driverHome ?? "Driver"} ID: ${widget.driverId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : _darkGrey,
                        ),
                      ),
                    ],
                  ),
                  ),
                  IconButton(
                    onPressed: () {},
                  icon: Icon(Icons.notifications, color: isDark ? Colors.white70 : _darkGrey),
                  ),
                ],
              ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildModernTextField(
                    controller: _searchController,
                    hint: 'Search ${localizations?.orders ?? "orders"}...',
                    icon: Icons.search,
                    onChanged: _filterOrders,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildFilterDropdown(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: isDark ? Colors.white38 : _darkGrey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations?.noOrders ?? 'No orders found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white70 : _darkGrey.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_filteredOrders[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Méthode utilitaire pour obtenir la couleur du statut
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return _accentGreen;
      case 'picked up':
        return _primaryBlue;
      case 'no answer':
        return Colors.orange;
      case 'rejected':
        return _primaryRed;
      case 'cancelled':
        return Colors.grey;
      case 'reported':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Widget de statut cliquable comme dans la page des factures
  Widget _buildStatusChip(String status, int orderId, bool canChange) {
    return GestureDetector(
      onTap: canChange ? () => _showStatusChangeDialog(context, orderId, status) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getStatusColor(status)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLocalizedStatus(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (canChange) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: _getStatusColor(status),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatus(String status) {
    final localizations = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'pending':
        return localizations?.pending ?? status;
      case 'accepted':
        return localizations?.accepted ?? status;
      case 'picked up':
        return localizations?.pickedUp ?? status;
      case 'delivered':
        return localizations?.delivered ?? status;
      case 'cancelled':
        return localizations?.cancelled ?? status;
      default:
        return status;
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white70 : _darkGrey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : _darkGrey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : _darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printLabel(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('YanShip Delivery Label', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Order No: ${order['order_prefix'] ?? ''}${order['order_no']}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Receiver: ${order['receiver_name']}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Address: ${order['address']}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Phone: ${order['phone']}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('City: ${order['city']}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: order['order_no'],
                width: 200,
                height: 200,
              ),
            ],
          );
        },
      ),
    );
  
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Helper method to convert status name to ID
  int _getStatusId(String statusName) {
    switch (statusName) {
      case 'Picked up':
        return 25;
      case 'Delivered':
        return 28;
      case 'No answer':
        return 29;
      case 'Rejected':
        return 5;
      case 'Cancelled':
        return 3;
      case 'Reported':
        return 26;
      default:
        return 0; // Unknown status
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    if (!mounted) return;
    
    final localizations = AppLocalizations.of(context);
    
    // Save the current orders for potential rollback
    final List<Map<String, dynamic>> previousOrders = List.from(_orders);
    
    // Update the local state immediately for a responsive UI
    setState(() {
      _isLoading = true;
      // Find the order and update its status locally
      final orderIndex = _orders.indexWhere((order) => order['order_id'] == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex]['status_name'] = newStatus;
        _orders[orderIndex]['status_courier'] = _getStatusId(newStatus);
      }
    });

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/missions/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'newStatus': newStatus}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSnackBar(localizations?.success ?? 'Status updated successfully');
          // Refresh the orders list to ensure we have the latest data
          await _loadOrders();
        } else {
          // Revert to previous state if update failed
          setState(() {
            _orders = previousOrders;
          });
          _showSnackBar(
            '${localizations?.error ?? "Error"}: ${data['message'] ?? 'Failed to update status'}', 
            isError: true
          );
        }
      } else {
        // Revert to previous state on error
        setState(() {
          _orders = previousOrders;
        });
        final errorData = json.decode(response.body);
        _showSnackBar(
          '${localizations?.error ?? "Error"}: ${errorData['message'] ?? 'Failed to update status'}', 
          isError: true
        );
      }
    } catch (e) {
      // Revert to previous state on exception
      if (mounted) {
        setState(() {
          _orders = previousOrders;
        });
      }
      _showSnackBar(
        '${localizations?.error ?? "Error"}: ${e is TimeoutException ? 'Request timed out' : e.toString()}', 
        isError: true
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeOrder(int orderId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    final localizations = AppLocalizations.of(context);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/missions/$orderId/complete'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('preuve', image.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['success']) {
        _showSnackBar(localizations?.orderDelivered ?? 'Order delivered successfully');
        _loadOrders();
      } else {
        _showSnackBar('${localizations?.error ?? "Error"}: ${data['message']}', isError: true);
      }
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    }
  }

  Future<void> _generateInvoice(int orderId) async {
    final localizations = AppLocalizations.of(context);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/missions/$orderId/invoice'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSnackBar(localizations?.success ?? 'Invoice generated successfully');
          _loadOrders();
        } else {
          _showSnackBar('${localizations?.error ?? "Error"}: ${data['message']}', isError: true);
        }
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('${localizations?.error ?? "Error"}: ${errorData['message'] ?? 'Connection error'}', isError: true);
      }
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    }
  }

  Future<void> _uploadDeliveryProof(int orderId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    final localizations = AppLocalizations.of(context);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/missions/$orderId/proof'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('proof', image.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['success']) {
        _showSnackBar(localizations?.success ?? 'Delivery proof uploaded successfully');
        _loadOrders();
      } else {
        _showSnackBar('${localizations?.error ?? "Error"}: ${data['message']}', isError: true);
      }
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);
    
    return Directionality(
      textDirection: languageProvider.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? _darkSoftGrey : _softGrey,
        drawer: _buildNavigationDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            DashboardPage(driverId: widget.driverId),
            HistoryPage(driverId: widget.driverId),
            InvoicesPage(driverId: widget.driverId),
            ProfilePage(driverId: widget.driverId),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? _darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? _darkCardColor : Colors.white,
              selectedItemColor: _primaryBlue,
              unselectedItemColor: isDark ? Colors.white54 : _darkGrey.withOpacity(0.6),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: localizations?.driverHome ?? 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: localizations?.invoices ?? 'Invoices',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final bool canChangeStatus = order['can_change_status'] ?? true;
    final bool canGenerateInvoice = order['can_generate_invoice'] ?? false;
    final bool canUploadProof = order['can_upload_proof'] ?? false;
    final bool isDelivered = order['status_name']?.toString().toLowerCase() == 'delivered';
    final bool hasProof = order['photo_delivered'] != null && order['photo_delivered'].toString().isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? _darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canChangeStatus)
                    GestureDetector(
                      onTap: () => _showStatusChangeDialog(context, order['order_id'], order['status_name']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getStatusColor(order['status_name']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: getStatusColor(order['status_name']),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getStatusIcon(order['status_name']),
                              size: 16,
                              color: getStatusColor(order['status_name']),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getLocalizedStatus(order['status_name'] ?? 'Unknown'),
                              style: TextStyle(
                                color: getStatusColor(order['status_name']),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: getStatusColor(order['status_name']),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(order['status_name']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getStatusColor(order['status_name']),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getStatusIcon(order['status_name']),
                            size: 16,
                            color: getStatusColor(order['status_name']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLocalizedStatus(order['status_name'] ?? 'Unknown'),
                            style: TextStyle(
                              color: getStatusColor(order['status_name']),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order['price'] ?? '0'} MAD',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                localizations?.orderId ?? 'Order No', 
                '${order['order_prefix'] ?? ''}${order['order_no'] ?? 'N/A'}', 
                Icons.receipt, 
                isDark
              ),
              _buildDetailRow(localizations?.customerName ?? 'Client', order['receiver_name'] ?? order['person_receives'] ?? 'N/A', Icons.person, isDark),
              _buildDetailRow(localizations?.deliveryAddress ?? 'Address', order['address'] ?? 'N/A', Icons.location_on, isDark),
              _buildDetailRow(localizations?.phoneNumber ?? 'Phone', order['phone'] ?? 'N/A', Icons.phone, isDark),
              _buildDetailRow('City', order['city_name'] ?? order['city'] ?? 'N/A', Icons.location_city, isDark),
              const SizedBox(height: 16),
              // Boutons pour les commandes livrées
              if (isDelivered) ...[
                Row(
                  children: [
                    if (canUploadProof) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _uploadDeliveryProof(order['order_id']),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: Text(localizations?.uploadProof ?? 'Upload Proof'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (canGenerateInvoice) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateInvoice(order['order_id']),
                          icon: const Icon(Icons.receipt, size: 18),
                          label: Text(localizations?.generateInvoice ?? 'Generate Invoice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasProof) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: _accentGreen),
                        SizedBox(width: 4),
                        Text(
                          localizations!.proofUploaded,
                          style: TextStyle(
                            color: _accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canChangeStatus ? () => _completeOrder(order['order_id']) : null,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(localizations?.markDelivered ?? 'Deliver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canChangeStatus ? _accentGreen : _darkGrey.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!canChangeStatus) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Status locked',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}