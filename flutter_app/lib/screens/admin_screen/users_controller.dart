// users_controller.dart
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Admin.dart';
import 'package:flutter_app/models/Customer.dart';
import 'package:flutter_app/models/Driver.dart';
import 'package:flutter_app/services/api_serice.dart';


class UsersManager {
  static const int SUPER_ADMIN_LEVEL = 9;
  static const int USER_MANAGEMENT_LEVEL = 2;

  final ApiService apiService;

  UsersManager({required this.apiService});

  Future<Driver> updateDriver(Driver driver, {String? password}) async {
    try {
      final userData = driver.toJson();

      // Ajouter le mot de passe si fourni
      if (password != null && password.isNotEmpty) {
        userData['password'] = password;
      }

      // CORRECTION : Utiliser la bonne URL et convertir l'ID en string
      final response = await apiService.put('/users/${driver.id.toString()}', data: userData);
      return Driver.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'utilisateur: $e');
    }
  }


  // Récupérer la liste des Super Admins
  Future<List<Admin>> getSuperAdmins() async {
    try {
      final response = await apiService.get('/users/super-admins');
      return (response as List).map((userData) => Admin.fromJson(userData)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des Super Admins: $e');
    }
  }

  // Récupérer la liste des User Management
  Future<List<Admin>> getUserManagements() async {
    try {
      final response = await apiService.get('/users/user-managements');
      return (response as List).map((userData) => Admin.fromJson(userData)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des User Managements: $e');
    }
  }

  Future<List<Customer>> getCustomers() async {
    try {
      final response = await apiService.get('/users/customers');
      return (response as List).map((userData) => Customer.fromJson(userData)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des Customers: $e');
    }
  }

  Future<List<Driver>> getDrivers() async {
    try {
      final response = await apiService.get('/users/drivers');
      return (response as List).map((userData) => Driver.fromJson(userData)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des drivers: $e');
    }
  }

  // Visualiser un utilisateur
  Future<Admin> viewUser(int userId) async {
    try {
      final response = await apiService.get('/users/$userId');
      return Admin.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la visualisation de l\'utilisateur: $e');
    }
  }


  // Supprimer un utilisateur
  Future<void> deleteUser(int userId) async {
    try {
      await apiService.delete('/users/$userId');
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  // Ajouter un utilisateur
  Future<Admin> addUser(Admin user, String password) async {
    try {
      final userData = user.toJson();
      userData['password'] = password;

      final response = await apiService.post('/users', data: userData);
      return Admin.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'utilisateur: $e');
    }
  }

// Mettre à jour un utilisateur
  Future<Admin> updateUser(Admin admin, {String? password}) async {
    try {
      final userData = admin.toJson();

      // Ajouter le mot de passe si fourni
      if (password != null && password.isNotEmpty) {
        userData['password'] = password;
      }

      // CORRECTION : Utiliser la bonne URL et convertir l'ID en string
      final response = await apiService.put('/users/${admin.id.toString()}', data: userData);
      return Admin.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'utilisateur: $e');
    }
  }

  // Mettre à jour un utilisateur
  Future<Customer> updateCustomer(Customer customer, {String? password}) async {
    try {
      final userData = customer.toJson();

      // Ajouter le mot de passe si fourni
      if (password != null && password.isNotEmpty) {
        userData['password'] = password;
      }

      // CORRECTION : Utiliser la bonne URL et convertir l'ID en string
      final response = await apiService.put('/users/${customer.id.toString()}', data: userData);
      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la modification de l\'utilisateur: $e');
    }
  }


  // Mettre à jour un utilisateur

// Récupérer un utilisateur spécifique
  Future<Admin> getUserById(int userId) async {
    try {
      final response = await apiService.get('/users/$userId');

      // Nouveau format de réponse
      if (response is Map<String, dynamic> && response['success'] == true) {
        return Admin.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get user');
      }

    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  Future<Customer> getCustomerById(int userId) async {
    try {
      final response = await apiService.get('/users/customer/$userId');

      // Nouveau format de réponse
      if (response is Map<String, dynamic> && response['success'] == true) {
        return Customer.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get customer');
      }

    } catch (e) {
      throw Exception('Erreur lors de la récupération du customer: $e');
    }
  }

  Future<Driver> getDriverById(int userId) async {
    try {
      final response = await apiService.get('/users/driver/$userId');

      // Nouveau format de réponse
      if (response is Map<String, dynamic> && response['success'] == true) {
        return Driver.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get driver');
      }

    } catch (e) {
      throw Exception('Erreur lors de la récupération du driver: $e');
    }
  }

  Future<List<Address>> getUserAddresses(int userId) async {
    try {
      final response = await apiService.get('/users/$userId/addresses');

      // Nouveau format de réponse : {"success": true, "data": [...]}
      if (response is Map<String, dynamic> && response['success'] == true) {
        final addressesData = response['data'] as List;
        return addressesData.map((addressData) => Address.fromJson(addressData)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch addresses');
      }

    } catch (e) {
      throw Exception('Erreur lors de la récupération des adresses: $e');
    }
  }
}

