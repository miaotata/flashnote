class Tag {
  final int id;
  final String name;
  final String color; // hex string e.g. '#FF3B30'
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });
}
