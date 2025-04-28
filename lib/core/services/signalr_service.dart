import 'dart:async';
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  final StorageService _storageService = StorageService();
  bool _isConnected = false;

  // Token içinden userId'yi çıkaran metod
  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      return payload['userid'] as String?;
    } catch (e) {
      print('Token içinden userId alınırken hata oluştu: $e');
      return null;
    }
  }

  // SignalR bağlantısı başlatma metodu
  Future<void> startConnection() async {
    if (_hubConnection != null && _isConnected) {
      return;
    }

    try {
      // SignalR hub URL'i
      final hubUrl = 'http://api.smartplug-io.tech/devicehub';

      // Token getirmeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      final token = _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Token içinden userId'yi al
      final userId = _getUserIdFromToken(token);
      if (userId == null) {
        print('Token içinden userId alınamadı');
      }

      // HTTP Options
      final httpConnectionOptions =
          HttpConnectionOptions(accessTokenFactory: () async => token);

      // Hub bağlantısı oluşturma
      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: httpConnectionOptions)
          .withAutomaticReconnect(
              retryDelays: [2000, 5000, 10000, 15000, 30000]).build();

      // Bağlantıyı başlatma
      await _hubConnection!.start();
      _isConnected = true;

      print('SignalR bağlantısı başarıyla kuruldu');

      // Bağlantı kurulduktan sonra AddList metodunu çağır
      try {
        if (userId != null) {
          await _hubConnection!.invoke('AddList', args: [userId]);
          print('AddList metodu userId ile başarıyla çağrıldı: $userId');
        } else {
          print('userId olmadığı için AddList metodu çağrılamadı');
        }
      } catch (e) {
        print('AddList metodu çağrılırken hata oluştu: $e');
      }

      // Bağlantı durumu değiştiğinde
      _hubConnection!.onclose(({error}) {
        _isConnected = false;
        print('SignalR bağlantısı kapandı: $error');
      });

      _hubConnection!.onreconnecting(({error}) {
        _isConnected = false;
        print('SignalR bağlantısı yeniden kuruluyor: $error');
      });

      _hubConnection!.onreconnected(({connectionId}) {
        _isConnected = true;
        print('SignalR bağlantısı yeniden kuruldu: $connectionId');

        // Yeniden bağlandığında da AddList metodunu çağır
        if (userId != null) {
          _hubConnection!.invoke('AddList', args: [
            userId
          ]).catchError((e) => print(
              'Yeniden bağlantıda AddList metodu çağrılırken hata oluştu: $e'));
        }
      });
    } catch (e) {
      print('SignalR bağlantısı kurulamadı: $e');
      _isConnected = false;
    }
  }

  // Cihaz durumu değişikliğini dinleme
  void listenDeviceStatusChange(Function() onStatusChange) {
    if (_hubConnection == null) {
      print('SignalR bağlantısı kurulmadan dinleme yapılamaz');
      return;
    }

    _hubConnection!.on('StatusChangeOnDevice', (arguments) {
      print('Cihaz durumu değişti: $arguments');
      onStatusChange();
    });
  }

  // Bağlantıyı kapatma
  Future<void> stopConnection() async {
    if (_hubConnection != null && _isConnected) {
      await _hubConnection!.stop();
      _isConnected = false;
      print('SignalR bağlantısı kapatıldı');
    }
  }

  bool get isConnected => _isConnected;
}
