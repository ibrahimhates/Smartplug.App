import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../core/services/device_service.dart';
import '../main.dart';
import 'dart:async';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = true;
  String? _error;
  List<Device> _devices = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    Future.delayed(Duration.zero, () {
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          _loadDevices();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    if (_devices.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final response = await _deviceService.getDevices();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _devices = response.data ?? [];
        } else {
          _error = response.error;
        }
      });
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
                          // Cihaz detay/ayar sayfasına git
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Ayarlar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: device.isOnline
                            ? () async {
                                final response =
                                    await _deviceService.togglePlugStatus(
                                  device.id,
                                  !device.isWorking,
                                );

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(response.data ?? 'İşlem başarılı'),
                                    backgroundColor: response.success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );

                                // Listeyi yenile
                                if (response.success) {
                                  _loadDevices();
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
