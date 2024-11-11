import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android;
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart' as ios;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/screens/intro_user_screen.dart';
import 'package:wedweb/screens/master_data/md_guest_screen_user.dart';
import 'package:wedweb/screens/master_data/md_guest_screen_user_envelope.dart';
import 'package:wedweb/screens/scan_qr_screen.dart';
import 'package:wedweb/services/abjad_event.dart';
import 'package:wedweb/services/printer_service_ios.dart';
import 'package:wedweb/services/settings_page.dart';
import 'package:wedweb/widgets/custom_action_button.dart';
import '../screens/event_screen_user.dart';
import '../services/api_service.dart';
import '../services/data_service.dart';
import '../services/dropdown_provider.dart';
import '../screens/role_selection_screen.dart';
import '../screens/statistic/user_stat_screen_user.dart';
import '../screens/user_auth/user_login_screen.dart';
import '../services/printer_service_android.dart';
import '../widgets/styles.dart';
import '../widgets/custom_app_bar.dart';
import '../services/database_helper.dart';
import '../services/sync_provider.dart';

class BottomNavigationPageUser extends StatefulWidget {
  final String idServer;
  final String role;
  final String clientId;
  final String clientName;
  final Event event;
  final Session session;
  final String name;

  BottomNavigationPageUser({
    required this.name,
    required this.idServer,
    required this.role,
    required this.clientId,
    required this.clientName,
    required this.event,
    required this.session,
  });

  @override
  _BottomNavigationPageUserState createState() =>
      _BottomNavigationPageUserState();
}

