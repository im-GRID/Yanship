import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';

import '../providers/order_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';
import '../utils/label_printing.dart';
import 'CreateOrder.dart';
import 'Notifications.dart';
import 'History.dart';
import 'Profile.dart';
import 'EditOrder.dart';
import 'ClientsPage.dart';

// Status mapping constants
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Configuration
  static const int _maxLatestOrders = 10; // Show only latest 10 orders
  
  // UI State
  String filterType = 'All'; // Will be updated in initState with localized value
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Selection State
  Set<String> selectedOrders = <String>{};
  bool isSelectionMode = false;
  Set<String> expandedOrders = <String>{};
  
  // Timer for periodic refresh
  Timer? _notificationTimer;
  
  // Constants
  static const int _currentIndex = 0;
  static const Color _primaryRed = Color(0xFFD32F2F);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _softGrey = Color(0xFFF5F5F5);
  
  // Getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get softGrey => _softGrey;
  
  @override
  bool get wantKeepAlive => true;

  // Build filter options dynamically with localization
  List<String> getFilterOptions(BuildContext context) {
    return [
      AppLocalizations.of(context)!.all,
      AppLocalizations.of(context)!.statusCreated,
      AppLocalizations.of(context)!.statusConfirmed,
      AppLocalizations.of(context)!.statusInTransit,
      AppLocalizations.of(context)!.statusPickedUp,
      AppLocalizations.of(context)!.statusOutForDelivery,
      AppLocalizations.of(context)!.statusAttemptedDelivery,
      AppLocalizations.of(context)!.statusDelivered,
      AppLocalizations.of(context)!.statusReturned,
      AppLocalizations.of(context)!.statusCancelled,
      AppLocalizations.of(context)!.statusRejected,
    ];
  }

  // Status conversion methods
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

  // Localized version of status display name
  String getLocalizedStatusDisplayName(BuildContext context, dynamic status) {
    final englishStatus = getStatusDisplayName(status);
    
    switch (englishStatus) {
      case 'Created': return AppLocalizations.of(context)!.statusCreated;
      case 'Confirmed': return AppLocalizations.of(context)!.statusConfirmed;
      case 'In Transit': return AppLocalizations.of(context)!.statusInTransit;
      case 'Picked up': return AppLocalizations.of(context)!.statusPickedUp;
      case 'Out for Delivery': return AppLocalizations.of(context)!.statusOutForDelivery;
      case 'Attempted Delivery': return AppLocalizations.of(context)!.statusAttemptedDelivery;
      case 'Delivered': return AppLocalizations.of(context)!.statusDelivered;
      case 'Returned': return AppLocalizations.of(context)!.statusReturned;
      case 'Cancelled': return AppLocalizations.of(context)!.statusCancelled;
      case 'Rejected': return AppLocalizations.of(context)!.statusRejected;
      case 'Unknown':
      default: return AppLocalizations.of(context)!.unknown;
    }
  }

  // Convert localized status back to English for filtering
  static String getEnglishStatusFromLocalized(BuildContext context, String localizedStatus) {
    if (localizedStatus == AppLocalizations.of(context)!.all) return 'All';
    if (localizedStatus == AppLocalizations.of(context)!.statusCreated) return 'Created';
    if (localizedStatus == AppLocalizations.of(context)!.statusConfirmed) return 'Confirmed';
    if (localizedStatus == AppLocalizations.of(context)!.statusInTransit) return 'In Transit';
    if (localizedStatus == AppLocalizations.of(context)!.statusPickedUp) return 'Picked up';
    if (localizedStatus == AppLocalizations.of(context)!.statusOutForDelivery) return 'Out for Delivery';
    if (localizedStatus == AppLocalizations.of(context)!.statusAttemptedDelivery) return 'Attempted Delivery';
    if (localizedStatus == AppLocalizations.of(context)!.statusDelivered) return 'Delivered';
    if (localizedStatus == AppLocalizations.of(context)!.statusReturned) return 'Returned';
    if (localizedStatus == AppLocalizations.of(context)!.statusCancelled) return 'Cancelled';
    if (localizedStatus == AppLocalizations.of(context)!.statusRejected) return 'Rejected';
    return 'All'; // Default fallback
  }

  static String _mapLegacyStatus(String status) {
    const legacyMapping = {
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

  static int? getStatusId(String statusName) => statusNameToId[statusName];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load orders when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadRecentOrders();
      context.read<NotificationProvider>().loadUnreadCount();
    });
    
    // Set up periodic refresh for unread count (every 30 seconds)
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      context.read<NotificationProvider>().refresh();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh unread count when app comes to foreground
      context.read<NotificationProvider>().refresh();
    }
  }
  
  // Load unread notification count
  Future<void> _loadUnreadNotificationCount() async {
    context.read<NotificationProvider>().refresh();
  }
  
  // Public method to refresh notification count (can be called from other widgets)
  void refreshNotificationCount() {
    context.read<NotificationProvider>().refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Badge color methods
  static Color getBadgeColor(String status) {
    const colorMap = {
      'delivered': Colors.green,
      'confirmed': _primaryBlue,
      'picked up': Colors.purple,
      'in transit': Colors.orange,
      'out for delivery': Colors.orange,
      'attempted delivery': Colors.amber,
      'returned': Colors.brown,
      'cancelled': Colors.red,
      'rejected': Colors.red,
      'created': Colors.grey,
    };
    
    return colorMap[status.toLowerCase()] ?? Colors.grey;
  }

  static Color getBadgeBgColor(String status) => 
      getBadgeColor(status).withOpacity(0.15);

  // Order management methods
  void _changeOrderStatus(String tracking, String newStatus) {
    final statusId = getStatusId(newStatus);
    if (statusId != null) {
      print('Changing order $tracking to status: $newStatus (ID: $statusId)');
    }
    context.read<OrderProvider>().updateOrderStatusLocally(tracking, newStatus);
  }

  void _toggleSelection(String tracking) {
    setState(() {
      if (selectedOrders.contains(tracking)) {
        selectedOrders.remove(tracking);
      } else {
        selectedOrders.add(tracking);
      }
      isSelectionMode = selectedOrders.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedOrders.clear();
      isSelectionMode = false;
    });
  }

  void _toggleExpansion(String tracking) {
    setState(() {
      if (expandedOrders.contains(tracking)) {
        expandedOrders.remove(tracking);
      } else {
        expandedOrders.add(tracking);
      }
    });
  }

  void _pickupAllConfirmedOrders() async {
    final orderProvider = context.read<OrderProvider>();
    
    // Check if there are any confirmed orders first
    final confirmedOrders = orderProvider.recentOrders
        .where((order) => getStatusDisplayName(order['status']) == 'Confirmed')
        .toList();
        
    if (confirmedOrders.isEmpty) {
      _showSnackBar('No confirmed orders to pick up', Colors.orange);
      return;
    }

    try {
      // Call the API to bulk pickup all confirmed orders
      final success = await orderProvider.bulkPickupOrders();
      
      if (success) {
        _showSnackBar('${confirmedOrders.length} ${AppLocalizations.of(context)!.ordersPickedUpSuccessfully}', primaryBlue);
        // Refresh orders to get the latest status from server
        await orderProvider.loadRecentOrders();
      } else {
        final errorMessage = orderProvider.errorMessage ?? AppLocalizations.of(context)!.failedToPickupOrders;
        _showSnackBar('${AppLocalizations.of(context)!.error}: $errorMessage', primaryRed);
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.errorPickingUpOrders}: $e', primaryRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showOrderOptions(Map<String, dynamic> order) {
    final statusDisplay = getStatusDisplayName(order['status']);
    final isCreated = statusDisplay == 'Created';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OrderOptionsBottomSheet(
        order: order,
        primaryBlue: primaryBlue,
        primaryRed: primaryRed,
        onEdit: isCreated ? () => _editOrder(order) : null,
        onViewDetails: () {
          Navigator.pop(context);
          _toggleExpansion(order['trackingNumber']);
        },
        onCancel: isCreated ? () => _cancelOrder(order) : null,
        onConfirm: isCreated ? () => _confirmOrder(order) : null,
        onPrintLabel: () async {
          final messenger = ScaffoldMessenger.of(context);
          final localizations = AppLocalizations.of(context)!;
          Navigator.pop(context);
          try {
            await printOrderLabel(order);
            messenger.showSnackBar(
              SnackBar(content: Text(localizations.labelPrintedSuccess), backgroundColor: primaryBlue),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('Error printing label: $e'), backgroundColor: primaryRed),
            );
          }
        },
      ),
    );
  }

  // Edit order - navigate to edit page
  void _editOrder(Map<String, dynamic> order) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderPage(order: order),
      ),
    ).then((_) {
      // Refresh orders when returning from edit page
      context.read<OrderProvider>().loadRecentOrders();
    });
  }

  // Cancel order - delete from database
  void _cancelOrder(Map<String, dynamic> order) {
    Navigator.pop(context);
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelOrder),
        content: Text(
          'Are you sure you want to cancel order ${order['trackingNumber']}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancelOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: Text(AppLocalizations.of(context)!.cancelOrder, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Perform the actual cancellation
  void _performCancelOrder(Map<String, dynamic> order) async {
    final orderId = order['id'];
    if (orderId == null) {
      _showSnackBar(AppLocalizations.of(context)!.errorOrderIdNotFound, primaryRed);
      return;
    }

    try {
      final success = await context.read<OrderProvider>().deleteOrder(orderId);
      if (success) {
        _showSnackBar(
          '${AppLocalizations.of(context)!.order} ${order['trackingNumber']} ${AppLocalizations.of(context)!.orderCancelledSuccessfully}',
          Colors.green,
        );
      } else {
        _showSnackBar(AppLocalizations.of(context)!.failedToCancelOrder, primaryRed);
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.errorCancellingOrder}: $e', primaryRed);
    }
  }

  // Confirm order - update status to confirmed
  void _confirmOrder(Map<String, dynamic> order) {
    Navigator.pop(context);
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmOrderDialogTitle),
        content: Text(
          'Confirm order ${order['trackingNumber']}?\n\n${AppLocalizations.of(context)!.confirmOrderDialogMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performConfirmOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: Text(AppLocalizations.of(context)!.confirmOrderDialogTitle, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Perform the actual confirmation
  void _performConfirmOrder(Map<String, dynamic> order) async {
    final trackingNumber = order['trackingNumber']?.toString();
    if (trackingNumber == null) {
      _showSnackBar(AppLocalizations.of(context)!.errorTrackingNumberNotFound, primaryRed);
      return;
    }

    try {
      // Update status using the API with status name "Confirmed"
      final success = await context.read<OrderProvider>().updateOrderStatus(
        trackingNumber, 
        'Confirmed', // Pass the status name directly
      );
      
      if (success) {
        _showSnackBar(
          '${AppLocalizations.of(context)!.order} ${order['trackingNumber']} ${AppLocalizations.of(context)!.orderConfirmedSuccessfully}',
          primaryBlue,
        );
        // Also update locally for immediate UI feedback
        _changeOrderStatus(trackingNumber, 'Confirmed');
      } else {
        _showSnackBar(AppLocalizations.of(context)!.failedToConfirmOrder, primaryRed);
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.errorConfirmingOrder}: $e', primaryRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Detect if current language is Arabic (RTL)
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    // Ensure filterType matches available localized options
    final filterOptions = getFilterOptions(context);
    if (!filterOptions.contains(filterType)) {
      filterType = filterOptions.first; // Default to "All" in current language
    }
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: ResponsiveUtils.buildResponsiveContainer(
            context: context,
            child: Column(
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    return _HeaderSection(
                      isSelectionMode: isSelectionMode,
                      selectedCount: selectedOrders.length,
                      primaryRed: primaryRed,
                      primaryBlue: primaryBlue,
                      onClearSelection: _clearSelection,
                      unreadNotificationCount: notificationProvider.unreadCount,
                      onRefreshUnreadCount: _loadUnreadNotificationCount,
                      onNotifications: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage()),
                        );
                        // Refresh unread count when returning from notifications
                        _loadUnreadNotificationCount();
                      },
                    );
                  },
                ),
                
                if (isSelectionMode) ...[
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),
                  _PrintButton(selectedCount: selectedOrders.length, primaryBlue: primaryBlue),
                ] else ...[
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),
                  _CreateOrderButton(primaryBlue: primaryBlue),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),
                  _SearchAndFilterBar(
                    searchController: _searchController,
                    filterType: filterType,
                    primaryRed: primaryRed,
                    onSearchChanged: (value) => setState(() => searchQuery = value),
                    onFilterChanged: (value) => setState(() => filterType = value ?? AppLocalizations.of(context)!.all),
                    filterOptions: getFilterOptions(context),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),
                  _RecentOrdersHeader(
                    primaryBlue: primaryBlue,
                    onPickupAll: _pickupAllConfirmedOrders,
                  ),
                ],
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8)),
                Expanded(child: _OrdersList(
                  filterType: filterType,
                  searchQuery: searchQuery,
                  selectedOrders: selectedOrders,
                  expandedOrders: expandedOrders,
                  isSelectionMode: isSelectionMode,
                  primaryRed: primaryRed,
                  primaryBlue: primaryBlue,
                  softGrey: softGrey,
                  onToggleSelection: _toggleSelection,
                  onToggleExpansion: _toggleExpansion,
                  onShowOptions: _showOrderOptions,
                  onChangeStatus: _changeOrderStatus,
                )),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomNavigation(
          currentIndex: _currentIndex,
          primaryRed: primaryRed,
        ),
      ),
    );
  }
}

