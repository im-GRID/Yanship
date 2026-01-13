import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../services/api_config.dart';

class HistoryPage extends StatefulWidget {
  final String driverId;

  const HistoryPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> futureHistory;
  late final String _baseUrl = ApiConfig.resolveBaseUrl();

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

  }
  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Charger l’historique ici, car localizations est dispo
  futureHistory = _fetchHistory();
}

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final localizations = AppLocalizations.of(context);
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/missions/history?driverId=${widget.driverId}'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception(localizations?.error ?? 'Connection error');
      }
    } on TimeoutException {
      throw Exception(localizations?.connectionError ?? 'Request timed out. Check server connection.');
    } catch (e) {
      throw Exception('${localizations?.error ?? "Error"}: $e');
    }
  }

  IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
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
        return accentGreen;
      case 'returned':
        return Colors.purple;
      case 'cancelled':
      case 'rejected':
        return primaryRed;
      default:
        return darkGrey;
    }
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

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final bool isDelivered = order['status_name']?.toString().toLowerCase() == 'delivered';
    final bool hasProof = order['photo_delivered'] != null && order['photo_delivered'].toString().isNotEmpty;
    final bool isInvoiced = order['is_invoiced'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            _buildDetailRow(localizations?.orderId ?? 'Order No', '${order['order_prefix'] ?? ''}${order['order_no'] ?? 'N/A'}', Icons.receipt, isDark),
            _buildDetailRow(localizations?.customerName ?? 'Client', order['receiver_name'] ?? order['person_receives'] ?? 'N/A', Icons.person, isDark),
            _buildDetailRow(localizations?.deliveryAddress ?? 'Address', order['address'] ?? 'N/A', Icons.location_on, isDark),
            _buildDetailRow(localizations?.phoneNumber ?? 'Phone', order['phone'] ?? 'N/A', Icons.phone, isDark),
            _buildDetailRow('City', order['city_name'] ?? 'N/A', Icons.location_city, isDark),
            _buildDetailRow('Date', order['order_date'] ?? 'N/A', Icons.calendar_today, isDark),
            
            // Additional information for delivered orders
            if (isDelivered) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (hasProof) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentGreen),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, size: 12, color: accentGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Proof',
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isInvoiced) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryBlue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt, size: 12, color: primaryBlue),
                          const SizedBox(width: 4),
                          Text(
                            'Invoiced',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white70 : darkGrey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : darkGrey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : darkGrey),
            ),
          ),
        ],
      ),
    );
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
        backgroundColor: isDark ? _darkSoftGrey : softGrey,
        body: SafeArea(
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
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.history,
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
                            'Delivery History',
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
                              color: isDark ? Colors.white70 : darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // History List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: futureHistory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              localizations?.loading ?? 'Loading...',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : darkGrey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: primaryRed.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations?.error ?? 'Error loading history',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : darkGrey.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  futureHistory = _fetchHistory();
                                });
                              },
                              icon: Icon(Icons.refresh),
                              label: Text(localizations?.retry ?? 'Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final history = snapshot.data ?? [];

                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: isDark ? Colors.white38 : darkGrey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No delivery history',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your completed deliveries will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : darkGrey.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              futureHistory = _fetchHistory();
                            });
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryCard(history[index]);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}