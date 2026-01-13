//concerne le livreur
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_config.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class TimelineResult {
  final List<dynamic> events;
  final bool hasError;
  final String errorMessage;

  TimelineResult({
    required this.events,
    this.hasError = false,
    this.errorMessage = '',
  });

  factory TimelineResult.success(List<dynamic> events) {
    return TimelineResult(events: events);
  }

  factory TimelineResult.error(String message) {
    return TimelineResult(
      events: [],
      hasError: true,
      errorMessage: message,
    );
  }
}

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // API base
  late final String _baseUrl = ApiConfig.resolveBaseUrl();
  late Future<TimelineResult> _timelineFuture;

  // Error handling states
  bool _hasNetworkError = false;

  // Generating invoice state
  bool _isGeneratingInvoice = false;

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
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Load timeline data
    _timelineFuture = _fetchTimeline().catchError((error) {
      if (mounted) {
        setState(() {
          _hasNetworkError = true;
        });
      }
      return TimelineResult.error(error.toString());
    });
  }

  Future<TimelineResult> _fetchTimeline() async {
    if (!mounted) return TimelineResult.error('Widget not mounted');
    
    try {
      final id = widget.order['order_id'];
      if (id == null) {
        return TimelineResult.error('Order ID is missing');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/missions/order/$id/timeline'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (!mounted) return TimelineResult.error('Widget disposed during request');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data['success'] == true) {
            final events = data['data'];
            if (events is List) {
              return TimelineResult.success(events);
            } else {
              return TimelineResult.error('Invalid timeline data format');
            }
          } else {
            final errorMsg = data is Map ? (data['message'] ?? 'Unknown server error') : 'Invalid response format';
            return TimelineResult.error(errorMsg);
          }
        } catch (e) {
          return TimelineResult.error('Failed to parse server response');
        }
      } else if (response.statusCode == 404) {
        return TimelineResult.error('Timeline not found for this order');
      } else if (response.statusCode >= 500) {
        return TimelineResult.error('Server error - please try again later');
      } else {
        return TimelineResult.error('Failed to load timeline (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasNetworkError = true;
        });
      }
      
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        return TimelineResult.error('No internet connection - please check your network');
      } else if (e.toString().contains('timeout')) {
        return TimelineResult.error('Request timeout - please try again');
      } else {
        return TimelineResult.error('Failed to load timeline: ${e.toString()}');
      }
    }
  }

  Future<void> _retryLoadingTimeline() async {
    if (!mounted) return;
    
    setState(() {
      _hasNetworkError = false;
    });
    
    try {
      final result = await _fetchTimeline();
      if (mounted) {
        setState(() {
          _timelineFuture = Future.value(result);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasNetworkError = true;
        });
      }
    }
  }

  Future<void> _generateAndPrintOrderInvoice() async {
    if (_isGeneratingInvoice) return;
    final localizations = AppLocalizations.of(context);
    final orderId = widget.order['order_id'];
    final driverId = widget.order['driver_id'];
    if (orderId == null || driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing order or driver id'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isGeneratingInvoice = true; });
    try {
      // Try root-mounted, then /factures prefix
      final endpoints = [
        Uri.parse('$_baseUrl/driver/$driverId/orders/$orderId/invoice'),
        Uri.parse('$_baseUrl/factures/driver/$driverId/orders/$orderId/invoice'),
        Uri.parse('$_baseUrl/api/factures/driver/$driverId/orders/$orderId/invoice'),
      ];
      http.Response? resp;
      for (final uri in endpoints) {
        try {
          final r = await http.post(uri, headers: {'Content-Type': 'application/json'}).timeout(const Duration(seconds: 25));
          resp = r; // capture last response even if non-200 so we can show server message
          if (r.statusCode == 200) { break; }
        } catch (_) {}
      }
      if (resp == null) {
        throw Exception('Failed to generate invoice (no reachable endpoint)');
      }
      if (resp.statusCode != 200) {
        try {
          final body = json.decode(resp.body);
          final msg = body is Map && body['message'] != null ? body['message'] : 'HTTP ${resp.statusCode}';
          throw Exception(msg);
        } catch (_) {
          throw Exception('HTTP ${resp.statusCode}');
        }
      }
      final data = json.decode(resp.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Invoice generation failed');
      }
      final String fileName = data['data']?['fileName'] ?? '';
      if (fileName.isEmpty) {
        throw Exception('No file returned');
      }
      final pdfResp = await http.get(Uri.parse('$_baseUrl/invoices/$fileName')).timeout(const Duration(seconds: 20));
      if (pdfResp.statusCode != 200) {
        throw Exception('Unable to download PDF');
      }
      final bytes = pdfResp.bodyBytes;
      await Printing.layoutPdf(onLayout: (format) async => bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.success ?? 'Invoice ready for printing'), backgroundColor: _accentGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations?.error ?? 'Error'}: $e'), backgroundColor: _primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() { _isGeneratingInvoice = false; });
    }
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _fadeController.dispose();
    _slideController.dispose();
    // Clear any pending FutureBuilders
    _timelineFuture = Future.value(TimelineResult.error('Widget disposed'));
    super.dispose();
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
        return accentGreen;
      case 'confirmed':
        return Colors.amber;
      case 'picked up':
      case 'in transit':
      case 'out for delivery':
        return primaryBlue;
      case 'attempted delivery':
        return Colors.orange;
      case 'returned':
        return Colors.purple;
      case 'cancelled':
      case 'rejected':
        return primaryRed;
      default:
        return darkGrey;
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : darkGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final bool canChangeStatus = widget.order['can_change_status'] ?? true;
    final bool isDelivered = widget.order['status_name']?.toString().toLowerCase() == 'delivered';
    final bool hasProof = widget.order['photo_delivered'] != null && widget.order['photo_delivered'].toString().isNotEmpty;
    final bool isInvoiced = widget.order['is_invoiced'] == 1;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor(widget.order['status_name']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: getStatusColor(widget.order['status_name']),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getStatusIcon(widget.order['status_name']),
                      size: 16,
                      color: getStatusColor(widget.order['status_name']),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.order['status_name'] ?? 'Unknown',
                      style: TextStyle(
                        color: getStatusColor(widget.order['status_name']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!canChangeStatus) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        localizations.locked,
                        style: const TextStyle(
                          color: Colors.orange,
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
          const SizedBox(height: 16),
          if (isDelivered) ...[
            _buildDetailRow(localizations.deliveryStatus, localizations.completed, Icons.check_circle),
            if (hasProof) ...[
              _buildDetailRow(localizations.proofUploaded, localizations.yes, Icons.camera_alt),
              _buildDetailRow(localizations.proofFile, widget.order['photo_delivered'] ?? 'N/A', Icons.attach_file),
            ] else ...[
              _buildDetailRow(localizations.proofUploaded, localizations.no, Icons.camera_alt),
            ],
            if (isInvoiced) ...[
              _buildDetailRow(localizations.invoiceStatus, localizations.generated, Icons.receipt),
            ] else ...[
              _buildDetailRow(localizations.invoiceStatus, localizations.notGenerated, Icons.receipt),
            ],
          ] else ...[
            if (!canChangeStatus) ...[
              _buildDetailRow(localizations.statusNote, localizations.statusCannotChange, Icons.info),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.red[300] : Colors.red[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.orderTimeline,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<TimelineResult>(
            future: _timelineFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final result = snapshot.data ?? TimelineResult.error('Unknown error');
              
              if (result.hasError) {
                return _buildErrorWidget(result.errorMessage, _retryLoadingTimeline);
              }
              
              if (result.events.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? _darkSoftGrey : softGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.white54 : darkGrey.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.noTimelineEvents,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: result.events.map<Widget>((e) {
                  final statusName = e['status_name']?.toString() ?? 'Unknown';
                  final comments = e['comments']?.toString() ?? '';
                  final date = e['t_date']?.toString() ?? '';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          getStatusIcon(statusName), 
                          color: getStatusColor(statusName), 
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusName, 
                                style: TextStyle(
                                  fontWeight: FontWeight.w600, 
                                  color: isDark ? Colors.white : darkGrey,
                                ),
                              ),
                              if (comments.isNotEmpty)
                                Text(
                                  comments, 
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : darkGrey.withOpacity(0.8),
                                  ),
                                ),
                              if (date.isNotEmpty)
                                Text(
                                  date, 
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isDark ? Colors.white54 : darkGrey.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, color: primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.orderInformation,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : darkGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _printLabel,
                        icon: const Icon(Icons.local_printshop, size: 18),
                        label: Text(localizations.printLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isGeneratingInvoice ? null : _generateAndPrintOrderInvoice,
                        icon: _isGeneratingInvoice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.receipt_long, size: 18),
                        label: Text(_isGeneratingInvoice ? 'Please wait...' : 'Generate Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDetailRow(localizations.orderId, '${widget.order['order_prefix'] ?? ''}${widget.order['order_no'] ?? 'N/A'}', Icons.receipt),
          if (widget.order['order_encoded'] != null && widget.order['order_encoded'].toString().isNotEmpty)
            _buildDetailRow(localizations.orderEncoded, widget.order['order_encoded'] ?? 'N/A', Icons.qr_code),
          _buildDetailRow(localizations.orderDate, widget.order['order_date'] ?? 'N/A', Icons.calendar_today),
          _buildDetailRow(localizations.driverId, widget.order['driver_id']?.toString() ?? 'N/A', Icons.person),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.customerInformation,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(localizations.receiverName, widget.order['receiver_name'] ?? 'N/A', Icons.person),
          _buildDetailRow(localizations.personReceives, widget.order['person_receives'] ?? 'N/A', Icons.person_outline),
          _buildDetailRow(localizations.phone, widget.order['phone'] ?? 'N/A', Icons.phone),
          _buildDetailRow(localizations.address, widget.order['address'] ?? 'N/A', Icons.location_on),
          _buildDetailRow(localizations.city, widget.order['city_name'] ?? 'N/A', Icons.location_city),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.paymentInformation,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(localizations.price, '${widget.order['price'] ?? '0'} MAD', Icons.attach_money),
          _buildDetailRow(localizations.priceAfterFee, '${widget.order['price_afterfee'] ?? '0'} MAD', Icons.account_balance_wallet),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final notes = widget.order['notes'];
    if (notes == null || notes.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.notes,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A202C) : softGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF4A5568) : borderColor,
              ),
            ),
            child: Text(
              notes.toString(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : darkGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printLabel() async {
    try {
      final localizations = AppLocalizations.of(context)!;
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
                  child: pw.Text(
                    'YanShip Delivery Label', 
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('${localizations.orderNo}: ${widget.order['order_prefix'] ?? ''}${widget.order['order_no'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('${localizations.receiverName}: ${widget.order['receiver_name'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('${localizations.address}: ${widget.order['address'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('${localizations.phone}: ${widget.order['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('${localizations.city}: ${widget.order['city'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 20),
                if (widget.order['order_no'] != null)
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: widget.order['order_no'].toString(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print label: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: isDark ? _darkSoftGrey : softGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            languageProvider.isRTL ? Icons.arrow_forward : Icons.arrow_back,
            color: isDark ? Colors.white : darkGrey,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localizations.orderDetails,
          style: TextStyle(
            color: isDark ? Colors.white : darkGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasNetworkError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: _retryLoadingTimeline,
              tooltip: 'Retry loading',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _retryLoadingTimeline,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_hasNetworkError)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Some features may not work properly due to network issues',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildStatusSection(),
                  const SizedBox(height: 16),
                  _buildOrderSection(),
                  const SizedBox(height: 16),
                  _buildCustomerSection(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 16),
                  _buildTimelineSection(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}