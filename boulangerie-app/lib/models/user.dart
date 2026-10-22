import 'json.dart';

enum UserRole { owner, staff }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.active,
  });

  factory AppUser.fromJson(Json json) => AppUser(
        id: asInt(json['id']),
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: UserRole.values.byName(json['role'] as String),
        active: json['active'] as bool,
      );

  final int id;
  final String name;
  final String phone;
  final UserRole role;
  final bool active;

  bool get isOwner => role == UserRole.owner;

  Json toJson() => {'id': id, 'name': name, 'phone': phone, 'role': role.name, 'active': active};
}
