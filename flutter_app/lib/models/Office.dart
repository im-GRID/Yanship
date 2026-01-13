class Office {
  final int id;
  final String name;

  Office({required this.id, required this.name});

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['id'],
      name: json['name_off'],
    );
  }
}