// Orders List Widget
class _OrdersList extends StatelessWidget {
  final String filterType;
  final String searchQuery;
  final Set<String> selectedOrders;
  final Set<String> expandedOrders;
  final bool isSelectionMode;
  final Color primaryRed;
  final Color primaryBlue;
  final Color softGrey;
  final Function(String) onToggleSelection;
  final Function(String) onToggleExpansion;
  final Function(Map<String, dynamic>) onShowOptions;
  final Function(String, String) onChangeStatus;

  const _OrdersList({
    required this.filterType,
    required this.searchQuery,
    required this.selectedOrders,
    required this.expandedOrders,
    required this.isSelectionMode,
    required this.primaryRed,
    required this.primaryBlue,
    required this.softGrey,
    required this.onToggleSelection,
    required this.onToggleExpansion,
    required this.onShowOptions,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.errorMessage != null) {
          return _ErrorView(
            errorMessage: orderProvider.errorMessage!,
            primaryRed: primaryRed,
            primaryBlue: primaryBlue,
            onRetry: () => orderProvider.loadRecentOrders(),
          );
        }

        final filteredOrders = orderProvider.getFilteredOrders(
          _HomePageState.getEnglishStatusFromLocalized(context, filterType), 
          searchQuery,
          limit: _HomePageState._maxLatestOrders // Show only latest orders
        );
        if (filteredOrders.isEmpty) return _EmptyView();

        return RefreshIndicator(
          onRefresh: () => orderProvider.loadRecentOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              final trackingNumber = order['trackingNumber']?.toString() ?? '';
              final isExpanded = expandedOrders.contains(trackingNumber);
              final isSelected = selectedOrders.contains(trackingNumber);
              final statusDisplay = _HomePageState.getStatusDisplayName(order['status']);
              final canBeSelected = statusDisplay == 'Picked up' || statusDisplay == 'Confirmed';
              
              return GestureDetector(
                onLongPress: canBeSelected ? () => onToggleSelection(trackingNumber) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _OrderCard(
                    order: order,
                    isSelected: isSelected,
                    isExpanded: isExpanded,
                    isSelectionMode: isSelectionMode,
                    primaryBlue: primaryBlue,
                    softGrey: softGrey,
                    onToggleSelection: () => onToggleSelection(trackingNumber),
                    onToggleExpansion: () => onToggleExpansion(trackingNumber),
                    onShowOptions: () => onShowOptions(order),
                    onChangeStatus: (status) => onChangeStatus(order['trackingNumber'], status),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Error View Widget
class _ErrorView extends StatelessWidget {
  final String errorMessage;
  final Color primaryRed;
  final Color primaryBlue;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorMessage,
    required this.primaryRed,
    required this.primaryBlue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: primaryRed),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.errorLoadingOrders,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryRed),
          ),
          const SizedBox(height: 8),
          Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFFB1BAC4)
              : Colors.grey.shade600
          )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Empty View Widget
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF8B949E)
            : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFE6EDF3)
                : Colors.grey[600]
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first order to get started', 
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFB1BAC4)
                : Colors.grey.shade600
            )
          ),
        ],
      ),
    );
  }
}

