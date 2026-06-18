class Student {
  final String id;
  final String name;
  final String nis;
  final String className;
  final String department;
  final int points;
  final String status;
  final String? imageUrl;
  final String initials;

  Student({
    required this.id,
    required this.name,
    required this.nis,
    required this.className,
    required this.department,
    this.points = 0,
    this.status = 'Aktif',
    this.imageUrl,
    String? initials,
  }) : initials = initials ?? _getInitials(name);

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Student copyWith({
    String? id,
    String? name,
    String? nis,
    String? className,
    String? department,
    int? points,
    String? status,
    String? imageUrl,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      nis: nis ?? this.nis,
      className: className ?? this.className,
      department: department ?? this.department,
      points: points ?? this.points,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nis': nis,
        'className': className,
        'department': department,
        'points': points,
        'status': status,
        'imageUrl': imageUrl,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        nis: (json['nis'] as String?) ?? '',
        className: (json['className'] as String?) ?? '',
        department: (json['department'] as String?) ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        status: (json['status'] as String?) ?? 'Aktif',
        imageUrl: json['imageUrl'] as String?,
      );
}
