import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/invoice_provider.dart';
import '../l10n/app_localizations.dart';

class DashboardPage extends StatefulWidget {
  final String driverId;

  const DashboardPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final String _baseUrl = 'http://10.0.2.2:3000';
  bool _isLoading = true;
  Map<String, int> _stats = {
    'total': 0,
    'delivered': 0,
    'returned': 0,
    'cancelled': 0,
  };
  Map<String, dynamic> _earnings = {
    'delivered_orders': 0,
    'delivered_amount': 0.0,
    'average_ticket': 0.0,
    'invoiced_orders': 0,
    'pending_invoice_orders': 0,
    'pending_payment_invoices': 0,
  };

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  // Cached getters for better performance
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get accentGreen => _accentGreen;
  Color get softGrey => _softGrey;
  Color get darkGrey => _darkGrey;
  Color get borderColor => _borderColor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
    _loadData();
    
    // Écouter les changements du provider
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    invoiceProvider.addListener(_onInvoiceUpdated);
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadStats(),
      _loadEarnings(),
    ]);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _loadData();
    }
  }
  
  @override
  void dispose() {
    // Nettoyer le listener
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    invoiceProvider.removeListener(_onInvoiceUpdated);
    
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  void _onInvoiceUpdated() {
    if (mounted && Provider.of<InvoiceProvider>(context, listen: false).needsRefresh) {
      _loadData().then((_) {
        if (mounted) {
          Provider.of<InvoiceProvider>(context, listen: false).resetRefresh();
        }
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadData();
    }
  }


  Future<void> _loadStats() async {
    if (!mounted) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/missions/driver/stats?driverId=${widget.driverId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
        // Safely parse stats to int to avoid type cast errors when backend sends strings
        final Map<String, dynamic> raw = Map<String, dynamic>.from(data['data'] ?? {});
        final Map<String, int> parsedStats = {
          'total': _parseIntSafe(raw['total']),
          'delivered': _parseIntSafe(raw['delivered']),
          'returned': _parseIntSafe(raw['returned']),
          'cancelled': _parseIntSafe(raw['cancelled']),
        };
        setState(() {
            _stats = parsedStats;
            _isLoading = false;
        });
        } else {
          _showSnackBar('${AppLocalizations.of(context)!.error}: ${data['message']}', isError: true);
        }
      } else {
        _showSnackBar(AppLocalizations.of(context)!.connectionError, isError: true);
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.error}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEarnings() async {
    if (!mounted) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/dashboard'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Normalize earnings types to avoid format exceptions
          final Map<String, dynamic> raw = Map<String, dynamic>.from(data['data'] ?? {});
          final Map<String, dynamic> parsed = {
            'delivered_orders': _parseIntSafe(raw['deliveredCount']),
            'delivered_amount': _parseDoubleSafe(raw['deliveredAmount']),
            'average_ticket': 0.0, // Non utilisé pour l'instant
            'invoiced_orders': 0, // Non utilisé pour l'instant
            'pending_invoice_orders': 0, // Non utilisé pour l'instant
            'pending_payment_invoices': 0, // Non utilisé pour l'instant
          };
          setState(() {
            _earnings = parsed;
          });
        }
      }
    } catch (_) {}
  }

  // Helpers to safely parse ints/doubles coming from backend
  int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _parseDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? primaryRed : accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? _darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                localizations.performanceOverview,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  localizations.delivered,
                  _stats['delivered'] ?? 0,
                  _stats['total'] ?? 1,
                  accentGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressIndicator(
                  localizations.returned,
                  _stats['returned'] ?? 0,
                  _stats['total'] ?? 1,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  localizations.cancelled,
                  _stats['cancelled'] ?? 0,
                  _stats['total'] ?? 1,
                  primaryRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressIndicator(
                  localizations.successRate,
                  _stats['delivered'] ?? 0,
                  _stats['total'] ?? 1,
                  primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String label, int value, int max, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = (max <= 0) ? 0.0 : (value / max).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : darkGrey,
              ),
            ),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: isDark ? _darkSoftGrey : softGrey,
      appBar: AppBar(
        title: Text(localizations.dashboard),
        backgroundColor: isDark ? _darkCardColor : Colors.white,
        foregroundColor: isDark ? Colors.white : darkGrey,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? _darkCardColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.dashboard,
                                color: primaryBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                  Text(
                                    localizations.driverDashboard,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                                    ),
                                  ),
                    Text(
                                    '${localizations.driverId}: ${widget.driverId}',
                      style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Stats Grid
                    GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                        _buildStatCard(
                            localizations.totalOrders,
                            _stats['total'] ?? 0,
                            Icons.shopping_cart,
                            primaryBlue,
                        ),
                        _buildStatCard(
                            localizations.delivered,
                            _stats['delivered'] ?? 0,
                          Icons.check_circle,
                            accentGreen,
                        ),
                        _buildStatCard(
                            localizations.returned,
                            _stats['returned'] ?? 0,
                            Icons.undo,
                          Colors.orange,
                        ),
                        _buildStatCard(
                            localizations.cancelled,
                            _stats['cancelled'] ?? 0,
                          Icons.cancel,
                            primaryRed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Earnings
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? _darkCardColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: primaryBlue),
                                const SizedBox(width: 8),
                                Text(
                                  localizations.earnings,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(localizations.deliveredOrders, 
                                          _earnings['delivered_orders'] ?? 0, 
                                          Icons.local_shipping, 
                                          primaryBlue),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(localizations.deliveredAmount, 
                                          (_earnings['delivered_amount'] ?? 0.0).toStringAsFixed(2), 
                                          Icons.payments, 
                                          accentGreen),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(localizations.averageTicket, 
                                          (_earnings['average_ticket'] ?? 0.0).toStringAsFixed(2), 
                                          Icons.leaderboard, 
                                          Colors.orange),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard('${localizations.pendingInvoices} (Client)', 
                                          _earnings['pending_payment_invoices'] ?? 0, 
                                          Icons.receipt_long, 
                                          primaryRed),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                      ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Chart
                      _buildChartCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}