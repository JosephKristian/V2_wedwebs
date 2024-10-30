import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'screens/loading_first_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'services/database_helper.dart';
import 'services/printer_service_android.dart';
import 'services/printer_service_ios.dart';
import 'services/dropdown_provider.dart';
import 'services/dropdown_provider_user.dart';
import 'services/sync_provider.dart';

void main() async {
  // Inisialisasi binding Flutter terlebih dahulu
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Setup logger
  _setupLogging();

  // Initialize DatabaseHelper
  await _initializeDatabase();

  // Konfigurasikan EasyLoading
  configLoading();

  // Minta perizinan
  await _requestPermissions(); // Tambahkan permintaan izin

  String? idServer = '';

  if (idServer == null) {
    // Handle kasus di mana idServer tidak ditemukan
    // Misalnya, Anda dapat menggunakan nilai default atau menginformasikan pengguna
    print(
        'ID Server tidak ditemukan, menggunakan default atau melakukan penanganan.');
    idServer = 'default_server_id'; // Ganti dengan ID default jika diperlukan
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Printer1Service()),
        ChangeNotifierProvider(create: (context) => PrinterServiceIOS()),
        ChangeNotifierProvider(create: (_) => DropdownProvider()),
        ChangeNotifierProvider(create: (_) => DropdownProviderUser()),
        ChangeNotifierProvider(create: (context) => SyncProvider()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  final log = Logger('_requestPermissions');

  try {
    var permissions = [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ];

    var statuses = await permissions.request();

    statuses.forEach((permission, status) {
      log.info('Permission for $permission: $status');
    });
  } catch (e) {
    log.severe('Error requesting permissions: $e');
  }
}

void _setupLogging() {
  Logger.root.level = Level.ALL; // Log semua level
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

Future<void> _initializeDatabase() async {
  final log = Logger('_initializeDatabase');

  try {
    // Panggil method untuk inisialisasi database
    await DatabaseHelper.instance
        .database; // Memanggil getter instance untuk mendapatkan DatabaseHelper singleton

    log.info('Database berhasil diinisialisasi');
  } catch (e) {
    log.severe('Terjadi kesalahan saat inisialisasi database: $e');
    // Handle error
  }
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final log = Logger('MyApp');
    log.info('MyApp widget dibangun');
    return MaterialApp(
      title: 'Digital Guestbook',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: EasyLoading.init(), // Inisialisasi EasyLoading
      initialRoute: '/login', // Rute awal diatur ke halaman login
      routes: {
        '/login': (context) =>
            LoadingFirstScreen(), // Rute untuk halaman registrasi
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Error')),
            body: Center(
              child: Text('Halaman tidak ditemukan'),
            ),
          ),
        );
      },
    );
  }
}