// Bottom Navigation Widget
class _BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Color primaryRed;

  const _BottomNavigation({required this.currentIndex, required this.primaryRed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        height: 65,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF161B22).withOpacity(0.95), 
                  const Color(0xFF161B22)
                ]
              : [
                  Colors.white.withOpacity(0.95), 
                  Colors.white
                ],
          ),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF30363D)
              : Colors.white.withOpacity(0.8), 
            width: 1
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF161B22).withOpacity(0.4)
                : Colors.white.withOpacity(0.8),
              blurRadius: 20,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
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
              currentIndex: currentIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: primaryRed,
              unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFB1BAC4)
                : Colors.grey[400],
              selectedFontSize: 12,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 24), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.history_rounded, size: 24), label: 'History'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 24), label: 'Profile'),
              ],
              onTap: (index) {
                switch (index) {
                  case 0: break; // Already on Home
                  case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())); break;
                  case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); break;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Extracted widgets for better performance
class _HeaderSection extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final Color primaryRed;
  final Color primaryBlue;
  final VoidCallback onClearSelection;
  final VoidCallback onNotifications;
  final int unreadNotificationCount;
  final VoidCallback onRefreshUnreadCount;

  const _HeaderSection({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.primaryRed,
    required this.primaryBlue,
    required this.onClearSelection,
    required this.onNotifications,
    required this.unreadNotificationCount,
    required this.onRefreshUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF161B22)
              : Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Theme.of(context).brightness == Brightness.dark 
              ? Border.all(color: const Color(0xFF30363D), width: 1)
              : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark 
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          ),
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              'images/logo.png',
              width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 60),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 60),
                  height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'Yanship',
                      style: TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Row(
          children: [
            if (isSelectionMode) ...[
              Text(
                '$selectedCount selected',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 6)),
              IconButton(
                icon: Icon(
                  Icons.close, 
                  color: primaryRed, 
                  size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                ),
                onPressed: onClearSelection,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ] else ...[
              IconButton(
                icon: Icon(
                  Icons.people_outline, 
                  color: primaryBlue, 
                  size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 28),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientsPage()),
                  );
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: 'Client Management',
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 4)),
              IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_none, 
                      color: primaryBlue, 
                      size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 32),
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  onNotifications();
                  // Refresh unread count when notifications are opened
                  onRefreshUnreadCount();
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PrintButton extends StatelessWidget {
  final int selectedCount;
  final Color primaryBlue;

  const _PrintButton({
    required this.selectedCount,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printing bon de réception for $selectedCount orders'),
            backgroundColor: primaryBlue,
          ),
        );
      },
      icon: const Icon(Icons.print, color: Colors.white, size: 18),
      label: Text(
        AppLocalizations.of(context)!.printBonReception,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        elevation: 4,
        shadowColor: primaryBlue.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

class _CreateOrderButton extends StatelessWidget {
  final Color primaryBlue;

  const _CreateOrderButton({required this.primaryBlue});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateOrder()),
        );
        
        // Refresh orders when returning from CreateOrder
        if (context.mounted) {
          Provider.of<OrderProvider>(context, listen: false).loadRecentOrders();
        }
      },
      icon: Icon(
        Icons.add, 
        color: Colors.white, 
        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 18),
      ),
      label: Text(
        AppLocalizations.of(context)!.createOrderBtn,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        elevation: 4,
        shadowColor: primaryBlue.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
          vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12),
        ),
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String filterType;
  final Color primaryRed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;
  final List<String> filterOptions;

  const _SearchAndFilterBar({
    required this.searchController,
    required this.filterType,
    required this.primaryRed,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.filterOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search, 
                  color: Colors.grey[600],
                  size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                ),
                hintText: AppLocalizations.of(context)!.searchOrders,
                hintStyle: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16), 
                  horizontal: 0,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryRed, width: 2),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filterType,
              items: filterOptions
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onFilterChanged,
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                color: primaryRed,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
              ),
              icon: Icon(
                Icons.filter_alt_outlined, 
                color: primaryRed,
                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentOrdersHeader extends StatelessWidget {
  final Color primaryBlue;
  final VoidCallback onPickupAll;

  const _RecentOrdersHeader({
    required this.primaryBlue,
    required this.onPickupAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Latest Orders (${_HomePageState._maxLatestOrders})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : const Color(0xff1e1e2d),
          ),
        ),
        OutlinedButton(
          onPressed: onPickupAll,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primaryBlue, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            'Pick Up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// Extract the complex order list to a separate widget

// Simple order card for now - you can expand this later
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isSelected;
  final bool isExpanded;
  final bool isSelectionMode;
  final Color primaryBlue;
  final Color softGrey;
  final VoidCallback onToggleSelection;
  final VoidCallback onToggleExpansion;
  final VoidCallback onShowOptions;
  final Function(String) onChangeStatus;

  const _OrderCard({
    required this.order,
    required this.isSelected,
    required this.isExpanded,
    required this.isSelectionMode,
    required this.primaryBlue,
    required this.softGrey,
    required this.onToggleSelection,
    required this.onToggleExpansion,
    required this.onShowOptions,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusDisplay = _HomePageState.getStatusDisplayName(order['status']);
    final localizedStatusDisplay = context.findAncestorStateOfType<_HomePageState>()?.getLocalizedStatusDisplayName(context, order['status']) ?? statusDisplay;
    final canBeSelected = statusDisplay == 'Picked up' || statusDisplay == 'Confirmed';
    final isCreated = statusDisplay == 'Created';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return InkWell(
      onTap: () {
        if (isSelectionMode && canBeSelected) {
          onToggleSelection();
          return;
        }
        onToggleExpansion();
      },
      onLongPress: () {
        if (canBeSelected) {
          onToggleSelection();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: isArabic ? 8 : 4, // Better margins for Arabic
          vertical: isArabic ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: isSelected 
            ? primaryBlue.withOpacity(0.2) 
            : (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF161B22) 
                : const Color(0xFFF7FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
            ? Border.all(color: primaryBlue, width: 2)
            : isCreated
              ? Border.all(color: Colors.amber.shade400, width: 2)
              : Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF30363D)
                    : const Color(0xFFE2E8F0), 
                  width: 1
                ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.03),
              blurRadius: Theme.of(context).brightness == Brightness.dark ? 8 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content with improved padding for Arabic
            Padding(
              padding: EdgeInsets.all(isArabic ? 20 : 16), // More padding for Arabic
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _OrderMainContent(order: order),
                  if (isExpanded) _OrderExpandedContent(order: order, primaryBlue: primaryBlue),
                ],
              ),
            ),
            
            // Status badge - using PositionedDirectional for RTL support
            PositionedDirectional(
              top: 16,
              end: isArabic ? 16 : 60, // Closer to edge for Arabic, further for LTR
              child: _StatusBadge(status: localizedStatusDisplay),
            ),
            
            // More options button - using PositionedDirectional
            PositionedDirectional(
              top: 16,
              end: isArabic ? 16 : 16, // Same position for both, but status badge moved
              child: Transform.translate(
                offset: Offset(isArabic ? 0 : 0, isArabic ? 40 : 0), // Move down for Arabic to avoid badge overlap
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 20,
                  ),
                  onPressed: onShowOptions,
                ),
              ),
            ),
            
            // Created order indicator (small badge on top start) - using PositionedDirectional
            if (isCreated)
              PositionedDirectional(
                top: 8,
                start: 8, // This will be left in LTR and right in RTL
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.editable,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Date badge - using PositionedDirectional
            PositionedDirectional(
              bottom: 16,
              end: 16, // This will be right in LTR and left in RTL
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                    (() {
                    final dateStr = order['date']?.toString();
                    
                    if (dateStr == null || dateStr.isEmpty) return 'N/A';
                    final date = DateTime.tryParse(dateStr);
                    if (date == null) return 'N/A';
                    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    })(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            // Selection indicator - using PositionedDirectional
            if (isSelected)
              PositionedDirectional(
                top: 8,
                start: 8, // This will be left in LTR and right in RTL
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F), // Red color
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Continue with more extracted widgets...
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _HomePageState.getBadgeColor(status);
    final bgColor = _HomePageState.getBadgeBgColor(status);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isArabic ? 16 : 12, // More horizontal padding for Arabic
        vertical: isArabic ? 8 : 6, // More vertical padding for Arabic
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isArabic ? 13 : 12, // Slightly larger for Arabic
          height: isArabic ? 1.3 : 1.2, // Better line height for Arabic
          letterSpacing: isArabic ? 0.1 : 0, // Better letter spacing for Arabic
        ),
        textAlign: isArabic ? TextAlign.center : TextAlign.center,
      ),
    );
  }
}

class _OrderMainContent extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderMainContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Padding(
      padding: EdgeInsets.only(
        // Add padding to avoid overlap with positioned elements
        top: 8, // Space for status badge and more button
        bottom: 8, // Space for date badge and selection indicator
        left: isArabic ? 8 : 8, // Consistent padding
        right: isArabic ? 8 : 90, // More space on right for English/French (dots on right)
      ),
      child: isArabic 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Icon and text content for Arabic
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Tracking number with prefix
                          Text(
                            order['fullTrackingNumber']?.toString() ?? 
                            '${order['orderPrefix'] ?? ''}-${order['trackingNumber'] ?? AppLocalizations.of(context)!.na}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17, // Larger for Arabic readability
                              color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : const Color(0xff1e1e2d),
                              letterSpacing: 0.5, // Better letter spacing for Arabic
                              height: 1.3, // Better line height for Arabic
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr, // Keep tracking numbers LTR
                          ),
                          SizedBox(height: 8), // More space for Arabic
                          // Price
                          Text(
                            '${AppLocalizations.of(context)!.price}: ${order['price']?.toString() ?? AppLocalizations.of(context)!.na}',
                            style: TextStyle(
                              color: const Color(0xff4f46e5),
                              fontWeight: FontWeight.w600,
                              fontSize: 15, // Larger for Arabic
                              height: 1.4, // Better line height for Arabic
                            ),
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 6), // More space for Arabic
                          // Recipient and city
                          Text(
                            '${AppLocalizations.of(context)!.to}: ${order['recipientName']?.toString() ?? AppLocalizations.of(context)!.unknown} - ${order['cityName']?.toString() ?? AppLocalizations.of(context)!.unknownCity}',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.grey[600],
                              fontSize: 14, // Larger for Arabic
                              height: 1.5, // Better line height for Arabic
                              letterSpacing: 0.2, // Better letter spacing for Arabic
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    // Icon on the right for Arabic
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.inventory_2, 
                        color: Color(0xFF1E88E5), 
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Right side: Space for badge (handled by positioned widget)
              SizedBox(width: 100), // Space for status badge and menu
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.ltr,
            children: [
              // Icon container for LTR
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.inventory_2, 
                  color: Color(0xFF1E88E5), 
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tracking number with prefix
                    Text(
                      order['fullTrackingNumber']?.toString() ?? 
                      '${order['orderPrefix'] ?? ''}-${order['trackingNumber'] ?? AppLocalizations.of(context)!.na}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : const Color(0xff1e1e2d),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                    ),
                    SizedBox(height: 6),
                    // Price
                    Text(
                      '${AppLocalizations.of(context)!.price}: ${order['price']?.toString() ?? AppLocalizations.of(context)!.na}',
                      style: TextStyle(
                        color: const Color(0xff4f46e5),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 4),
                    // Recipient and city
                    Text(
                      '${AppLocalizations.of(context)!.to}: ${order['recipientName']?.toString() ?? AppLocalizations.of(context)!.unknown} - ${order['city']?.toString() ?? AppLocalizations.of(context)!.unknownCity}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                        fontSize: 13,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _OrderExpandedContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;

  const _OrderExpandedContent({
    required this.order,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SizedBox(height: isArabic ? 24 : 20), // More space for Arabic
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                  Colors.grey[200]!,
                ],
              ),
            ),
          ),
          SizedBox(height: isArabic ? 24 : 20), // More space for Arabic
          _DeliveryInformation(order: order, primaryBlue: primaryBlue),
          SizedBox(height: isArabic ? 24 : 20), // More space for Arabic
          _StatusHistory(order: order),
          SizedBox(height: isArabic ? 24 : 20), // More space for Arabic
        ],
      ),
    );
  }
}

