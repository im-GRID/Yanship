import 'package:flutter/material.dart';
import 'package:flutter_app/constants/url.dart';
import '../services/api_serice.dart';

class ShipmentProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _allShipments = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService(baseUrl: baseURL);
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> get cities => _cities;

  List<Map<String, dynamic>> get allShipments => _allShipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }



  Future<void> loadCities() async {
    try {
      final response = await _apiService.get('/orders/cities/all');

      if (response['success'] == true) {
        _cities = List<Map<String, dynamic>>.from(response['data']);
        notifyListeners();
      } else {
        _setError('Erreur lors du chargement des villes: ${response['message']}');
      }
    } catch (e) {
      _setError('Erreur de chargement des villes: $e');
    }
  }

  Map<String, dynamic>? getCityById(int? cityId) {
    if (cityId == null) return null;
    return _cities.firstWhere(
          (city) => city['id'] == cityId,
      orElse: () => {},
    );
  }

  Future<void> loadAllShipments() async {
    _setLoading(true);
    clearError();

    try {
      final response = await _apiService.get('/orders/all');

      if (response['success'] == true) {
        final rawOrders = List<Map<String, dynamic>>.from(response['data']['orders']);
        _allShipments = rawOrders.map((order) => _formatShipmentForUI(order)).toList();
        notifyListeners();
      } else {
        _setError('Erreur API: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _setError('Erreur de chargement: $e');
    } finally {
      _setLoading(false);
    }
  }

  List<Map<String, dynamic>> getFilteredShipments(String filterType, String searchQuery) {
    List<Map<String, dynamic>> shipments = _allShipments;

    // Filter by status
    if (filterType != 'All') {
      shipments = shipments.where((shipment) {
        final statusDisplay = _getStatusDisplayName(shipment['status']);
        return statusDisplay == filterType;
      }).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      shipments = shipments.where((shipment) =>
      (shipment['trackingNumber']?.toString() ?? '').toLowerCase().contains(query) ||
          (shipment['recipientName']?.toString() ?? '').toLowerCase().contains(query) ||
          (shipment['city']?.toString() ?? '').toLowerCase().contains(query)
      ).toList();
    }

    return shipments;
  }
  // Update shipment status locally
  void updateShipmentStatusLocally(String trackingNumber, String newStatus) {
    // final index = _recentShipments.indexWhere(
    //       (shipment) => shipment['trackingNumber'] == trackingNumber,
    // );
    //
    //
    // if (index != -1) {
    //   _recentShipments[index]['status'] = newStatus;
    //   notifyListeners();
    // }
  }

  // Update shipment status via API
  Future<void> updateShipmentStatus(String trackingNumber, String statusName) async {
   /* clearError();

    try {
      // Trouver le shipment par tracking number pour obtenir l'ID
      final shipment = _recentShipments.firstWhere(
            (shipment) => shipment['trackingNumber'] == trackingNumber,
        orElse: () => <String, dynamic>{},
      );

      final shipmentId = shipment['id'];
      if (shipmentId == null) {
        _setError('Shipment not found');
        return false;
      }

      // Convertir le nom du statut en ID
      final statusId = _getStatusId(statusName);
      if (statusId == null) {
        _setError('Statut invalide: $statusName');
        return false;
      }

      // Appel API pour mettre à jour le statut
      final response = await _apiService.put(
          '/orders/$shipmentId/status',
          data: {'status': statusId}
      );

      if (response['success'] == true) {
        // Mettre à jour localement aussi
        updateShipmentStatusLocally(trackingNumber, statusName);
        return true;
      } else {
        _setError(response['message'] ?? 'Erreur de mise à jour');
        return false;
      }
    } catch (e) {
      _setError('Échec de la mise à jour: $e');
      return false;
    }*/
  }

  // Helper method to get status display name
  String _getStatusDisplayName(dynamic status) {
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

  // Helper method to get status ID from name
  int? _getStatusId(String statusName) {
    const statusNameToId = {
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

    return statusNameToId[statusName];
  }


  // Format shipment data from API to UI format
  Map<String, dynamic> _formatShipmentForUI(Map<String, dynamic> apiOrder) {
    // Récupérer l'historique des statuts depuis l'API
    final Map<String, String> statusHistory = {};

    // Ajouter le statut Created par défaut
    statusHistory['Created'] = apiOrder['order_date'] ?? DateTime.now().toIso8601String();

    // Traiter l'historique des statuts de l'API
    if (apiOrder['statusHistory'] is List) {
      final List<dynamic> historyList = apiOrder['statusHistory'];

      for (var historyItem in historyList) {
        if (historyItem is Map<String, dynamic>) {
          final String action = historyItem['action']?.toString() ?? '';
          final String date = historyItem['date']?.toString() ?? '';

          if (action.isNotEmpty && date.isNotEmpty) {
            // Mapper l'action au nom du statut approprié
            final String statusName = _mapActionToStatusName(action);
            statusHistory[statusName] = date;
          }
        }
      }
    }

    return {
      'id': apiOrder['order_id'],
      'trackingNumber': '${apiOrder['order_prefix'] ?? ''}-${apiOrder['order_no'] ?? 'N/A'}',
      'status': apiOrder['status_courier']?.toString(),
      'price': apiOrder['price']?.toString() ?? '0',
      'recipientName': apiOrder['receiver_name'] ?? 'Unknown',
      'city': apiOrder['city'] ?? 'Unknown City',
      'cityName': apiOrder['city_name'] ?? 'Unknown City',

      'phone': apiOrder['phone'] ?? 'No phone',
      'deliveryAddress': apiOrder['address'] ?? 'No address',
      'date': apiOrder['order_date'] ?? DateTime.now().toIso8601String(),
      'statusHistory': statusHistory, // Utiliser le statusHistory construit
      'userNotes': apiOrder['notes'] ?? '',
      'senderName': '${apiOrder['fname']?.toString() ?? ''} ${apiOrder['lname']?.toString() ?? ''}'.trim(),
      'senderEmail': apiOrder['user_email'] ?? 'N/A',
      'driverId': apiOrder['driver_id'],
      'notes': apiOrder['description'] ?? '',
      'rawStatusHistory': apiOrder['statusHistory'],
    };
  }

  String _mapActionToStatusName(String action) {
    const actionToStatusMap = {
      'has delivered the shipment': 'Delivered',
      'create order shipment': 'Created', // ← Maintenant en minuscules
      'has picked up the shipment': 'Picked up',
      'is in transit': 'In Transit',
      'is out for delivery': 'Out for Delivery',
      'attempted delivery': 'Attempted Delivery',
      'has returned the shipment': 'Returned',
      'has cancelled the shipment': 'Cancelled',
      'has confirmed the shipment': 'Confirmed',
      'has rejected the shipment': 'Rejected',
    };

    return actionToStatusMap[action.toLowerCase()] ?? action;
  }
  // Dans ShipmentProvider
  Future<Map<String, dynamic>> updateOrder({
    required String orderId,
    required String recipientName,
    required String recipientPhone,
    required String deliveryAddress,
    required String city,
    required double price,
    String? description,
  }) async {
    try {
      final data = {
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'deliveryAddress': deliveryAddress,
        'city': city,
        'price': price,
        'description': description,
      };

      // Nettoyer les données
      data.removeWhere((key, value) => value == null);

      final response = await _apiService.put('/orders/$orderId', data: data);

      if (response['success'] == true) {
        // Mettre à jour la liste localement
        final int index = _allShipments.indexWhere((order) => order['id'].toString() == orderId);
        if (index != -1) {
          final updatedOrder = _formatShipmentForUI(response['data']['order']);
          _allShipments[index] = updatedOrder;
          notifyListeners();
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Order updated successfully',
          'order': response['data']['order'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to update order',
        };
      }
    } catch (error) {
      print('Update order error: $error');
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }
  // Dans ShipmentProvider
  Future<Map<String, dynamic>> assignDriverToOrder({
    required String orderId,
    required int driverId,
  }) async {
    try {
      final data = {
        'driver_id': driverId,
      };

      final response = await _apiService.put('/orders/$orderId/assign-driver', data: data);

      if (response['success'] == true) {
        // Mettre à jour la commande localement
        final int index = _allShipments.indexWhere((order) => order['id'].toString() == orderId);
        if (index != -1) {
          _allShipments[index]['driverId'] = driverId;
          notifyListeners();
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Chauffeur assigné avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Échec de l\'assignation',
        };
      }
    } catch (error) {
      print('Assign driver error: $error');
      return {
        'success': false,
        'message': 'Erreur réseau: $error',
      };
    }
  }


  // Dans ShipmentProvider
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    try {
      final data = {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _apiService.put('/orders/$orderId/status', data: data);

      if (response['success'] == true) {
        // Mettre à jour la commande localement
        final int index = _allShipments.indexWhere((order) => order['id'].toString() == orderId);
        if (index != -1) {
          // Convertir le nom du statut en ID pour le stockage local
          final statusId = _getStatusId(status);
          if (statusId != null) {
            _allShipments[index]['status'] = statusId.toString();
          } else {
            _allShipments[index]['status'] = status; // Fallback au nom textuel
          }
          notifyListeners();
        }

        return {
          'success': true,
          'message': response['message'] ?? 'Statut mis à jour avec succès',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Échec de la mise à jour du statut',
        };
      }
    } catch (error) {
      print('Update order status error: $error');
      return {
        'success': false,
        'message': 'Erreur réseau: $error',
      };
    }
  }

  // Dans ShipmentProvider
  Future<void> refreshOrders() async {
    await loadAllShipments();
  }



}