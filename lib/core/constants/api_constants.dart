class ApiConstants {
  static const String baseUrl = 'https://api.smartplug-io.tech/api';

  // Auth endpoints
  static const String auth = '/Auth/login';

  // Device endpoints
  static const String devices = '/devices';
  static const String networkDevices = '/devices/network';

  // Network endpoints
  static const String networks = '/networks';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'accept': '*/*',
  };

  static const String allDevices = '/Plugs/all-devices';
  static const String refreshToken = '/Auth/refreshToken';

  static String plugStatus(String id) => '/Plugs/plug-status/$id';
}
