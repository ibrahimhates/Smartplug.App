import '../models/api_response.dart';
import '../constants/api_constants.dart';
import '../../models/device_model.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import '../enums/api_error_type.dart';
import '../../screens/login_screen.dart';
import '../../main.dart';
import 'auth_service.dart'; // AuthService'deki getToken metodunu kullanabilmek için import

class DeviceService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<Device>>> getDevices() async {
    final response = await _apiService.get<List<Device>>(
      endpoint: ApiConstants.allDevices,
      fromJson: (json) {
        final List<dynamic> devices = json['data'];
        return devices.map((device) => Device.fromJson(device)).toList();
      },
    );

    if (!response.success && response.errorType == ApiErrorType.unauthorized) {
      await AuthService().logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    return response;
  }

  Future<ApiResponse<NoContent>> togglePlugStatus(
      String deviceId, bool status) async {
    final response = await _apiService.get<NoContent>(
      endpoint: ApiConstants.plugStatus(deviceId),
      queryParameters: {'status': status.toString().toLowerCase()},
    );
    print("RESPONSEEE : ${response.success}");

    if (!response.success && response.errorType == ApiErrorType.unauthorized) {
      await AuthService().logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    return response;
  }

  /// Cihaz adını değiştirmek için PUT isteği gönderen metot
  Future<ApiResponse<NoContent>> editDeviceName({
    required String deviceId,
    required String newName,
  }) async {
    final body = {
      'id': deviceId, // deviceId yerine id kullan
      'name': newName, // newName yerine name kullan
    };

    try {
      final response = await _apiService.put<NoContent>(
        endpoint: ApiConstants.plugDevices, // editDevice yerine plugDevices kullan
        body: body,
      );

      if (!response.success &&
          response.errorType == ApiErrorType.unauthorized) {
        await AuthService().logout();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }

      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
