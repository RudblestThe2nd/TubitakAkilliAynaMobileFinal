import 'package:equatable/equatable.dart';

/// Kullanıcı domain entity'si — veri katmanından bağımsız saf iş nesnesi.
class User extends Equatable {
  final String id;
  final String name;
  final String avatarPath;
  final String pin; // Hashed PIN (güvenli depolama için)
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserRole role;
  final UserPreferences preferences;

  const User({
    required this.id,
    required this.name,
    required this.avatarPath,
    required this.pin,
    required this.createdAt,
    this.lastLoginAt,
    this.role = UserRole.member,
    this.preferences = const UserPreferences(),
  });

  User copyWith({
    String? name,
    String? avatarPath,
    String? pin,
    DateTime? lastLoginAt,
    UserRole? role,
    UserPreferences? preferences,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        avatarPath: avatarPath ?? this.avatarPath,
        pin: pin ?? this.pin,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        role: role ?? this.role,
        preferences: preferences ?? this.preferences,
      );

  @override
  List<Object?> get props => [id, name, role];
}

enum UserRole { admin, member, guest }

/// Kullanıcıya özgü uygulama tercihleri.
class UserPreferences extends Equatable {
  final String language;
  final bool voiceEnabled;
  final bool notificationsEnabled;
  final double ttsSpeed;
  final double ttsPitch;

  const UserPreferences({
    this.language = 'tr_TR',
    this.voiceEnabled = true,
    this.notificationsEnabled = true,
    this.ttsSpeed = 1.0,
    this.ttsPitch = 1.0,
  });

  UserPreferences copyWith({
    String? language,
    bool? voiceEnabled,
    bool? notificationsEnabled,
    double? ttsSpeed,
    double? ttsPitch,
  }) =>
      UserPreferences(
        language: language ?? this.language,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        ttsSpeed: ttsSpeed ?? this.ttsSpeed,
        ttsPitch: ttsPitch ?? this.ttsPitch,
      );

  @override
  List<Object?> get props =>
      [language, voiceEnabled, notificationsEnabled, ttsSpeed, ttsPitch];
}
