import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../core/services/device_service.dart';
import '../core/services/signalr_service.dart';
import '../main.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final DeviceService _deviceService = DeviceService();
  final SignalRService _signalRService = SignalRService();
  bool _isLoading = true;
  String? _error;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _setupSignalR();
  }

  @override
  void dispose() {
    _signalRService.stopConnection();
    super.dispose();
  }

  Future<void> _setupSignalR() async {
    await _signalRService.startConnection();
    _signalRService.listenDeviceStatusChange(_loadDevices);
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _deviceService.getDevices();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success) {
            _devices = response.data ?? [];
          } else {
            _error = 'Bağlantı sağlanamadı';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Bağlantı sağlanamadı';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDevices,
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Henüz cihazınız yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cihaz bağlamak için Ağ tabına gidebilirsiniz',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Bottom navigation bar'da Ağ tabına git (index: 1)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MainScreen(initialIndex: 1),
                  ),
                );
              },
              icon: const Icon(Icons.wifi),
              label: const Text('Ağ Tabına Git'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  device.isWorking ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              device.isWorking ? 'Açık' : 'Kapalı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  device.isOnline ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              device.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('IP: ${device.localIP}'),
                  const SizedBox(height: 4),
                  Text('MAC: ${device.mac}'),
                  if (device.serialNumber != null) ...[
                    const SizedBox(height: 4),
                    Text('Seri No: ${device.serialNumber}'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Cihaz adını değiştirmek için dialog göster
                          final TextEditingController nameController = TextEditingController(text: device.name);
                          
                          showDialog(
                            context: context,
                            builder: (context) {
                              bool isLoading = false;
                              
                              return StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: const Text('Cihaz Adını Değiştir'),
                                  content: Container(
                                    width: double.maxFinite, // Dialog genişliğini artır
                                    child: TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Cihaz Adı',
                                        border: OutlineInputBorder(),
                                      ),
                                      autofocus: true,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                                  actions: [
                                    TextButton(
                                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                                      child: const Text('İptal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: isLoading 
                                          ? null 
                                          : () async {
                                              if (nameController.text.trim().isNotEmpty) {
                                                // Dialog üzerinde yükleniyor göster
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                
                                                try {
                                                  // API çağrısı
                                                  final response = await _deviceService.editDeviceName(
                                                    deviceId: device.id,
                                                    newName: nameController.text.trim(),
                                                  );

                                                  if (response.success) {
                                                    // API çağrısı başarılıysa UI'da güncelle
                                                    this.setState(() {
                                                      final updatedDevices = [..._devices];
                                                      final deviceIndex = updatedDevices.indexWhere((d) => d.id == device.id);
                                                      if (deviceIndex != -1) {
                                                        updatedDevices[deviceIndex] = updatedDevices[deviceIndex].copyWith(
                                                          name: nameController.text.trim(),
                                                        );
                                                        _devices = updatedDevices;
                                                      }
                                                    });
                                                    
                                                    // Başarılıysa dialog'u kapat
                                                    Navigator.of(context).pop();
                                                    
                                                    // Başarı mesajı göster
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Cihaz adı başarıyla değiştirildi'),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  } else {
                                                    // İşlem başarısızsa dialog üzerinde hata göster
                                                    setState(() {
                                                      isLoading = false;
                                                    });
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('İşlem başarısız oldu. Lütfen daha sonra tekrar deneyin.'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  // Hata durumunda dialog üzerinde hata göster
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                  
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Hata: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Kaydet'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Düzenle'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: device.isOnline
                            ? () async {
                                try {
                                  final response =
                                      await _deviceService.togglePlugStatus(
                                    device.id,
                                    !device.isWorking,
                                  );

                                  if (!mounted) return;
                                  print(
                                      "RESPONSEEE  DURUM: ${response.success}");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.success
                                          ? ('İşlem başarılı')
                                          : 'Bağlantı sağlanamadı'),
                                      backgroundColor: response.success
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );

                                  // Listeyi yenile
                                  if (response.success) {
                                    _loadDevices();
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  print("ERROR : $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Bağlantı sağlanamadı'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: Icon(
                          device.isWorking
                              ? Icons.power_settings_new
                              : Icons.power_off,
                          color: device.isWorking ? Colors.red : Colors.green,
                        ),
                        label: Text(device.isWorking ? 'Kapat' : 'Aç'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
