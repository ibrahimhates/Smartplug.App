import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../services/storage_service.dart';
import '../enums/api_error_type.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _token = _storageService.getAuthToken();
  }

  final StorageService _storageService = StorageService();
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConstants.headers);
    final token = _token ?? _storageService.getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse<T>> _refreshToken<T>() async {
    try {
      final refreshToken = _storageService.getRefreshToken();
      if (refreshToken == null) {
        return ApiResponse.error('Refresh token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}')
            .replace(queryParameters: {'RefreshToken': refreshToken}),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storageService.setTokens(
          authToken: data['token'],
          refreshToken: data['refreshToken'],
        );
        return ApiResponse.success(data);
      }
      return ApiResponse.error('Token yenilenemedi');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    Map<String, String>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    bool retry = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        if (fromJson == null) {
          return ApiResponse.success(null);
        }
        final jsonData = json.decode(response.body);
        return ApiResponse.success(fromJson(jsonData));
      } else if (response.statusCode == 401 && retry) {
        final refreshResponse = await _refreshToken();
        if (refreshResponse.success) {
          return get(
              endpoint: endpoint,
              queryParameters: queryParameters,
              fromJson: fromJson,
              retry: false);
        }
        return ApiResponse.error(
          'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
          errorType: ApiErrorType.unauthorized,
        );
      }
      return ApiResponse.error(
        'İstek başarısız: ${response.statusCode}',
        errorType: ApiErrorType.fromStatusCode(response.statusCode),
      );
    } catch (e) {
      print("RESPOINSE BASE : ${e}");
      return ApiResponse.error(
        e.toString(),
        errorType: ApiErrorType.networkError,
      );
    }
  }

  Future<ApiResponse<T>> login<T>({
    required String endpoint,
    required dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: ApiConstants.headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (fromJson != null) {
          return ApiResponse.success(fromJson(jsonData));
        }
        return ApiResponse.success(jsonData);
      } else {
        return ApiResponse.error(
            'HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    required dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
    bool retry = true,
  }) async {
    try {
      print('Request Body: ${json.encode(body)}');

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (fromJson != null) {
          return ApiResponse.success(fromJson(jsonData));
        }
        return ApiResponse.success(jsonData);
      } else if (response.statusCode == 401 && retry) {
        final refreshResponse = await _refreshToken();
        if (refreshResponse.success) {
          return post(
              endpoint: endpoint, body: body, fromJson: fromJson, retry: false);
        }
        return ApiResponse.error(
          'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
          errorType: ApiErrorType.unauthorized,
        );
      }
      return ApiResponse.error(
        'HTTP Error ${response.statusCode}: ${response.body}',
        errorType: ApiErrorType.fromStatusCode(response.statusCode),
      );
    } catch (e) {
      return ApiResponse.error(
        e.toString(),
        errorType: ApiErrorType.networkError,
      );
    }
  }

  /// PUT isteği gerçekleştiren metot
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    required dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
    bool retry = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (fromJson != null) {
          return ApiResponse.success(fromJson(jsonData));
        }
        return ApiResponse.success(jsonData);
      } else if (response.statusCode == 401 && retry) {
        final refreshResponse = await _refreshToken();
        if (refreshResponse.success) {
          return put(
              endpoint: endpoint, body: body, fromJson: fromJson, retry: false);
        }
        return ApiResponse.error(
          'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
          errorType: ApiErrorType.unauthorized,
        );
      }
      return ApiResponse.error(
        'HTTP Error ${response.statusCode}: ${response.body}',
        errorType: ApiErrorType.fromStatusCode(response.statusCode),
      );
    } catch (e) {
      return ApiResponse.error(
        e.toString(),
        errorType: ApiErrorType.networkError,
      );
    }
  }
}
