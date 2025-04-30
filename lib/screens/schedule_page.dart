import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/constants/api_constants.dart';
import '../core/services/auth_service.dart';
import '../models/device_model.dart';

enum ScheduleTab { OneTime, Recurring }

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScheduleTab currentTab = ScheduleTab.OneTime;

  // Tüm cihazları tutan liste (Plugs/all-devices çağrısı ile)
  List<Device> _devices = [];
  // Seçili cihazın ID'si (Schedule API çağrısı için kullanıyoruz)
  String selectedDevice = "";

  // Tek seferlik schedule için state
  bool oneTimeStatus = true; // true = Açık, false = Kapalı
  DateTime? oneTimeDateTime;
  List<Map<String, dynamic>> oneTimeSchedules = [];

  // Tekrarlayan schedule için state
  String? selectedDay; // Örneğin "Pzt", "Sal", vb.
  TimeOfDay? recurringStartTime;
  TimeOfDay? recurringEndTime;
  List<Map<String, dynamic>> recurringSchedules = [];

  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        currentTab =
            _tabController.index == 0 ? ScheduleTab.OneTime : ScheduleTab.Recurring;
      });
    });
    // Önce cihazları yükleyip, seçili cihazı belirleyelim, sonra bu cihaza ait schedule'leri getirelim.
    loadDevices().then((_) {
      if (selectedDevice.isNotEmpty) {
        loadSchedules();
      }
    });
  }

  // Tüm cihazları API'den yükler (Plugs/all-devices endpoint)
  Future<void> loadDevices() async {
    final token = await AuthService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.allDevices}');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      setState(() {
        _devices = data.map((json) => Device.fromJson(json)).toList();
        if (_devices.isNotEmpty) {
          // Varsayılan olarak ilk cihazı seçiyoruz.
          selectedDevice = _devices[0].id;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cihazlar yüklenemedi.")),
      );
    }
  }

  // Seçili cihaza ait schedule'leri API'den getirir
  Future<void> loadSchedules() async {
    final token = await AuthService.getToken();
    // Örneğin, API endpoint'iniz: /schedules/device/{deviceId}
    final url =
        Uri.parse('${ApiConstants.baseUrl}/schedules/device/$selectedDevice');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> schedules = jsonResponse['data'];
      List<Map<String, dynamic>> oneTimeList = [];
      List<Map<String, dynamic>> recurringList = [];
      for (var item in schedules) {
        if (item['type'] == 0) {
          oneTimeList.add(item);
        } else if (item['type'] == 1) {
          recurringList.add(item);
        }
      }
      setState(() {
        oneTimeSchedules = oneTimeList;
        recurringSchedules = recurringList;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schedule'ler yüklenemedi.")),
      );
    }
  }

  // --- Tek Seferlik İşlemler ---
  Future<void> pickOneTimeDateTime() async {

    final date = await showDatePicker(
      context: context,
      initialDate: oneTimeDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(oneTimeDateTime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      oneTimeDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> submitOneTimeSchedule() async {
    if (oneTimeDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tarih ve saat seçiniz.")),
      );
      return;
    }
    final token = await AuthService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.schedule}');
    print("MErhaba");

    // Yerel zamanı UTC'ye dönüştürüyoruz
    final body = jsonEncode({
      "deviceId": selectedDevice,
      "type": 0, // OneTime
      "scheduledTime": oneTimeDateTime!.toUtc().toIso8601String(),
      "desiredStatus": oneTimeStatus,
    });
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tek seferlik zaman ayarı kaydedildi.")),
      );
      // Yeni kayıt sonrası tüm schedule'leri tekrar çekiyoruz.
      await loadSchedules();
      setState(() {
        oneTimeDateTime = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tek seferlik zaman ayarı kaydedilemedi.")),
      );
    }
  }

  // --- Tekrarlayan İşlemler ---
  Future<void> pickRecurringStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: recurringStartTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        recurringStartTime = time;
      });
    }
  }

  Future<void> pickRecurringEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: recurringEndTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        recurringEndTime = time;
      });
    }
  }

  /// TimeOfDay'ı "HH:mm:ss" formatında stringe çevirir.
  String timeOfDayToTimeSpanString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00";
  }

