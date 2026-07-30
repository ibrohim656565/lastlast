import '../../../core/constants/incident_constants.dart';

/// Mirrors the `User` shape from docs/API_CONTRACT.md:
/// `{ id, name, phone, preferred_language, role, created_at }`.
enum UserRole {
  citizen,
  dispatcher,
  admin;

  String get wireValue => name;

  static UserRole fromWire(String value) => UserRole.values.firstWhere(
        (e) => e.wireValue == value,
        orElse: () => UserRole.citizen,
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.preferredLanguage,
    required this.role,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String phone;
  final AppLanguage preferredLanguage;
  final UserRole role;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        preferredLanguage: AppLanguage.fromWire(
          json['preferred_language'] as String? ?? 'en',
        ),
        role: UserRole.fromWire(json['role'] as String? ?? 'citizen'),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'preferred_language': preferredLanguage.wireValue,
        'role': role.wireValue,
        'created_at': createdAt.toIso8601String(),
      };
}
