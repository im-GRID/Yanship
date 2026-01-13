import 'userIlyass.dart';

class Livreur extends User {
  String vehiculeRegistrationNumber;
  String vehiculeCode;

  Livreur({
    required super.idUser,
    required super.firstName,
    required super.lastName,
    required super.username,
    required super.password,
    required super.ice,
    required super.rib,
    required super.cin,
    required super.email,
    required super.phone,
    required super.status,
    required super.gender,
    required super.newsletter,
    super.avatar,
    super.userNotes,
    required super.idAdresse,
    required super.dateCreation,
    required super.dateModification,
    super.lastLogin,
    super.lastIP,
    required super.userLevel,
    required this.vehiculeRegistrationNumber,
    required this.vehiculeCode,
  });

  @override
  void notifyUser() {
    // Implémentation de la notification spécifique au livreur
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['vehiculeRegistrationNumber'] = vehiculeRegistrationNumber;
    data['vehiculeCode'] = vehiculeCode;
    return data;
  }

  factory Livreur.fromJson(Map<String, dynamic> json) {
    return Livreur(
      idUser: json['idUser'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      username: json['username'],
      password: json['password'],
      ice: json['ice'],
      rib: json['rib'],
      cin: json['cin'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      gender: json['gender'],
      newsletter: json['newsletter'],
      avatar: json['avatar'],
      userNotes: json['userNotes'],
      idAdresse: json['idAdresse'],
      dateCreation: DateTime.parse(json['dateCreation']),
      dateModification: DateTime.parse(json['dateModification']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      lastIP: json['lastIP'],
      userLevel: json['userLevel'],
      vehiculeRegistrationNumber: json['vehiculeRegistrationNumber'],
      vehiculeCode: json['vehiculeCode'],
    );
  }
}