String timeOfDayToUtcTimeSpanString(TimeOfDay time) {
  // UTC+3 olduğunu varsay (manuel)
  final localTime = DateTime(0, 1, 1, time.hour, time.minute); // tarih önemsiz
  final utcTime = localTime.subtract(Duration(hours: 3)); // UTC = UTC+3 - 3

  final hour = utcTime.hour.toString().padLeft(2, '0');
  final minute = utcTime.minute.toString().padLeft(2, '0');
  final second = utcTime.second.toString().padLeft(2, '0');

  return "$hour:$minute:$second";
}
  Future<void> submitRecurringSchedule() async {
    if (selectedDay == null ||
        recurringStartTime == null ||
        recurringEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }
    Map<String, int> dayMap = {
      "Pzt": 1,
      "Sal": 2,
      "Çar": 3,
      "Per": 4,
      "Cum": 5,
      "Cmt": 6,
      "Paz": 0,
    };
    final token = await AuthService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.schedule}');
    print("SELECTED DEVICE : $selectedDevice");
    print("SELECTED DAY : $selectedDay");
    print("RECURRING START TIME : ${recurringStartTime}");
    print("RECURRING END TIME : ${recurringEndTime}");
    print("DAY MAP : ${dayMap[selectedDay]}");
    print("TIME OF DAY TO TIME SPAN STRING : ${timeOfDayToUtcTimeSpanString(recurringStartTime!)}");
    print("TIME OF DAY TO TIME SPAN STRING : ${timeOfDayToUtcTimeSpanString(recurringEndTime!)}");

    final body = jsonEncode({
      "deviceId": selectedDevice,
      "type": 1, // Recurring
      "recurringDay": dayMap[selectedDay],
      "startTimeOfDay": timeOfDayToUtcTimeSpanString(recurringStartTime!),
      "endTimeOfDay": timeOfDayToUtcTimeSpanString(recurringEndTime!),
    });
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tekrarlayan zaman ayarı kaydedildi.")),
      );
      await loadSchedules();
      setState(() {
        selectedDay = null;
        recurringStartTime = null;
        recurringEndTime = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tekrarlayan zaman ayarı kaydedilemedi.")),
      );
    }
  }

  // --- UI Widget'ları ---
  Widget buildOneTimeForm() {
    // Listenin ters sıralı hali: Yeni eklenen en üstte görünsün.
    final reversedOneTimeSchedules = oneTimeSchedules.reversed.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tek Seferlik Zaman Ayarı",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Cihaz Seçimi",
              border: OutlineInputBorder(),
            ),
            value: selectedDevice.isNotEmpty ? selectedDevice : null,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedDevice = value;
                  loadSchedules();
                });
              }
            },
            items: _devices.map((device) {
              return DropdownMenuItem(
                value: device.id,
                child: Text(device.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Durum:"),
              Switch(
                value: oneTimeStatus,
                onChanged: (value) {
                  setState(() {
                    oneTimeStatus = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              Text(oneTimeStatus ? "Açık" : "Kapalı"),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            tileColor: Colors.grey.shade200,
            title: Text(oneTimeDateTime == null
                ? "Tarih ve Saat Seçin"
                : dateFormat.format(oneTimeDateTime!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: pickOneTimeDateTime,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: submitOneTimeSchedule,
              icon: const Icon(Icons.save),
              label: const Text("Kaydet"),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text("Kaydedilen Tek Seferlik Ayarlar",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversedOneTimeSchedules.length,
            itemBuilder: (context, index) {
              final schedule = reversedOneTimeSchedules[index];
              // API'de cihaz bilgisi gelmediğinden, seçili cihaz üzerinden cihaz adını alıyoruz.
              final deviceName = _devices.firstWhere(
                (d) => d.id == selectedDevice,
                orElse: () => Device(
                  id: selectedDevice,
                  name: selectedDevice,
                  localIP: '',
                  mac: '',
                  isWorking: false,
                  isOnline: false,
                ),
              ).name;
              final status =
                  schedule['desiredStatus'] == true ? "Açık" : "Kapalı";
              final scheduledTime = schedule['scheduledTime'] != null
                  ? DateTime.parse(schedule['scheduledTime']).toLocal()
                  : null;
              final operationLabel =
                  schedule['executed'] == true ? "Gerçekleşti" : "Planlandı";
              return Card(
                child: ListTile(
                  title: Text("Cihaz $deviceName - $status"),
                  subtitle: Text(
                    "İşlem Zamanı: ${scheduledTime != null ? dateFormat.format(scheduledTime) : '-'} ($operationLabel)",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildRecurringForm() {
    final reversedRecurringSchedules = recurringSchedules.reversed.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tekrarlayan Zaman Ayarı",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Cihaz Seçimi",
              border: OutlineInputBorder(),
            ),
            value: selectedDevice.isNotEmpty ? selectedDevice : null,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedDevice = value;
                  loadSchedules();
                });
              }
            },
            items: _devices.map((device) {
              return DropdownMenuItem(
                value: device.id,
                child: Text(device.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Haftanın Günü",
              border: OutlineInputBorder(),
            ),
            value: selectedDay,
            onChanged: (value) {
              setState(() {
                selectedDay = value;
              });
            },
            items: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                .map((day) => DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            tileColor: Colors.grey.shade200,
            title: Text(recurringStartTime == null
                ? "Başlangıç Saati Seçin"
                : recurringStartTime!.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: pickRecurringStartTime,
          ),
          const SizedBox(height: 16),
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            tileColor: Colors.grey.shade200,
            title: Text(recurringEndTime == null
                ? "Bitiş Saati Seçin"
                : recurringEndTime!.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: pickRecurringEndTime,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: submitRecurringSchedule,
              icon: const Icon(Icons.save),
              label: const Text("Kaydet"),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text("Kaydedilen Tekrarlayan Ayarlar",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: reversedRecurringSchedules.length,
  itemBuilder: (context, index) {
    final schedule = reversedRecurringSchedules[index];
    final deviceName = _devices.firstWhere(
      (d) => d.id == selectedDevice,
      orElse: () => Device(
        id: selectedDevice,
        name: selectedDevice,
        localIP: '',
        mac: '',
        isWorking: false,
        isOnline: false,
      ),
    ).name;
    // Schedule kaydından gelen recurringDay sayısal değeri, gün ismine dönüştürüyoruz.
    final int? dayNumber = schedule['recurringDay'];
    final Map<int, String> dayNames = {
      0: "Pazar",
      1: "Pazartesi",
      2: "Salı",
      3: "Çarşamba",
      4: "Perşembe",
      5: "Cuma",
      6: "Cumartesi",
    };
    final dayName = dayNumber != null ? dayNames[dayNumber] ?? "-" : "-";
    
    final startTime = schedule['startTimeOfDay'] ?? "-";
    final endTime = schedule['endTimeOfDay'] ?? "-";

    // startTime ve endTime'ı UTC-3'e çevirmek
    final startDateTime = parseTime(startTime)?.subtract(Duration(hours: -3));
    final endDateTime = parseTime(endTime)?.subtract(Duration(hours: -3));
    return Card(
      child: ListTile(
        title: Text("Cihaz $deviceName - Gün: $dayName"),
        subtitle: Text("Başlangıç: ${formatTimeOnly(startDateTime)}\nBitiş: ${formatTimeOnly(endDateTime)}"),
      ),
    );
  },
)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zaman Ayarları"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tek Seferlik"),
            Tab(text: "Tekrarlayan"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildOneTimeForm(),
          buildRecurringForm(),
        ],
      ),
    );
  }
}

DateTime? parseTime(String time) {
  try {
    final parts = time.split(':');
    if (parts.length == 3) {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final second = int.parse(parts[2]);
      return DateTime(0, 1, 1, hour, minute, second); // Tarih önemsiz
    }
  } catch (e) {
    print("parseTime error: $e");
  }
  return null;
}

String formatTimeOnly(DateTime? dateTime) {
  if (dateTime == null) return "-";
  
  // Saat ve dakikayı formatla (hh:mm)
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  
  return "$hour:$minute";
}