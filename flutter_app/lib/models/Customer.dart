import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/User.dart';

class Customer extends User {
  String documentType;
  String documentNumber;

  Customer({
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
    this.documentType = '',
    this.documentNumber = '',
    int userLevel = 1,
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
  Customer copyWith({
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
    String? documentType,
    String? documentNumber,
    int? userLevel,
    DateTime? createdAt,
  }) {
    return Customer(
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
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      userLevel: userLevel ?? this.userLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Création depuis JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
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
      isActive: (json['isActive'] ?? 1) == 1,
      newsletterSubscribed: (json['newsletter'] ?? 0) == 1,
      userNotes: json['notes'] ?? '',
      documentType: json['document_type'] ?? '',
      documentNumber: json['document_number'] ?? '',
      userLevel: json['userlevel'] ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }


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
      'documentType': documentType,
      'documentNumber': documentNumber,
      'gender': gender,
      'newsletterSubscribed': newsletterSubscribed,
      'userNotes': userNotes,
      'addresses': addresses.map((addr) => addr.toJson()).toList(),
    };
  }
}