import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'HomePage.dart';
import 'Profile.dart';
import '../utils/responsive_utils.dart';
import '../providers/order_provider.dart';
import '../l10n/app_localizations.dart';
import './_grouped_orders_list.dart';

// Import status mapping constants from HomePage
const Map<String, int> statusNameToId = {
  'Created': 1,
  'Confirmed': 10,
  'In Transit': 24,
  'Picked up': 25,
  'Out for Delivery': 26,
  'Attempted Delivery': 27,
  'Delivered': 28,
  'Returned': 29,
  'Cancelled': 3,
  'Rejected': 5,
};

const Map<int, String> statusIdToName = {
  1: 'Created',
  3: 'Cancelled',
  5: 'Rejected',
  10: 'Confirmed',
  24: 'In Transit',
  25: 'Picked up',
  26: 'Out for Delivery',
  27: 'Attempted Delivery',
  28: 'Delivered',
  29: 'Returned',
};

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _didLoadOnce = false;
  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  
  // Cache expensive getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;

  String selectedFilter = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Pagination variables
  int currentPage = 1;
  final int ordersPerPage = 15; // Increased from 10 to 15 orders per page
  int get totalPages {
    final totalOrders = filteredOrders.length;
    return (totalOrders / ordersPerPage).ceil();
  }

  // Helper method to get translated status names
  String getLocalizedStatus(String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'created':
        return localizations.pending;
      case 'confirmed':
        return 'Confirmed';
      case 'picked up':
        return localizations.pickedUp;
      case 'delivered':
        return localizations.delivered;
      case 'cancelled':
        return localizations.cancelled;
      case 'rejected':
        return 'Rejected'; // Keep English for now
      case 'in transit':
        return 'In Transit'; // Keep English for now
      case 'out for delivery':
        return 'Out for Delivery'; // Keep English for now
      case 'attempted delivery':
        return 'Attempted Delivery'; // Keep English for now
      case 'returned':
        return 'Returned'; // Keep English for now
      default:
        return status;
    }
  }

  // Updated filter options using translations
  List<String> get filterOptions {
    final localizations = AppLocalizations.of(context)!;
    return [
      'All',  // Keep English for now
      localizations.pending,  // 'Created' maps to pending
      'Confirmed', // 'Confirmed' maps to confirmed with red color
      'In Transit',  // Keep English for now
      localizations.pickedUp,
      'Out for Delivery',  // Keep English for now
      'Attempted Delivery',  // Keep English for now  
      localizations.delivered,
      'Returned',  // Keep English for now
      localizations.cancelled,
      'Rejected'  // Keep English for now
    ];
  }

  // Map localized filter names back to English status names for filtering
  String mapFilterToStatusName(String filter) {
    final localizations = AppLocalizations.of(context)!;
    
    if (filter == 'All') return 'All';
    if (filter == localizations.pending) return 'Created';
    if (filter == 'Confirmed') return 'Confirmed';
    if (filter == 'In Transit') return 'In Transit';
    if (filter == localizations.pickedUp) return 'Picked up';
    if (filter == 'Out for Delivery') return 'Out for Delivery';
    if (filter == 'Attempted Delivery') return 'Attempted Delivery';
    if (filter == localizations.delivered) return 'Delivered';
    if (filter == 'Returned') return 'Returned';
    if (filter == localizations.cancelled) return 'Cancelled';
    if (filter == 'Rejected') return 'Rejected';
    
    return filter; // Fallback to original filter
  }
  
  // Cached filtered orders to avoid rebuilding on every build
  List<Map<String, dynamic>>? _cachedFilteredOrders;
  String? _lastSelectedFilter;
  String? _lastSearchQuery;

  // Keep state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
        _cachedFilteredOrders = null; // Invalidate cache
        currentPage = 1; // Reset to first page when search changes
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadOnce) {
      final orderProvider = context.read<OrderProvider>();
      orderProvider.loadAllOrders(refresh: true);
      if (orderProvider.recentOrders.isEmpty) {
        orderProvider.loadRecentOrders();
      }
      _didLoadOnce = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Status conversion methods - same as HomePage
  static String getStatusDisplayName(dynamic status) {
    if (status == null) return 'Unknown';
    
    if (status is int) {
      return statusIdToName[status] ?? 'Unknown Status ($status)';
    }
    
    if (status is String) {
      if (statusNameToId.containsKey(status)) return status;
      
      final intStatus = int.tryParse(status);
      if (intStatus != null && statusIdToName.containsKey(intStatus)) {
        return statusIdToName[intStatus]!;
      }
      
      // Handle legacy statuses
      return _mapLegacyStatus(status.toLowerCase().trim());
    }
    
    return 'Unknown';
  }

  static String _mapLegacyStatus(String status) {
    const legacyMapping = {
      'pending': 'Created',
      'in transit': 'Out for Delivery',
      'intransit': 'Out for Delivery', 
      'failed': 'Cancelled',
      'pickedup': 'Picked up',
      'attempteddelivery': 'Attempted Delivery',
      'outfordelivery': 'Out for Delivery',
    };
    
    return legacyMapping[status] ?? 
           statusIdToName.values.firstWhere(
             (name) => name.toLowerCase() == status, 
             orElse: () => status
           );
  }

  // Map status codes to readable text - deprecated, use getStatusDisplayName instead
  String getStatusText(dynamic status) {
    return getStatusDisplayName(status);
  }

  /* 
  // DEPRECATED: No longer needed since OrderProvider now formats orders correctly
  // Map backend order data to UI-expected format
  Map<String, dynamic> mapOrderData(Map<String, dynamic> backendOrder) {
    print('Debug - Backend Order: $backendOrder');
    
    final mappedOrder = {
      'id': backendOrder['id']?.toString() ?? '',
      'tracking': backendOrder['trackingNumber']?.toString() ?? 'N/A',
      'status': getStatusDisplayName(backendOrder['status']), // Use consistent status mapping
      'recipient': backendOrder['recipientName']?.toString() ?? 'N/A',
      'city': backendOrder['cityName']?.toString() ?? 'N/A',
      'date': backendOrder['created_at'] != null 
          ? DateTime.parse(backendOrder['created_at'].toString()).toString().split(' ')[0]
          : 'N/A',
      'price': '\$${backendOrder['price']?.toString() ?? '0'}',
      'phone': backendOrder['phone']?.toString() ?? 'N/A',
      'address': backendOrder['deliveryAddress']?.toString() ?? 'N/A',
      'senderAddress': backendOrder['senderAddress'] != null 
          ? '${backendOrder['senderAddress']['address'] ?? ''}, ${backendOrder['senderAddress']['name'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '')
          : 'N/A',
      'deliveryTime': 'N/A', // Can be enhanced with actual delivery time from backend
      'rating': 0, // Default rating, can be enhanced later
      'statusHistory': backendOrder['statusHistory'] ?? {},
    };
    
    print('Debug - Mapped Order: $mappedOrder');
    return mappedOrder;
  }
  */

  List<Map<String, dynamic>> get filteredOrders {
    final orderProvider = context.watch<OrderProvider>();
    // Use allOrders for complete history, fallback to recentOrders
    final orders = orderProvider.allOrders.isNotEmpty 
        ? orderProvider.allOrders 
        : orderProvider.recentOrders;
    
    print('Debug - Backend Orders count: ${orders.length}');
    print('Debug - Backend Orders: $orders');
    
    // Check if cache is valid
    if (_cachedFilteredOrders != null && 
        _lastSelectedFilter == selectedFilter && 
        _lastSearchQuery == searchQuery) {
      return _cachedFilteredOrders!;
    }
    
    // Use orders directly from OrderProvider (they should already be properly formatted)
    List<Map<String, dynamic>> filtered = List.from(orders);
    
    // Apply filters
    // Filter by status
    if (selectedFilter != 'All') {
      final statusName = mapFilterToStatusName(selectedFilter);
      filtered = filtered.where((o) => getStatusDisplayName(o['status']) == statusName).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((o) => 
        (o['fullTrackingNumber'] ?? o['tracking'] ?? '').toLowerCase().contains(query) ||
        (o['tracking'] ?? '').toLowerCase().contains(query) ||
        (o['recipient'] ?? '').toLowerCase().contains(query) ||
        (o['city'] ?? '').toLowerCase().contains(query)
      ).toList();
    }
    
    // Update cache
    _cachedFilteredOrders = filtered;
    _lastSelectedFilter = selectedFilter;
    _lastSearchQuery = searchQuery;
    
    print('Debug - Filtered Orders count: ${filtered.length}');
    return filtered;
  }

  // Get orders for current page
  List<Map<String, dynamic>> get paginatedOrders {
    final orders = filteredOrders;
    final startIndex = (currentPage - 1) * ordersPerPage;
    final endIndex = (startIndex + ordersPerPage).clamp(0, orders.length);
    
    if (startIndex >= orders.length) return [];
    return orders.sublist(startIndex, endIndex);
  }

  // Pagination controls widget
  Widget _buildPaginationControls() {
    if (totalPages <= 1) return Container(); // Hide pagination if only one page

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          Flexible(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: currentPage > 1 ? () {
                setState(() {
                  currentPage--;
                });
              } : null,
              icon: Icon(Icons.chevron_left, size: 16),
              label: Text('Prev', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPage > 1 ? primaryBlue : Colors.grey.shade300,
                foregroundColor: currentPage > 1 ? Colors.white : Colors.grey.shade600,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size(60, 28), // Smaller minimum size
              ),
            ),
          ),
          
          // Page info
          Flexible(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Page $currentPage of $totalPages',
                style: TextStyle(
                  fontSize: 11, // Smaller font size
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Next button
          Flexible(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: currentPage < totalPages ? () {
                setState(() {
                  currentPage++;
                });
              } : null,
              icon: Icon(Icons.chevron_right, size: 16),
              label: Text('Next', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPage < totalPages ? primaryBlue : Colors.grey.shade300,
                foregroundColor: currentPage < totalPages ? Colors.white : Colors.grey.shade600,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size(60, 28), // Smaller minimum size
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      case 'created':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'picked up':
        return Colors.purple;
      case 'in transit':
        return Colors.indigo;
      case 'out for delivery':
        return Colors.teal;
      case 'attempted delivery':
        return Colors.amber;
      case 'returned':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      case 'created':
        return Icons.access_time;
      case 'confirmed':
        return Icons.verified;
      case 'picked up':
        return Icons.local_shipping;
      case 'in transit':
        return Icons.local_shipping;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'attempted delivery':
        return Icons.warning;
      case 'returned':
        return Icons.keyboard_return;
      default:
        return Icons.help;
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildStatsCard() {
    final orderProvider = context.watch<OrderProvider>();
    // Use allOrders for complete history, fallback to recentOrders
    final orders = orderProvider.allOrders.isNotEmpty 
        ? orderProvider.allOrders 
        : orderProvider.recentOrders;
    
    // Calculate stats using the properly formatted orders
    final total = orders.length;
    final confirmed = orders.where((o) => getStatusDisplayName(o['status']) == 'Confirmed').length;
    final pickedUp = orders.where((o) => getStatusDisplayName(o['status']) == 'Picked up').length;
    final delivered = orders.where((o) => getStatusDisplayName(o['status']) == 'Delivered').length;
    final cancelled = orders.where((o) => getStatusDisplayName(o['status']) == 'Cancelled').length;

    return Container(
      margin: ResponsiveUtils.getResponsivePadding(context),
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withAlpha((0.1 * 255).toInt()),
            primaryRed.withAlpha((0.05 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.deliveryStatistics,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 24),
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          // First row of stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', total, Colors.blue),
              ),
              Expanded(
                child: _buildStatItem('Confirmed', confirmed, Colors.red),
              ),
              Expanded(
                child: _buildStatItem(AppLocalizations.of(context)!.pickedUp, pickedUp, Colors.indigo),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
          // Second row of stats  
          Row(
            children: [
              Expanded(
                child: _buildStatItem(AppLocalizations.of(context)!.delivered, delivered, Colors.green),
              ),
              Expanded(
                child: _buildStatItem(AppLocalizations.of(context)!.cancelled, cancelled, Colors.red),
              ),
              Expanded(
                child: Container(), // Empty space for symmetry
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20, tablet: 24, desktop: 28),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF161B22) 
        : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF161B22) 
            : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.orderDetailsTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryRed,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(AppLocalizations.of(context)!.trackingInfoSection, [
                      _buildDetailRow(AppLocalizations.of(context)!.trackingId, 
                        order['fullTrackingNumber'] ?? order['tracking'] ?? 'N/A'),
                      _buildDetailRow(AppLocalizations.of(context)!.status, getLocalizedStatus(order['status'] ?? 'Unknown'), 
                        valueColor: getStatusColor(order['status'] ?? 'Unknown')),
                      _buildDetailRow(AppLocalizations.of(context)!.date, order['date']),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailCard(AppLocalizations.of(context)!.customerInfoSection, [
                      _buildDetailRow(AppLocalizations.of(context)!.recipient, order['recipient']),
                      _buildDetailRow(AppLocalizations.of(context)!.phone, order['phone']),
                      _buildDetailRow(AppLocalizations.of(context)!.city, order['city']),
                      _buildDetailRow(AppLocalizations.of(context)!.address, order['address']),
                    ]),
                    SizedBox(height: 16),
                    _buildDetailCard(AppLocalizations.of(context)!.orderSummarySection, [
                      _buildDetailRow(AppLocalizations.of(context)!.price, order['price'], 
                        valueColor: primaryBlue),
                      if ((order['rating'] ?? 0) > 0)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppLocalizations.of(context)!.rating, style: TextStyle(fontWeight: FontWeight.w500)),
                              _buildRatingStars(order['rating'] ?? 0),
                            ],
                          ),
                        ),
                    ]),
                    SizedBox(height: 16),
                    _buildStatusHistoryCard(order),
                    if (order['status'] == 'Delivered') ...[
                      SizedBox(height: 16),
                      _buildPrintInvoiceButton(order),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF21262D) 
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D) 
            : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: valueColor ?? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade300 
                  : Colors.grey.shade700),
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHistoryDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return dateValue.toString();
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildStatusHistoryCard(Map<String, dynamic> order) {
    // Safely handle statusHistory with proper type conversion
    final rawStatusHistory = order['statusHistory'];
    final statusHistory = <String, dynamic>{};
    
    if (rawStatusHistory is Map) {
      rawStatusHistory.forEach((key, value) {
        statusHistory[key.toString()] = value;
      });
    }
    
    // Sort history entries by date (newest first)
    final sortedEntries = statusHistory.entries.toList()
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a.value.toString());
          final dateB = DateTime.parse(b.value.toString());
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          return 0;
        }
      });

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF21262D) 
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D) 
            : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.statusHistory,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 12),
          sortedEntries.isEmpty 
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No history available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            : Column(
                children: sortedEntries.map<Widget>((entry) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xff4f46e5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : const Color(0xff1e1e2d),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatHistoryDate(entry.value),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        AppLocalizations.of(context)!.history,
        style: TextStyle(
          color: primaryRed,
          fontWeight: FontWeight.bold,
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 24),
        ),
      ),
      centerTitle: ResponsiveUtils.shouldCenterTitle(context),
      bottom: TabBar(
        controller: _tabController,
        labelColor: primaryRed,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        indicatorColor: primaryRed,
        labelStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
        ),
        tabs: [
        Tab(text: AppLocalizations.of(context)!.overview),
        Tab(text: AppLocalizations.of(context)!.orders),
        Tab(text: AppLocalizations.of(context)!.analytics),
        ],
      ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',  // Keep English for now
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          if (orderProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 64, tablet: 72, desktop: 80),
                    color: primaryRed,
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                  Text(
                    'Error loading orders',  // Keep English for now
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 24),
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                  Text(
                    orderProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => orderProvider.loadRecentOrders(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Retry',  // Keep English for now
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
        // Overview Tab
        SingleChildScrollView(
        child: Column(
        children: [
        _buildStatsCard(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            AppLocalizations.of(context)!.recentActivity,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
            ),
            SizedBox(height: 16),
            ...filteredOrders.take(3).map((order) => _buildOrderCard(order)),
          ],
          ),
        ),
        ],
      ),
      ),

      // Orders Tab
      Column(
      children: [
        // Search and Filter
        Padding(
        padding: EdgeInsets.all(12), // Reduced from 16 to 12
        child: Column(
          children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            hintText: AppLocalizations.of(context)!.searchOrders,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF161B22)
              : Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
            ),
          ),
          SizedBox(height: 8), // Reduced from 12 to 8
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            children: filterOptions.map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(filter, style: TextStyle(fontSize: 12)), // Smaller font
                onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
                  currentPage = 1; // Reset to first page when filter changes
                });
                },
                selectedColor: primaryBlue.withAlpha((0.2 * 255).toInt()),
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF21262D) 
                  : null,
                labelStyle: TextStyle(
                color: isSelected 
                  ? primaryBlue 
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[700]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11, // Smaller font size
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Compact tap target
                visualDensity: VisualDensity.compact, // Compact density
              ),
              );
            }).toList(),
            ),
          ),
          ],
        ),
        ),
        
        // Orders List with Pagination
        Expanded(
          child: Column(
            children: [
              // Orders count info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${paginatedOrders.length} of ${filteredOrders.length} orders',
                      style: TextStyle(
                        fontSize: 11, // Reduced from 12 to 11
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (filteredOrders.length > ordersPerPage)
                      Text(
                        'Page $currentPage of $totalPages',
                        style: TextStyle(
                          fontSize: 11, // Reduced from 12 to 11
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              // Orders List
              Expanded(
                child: paginatedOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (searchQuery.isNotEmpty || selectedFilter != 'All') ...[
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : GroupedOrdersList(
                      orders: paginatedOrders,
                      buildOrderCard: _buildOrderCard,
                    ),
              ),
              // Pagination Controls
              _buildPaginationControls(),
            ],
          ),
        ),
      ],
      ),

      // Analytics Tab
      Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          AppLocalizations.of(context)!.performanceAnalytics,
          style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryRed,
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                final orders = orderProvider.allOrders.isNotEmpty 
                    ? orderProvider.allOrders 
                    : orderProvider.recentOrders;
                final analytics = _calculateAnalytics(orders);
                
                return Column(
                  children: [
                    _buildAnalyticsCard(AppLocalizations.of(context)!.successRate, analytics['successRate'], Colors.green, Icons.trending_up),
                    SizedBox(height: 12),
                    _buildAnalyticsCard('Top City', analytics['topCity'], Colors.orange, Icons.location_city),
                    SizedBox(height: 12),
                    _buildAnalyticsCard(AppLocalizations.of(context)!.totalRevenue, analytics['totalRevenue'], Colors.purple, Icons.attach_money),
                    SizedBox(height: 20), // Extra space at bottom
                  ],
                );
              },
            ),
          ),
        ),
        ],
      ),
      ),
    ],
    );
        },
      ),
      bottomNavigationBar: SafeArea(
      child: Container(
        margin: EdgeInsets.only(left: 20, right: 20, bottom: 16),
        height: 65,
        decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark 
            ? [
                const Color(0xFF161B22).withAlpha((0.95 * 255).toInt()),
                const Color(0xFF161B22),
              ]
            : [
                Colors.white.withAlpha((0.95 * 255).toInt()),
                Colors.white,
              ],
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D).withAlpha((0.8 * 255).toInt())
            : Colors.white.withAlpha((0.8 * 255).toInt()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF161B22).withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
          blurRadius: 20,
          offset: Offset(0, -2),
          spreadRadius: 0,
          ),
          BoxShadow(
          color: Colors.black.withAlpha((0.08 * 255).toInt()),
          blurRadius: 25,
          offset: Offset(0, 8),
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
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          items: [
            BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 24),
            label: 'Home',  // Keep English for now
            ),
            BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded, size: 24),
            label: AppLocalizations.of(context)!.history,
            ),
            BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 24),
            label: 'Profile',  // Keep English for now
            ),
          ],
          onTap: (index) {
            switch (index) {
            case 0:
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              );
              break;
            case 1:
              // Already on History page
              break;
            case 2:
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              break;
            }
          },
          ),
        ),
        ),
        ),
      ),
    ); // Scaffold
  }

  // Helper function to format date nicely
  String formatOrderDate(Map<String, dynamic> order) {
    // Try different date fields
    String? dateStr = order['created_at']?.toString() ?? 
                     order['date']?.toString() ?? 
                     order['order_datetime']?.toString();
    
    if (dateStr == null || dateStr == 'N/A') {
      return 'N/A';
    }
    
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      
      // Always show the actual date instead of relative dates like "Today"
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      String month = months[dateTime.month - 1];
      
      // If time is midnight (00:00), show only the date
      if (dateTime.hour == 0 && dateTime.minute == 0) {
        return '${dateTime.day} $month ${dateTime.year}';
      }
      
      // Otherwise show date with time: "24 Jul 2025 15:30"
      return '${dateTime.day} $month ${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
      return dateStr.split(' ')[0]; // Return just the date part if parsing fails
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColor = getStatusColor(order['status'] ?? 'Unknown');
    final statusIcon = getStatusIcon(order['status'] ?? 'Unknown');
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        padding: EdgeInsets.all(12), // Fixed reduced padding instead of responsive
        margin: EdgeInsets.only(bottom: 6), // Fixed reduced margin
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF161B22)
            : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12), // Fixed smaller radius
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF30363D)
              : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arabic layout: text on left, badge on right in same row
            if (isArabic) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: tracking number and recipient info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First row: Order prefix and tracking number
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: order['orderPrefix'] ?? 'N/A',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13, // Fixed smaller font size
                                  color: primaryRed,
                                ),
                              ),
                              TextSpan(
                                text: '-${order['trackingNumber'] ?? order['tracking'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // Fixed smaller font size
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 3), // Fixed smaller spacing
                        Text(
                          '${AppLocalizations.of(context)!.toPrefix} ${order['recipient'] ?? 'N/A'} - ${order['city'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12, // Fixed smaller font size
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8), // Fixed spacing
                  // Right side: status badge
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Fixed smaller padding
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(16), // Fixed smaller radius
                        border: Border.all(color: statusColor.withAlpha((0.3 * 255).toInt())),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon, 
                            size: 12, // Fixed smaller icon size
                            color: statusColor
                          ),
                          SizedBox(width: 3), // Fixed smaller spacing
                          Flexible(
                            child: Text(
                              getLocalizedStatus(order['status'] ?? 'Unknown'),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10, // Fixed smaller font size
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Non-Arabic layout: original structure with tracking and badge in top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // First row: Order prefix and tracking number  
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: order['orderPrefix'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13, // Fixed smaller font size
                            color: primaryRed,
                          ),
                        ),
                        TextSpan(
                          text: '-${order['trackingNumber'] ?? order['tracking'] ?? 'N/A'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Fixed smaller font size
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Fixed smaller padding
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16), // Fixed smaller radius
                      border: Border.all(color: statusColor.withAlpha((0.3 * 255).toInt())),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon, 
                          size: 12, // Fixed smaller icon size
                          color: statusColor
                        ),
                        SizedBox(width: 3), // Fixed smaller spacing
                        Text(
                          getLocalizedStatus(order['status'] ?? 'Unknown'),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10, // Fixed smaller font size
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6), // Fixed smaller spacing
              Text(
                '${AppLocalizations.of(context)!.toPrefix} ${order['recipient'] ?? 'N/A'} - ${order['city'] ?? 'N/A'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12, // Fixed smaller font size
                ),
              ),
            ],
            SizedBox(height: 4), // Fixed smaller spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12, // Fixed smaller icon size
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 3), // Fixed smaller spacing
                    Text(
                      formatOrderDate(order),
                      style: TextStyle(
                        color: Colors.grey.shade500, 
                        fontSize: 11, // Fixed smaller font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      order['price'] ?? '\$0',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((order['rating'] ?? 0) > 0) ...[
                      SizedBox(width: 8),
                      _buildRatingStars(order['rating'] ?? 0),
                    ],
                    if (order['status'] == 'Delivered') ...[
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () => _printInvoice(order),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryBlue.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.print,
                            size: 16,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calculate real analytics based on order data
  Map<String, dynamic> _calculateAnalytics(List<Map<String, dynamic>> orders) {
    print('Analytics Debug - Total orders: ${orders.length}');
    
    if (orders.isEmpty) {
      print('No orders found');
      return {
        'successRate': '0%',
        'topCity': 'N/A (0 orders)',
        'totalRevenue': '0.00 MAD',
      };
    }

    // Debug: Print sample order data
    if (orders.isNotEmpty) {
      print('📋 Sample order data: ${orders.first}');
      print('📋 All available fields: ${orders.first.keys.toList()}');
    }

    // Calculate success rate - matching SQL logic exactly
    // SQL: Success Rate: (COUNT(CASE WHEN status_courier = 'delivered' THEN 1 END) / COUNT(*)) * 100
    print('Success Rate Debug - Checking all ${orders.length} orders:');
    
    int deliveredCount = 0;
    for (int i = 0; i < orders.length; i++) {
      var order = orders[i];
      String status = (order['status']?.toString() ?? '').toLowerCase();
      String displayStatus = getStatusDisplayName(order['status']);
      bool isDelivered = status == 'delivered' || status == '28' || displayStatus == 'Delivered';
      
      print('📋 Order ${i+1}: status="$status", displayStatus="$displayStatus", isDelivered=$isDelivered');
      
      if (isDelivered) {
        deliveredCount++;
      }
    }
    
    final totalCount = orders.length;
    final successRate = totalCount > 0 ? (deliveredCount / totalCount) * 100 : 0.0;
    
    print('Success Rate: ($deliveredCount delivered / $totalCount total) × 100 = ${successRate.toStringAsFixed(1)}%');
    print('Expected from SQL: Check your database query result to compare');

    // Calculate total revenue - sum of DELIVERED orders only (matching SQL query)
    // SQL: SELECT SUM(o.price) FROM cdb_users u JOIN cdb_add_order o ON u.id = o.user_id WHERE u.id = 65 AND o.status_courier = 28
    double totalRevenue = 0.0;
    
    // Filter for delivered orders only (status 28 = delivered)
    final deliveredOrdersForRevenue = orders.where((o) {
      String status = (o['status']?.toString() ?? '').toLowerCase();
      return status == 'delivered' || status == '28' || getStatusDisplayName(o['status']) == 'Delivered';
    }).toList();
    
    print('Revenue Debug - Delivered orders only: ${deliveredOrdersForRevenue.length} out of ${orders.length} total');
    
    for (var order in deliveredOrdersForRevenue) {
      String priceStr = '';
      
      // Handle different price field names and formats - check common field names
      if (order['total_price'] != null) {
        priceStr = order['total_price'].toString();
        print('Found total_price field: $priceStr');
      } else if (order['price'] != null) {
        priceStr = order['price'].toString();
        print('Found price field: $priceStr');
      } else if (order['delivery_amount'] != null) {
        priceStr = order['delivery_amount'].toString();
        print('Found delivery_amount field: $priceStr');
      } else if (order['amount'] != null) {
        priceStr = order['amount'].toString();
        print('Found amount field: $priceStr');
      } else if (order['total'] != null) {
        priceStr = order['total'].toString();
        print('Found total field: $priceStr');
      } else if (order['cost'] != null) {
        priceStr = order['cost'].toString();
        print('Found cost field: $priceStr');
      } else if (order['fee'] != null) {
        priceStr = order['fee'].toString();
        print('Found fee field: $priceStr');
      } else {
        print('No price field found in delivered order: ${order.keys.toList()}');
        continue;
      }
      
      // Remove currency symbols and parse (handle MAD, $, etc.)
      String cleanPriceStr = priceStr;
      if (cleanPriceStr.startsWith('\$')) {
        cleanPriceStr = cleanPriceStr.substring(1);
      }
      // Handle MAD currency format like "350 MAD" or "350MAD"
      if (cleanPriceStr.contains('MAD')) {
        cleanPriceStr = cleanPriceStr.replaceAll('MAD', '').trim();
      }
      // Handle other common currency formats
      cleanPriceStr = cleanPriceStr.replaceAll(RegExp(r'[^\d\.]'), '');
      
      double orderAmount = double.tryParse(cleanPriceStr) ?? 0.0;
      totalRevenue += orderAmount;
      print('Delivered order - Cleaned price: "$cleanPriceStr" → Amount: $orderAmount, Running total: $totalRevenue');
    }
    
    print('Final revenue (delivered orders only): $totalRevenue MAD');

    // Calculate orders by city
    Map<String, int> cityOrders = {};
    for (var order in orders) {
      String city = order['city']?.toString() ?? order['cityName']?.toString() ?? 'Unknown';
      cityOrders[city] = (cityOrders[city] ?? 0) + 1;
    }
    
    // Find the city with the most orders
    String topCity = 'N/A';
    int topCityCount = 0;
    if (cityOrders.isNotEmpty) {
      cityOrders.forEach((city, count) {
        if (count > topCityCount) {
          topCity = city;
          topCityCount = count;
        }
      });
    }
    print('🏙️ Orders by city: $cityOrders');
    print('Top city: $topCity with $topCityCount orders');

    return {
      'successRate': '${successRate.toStringAsFixed(1)}%',
      'topCity': '$topCity ($topCityCount orders)',
      'totalRevenue': '${totalRevenue.toStringAsFixed(2)} MAD',
    };
  }

  Widget _buildPrintInvoiceButton(Map<String, dynamic> order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _printInvoice(order),
        icon: Icon(Icons.print, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.printInvoiceButton,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _printInvoice(Map<String, dynamic> order) {
    // Show a confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.print, color: primaryBlue),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.printInvoiceButton),
            ],
          ),
          content: Text(
            '${AppLocalizations.of(context)!.generateInvoiceDialog} ${order['fullTrackingNumber'] ?? order['tracking'] ?? 'N/A'}?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancelButton, style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateInvoice(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(AppLocalizations.of(context)!.printButton, style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _generateInvoice(Map<String, dynamic> order) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryBlue),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.generatingInvoiceText),
            ],
          ),
        );
      },
    );

    // Simulate invoice generation process
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('${AppLocalizations.of(context)!.invoiceSuccessPrefix} ${order['fullTrackingNumber'] ?? order['tracking'] ?? 'N/A'} ${AppLocalizations.of(context)!.invoiceSuccessSuffix}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}
