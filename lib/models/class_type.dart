class ClassType {
  final String id;
  final String name;

  ClassType({
    required this.id,
    required this.name,
  });

  factory ClassType.fromMap(String id, Map<String, dynamic> data) {
    return ClassType(
      id: id,
      name: data['name'] ?? '',
    );
  }
}