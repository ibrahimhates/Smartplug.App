import '../models/api_response.dart';
import '../constants/api_constants.dart';
import '../../models/device_model.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import '../enums/api_error_type.dart';
import '../../screens/login_screen.dart';
import '../../main.dart';

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
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    return response;
  }
}
