import 'dart:convert';
import '../../domain/entities/user.dart';

/// Kullanıcı data modeli: JSON ↔ Entity dönüşümlerini yönetir.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.avatarPath,
    required super.pin,
    required super.createdAt,
    super.lastLoginAt,
    super.role,
    super.preferences,
  });

  // ── JSON / SQLite Satırı ──────────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarPath: (map['avatar_path'] as String?) ?? '',
      pin: map['pin'] as String,
      role: _parseRole(map['role'] as String? ?? 'member'),
      preferences: UserPreferences(
        language: (map['language'] as String?) ?? 'tr_TR',
        voiceEnabled: (map['voice_enabled'] as int? ?? 1) == 1,
        notificationsEnabled:
            (map['notifications_enabled'] as int? ?? 1) == 1,
        ttsSpeed: (map['tts_speed'] as num?)?.toDouble() ?? 1.0,
        ttsPitch: (map['tts_pitch'] as num?)?.toDouble() ?? 1.0,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatar_path': avatarPath,
        'pin': pin,
        'role': role.name,
        'language': preferences.language,
        'voice_enabled': preferences.voiceEnabled ? 1 : 0,
        'notifications_enabled': preferences.notificationsEnabled ? 1 : 0,
        'tts_speed': preferences.ttsSpeed,
        'tts_pitch': preferences.ttsPitch,
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
      };

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  /// Domain entity'sini model'e dönüştür.
  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        name: user.name,
        avatarPath: user.avatarPath,
        pin: user.pin,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
        role: user.role,
        preferences: user.preferences,
      );

  static UserRole _parseRole(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.member,
    );
  }
}