class _DeliveryInformation extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;

  const _DeliveryInformation({
    required this.order,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.showDeliveryInformation,
          style: TextStyle(
            fontSize: isArabic ? 15 : 14, // Slightly larger for Arabic
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : const Color(0xff1e1e2d),
            height: isArabic ? 1.4 : 1.2, // Better line height for Arabic
          ),
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
        ),
        SizedBox(height: isArabic ? 16 : 12), // More space for Arabic
        _InfoContainer(
          icon: Icons.person,
          title: AppLocalizations.of(context)!.recipientName,
          content: order['recipientName']?.toString() ?? AppLocalizations.of(context)!.unknown,
          primaryBlue: primaryBlue,
        ),
        SizedBox(height: isArabic ? 16 : 12), // More space for Arabic
        _InfoContainer(
          icon: Icons.phone,
          title: AppLocalizations.of(context)!.phoneNumber,
          content: order['phone']?.toString() ?? AppLocalizations.of(context)!.noPhoneNumber,
          primaryBlue: primaryBlue,
        ),
        SizedBox(height: isArabic ? 16 : 12), // More space for Arabic
        _InfoContainer(
          icon: Icons.location_on,
          title: AppLocalizations.of(context)!.address,
          content: '${order['deliveryAddress']?.toString() ?? AppLocalizations.of(context)!.noAddress} -- ${order['city']?.toString().isNotEmpty == true ? order['city'].toString() : AppLocalizations.of(context)!.unknownCity}',
          primaryBlue: primaryBlue,
        ),
      ],
    );
  }
}