class _BottomNavigationPageUserState extends State<BottomNavigationPageUser>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  bool _isFullscreen = false;
  bool isLoading = false;
  List<dynamic> devices = [];
  dynamic selectedDevice;
  late final List<Widget> _pages;
  EventBus eventBus = EventBus();

  late final String apiUrl;
  String _selectedAbjad = 'A';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    eventBus.on<AbjadEvent>().listen((event) {
      setState(() {
        _selectedAbjad = event.newAbjad; // Memperbarui state
      });
    });
    _pages = [
      UserStatScreenUser(
        idServer: widget.idServer,
        isFullscreen: _isFullscreen,
        onToggleFullscreen: _toggleFullscreen,
        session: widget.session,
        event: widget.event,
        name: widget.name,
        counterLabel: _selectedAbjad,
        clientId: widget.clientId,
        role: widget.role,
        clientName: widget.clientName,
      ),
      MDGuestScreenUser(
        idServer: widget.idServer,
        name: widget.name,
        eventId: widget.event.event_id!,
        clientId: widget.clientId,
        eventName: widget.event.event_name,
        sessionId: widget.session.session_id!,
        role: widget.role,
        event: widget.event,
        clientName: widget.clientName,
        counterLabel: _selectedAbjad,
        session: widget.session,
      ),
      MdGuestScreenUserEnvelope(
          eventId: widget.event.event_id!,
          idServer: widget.idServer,
          name: widget.name,
          clientId: widget.clientId,
          sessionId: widget.session.session_id!,
          event: widget.event,
          session: widget.session,
          role: widget.role,
          clientName: widget.clientName,
          counterLabel: _selectedAbjad,
          eventName: widget.event.event_name),
      SettingsPage(
        idServer: widget.idServer,
        name: widget.name,
        clientId: widget.clientId,
        role: widget.role,
        event: widget.event,
        clientName: widget.clientName,
        session: widget.session,
      ),
    ];
    _initialize();
    _syncProvider();
    _keyAngpau();
    _loadAbjadSetting();
    _savePage();
  }

  Future<void> _loadAbjadSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAbjad = prefs.getString('angpau_abjad') ?? 'A';
    });
  }

  Future<void> _keyAngpau() async {
    final dbHelper = DatabaseHelper.instance;

    // Lakukan pengecekan terlebih dahulu
    final existingData = await dbHelper.getKeys(widget.session.session_id!);

    // Jika data belum ada, maka lakukan insert
    if (existingData.isEmpty) {
      for (var i = 0; i < 26; i++) {
        String abjad = String.fromCharCode(65 + i); // ASCII 'A' = 65
        await dbHelper.insertKeyAngpau(abjad, widget.session.session_id!);
      }
    } else {
      print("Data sudah ada, tidak perlu menambahkan lagi.");
    }
  }

  Future<void> _initialize() async {
    try {
      apiUrl = await ApiService.pathApi();
    } catch (e) {
      print('Error initializing API URL: $e');
    }
  }

  void _savePage() {
    DatabaseHelper.instance.insertPageData(widget.role, widget.clientId,
        widget.idServer, widget.clientName, widget.event, widget.session);
  }

  void _syncProvider() async {
    final dbHelper = DatabaseHelper();
    String? idServer = await dbHelper.getIdServer();
    if (idServer != null) {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      syncProvider
          .updateIdServer(idServer); // Perbarui idServer dan mulai sinkronisasi
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Widget _buildPageContent(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildBottomNavigationItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      splashColor: AppColors.gradientEndColor,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 4.0), // Kurangi padding vertikal
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 25,
              color: isSelected
                  ? AppColors.selectedItemColor
                  : AppColors.unselectedItemColor,
            ),
            SizedBox(height: 2), // Kurangi jarak antara Icon dan Text
            Text(
              label,
              style: AppStyles.bottomNavTextStyle.copyWith(
                color: isSelected
                    ? AppColors.selectedItemColor
                    : AppColors.unselectedItemColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> printTest() async {
    print('Attempting to print test...');
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as Printer1Service;
      await printerService.printTest(context);
      print('Test print executed for Android');
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<PrinterServiceIOS>(context, listen: false);
      await printerService.printTest(context);
      print('Test print executed for iOS');
    }
  }

  void _showDeviceSelectionSheet() {
    print('Showing device selection sheet...');
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Printer',
                style: AppStyles.titleTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.appBarColor, // Sesuaikan warna teks
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: devices
                      .map((device) => ListTile(
                            title: Text(device.name ?? 'Unknown Device',
                                style: AppStyles.captionTextStyle),
                            onTap: () {
                              print('Device selected: ${device.name}');
                              setState(() {
                                selectedDevice = device;
                                if (Platform.isIOS) {
                                  final printerService =
                                      Provider.of<PrinterServiceIOS>(context,
                                          listen: false);
                                  printerService.selectDevice(device);
                                  printerService.connectToPrinter(device);
                                }
                              });
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  print('Search for Bluetooth devices');
                  setState(() {
                    getDevices();
                  });
                },
                child: Text(
                  'Search Devices',
                  selectionColor: AppColors.iconColor,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBarColor,
                  foregroundColor: AppColors.iconColor,
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void getDevices() async {
    print('Fetching devices...');
    setState(() {
      isLoading = true;
    });

    // Fetch devices based on platform
    // Android
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false);
      List<android.BluetoothDevice> devicesAndroid = [];
      await printerService.getDevices(devicesAndroid);
      setState(() {
        devices = devicesAndroid; // Update devices here
      });
      print('Devices fetched: $devicesAndroid');
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<PrinterServiceIOS>(context, listen: false);
      await printerService.getDevices();
      setState(() {
        // Update `devices` with the latest list from printerService
        devices = printerService.devices; // Pastikan ada getter untuk _devices
      });
      print('Devices fetched');
    }

    setState(() {
      isLoading = false;
    });
    print('Finished fetching devices');
  }

  Future<void> connectToPrinter() async {
    print('Attempting to connect to printer...');
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as Printer1Service;
      if (printerService.isPrinterConnected) {
        print('Printer is already connected');
        _showNotification('Printer is already connected');
      } else {
        await printerService.connectToPrinter(selectedDevice);
        if (printerService.isPrinterConnected) {
          print('Printer successfully connected');
          _showNotification('Printer successfully connected');
        } else {
          print('Failed to connect to printer');
          _showNotification('Failed to connect to printer');
        }
      }
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as PrinterServiceIOS;
      if (printerService.isPrinterConnected!) {
        print('Printer is already connected');
        _showNotification('Printer is already connected');
      } else {
        await printerService.connectToPrinter(selectedDevice);
        if (printerService.isPrinterConnected!) {
          print('Printer successfully connected');
          _showNotification('Printer successfully connected');
        } else {
          print('Failed to connect to printer');
          _showNotification('Failed to connect to printer');
        }
      }
    }
  }

  void _showPrinterOptionsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Printer Options'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : _showDeviceSelectionSheet,
                  child: Text('Select Printer'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.buttonColor,
                    backgroundColor: AppColors.appBarColor,
                  ),
                ),
                SizedBox(height: 16),

                // Tombol untuk Connect, Disconnect, dan Print Test
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (Platform.isAndroid) ...[
                      // Tombol Connect Printer, hanya tampil di Android
                      CustomActionButton(
                        icon: Icons.bluetooth,
                        backgroundColor: AppColors.appBarColor,
                        iconColor: AppColors.iconColorEdit,
                        onPressed: isLoading
                            ? null
                            : () async {
                                await connectToPrinter();
                                final printerService =
                                    Provider.of<Printer1Service>(
                                  context,
                                  listen: false,
                                );
                                if (printerService.isPrinterConnected) {
                                  Navigator.of(context).pop();
                                }
                              },
                        tooltip: 'Connect Printer',
                        label: 'Connect',
                        labelTextStyle: AppStyles.captionTextStyle,
                      ),
                      // Tombol Disconnect Printer, hanya tampil di Android
                      CustomActionButton(
                        backgroundColor: AppColors.appBarColor,
                        icon: Icons.bluetooth_disabled,
                        iconColor: AppColors.iconColorWarning,
                        onPressed: () {
                          disconnectPrinter();
                        },
                        tooltip: 'Disconnect Printer',
                        label: 'Disconnect',
                        labelTextStyle: AppStyles.captionTextStyle,
                      ),
                    ],
                    // Tombol Feed Test, tampil di Android dan iOS
                    CustomActionButton(
                      backgroundColor: AppColors.appBarColor,
                      icon: Icons.print,
                      iconColor: AppColors.iconColor,
                      onPressed: printTest,
                      tooltip: 'Print Test',
                      label: 'Feed Test',
                      labelTextStyle: AppStyles.captionTextStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNotification(String message) {
    print('Showing notification: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> disconnectPrinter() async {
    print('Attempting to disconnect from printer...');
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as Printer1Service;
      if (printerService.isPrinterConnected) {
        await printerService.disconnectPrinter();
        print('Printer successfully disconnected');
        _showNotification('Printer successfully disconnected');
      } else {
        print('Printer is already disconnected');
        _showNotification('Printer is already disconnected');
      }
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as PrinterServiceIOS;
      if (printerService.isPrinterConnected!) {
        // await printerService.disconnectPrinter();
        print('Printer successfully disconnected');
        _showNotification('Printer successfully disconnected');
      } else {
        print('Printer is already disconnected');
        _showNotification('Printer is already disconnected');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        _showSelectClientConfirmationDialog(context);
        return false; // Mengembalikan false agar aplikasi tidak langsung menutup
      },
      child: Scaffold(
        appBar: _isFullscreen
            ? null
            : CustomAppBar(
                title: 'Usher ${widget.name} ( ${_selectedAbjad} )',
                actions: [
                    Builder(
                      builder: (context) {
                        // Check if the platform is Android or iOS and choose the appropriate consumer
                        if (Platform.isAndroid) {
                          return Consumer<Printer1Service>(
                            builder: (context, printerService, child) =>
                                IconButton(
                              icon: Icon(
                                Icons.print,
                                color: printerService.isPrinterConnected
                                    ? Colors.red
                                    : const Color.fromARGB(255, 132, 255, 136),
                              ),
                              onPressed: () async {
                                if (printerService.isPrinterConnected) {
                                  printTest();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Printer Status'),
                                      content: Text('Printer is connected.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    getDevices();
                                  });
                                  _showPrinterOptionsModal(
                                      context); // Show printer options modal
                                }
                              },
                            ),
                          );
                        } else if (Platform.isIOS) {
                          return Consumer<PrinterServiceIOS>(
                            builder: (context, printerServiceIOS, child) =>
                                IconButton(
                              icon: Icon(
                                Icons.print,
                                color: (printerServiceIOS.isPrinterConnected ??
                                        false) // Anggap false sebagai true, null sebagai false
                                    ? const Color.fromARGB(255, 132, 255, 136)
                                    : Colors.red,
                              ),
                              onPressed: () async {
                                // Menganggap false sebagai true dan null sebagai false
                                if ((printerServiceIOS.isPrinterConnected ??
                                        false) ==
                                    true) {
                                  _showPrinterOptionsModal(
                                      context);
                                  printerServiceIOS.checkPrinterConnection();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Printer Status'),
                                      content: Text('Printer is connected.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  print(
                                      'PROFILBLUETOOTHDEVICES: ${printerServiceIOS.isPrinterConnected}');
                                  _showPrinterOptionsModal(
                                      context); // Show printer options modal
                                }
                              },
                            ),
                          );
                        } else {
                          return Container(); // Return an empty container for unsupported platforms
                        }
                      },
                    ),
                  ]),
        drawer: Drawer(
          backgroundColor: AppColors.appBarColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.iconColor,
                ),
                child: Image.asset(
                  'assets/images/logo-white-horizontal.png',
                  height: 200,
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_2, color: Colors.white),
                title: Text(
                  'Select Client',
                  style: AppStyles.dialogContentTextStyle,
                ),
                onTap: () {
                  _showSelectClientConfirmationDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text('Logout', style: AppStyles.dialogContentTextStyle),
                onTap: () async {
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ),
        body: _pages[_selectedIndex],

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle:
                    0.785398, // Rotasi 45 derajat (π/4 radian) untuk membentuk belah ketupat
                child: Container(
                  width: 50, // Lebar FAB
                  height: 50, // Tinggi FAB
                  decoration: BoxDecoration(
                    color: AppColors.iconColor, // Sesuaikan warna tombol
                    shape: BoxShape.rectangle, // Bentuk persegi panjang
                    borderRadius:
                        BorderRadius.circular(8), // Menyesuaikan rounded corner
                    border: Border.all(
                      // Tambahkan border hitam
                      color: AppColors.appBarColor,
                      width: 1,
                    ),
                  ),
                  child: Transform.rotate(
                    angle: -0.785398, // Rotasi kembali icon ke posisi normal
                    child: FloatingActionButton(
                      heroTag: 'qris',
                      onPressed: () {
                        _navigateToScanQRScreen(
                            context, widget.clientId, widget.role);
                      },
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                      elevation: 0, // Hilangkan shadow tambahan
                      backgroundColor: Colors
                          .transparent, // Transparan agar container yang terlihat
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10), // Jarak antara FAB dan label teks
              Text(
                'Scan QR Code', // Label teks
                style: TextStyle(
                  color: Colors.white, // Warna teks
                  fontSize: 11, // Ukuran font
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // Menggunakan BottomAppBar dengan notch untuk FAB
        bottomNavigationBar: Visibility(
          visible: _isFullscreen != true,
          child: BottomAppBar(
            child: Container(
              color: AppColors.appBarColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavigationItem(
                      FontAwesomeIcons.chartPie, 'Statistic', 0),
                  _buildBottomNavigationItem(
                      FontAwesomeIcons.userCheck, 'Search', 1),
                  SizedBox(width: 48), // Memberi ruang untuk FAB di tengah
                  _buildBottomNavigationItem(
                      FontAwesomeIcons.solidEnvelopeOpen, 'Envelope', 2),
                  _buildBottomNavigationItem(
                      FontAwesomeIcons.gears, 'Settings', 3),
                ],
              ),
            ),
            color: AppColors.bottomAppBarColor,
          ),
        ),
      ),
    );
  }
void _navigateToScanQRScreen(BuildContext context, String clientId, String role) {
  print('Navigating to ScanQRScreen');
  print('idServer: ${widget.idServer}');
  print('name: ${widget.name}');
  print('clientId: $clientId');
  print('role: $role');
  print('clientName: ${widget.clientName}');
  print('counterLabel: $_selectedAbjad');
  print('event: ${widget.event}');
  print('session: ${widget.session}');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ScanQRScreen(
        idServer: widget.idServer,
        name: widget.name,
        clientId: clientId,
        role: role,
        clientName: widget.clientName,
        counterLabel: _selectedAbjad,
        event: widget.event,
        session: widget.session,
      ),
    ),
  );
}


  Future<bool> checkInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<bool> _checkServerReachability() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _syncData() async {
    final _dataService = DataService();
    List<Future<void>> syncTasks = [
      _dataService.checkAndSyncClients(widget.idServer),
      _dataService.checkAndSyncEvents(widget.idServer),
      _dataService.checkAndSyncEventsSessionsTables(widget.idServer),
      _dataService.checkAndSyncGuests(widget.idServer),
      _dataService.checkAndSyncUshers(widget.idServer),
    ];

    await Future.wait(syncTasks.take(3));
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Sync data. Please wait..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  void _logout(BuildContext context) async {
    try {
      bool isInternetConnected = await checkInternetConnection();
      if (!isInternetConnected) {
        _showLogoutErrorNotification(
            context, 'No internet connection. Please check your internet!.');
        return; // Keluar dari fungsi logout
      }

      // Periksa kesehatan server
      bool isServerReachable = await _checkServerReachability();
      if (!isServerReachable) {
        _showLogoutErrorNotification(
            context, 'Server is bussy. Logout aborted.');
        return; // Keluar dari fungsi logout
      }

      // Pastikan provider masih ada
      if (!mounted) return;
      showLoadingDialog(context);
      await _syncData();

      final dropdownProvider =
          Provider.of<DropdownProvider>(context, listen: false);
      dropdownProvider.stopStatisticsUpdater();

      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      syncProvider.stopSyncing(); // Hentikan sinkronisasi

      final dbHelper = DatabaseHelper();
      await dbHelper.clearAllData();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      hideLoadingDialog(context);

      // Navigasi ke UserLoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => UserLoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void _showLogoutErrorNotification(BuildContext context, String message) {
    if (context.mounted) {
      final snackBar = SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to log out?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _logout(context); // Panggil fungsi logout jika dikonfirmasi
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _showSelectClientConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to Select Client?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Not sure"),
            ),
            TextButton(
              onPressed: () {
                _client(context); // Panggil fungsi logout jika dikonfirmasi
              },
              child: Text("Sure"),
            ),
          ],
        );
      },
    );
  }

  void _client(BuildContext context) async {
    try {
      // Navigasi ke UserLoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => IntroUserScreen(
            idServer: widget.idServer,
            role: widget.role,
            name: widget.name,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
