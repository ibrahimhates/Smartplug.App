import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/api_response.dart';
import '../services/storage_service.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  static const String deviceBaseUrl = 'http://192.168.4.1';
  final StorageService _storageService = StorageService();
  final NetworkInfo _networkInfo = NetworkInfo();

  String? _getUserIdFromToken() {
    final token = _storageService.getAuthToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      return payload['userid'] as String?;
    } catch (e) {
      return null;
    }
  }

  // WiFi ağlarını listele
  Future<ApiResponse<List<String>>> getNetworks() async {
    try {
      final response = await http.get(
        Uri.parse('$deviceBaseUrl/list-networks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> networks = json.decode(response.body);
        return ApiResponse.success(networks.cast<String>());
      } else {
        return ApiResponse.error('WiFi ağları listelenemedi');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // WiFi ağına bağlan
  Future<ApiResponse<void>> connectToWifi(String ssid, String password) async {
    try {
      final userId = _getUserIdFromToken();
      if (userId == null) {
        return ApiResponse.error('Kullanıcı bilgisi bulunamadı');
      }

      final response = await http.post(
        Uri.parse('$deviceBaseUrl/connect-wifi'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ssid': ssid,
          'password': password,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('WiFi bağlantısı başarısız');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> isConnectedToSmartPlug() async {
    try {
      final wifiName = await _networkInfo.getWifiGatewayIP();
      print('Bağlı olduğunuz WiFi: $wifiName');
      print(wifiName == "192.168.4.1");
      return ApiResponse(success: wifiName == "192.168.4.1");
    } catch (e) {
      print('WiFi bilgisi alınamadı: $e');
      return ApiResponse(success: false);
    }
  }
}