class _InfoContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color primaryBlue;

  const _InfoContainer({
    required this.icon,
    required this.title,
    required this.content,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isRTL ? 16 : 12), // More padding for Arabic
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D) 
            : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: Directionality.of(context),
            children: [
              Icon(icon, size: 16, color: primaryBlue),
              SizedBox(width: isRTL ? 12 : 8), // More space for Arabic
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isRTL ? 14 : 13, // Slightly larger for Arabic
                  color: primaryBlue,
                  height: isRTL ? 1.4 : 1.2, // Better line height for Arabic
                ),
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
            ],
          ),
          SizedBox(height: isRTL ? 8 : 4), // More space for Arabic
          Text(
            content,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[300] 
                : Colors.grey[700],
              fontSize: isRTL ? 15 : 14, // Slightly larger for Arabic
              fontWeight: FontWeight.w500,
              height: isRTL ? 1.5 : 1.3, // Better line height for Arabic
              letterSpacing: isRTL ? 0.2 : 0, // Better letter spacing for Arabic
            ),
            textAlign: isRTL ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }
}

class _StatusHistory extends StatelessWidget {
  final Map<String, dynamic> order;

  const _StatusHistory({required this.order});

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

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
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
    
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.statusHistory,
          style: TextStyle(
            fontSize: isRTL ? 15 : 14, // Slightly larger for Arabic
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : const Color(0xff1e1e2d),
            height: isRTL ? 1.4 : 1.2, // Better line height for Arabic
          ),
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
        ),
        SizedBox(height: isRTL ? 16 : 12), // More space for Arabic
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isRTL ? 20 : 16), // More padding for Arabic
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF161B22) 
              : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF30363D) 
                : Colors.grey[200]!,
            ),
          ),
          child: sortedEntries.isEmpty 
            ? Padding(
                padding: EdgeInsets.all(isRTL ? 20 : 16),
                child: Text(
                  'No status updates yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isRTL ? 14 : 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
              )
            : Column(
                children: sortedEntries.map<Widget>((entry) {
                  return Container(
                    margin: EdgeInsets.only(bottom: isRTL ? 16 : 12), // More space for Arabic
                    child: Row(
                      textDirection: Directionality.of(context),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: EdgeInsets.only(top: isRTL ? 6 : 4), // Better alignment for Arabic
                          decoration: const BoxDecoration(
                            color: Color(0xff4f46e5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: isRTL ? 16 : 12), // More space for Arabic
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : const Color(0xff1e1e2d),
                                  fontSize: isRTL ? 15 : 14, // Slightly larger for Arabic
                                  height: isRTL ? 1.4 : 1.2, // Better line height for Arabic
                                ),
                                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                              ),
                              SizedBox(height: isRTL ? 6 : 4), // More space for Arabic
                              Text(
                                _formatHistoryDate(entry.value),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isRTL ? 14 : 13, // Slightly larger for Arabic
                                  height: isRTL ? 1.5 : 1.3, // Better line height for Arabic
                                ),
                                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        ),
      ],
    );
  }
}

