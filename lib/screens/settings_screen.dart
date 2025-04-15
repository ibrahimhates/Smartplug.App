import 'package:flutter/material.dart';
import '../core/services/device_service.dart';
import '../core/services/auth_service.dart';
import '../models/device_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Şifre değiştirme formu kontrolcüleri:
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final _passFormKey = GlobalKey<FormState>();
  bool _isChangingPass = false;

  // Cihaz adı değiştirme alanı için:
  final DeviceService _deviceService = DeviceService();
  List<Device> _devices = [];
  Device? _selectedDevice;
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isEditingDevice = false;
  bool _devicesLoading = true;
  String? _devicesError;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _devicesLoading = true;
      _devicesError = null;
    });
    final response = await _deviceService.getDevices();
    if (mounted) {
      setState(() {
        _devicesLoading = false;
        if (response.success) {
          _devices = response.data ?? [];
          if (_devices.isNotEmpty) {
            _selectedDevice = _devices.first;
            _deviceNameController.text = _selectedDevice!.name;
          }
        } else {
          _devicesError = response.error;
        }
      });
    }
  }

  /// Şifre değiştirme işlemi için API çağrısı
  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;

    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler eşleşmiyor')),
      );
      return;
    }

    setState(() {
      _isChangingPass = true;
    });

    // Örneğin AuthService üzerinde editPassword fonksiyonunuz olsun
    final response = await AuthService().editPassword(
      currentPassword: _currentPassController.text,
      newPassword: _newPassController.text,
    );

    if (!mounted) return;
    setState(() {
      _isChangingPass = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.success ? 'Şifre başarıyla değiştirildi' : (response.error ?? 'Hata oluştu')),
        backgroundColor: response.success ? Colors.green : Colors.red,
      ),
    );
    if (response.success) {
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    }
  }

  /// Cihaz adı değiştirme işlemi için API çağrısı
  Future<void> _editDeviceName() async {
    if (_selectedDevice == null || _deviceNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir cihaz ve isim giriniz')),
      );
      return;
    }

    setState(() {
      _isEditingDevice = true;
    });

    // Örneğin DeviceService üzerinde editDeviceName fonksiyonunuz olsun
    final response = await _deviceService.editDeviceName(
      deviceId: _selectedDevice!.id,
      newName: _deviceNameController.text,
    );

    if (!mounted) return;
    setState(() {
      _isEditingDevice = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.success ? 'Cihaz adı güncellendi' : (response.error ?? 'Hata oluştu')),
        backgroundColor: response.success ? Colors.green : Colors.red,
      ),
    );

    // Eğer başarılı ise cihaz listesini yeniden yükleyebilirsiniz.
    if (response.success) {
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Şifre Değiştirme Bölümü
          const Text(
            'Şifre Değiştir',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Form(
            key: _passFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _currentPassController,
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mevcut şifre gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPassController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yeni şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPassController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yeni şifre tekrar gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChangingPass ? null : _changePassword,
                    child: _isChangingPass
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Şifreyi Değiştir'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          // Cihaz Adı Değiştirme Bölümü
          const Text(
            'Cihaz Adını Değiştir',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _devicesLoading
              ? const Center(child: CircularProgressIndicator())
              : _devicesError != null
                  ? Text(
                      _devicesError!,
                      style: const TextStyle(color: Colors.red),
                    )
                  : _devices.isEmpty
                      ? const Text('Daha önce eklenmiş cihaz bulunmuyor')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<Device>(
                              isExpanded: true,
                              value: _selectedDevice,
                              items: _devices
                                  .map(
                                    (device) => DropdownMenuItem<Device>(
                                      value: device,
                                      child: Text(device.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (Device? newDevice) {
                                setState(() {
                                  _selectedDevice = newDevice;
                                  _deviceNameController.text =
                                      newDevice?.name ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _deviceNameController,
                              decoration: const InputDecoration(
                                labelText: 'Yeni Cihaz Adı',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isEditingDevice ? null : _editDeviceName,
                                child: _isEditingDevice
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Cihaz Adını Güncelle'),
                              ),
                            ),
                          ],
                        ),
        ],
      ),
    );
  }
}
