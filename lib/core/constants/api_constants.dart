class ApiConstants {
  static const String baseUrl = 'https://api.smartplug-io.tech/api';

  // Auth endpoints
  static const String auth = '/Auth/login';
  static const String refreshToken = '/Auth/refreshToken';
  static const String editPass = '/editPass'; // Şifre değiştirme endpoint'i

  // Device endpoints
  static const String devices = '/devices';
  static const String networkDevices = '/devices/network';
  static const String allDevices = '/Plugs/all-devices';
  static String plugStatus(String id) => '/Plugs/plug-status/$id';
  static const String editDevice = '/devices/edit'; // Cihaz adı değiştirme endpoint'i

  static const String networks = '/networks';

  static const String schedule = '/schedules';

  static String getSchedules(String deviceId) => '/schedules/device/$deviceId';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'accept': '*/*',
  };
}
