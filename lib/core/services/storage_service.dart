import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(authTokenKey, authToken);
    await _prefs.setString(refreshTokenKey, refreshToken);
  }

  String? getAuthToken() => _prefs.getString(authTokenKey);
  String? getRefreshToken() => _prefs.getString(refreshTokenKey);

  Future<void> clearTokens() async {
    await _prefs.remove(authTokenKey);
    await _prefs.remove(refreshTokenKey);
  }
}
