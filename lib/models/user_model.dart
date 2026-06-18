enum UserRole { admin, waliKelas, student }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String nip;
  final UserRole role;
  final String? imageUrl;
  final String? className;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nip,
    required this.role,
    this.imageUrl,
    this.className,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isWaliKelas => role == UserRole.waliKelas;
  bool get isStudent => role == UserRole.student;

  String get roleDisplay {
    switch (role) {
      case UserRole.admin:
        return 'Admin BK';
      case UserRole.waliKelas:
        return 'Wali Kelas';
      case UserRole.student:
        return 'Siswa';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'nip': nip,
        'role': role.name,
        'imageUrl': imageUrl,
        'className': className,
        'class': className,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        nip: (json['nip'] as String?) ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.student,
        ),
        imageUrl: json['imageUrl'] as String?,
        className: (json['className'] as String?) ?? (json['class'] as String?),
      );

  static UserRole roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'guru_bk':
      case 'kepala_sekolah':
        return UserRole.admin;
      case 'wali_kelas':
        return UserRole.waliKelas;
      case 'student':
      case 'siswa':
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }
}
