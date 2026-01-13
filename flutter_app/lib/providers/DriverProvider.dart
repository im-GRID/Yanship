import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/models/Driver.dart';
import 'package:flutter_app/services/api_serice.dart';

class DriversProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(baseUrl: baseURL);
  final Map<int, Driver> _driversCache = {};
  List<Driver> _allDrivers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _pendingRequests = {};

  bool get isLoading => _isLoading;
  List<Driver> get allDrivers => _allDrivers;
  String? get errorMessage => _errorMessage;

  Future<Driver?> getDriverById(int driverId) async {
    if (driverId == 0) return null;

    // Vérifier d'abord dans le cache
    if (_driversCache.containsKey(driverId)) {
      return _driversCache[driverId];
    }

    // Éviter les appels multiples pour le même driverId
    if (_pendingRequests.contains(driverId)) {
      // Attendre que la requête en cours se termine
      await Future.delayed(const Duration(milliseconds: 100));
      return _driversCache[driverId]; // Retourner le résultat si disponible
    }

    _pendingRequests.add(driverId);

    try {
      // Ne pas appeler notifyListeners() ici pour éviter les erreurs de build
      final response = await _apiService.get('/users/driver/$driverId');

      Driver driver;
      if (response is Map && response.containsKey('data')) {
        driver = Driver.fromJson(response['data']);
      } else {
        driver = Driver.fromJson(response);
      }

      _driversCache[driverId] = driver;

      // Notifier les listeners APRÈS le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return driver;
    } catch (e) {
      return null;
    } finally {
      _pendingRequests.remove(driverId);
    }
  }
  // CORRECTION ICI : L'API retourne directement une liste, pas un objet avec success/data
  Future<void> getAllDrivers() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final response = await _apiService.get('/users/drivers');

      // Vérifier si la réponse est une List
      if (response is List) {

        _allDrivers = response.map((data) {
          try {
            return Driver.fromJson(data);
          } catch (e) {
            return Driver(
                id: 0,
                firstName: 'Invalid',
                lastName: 'Driver',
                username: '',
                password: '',
                email: '',
                phone: '',
                gender: '',
                addresses: []
            );
          }
        }).where((driver) => driver.id != 0).toList();

        for (var driver in _allDrivers) {
          _driversCache[driver.id] = driver;
        }

      }
      // Vérifier si c'est un Map avec une propriété 'data'
      else if (response is Map && response.containsKey('data')) {
        final List<dynamic> driversData = response['data'] ?? [];

        _allDrivers = driversData.map((data) {
          try {
            return Driver.fromJson(data);
          } catch (e) {
            return Driver(
                id: 0,
                firstName: 'Invalid',
                lastName: 'Driver',
                username: '',
                password: '',
                email: '',
                phone: '',
                gender: '',
                addresses: []
            );
          }
        }).where((driver) => driver.id != 0).toList();

        for (var driver in _allDrivers) {
          _driversCache[driver.id] = driver;
        }

      }
      // Vérifier si c'est un Map avec une propriété 'drivers'
      else if (response is Map && response.containsKey('drivers')) {
        final List<dynamic> driversData = response['drivers'] ?? [];

        _allDrivers = driversData.map((data) {
          try {
            return Driver.fromJson(data);
          } catch (e) {
            return Driver(
                id: 0,
                firstName: 'Invalid',
                lastName: 'Driver',
                username: '',
                password: '',
                email: '',
                phone: '',
                gender: '',
                addresses: []
            );
          }
        }).where((driver) => driver.id != 0).toList();

        for (var driver in _allDrivers) {
          _driversCache[driver.id] = driver;
        }

      }
      else {
        _errorMessage = 'Format de réponse inattendu de l\'API';
      }
    } catch (e) {
      _errorMessage = 'Error loading drivers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _driversCache.clear();
    _allDrivers.clear();
    notifyListeners();
  }
}