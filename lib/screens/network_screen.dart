import 'package:flutter/material.dart';
import '../core/services/network_service.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final NetworkService _networkService = NetworkService();
  bool _isLoading = true;
  String? _error;
  List<String> _networks = [];

  @override
  void initState() {
    super.initState();
    _scanNetworks();
  }

  Future<void> _scanNetworks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _networkService.getNetworks();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _networks = response.data ?? [];
        } else {
          _error = response.error;
        }
      });
    }
  }

  Future<void> _showPasswordDialog(String ssid) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isConnecting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ağa Bağlan: $ssid',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi Şifresi',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifre girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isConnecting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() => isConnecting = true);

                          final response = await _networkService.connectToWifi(
                            ssid,
                            passwordController.text,
                          );

                          if (!mounted) return;

                          setState(() => isConnecting = false);

                          if (response.success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bağlantı başarılı. Lütfen kendi WiFi ağınıza bağlanıp Cihazlarım sayfasına gidiniz.',
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(response.error ?? 'Bağlantı hatası'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: isConnecting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Bağla ve İmzala'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ağdaki cihazlar taranıyor...'),
          ],
        ),
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
              onPressed: _scanNetworks,
              child: const Text('Yeniden Tara'),
            ),
          ],
        ),
      );
    }

    if (_networks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Kullanılabilir ağ bulunamadı'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanNetworks,
              child: const Text('Yeniden Tara'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _scanNetworks,
      child: ListView.builder(
        itemCount: _networks.length,
        itemBuilder: (context, index) {
          final network = _networks[index];
          return ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(network),
            onTap: () => _showPasswordDialog(network),
          );
        },
      ),
    );
  }
}