import '../models/user_profile.dart';
import '../services/database_service.dart';

class UserProfileRepository {
  final DatabaseService _db = DatabaseService.instance;
  final String _tableName = 'user_profile';
  static const String _defaultId = 'me';

  /// Get the user's profile (there's only one)
  Future<UserProfile?> getUserProfile() async {
    final maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [_defaultId],
    );

    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  /// Alias for getUserProfile (for sync service compatibility)
  Future<UserProfile?> getProfile() async {
    return getUserProfile();
  }

  /// Create or update the user's profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final existing = await getUserProfile();

    if (existing != null) {
      await _db.update(
        _tableName,
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    } else {
      await _db.insert(_tableName, profile.toMap());
    }
  }

  /// Get or create the user's profile
  Future<UserProfile> getOrCreateUserProfile() async {
    final existing = await getUserProfile();
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final newProfile = UserProfile(
      id: _defaultId,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insert(_tableName, newProfile.toMap());
    return newProfile;
  }
}
