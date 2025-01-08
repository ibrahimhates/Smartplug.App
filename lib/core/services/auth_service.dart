import '../constants/api_constants.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import '../services/storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<ApiResponse> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        endpoint: ApiConstants.auth,
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final token = data['token'];
          final refreshToken = data['refreshToken'];

          if (token != null && refreshToken != null) {
            await _storageService.setTokens(
              authToken: token,
              refreshToken: refreshToken,
            );
            _apiService.setToken(token);
          }
        }
      }

      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _storageService.clearTokens();
  }

  bool isLoggedIn() {
    final token = _storageService.getAuthToken();
    return token != null;
  }
}
