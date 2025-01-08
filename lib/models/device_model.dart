class Device {
  final String id;
  final String name;
  final String? serialNumber;
  final String localIP;
  final String mac;
  final bool isWorking;
  final bool isOnline;

  Device({
    required this.id,
    required this.name,
    this.serialNumber,
    required this.localIP,
    required this.mac,
    required this.isWorking,
    required this.isOnline,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      serialNumber: json['serialNumber'],
      localIP: json['localIP'],
      mac: json['mac'],
      isWorking: json['isWorking'],
      isOnline: json['isOnline'],
    );
  }
}
