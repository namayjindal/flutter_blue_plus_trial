import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  requestBluetoothPermissions();
  runApp(MyApp());
}

Future<void> requestBluetoothPermissions() async {
  if (await Permission.bluetooth.request().isGranted) {
    // Bluetooth permission is granted
    print('Bluetooth permission granted');
  } else {
    // Bluetooth permission is not granted
    print('Bluetooth permission not granted');
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ignore: deprecated_member_use
  FlutterBluePlus flutterBlue = FlutterBluePlus();

  List<BluetoothDevice> devices = [];
  List<BluetoothCharacteristic> characteristics = [];

  @override
  void initState() {
    super.initState();
    connectToDevices();
  }

  void connectToDevices() async {
    devices = await FlutterBluePlus.connectedDevices;
    for (BluetoothDevice device in devices) {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            characteristics.add(characteristic);
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              print('Received data: $value');
              logDataToCSV(value);
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('BLE Sensor Logger'),
        ),
        body: Center(
          child: Text('Connecting to devices...'),
        ),
      ),
    );
  }
}

Future<void> logDataToCSV(List<int> data) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final fileName = 'sensor_data.csv';
  final file = File('$path/$fileName');

  final csvData = [data.map((value) => value.toString()).toList()];
  final csv = const ListToCsvConverter().convert(csvData);

  await file.writeAsString(csv, mode: FileMode.append);
}