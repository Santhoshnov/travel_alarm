import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const TravelAlarmApp());
}

class TravelAlarmApp extends StatelessWidget {
  const TravelAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Alarm',
      home: const TravelAlarmHome(),
    );
  }
}

class TravelAlarmHome extends StatefulWidget {
  const TravelAlarmHome({super.key});

  @override
  State<TravelAlarmHome> createState() => _TravelAlarmHomeState();
}

class _TravelAlarmHomeState extends State<TravelAlarmHome> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  bool isMonitoring = false;
  double? destLat, destLng;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    flutterLocalNotificationsPlugin!.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _startMonitoring() async {
    // Request location permission
    var status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')));
      return;
    }

    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter destination coordinates')));
      return;
    }

    destLat = double.tryParse(_latController.text);
    destLng = double.tryParse(_lngController.text);
    if (destLat == null || destLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coordinates')));
      return;
    }

    setState(() {
      isMonitoring = true;
    });

    // Start checking location every 10 seconds
    while (isMonitoring) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double distanceInMeters = Geolocator.distanceBetween(
          position.latitude, position.longitude, destLat!, destLng!);

      if (distanceInMeters < 1000) {
        _showNotification();
        setState(() {
          isMonitoring = false;
        });
        break;
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  void _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'travel_alarm_channel',
      'Travel Alarm',
      channelDescription: 'Notifies when near destination',
      importance: Importance.max,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    final generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin!.show(
      0,
      'Travel Alarm',
      'You are near your destination!',
      generalNotificationDetails,
    );
  }

  void _stopMonitoring() {
    setState(() {
      isMonitoring = false;
    });
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Alarm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Destination Latitude',
              ),
            ),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Destination Longitude',
              ),
            ),
            const SizedBox(height: 20),
            isMonitoring
                ? ElevatedButton(
                    onPressed: _stopMonitoring, child: const Text('Stop Alarm'))
                : ElevatedButton(
                    onPressed: _startMonitoring,
                    child: const Text('Start Alarm'),
                  ),
          ],
        ),
      ),
    );
  }
}
