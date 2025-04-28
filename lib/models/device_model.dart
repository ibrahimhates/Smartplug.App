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
  // İlgili Device sınıfına copyWith metodunu ekleyin
  Device copyWith({
    String? id,
    String? name,
    bool? isWorking,
    bool? isOnline,
    String? localIP,
    String? mac,
    String? serialNumber,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      isWorking: isWorking ?? this.isWorking,
      isOnline: isOnline ?? this.isOnline,
      localIP: localIP ?? this.localIP,
      mac: mac ?? this.mac,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }
}
