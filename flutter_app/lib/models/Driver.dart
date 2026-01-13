import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/User.dart';

class Driver extends User {
  String vehicleCode;
  String vehicleRegistrationNumber;

  Driver({
    required int id,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String gender,
    required List<Address> addresses,
    bool isActive = true,
    bool newsletterSubscribed = false,
    File? userAvatar,
    Uint8List? userAvatarWeb,
    String userNotes = '',
    this.vehicleCode = '',
    this.vehicleRegistrationNumber = '',
    int userLevel = 3,
    DateTime? createdAt,
  }) : super(
    id: id,
    username: username,
    password: password,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    gender: gender,
    addresses: addresses,
    isActive: isActive,
    newsletterSubscribed: newsletterSubscribed,
    userAvatar: userAvatar,
    userAvatarWeb: userAvatarWeb,
    userNotes: userNotes,
    userLevel: userLevel,
    createdAt: createdAt,
  );

  // Copier avec modifications
  Driver copyWith({
    int? id,
    String? username,
    String? password,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    List<Address>? addresses,
    bool? isActive,
    bool? newsletterSubscribed,
    File? userAvatar,
    Uint8List? userAvatarWeb,
    String? userNotes,
    String? vehicleCode,
    String? vehicleRegistrationNumber,
    int? userLevel,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      addresses: addresses ?? this.addresses,
      isActive: isActive ?? this.isActive,
      newsletterSubscribed: newsletterSubscribed ?? this.newsletterSubscribed,
      userAvatar: userAvatar ?? this.userAvatar,
      userAvatarWeb: userAvatarWeb ?? this.userAvatarWeb,
      userNotes: userNotes ?? this.userNotes,
      vehicleCode: vehicleCode ?? this.vehicleCode,
      vehicleRegistrationNumber:
      vehicleRegistrationNumber ?? this.vehicleRegistrationNumber,
      userLevel: userLevel ?? this.userLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Création depuis JSON
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? 0,
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      vehicleCode: json['vehiclecode'] ?? '',
      vehicleRegistrationNumber: json['enrollment'] ?? '',
      userLevel: json['userLevel'] ?? 3,

      username: json['username'] ?? '',
      password: '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((addr) => Address.fromJson(addr))
          .toList(),
      isActive: (json['active'] ?? 1) == 1,
      newsletterSubscribed: (json['newsletter'] ?? 0) == 1,
      userNotes: json['notes'] ?? '',
      createdAt: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
    );
  }

  // Conversion en JSON


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'userLevel': userLevel,
      'isActive': isActive,
      'vehicleCode': vehicleCode,
      'vehicleRegistrationNumber':vehicleRegistrationNumber,
      'gender': gender,
      'newsletterSubscribed': newsletterSubscribed,
      'userNotes': userNotes,
      'addresses': addresses.map((addr) => addr.toJson()).toList(),
    };
  }
}