class _OrderOptionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;
  final Color primaryRed;
  final VoidCallback? onEdit;
  final VoidCallback onViewDetails;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback onPrintLabel;

  const _OrderOptionsBottomSheet({
    required this.order,
    required this.primaryBlue,
    required this.primaryRed,
    this.onEdit,
    required this.onViewDetails,
    this.onCancel,
    this.onConfirm,
    required this.onPrintLabel,
  });

  @override
  Widget build(BuildContext context) {
    final trackingNumber = order['trackingNumber'] ?? 'N/A';
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: primaryBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Actions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tracking: $trackingNumber',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Edit option - only for Created orders
          if (onEdit != null)
            _ActionTile(
              icon: Icons.edit,
              color: primaryBlue,
              title: AppLocalizations.of(context)!.editOrder,
              subtitle: AppLocalizations.of(context)!.modifyOrderDetails,
              onTap: onEdit!,
            ),
          
          // View details - always available
          _ActionTile(
            icon: Icons.visibility,
            color: primaryBlue,
            title: AppLocalizations.of(context)!.orderDetails,
            subtitle: AppLocalizations.of(context)!.showDeliveryInformation,
            onTap: onViewDetails,
          ),
          
          // Print label - always available
          _ActionTile(
            icon: Icons.print,
            color: primaryBlue,
            title: AppLocalizations.of(context)!.printLabel,
            subtitle: AppLocalizations.of(context)!.generateShippingLabel,
            onTap: onPrintLabel,
          ),
          
          // Confirm option - only for Created orders
          if (onConfirm != null)
            _ActionTile(
              icon: Icons.check_circle,
              color: Colors.green,
              title: AppLocalizations.of(context)!.confirmOrderDialogTitle,
              subtitle: AppLocalizations.of(context)!.markConfirmedReady,
              onTap: onConfirm!,
            ),
          
          // Cancel option - only for Created orders
          if (onCancel != null)
            _ActionTile(
              icon: Icons.cancel,
              color: primaryRed,
              title: AppLocalizations.of(context)!.cancelOrder,
              subtitle: AppLocalizations.of(context)!.deleteOrderPermanently,
              onTap: onCancel!,
            ),
        ],
      ),
    );
  }
}

// Action Tile Widget for Bottom Sheet
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}