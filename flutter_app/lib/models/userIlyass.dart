
import '../services/notification_service.dart';

abstract class User {
  final String idUser;
  String firstName;
  String lastName;
  String username;
  String password;
  String ice;
  String rib;
  String cin;
  String email;
  String phone;
  String status;
  String gender;
  bool newsletter;
  String? avatar;
  String? userNotes;
  int idAdresse;
  DateTime dateCreation;
  DateTime dateModification;
  DateTime? lastLogin;
  String? lastIP;
  String userLevel;

  User({
    required this.idUser,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.ice,
    required this.rib,
    required this.cin,
    required this.email,
    required this.phone,
    required this.status,
    required this.gender,
    required this.newsletter,
    this.avatar,
    this.userNotes,
    required this.idAdresse,
    required this.dateCreation,
    required this.dateModification,
    this.lastLogin,
    this.lastIP,
    required this.userLevel,
  });

  void notifyUser() {
    /*final notificationService = NotificationService();
    notificationService.showOrderStatusNotification(
      orderId: idUser,
      status: status,
      customMessage: 'Your order status has been updated to: $status',
    );*/
  }

  Map<String, dynamic> toJson() {
    return {
      'idUser': idUser,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'password': password,
      'ice': ice,
      'rib': rib,
      'cin': cin,
      'email': email,
      'phone': phone,
      'status': status,
      'gender': gender,
      'newsletter': newsletter,
      'avatar': avatar,
      'userNotes': userNotes,
      'idAdresse': idAdresse,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'lastIP': lastIP,
      'userLevel': userLevel,
    };
  }
}