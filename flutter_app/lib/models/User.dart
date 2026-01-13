import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/screens/admin_screen/users_controller.dart';

class User {
  int id;
  String username;
  String password;
  String firstName;
  String lastName;
  String email;
  String phone;
  String gender;
  List<Address> addresses;
  bool isActive;
  bool newsletterSubscribed;
  String userNotes;
  int userLevel;

  File? userAvatar;
  Uint8List? userAvatarWeb;
  DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.addresses,
    this.isActive = true,
    this.newsletterSubscribed = false,
    this.userAvatar,
    this.userAvatarWeb,
    this.userNotes = '',
    this.userLevel = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';
  bool get isSuperAdmin => userLevel == UsersManager.SUPER_ADMIN_LEVEL;
  bool get isUserManagement => userLevel == UsersManager.USER_MANAGEMENT_LEVEL;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      password: '',
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((addr) => Address.fromJson(addr))
          .toList(),
      isActive: (json['active'] ?? 1) == 1,
      newsletterSubscribed: (json['newsletter'] ?? 0) == 1,
      userNotes: json['notes'] ?? '',
      userLevel: json['userlevel'] ?? 0,
      createdAt: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
    );
  }

  // 🔹 Convertir User en Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'addresses': addresses.map((addr) => addr.toJson()).toList(),
      'isActive': isActive ? 1 : 0,
      'newsletterSubscribed': newsletterSubscribed ? 1 : 0,
      'userNotes': userNotes,
      'userLevel': userLevel,
      'createdAt': createdAt.toIso8601String(),
      // Note: userAvatar et userAvatarWeb ne sont pas inclus dans le JSON
    };
  }
}
