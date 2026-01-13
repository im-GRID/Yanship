// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  // Private fields
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _allOrders = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreOrders = true;

  // Getters
  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  List<Map<String, dynamic>> get allOrders => _allOrders;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreOrders => _hasMoreOrders;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set loading more state
  void _setLoadingMore(bool loadingMore) {
    _isLoadingMore = loadingMore;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }



  // Load recent orders for home page
  // Helper method to sort orders by priority: Created first, then Confirmed, then by date
  List<Map<String, dynamic>> _sortOrdersByPriority(List<Map<String, dynamic>> orders) {
    return List.from(orders)..sort((a, b) {
      final statusA = _getStatusDisplayName(a['status']);
      final statusB = _getStatusDisplayName(b['status']);
      
      // Priority mapping: Created = 1, Confirmed = 2, Others = 3
      int getPriority(String status) {
        switch (status) {
          case 'Created': return 1;
          case 'Confirmed': return 2;
          default: return 3;
        }
      }
      
      final priorityA = getPriority(statusA);
      final priorityB = getPriority(statusB);
      
      // First sort by priority
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // If same priority, sort by date (newest first within same priority group)
      final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
  }

  Future<void> loadRecentOrders() async {
    _setLoading(true);
    clearError();

    try {
      final result = await OrderService.getRecentOrdersWithHistory();

      if (result['success']) {
        final rawOrders = List<Map<String, dynamic>>.from(result['orders']);
        print('Debug - loadRecentOrders: ${rawOrders.length} orders');
        if (rawOrders.isNotEmpty) {
          print('Debug - Sample recent order: ${rawOrders[0]}');
        }
        
        final formattedOrders = rawOrders.map((order) => formatOrderForUI(order)).toList();
        _recentOrders = _sortOrdersByPriority(formattedOrders); // Apply priority sorting
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to load recent orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load dashboard data
  Future<void> loadDashboard() async {
    _setLoading(true);
    clearError();

    try {
      final result = await OrderService.getUserDashboard();
      
      if (result['success']) {
        _dashboardStats = result['stats'] ?? {};
        final rawRecentOrders = List<Map<String, dynamic>>.from(result['recentOrders'] ?? []);
        final formattedOrders = rawRecentOrders.map((order) => formatOrderForUI(order)).toList();
        _recentOrders = _sortOrdersByPriority(formattedOrders); // Apply priority sorting
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to load dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all orders with pagination
  Future<void> loadAllOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreOrders = true;
      _allOrders.clear();
    }

    if (!_hasMoreOrders) return;

    if (_currentPage == 1) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    clearError();

    try {
      final result = await OrderService.getUserOrdersWithHistory(
        page: _currentPage,
        limit: 100, // Increased limit to show more orders in History
      );
      
      if (result['success']) {
        final rawNewOrders = List<Map<String, dynamic>>.from(result['orders']);
        print('Debug - Raw orders from backend: ${rawNewOrders.length} orders');
        if (rawNewOrders.isNotEmpty) {
          print('Debug - Sample raw order: ${rawNewOrders[0]}');
        }
        
        final formattedNewOrders = rawNewOrders.map((order) => formatOrderForUI(order)).toList();
        print('Debug - Sample formatted order: ${formattedNewOrders.isNotEmpty ? formattedNewOrders[0] : 'none'}');
        
        if (_currentPage == 1) {
          _allOrders = formattedNewOrders;
        } else {
          _allOrders.addAll(formattedNewOrders);
        }

        // Check if there are more orders to load
        final pagination = result['pagination'];
        if (pagination != null) {
          final currentPage = pagination['currentPage'] ?? 1;
          final totalPages = pagination['totalPages'] ?? 1;
          _hasMoreOrders = currentPage < totalPages;
        } else {
          _hasMoreOrders = formattedNewOrders.length >= 20;
        }

        _currentPage++;
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to load orders: $e');
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  // Create new order
  Future<bool> createOrder({
    required String receiver_name,
    required String phone,
    required String address,
    required String city,
    required double price,
    required bool open_product,
    String? sender_address_id,
  }) async {
    clearError();

    try {
      final result = await OrderService.createOrder(
        receiver_name: receiver_name,
        phone: phone,
        address: address,
        city: city,
        price: price,
        open_product: open_product,
        sender_address_id: sender_address_id,
      );

      if (result['success']) {
        // Add the new order to recent orders and re-sort by priority
        final rawNewOrder = result['order'];
        final formattedNewOrder = formatOrderForUI(rawNewOrder);
        _recentOrders.add(formattedNewOrder);
        _recentOrders = _sortOrdersByPriority(_recentOrders); // Re-sort to maintain priority
        
        // If we have all orders loaded, add it there too
        if (_allOrders.isNotEmpty) {
          _allOrders.insert(0, formattedNewOrder);
        }
        
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to create order: $e');
      return false;
    }
  }

  // Update order
  Future<bool> updateOrder({
    required int orderId,
    String? recipientName,
    String? recipientPhone,
    String? deliveryAddress,
    String? city,
    String? pickupPoint,
    double? price,
    bool? authorizeToOpenBox,
    String? description,
    String? weight,
    String? dimensions,
  }) async {
    clearError();

    try {
      final result = await OrderService.updateOrder(
        orderId: orderId,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        deliveryAddress: deliveryAddress,
        city: city,
        pickupPoint: pickupPoint,
        price: price,
        authorizeToOpenBox: authorizeToOpenBox,
        description: description,
        weight: weight,
        dimensions: dimensions,
      );

      if (result['success']) {
        final rawUpdatedOrder = result['order'];
        final formattedUpdatedOrder = formatOrderForUI(rawUpdatedOrder);
        
        // Update in recent orders and re-sort by priority
        final recentIndex = _recentOrders.indexWhere(
          (order) => order['id'] == orderId,
        );
        if (recentIndex != -1) {
          _recentOrders[recentIndex] = formattedUpdatedOrder;
          _recentOrders = _sortOrdersByPriority(_recentOrders); // Re-sort to maintain priority
        }

        // Update in all orders
        final allIndex = _allOrders.indexWhere(
          (order) => order['id'] == orderId,
        );
        if (allIndex != -1) {
          _allOrders[allIndex] = formattedUpdatedOrder;
        }

        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update order: $e');
      return false;
    }
  }

  // Delete order
  Future<bool> deleteOrder(int orderId) async {
    clearError();

    try {
      final result = await OrderService.deleteOrder(orderId);

      if (result['success']) {
        // Remove from recent orders
        _recentOrders.removeWhere((order) => order['id'] == orderId);
        
        // Remove from all orders
        _allOrders.removeWhere((order) => order['id'] == orderId);

        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete order: $e');
      return false;
    }
  }

  // Update order status locally (for immediate UI feedback)
  void updateOrderStatusLocally(String trackingNumber, String newStatus) {
    // Update in recent orders and re-sort by priority
    final recentIndex = _recentOrders.indexWhere(
      (order) => order['trackingNumber'] == trackingNumber,
    );
    if (recentIndex != -1) {
      _recentOrders[recentIndex]['status'] = newStatus;
      _recentOrders = _sortOrdersByPriority(_recentOrders); // Re-sort to maintain priority
    }

    // Update in all orders
    final allIndex = _allOrders.indexWhere(
      (order) => order['trackingNumber'] == trackingNumber,
    );
    if (allIndex != -1) {
      _allOrders[allIndex]['status'] = newStatus;
    }

    notifyListeners();
  }

  // Update order status via API
  Future<bool> updateOrderStatus(String trackingNumber, String statusName) async {
    clearError();
    
    try {
      // Find the order by tracking number to get the ID
      final order = _recentOrders.firstWhere(
        (order) => order['trackingNumber'] == trackingNumber,
        orElse: () => _allOrders.firstWhere(
          (order) => order['trackingNumber'] == trackingNumber,
          orElse: () => <String, dynamic>{},
        ),
      );
      
      final orderId = order['id'];
      if (orderId == null) {
        _setError('Order not found');
        return false;
      }

      // Convert status name to the format expected by the API
      // The API expects status names like "Confirmed", "Created", etc.
      final result = await OrderService.updateOrderStatus(
        orderId: orderId,
        status: statusName, // Pass the status name directly
      );

      if (result['success']) {
        // Update locally as well
        updateOrderStatusLocally(trackingNumber, statusName);
        
        // Reload data to get updated history from server
        await loadRecentOrders();
        await loadAllOrders(refresh: true);
        
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update order status: $e');
      return false;
    }
  }

  // Bulk pickup all confirmed orders
  Future<bool> bulkPickupOrders() async {
    clearError();

    try {
      final result = await OrderService.bulkPickupOrders();

      if (result['success']) {
        // Update all confirmed orders to picked up status locally
        for (final order in _recentOrders) {
          if (order['status'] == 'Confirmed' || order['status'] == 10) {
            order['status'] = 'Picked up';
          }
        }
        
        for (final order in _allOrders) {
          if (order['status'] == 'Confirmed' || order['status'] == 10) {
            order['status'] = 'Picked up';
          }
        }

        // Reload data to get updated history from server
        await loadRecentOrders();
        await loadAllOrders(refresh: true);

        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to pickup orders: $e');
      return false;
    }
  }

  // Get filtered orders
  List<Map<String, dynamic>> getFilteredOrders(String filterType, String searchQuery, {int? limit}) {
    List<Map<String, dynamic>> orders = _recentOrders;

    // First, exclude delivered orders from home page display
    orders = orders.where((order) {
      final orderStatusDisplay = _getStatusDisplayName(order['status']);
      return orderStatusDisplay != 'Delivered'; // Don't show delivered orders
    }).toList();

    // Apply priority sorting (recentOrders should already be sorted, but ensure consistency)
    orders = _sortOrdersByPriority(orders);

    // Limit orders if specified (for "latest orders" functionality)
    if (limit != null && limit > 0) {
      orders = orders.take(limit).toList();
    }

    // Filter by status
    if (filterType != 'All') {
      orders = orders.where((order) {
        // Get the display name of the order's status using HomePage's mapping function
        final orderStatusDisplay = _getStatusDisplayName(order['status']);
        return orderStatusDisplay == filterType;
      }).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      orders = orders.where((order) => 
        (order['trackingNumber']?.toString() ?? '').toLowerCase().contains(query) ||
        (order['recipientName']?.toString() ?? '').toLowerCase().contains(query) ||
        (order['city']?.toString() ?? '').toLowerCase().contains(query)
      ).toList();
    }

    return orders;
  }

  // Helper method to get status display name (same logic as HomePage)
  String _getStatusDisplayName(dynamic status) {
    // Status mapping constants (same as HomePage)
    const statusIdToName = {
      1: 'Created',
      10: 'Confirmed',
      24: 'In Transit',
      25: 'Picked up', 
      26: 'Out for Delivery',
      27: 'Attempted Delivery',
      28: 'Delivered',
      29: 'Returned',
      3: 'Cancelled',
      5: 'Rejected'
    };

    if (status == null) return 'Unknown';
    
    if (status is int) {
      return statusIdToName[status] ?? 'Unknown Status ($status)';
    } else if (status is String) {
      // Try to parse as integer
      final intStatus = int.tryParse(status);
      if (intStatus != null && statusIdToName.containsKey(intStatus)) {
        return statusIdToName[intStatus]!;
      }
      // If it's already a string status name, return it
      return status;
    }
    return 'Unknown';
  }

  // Map status from backend to frontend format
  String mapStatusToFrontend(dynamic backendStatus) {
    // Backend uses numeric status codes, map them to readable strings
    // Use the same mapping as HomePage
    switch (backendStatus.toString()) {
      case '1':
        return 'Created';
      case '3':
        return 'Cancelled';
      case '5':
        return 'Rejected';
      case '10':
        return 'Confirmed';
      case '24':
        return 'In Transit';
      case '25':
        return 'Picked up';
      case '26':
        return 'Out for Delivery';
      case '27':
        return 'Attempted Delivery';
      case '28':
        return 'Delivered';
      case '29':
        return 'Returned';
      case '31':
        return 'Created';
      default:
        return 'Created';
    }
  }

  // Format order data from backend to frontend
  Map<String, dynamic> formatOrderForUI(Map<String, dynamic> backendOrder) {
    final trackingNumber = backendOrder['trackingNumber'] ?? backendOrder['order_no'];
    final orderPrefix = backendOrder['orderPrefix'] ?? backendOrder['order_prefix'];
    final fullTrackingNumber = backendOrder['fullTrackingNumber'] ?? 
                              (orderPrefix != null && trackingNumber != null ? '$orderPrefix-$trackingNumber' : trackingNumber);
    final recipientName = backendOrder['recipientName'] ?? backendOrder['receiver_name'];
    final deliveryAddress = backendOrder['deliveryAddress'] ?? backendOrder['address'];
    final status = mapStatusToFrontend(backendOrder['status'] ?? backendOrder['status_courier']);
    final price = '${backendOrder['price'] ?? 0} MAD';
    
    // Handle phone number with multiple possible field names
    final phone = backendOrder['phone'] ?? 
                  backendOrder['recipientPhone'] ?? 
                  'No phone number';
    
    // Handle date with multiple possible field names and proper formatting
    String formattedDate = 'N/A';
    final rawDate = backendOrder['date'] ?? 
                    backendOrder['created_at'] ?? 
                    backendOrder['createdAt'] ??
                    backendOrder['order_datetime'];
    
    print('Debug - Date formatting for order ${backendOrder['id']}:');
    print('  - rawDate: $rawDate');
    print('  - date field: ${backendOrder['date']}');
    print('  - created_at field: ${backendOrder['created_at']}');
    print('  - order_datetime field: ${backendOrder['order_datetime']}');
    
    if (rawDate != null) {
      try {
        DateTime dateTime;
        if (rawDate is String) {
          dateTime = DateTime.parse(rawDate);
        } else {
          dateTime = DateTime.now(); // fallback
        }
        formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } catch (e) {
        print('Error formatting date: $e');
        formattedDate = rawDate.toString().split(' ')[0]; // Try to get just the date part
      }
    }
    
    return {
      'id': backendOrder['id'],
      // Include both old and new field names for compatibility
      'trackingNumber': trackingNumber,  // HomePage uses this
      'tracking': trackingNumber,        // History page uses this
      'orderPrefix': orderPrefix,        // New: Order prefix (e.g., USR001)
      'fullTrackingNumber': fullTrackingNumber, // New: Combined format (e.g., USR001-000001)
      'recipientName': recipientName,    // HomePage uses this
      'recipient': recipientName,        // History page uses this
      'deliveryAddress': deliveryAddress, // HomePage might use this
      'address': deliveryAddress,        // History page uses this
      'status': status,
      'price': price,
      'phone': phone,
      'city': backendOrder['cityName'] ?? backendOrder['city'] ?? 'N/A',
      'senderAddress': backendOrder['senderAddress'] != null 
          ? '${backendOrder['senderAddress']['address'] ?? ''}, ${backendOrder['senderAddress']['name'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '')
          : 'N/A',
      'date': formattedDate,
      'deliveryTime': 'N/A', // Default delivery time, can be enhanced later
      'rating': 0, // Default rating, can be enhanced later
      'icon': Icons.inventory_2,
      'iconColor': const Color(0xFF1E88E5),
      'statusHistory': backendOrder['statusHistory'] ?? {},
    };
  }
}
