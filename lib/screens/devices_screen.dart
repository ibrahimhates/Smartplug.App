import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../core/services/device_service.dart';
import '../main.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            leading: Icon(
              Icons.power,
              color: device.isOnline ? Colors.green : Colors.grey,
            ),
            title: Text(device.name),
            subtitle: Text(device.ipAddress),
            trailing: device.isOnline
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error_outline, color: Colors.grey),
          );
        },
      ),
    );
  }
}
