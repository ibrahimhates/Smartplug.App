class Device {
  final String id;
  final String name;
  final bool isOnline;
  final String ipAddress;

  Device({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.ipAddress,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      isOnline: json['isOnline'],
      ipAddress: json['ipAddress'],
    );
  }
}
