// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android;
// import 'package:wedweb/screens/intro_user_screen.dart';
// import 'package:wedweb/screens/master_data/md_guest_screen_user.dart';
// import '../services/api_service.dart';
// import 'statistic/user_stat_screen_user.dart';
// import 'dart:io' show Platform;
// import '../screens/dashboard_user_screen.dart';

// import '../screens/user_auth/user_login_screen.dart';
// import '../models/event_model.dart';
// import '../screens/scan_qr_screen.dart';
// import '../screens/role_selection_screen.dart';
// import '../services/data_service.dart';
// import '../services/dropdown_provider.dart';
// import '../services/printer_service_android.dart';
// import '../services/printer_service_ios.dart';
// import '../services/database_helper.dart';
// import '../services/sync_provider.dart';
// import '../widgets/custom_app_bar.dart';
// import '../widgets/custom_action_button.dart';
// import '../widgets/styles.dart';
// import '../models/session_model.dart';

// class DashboardFUserScreen extends StatefulWidget {
//   final String role;
//   final String clientId;
//   final String idServer;
//   final String clientName;
//   final String name;
//   final Event event;
//   final Session session;

//   DashboardFUserScreen({
//     required this.role,
//     required this.clientId,
//     required this.idServer,
//     required this.clientName,
//     required this.event,
//     required this.session,
//     required this.name,
//   });

//   @override
//   _DashboardFUserScreenState createState() => _DashboardFUserScreenState();
// }

// class _DashboardFUserScreenState extends State<DashboardFUserScreen> {
//   List<dynamic> devices = [];
//   dynamic selectedDevice;
//   bool isLoading = false;
//   bool _isFullscreen = false;
//   late final String apiUrl;

//   @override
//   void initState() {
//     super.initState();
//     print('Initializing DashboardFUserScreen...');
//     getDevices();
//     checkPrinterConnection();
//     _savePage();
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     try {
//       apiUrl = await ApiService.pathApi();
//     } catch (e) {
//       print('Error initializing API URL: $e');
//     }
//   }

//   void _savePage() {
//     DatabaseHelper.instance.insertPageData(widget.role, widget.clientId,
//         widget.idServer, widget.clientName, widget.event, widget.session);
//   }

//   void getDevices() async {
//     print('Fetching devices...');
//     setState(() {
//       isLoading = true;
//     });

//     // Fetch devices based on platform
//     // Android
//     if (Platform.isAndroid) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false);
//       List<android.BluetoothDevice> devicesAndroid = [];
//       await printerService.getDevices(devicesAndroid);
//       setState(() {
//         devices = devicesAndroid; // Update devices here
//       });
//       print('Devices fetched: $devicesAndroid');
//     } else if (Platform.isIOS) {
//       // final printerService =
//       //     Provider.of<PrinterServiceIOS>(context, listen: false);
//       // List<ios.BluetoothDevice> devicesIOS = await printerService.getDevices();
//       // setState(() {
//       //   devices = devicesIOS; // Update devices here
//       // });
//       // print('Devices fetched');
//     }

//     setState(() {
//       isLoading = false;
//     });
//     print('Finished fetching devices');
//   }

//   Future<void> checkPrinterConnection() async {
//     print('Checking printer connection...');
//     if (Platform.isAndroid) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as Printer1Service;
//       await printerService.checkPrinterConnection();
//       print('Checked printer connection for Android');
//     } else if (Platform.isIOS) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as PrinterServiceIOS;
//       await printerService.checkPrinterConnection();
//       print('Checked printer connection for iOS');
//     }
//   }

//   Future<void> connectToPrinter() async {
//     print('Attempting to connect to printer...');
//     if (Platform.isAndroid) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as Printer1Service;
//       if (printerService.isPrinterConnected) {
//         print('Printer is already connected');
//         _showNotification('Printer is already connected');
//       } else {
//         await printerService.connectToPrinter(selectedDevice);
//         if (printerService.isPrinterConnected) {
//           print('Printer successfully connected');
//           _showNotification('Printer successfully connected');
//         } else {
//           print('Failed to connect to printer');
//           _showNotification('Failed to connect to printer');
//         }
//       }
//     } else if (Platform.isIOS) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as PrinterServiceIOS;
//       if (printerService.isPrinterConnected!) {
//         print('Printer is already connected');
//         _showNotification('Printer is already connected');
//       } else {
//         await printerService.connectToPrinter(selectedDevice);
//         if (printerService.isPrinterConnected!) {
//           print('Printer successfully connected');
//           _showNotification('Printer successfully connected');
//         } else {
//           print('Failed to connect to printer');
//           _showNotification('Failed to connect to printer');
//         }
//       }
//     }
//   }

//   Future<void> disconnectPrinter() async {
//     print('Attempting to disconnect from printer...');
//     if (Platform.isAndroid) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as Printer1Service;
//       if (printerService.isPrinterConnected) {
//         await printerService.disconnectPrinter();
//         print('Printer successfully disconnected');
//         _showNotification('Printer successfully disconnected');
//       } else {
//         print('Printer is already disconnected');
//         _showNotification('Printer is already disconnected');
//       }
//     } else if (Platform.isIOS) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as PrinterServiceIOS;
//       if (printerService.isPrinterConnected!) {
//         await printerService.disconnectPrinter();
//         print('Printer successfully disconnected');
//         _showNotification('Printer successfully disconnected');
//       } else {
//         print('Printer is already disconnected');
//         _showNotification('Printer is already disconnected');
//       }
//     }
//   }

//   Future<void> printTest() async {
//     print('Attempting to print test...');
//     if (Platform.isAndroid) {
//       final printerService =
//           Provider.of<Printer1Service>(context, listen: false)
//               as Printer1Service;
//       await printerService.printTest(context);
//       print('Test print executed for Android');
//     } else if (Platform.isIOS) {
//       final printerService =
//           Provider.of<PrinterServiceIOS>(context, listen: false);
//       await printerService.printTest(context);
//       print('Test print executed for iOS');
//     }
//   }

//   void _showNotification(String message) {
//     print('Showing notification: $message');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   Future<bool> checkInternetConnection() async {
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     return connectivityResult != ConnectivityResult.none;
//   }

//   Future<bool> _checkServerReachability() async {
//     try {
//       final response = await http.get(Uri.parse('$apiUrl/health'));
//       return response.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<void> _syncData() async {
//     final _dataService = DataService();
//     List<Future<void>> syncTasks = [
//       _dataService.checkAndSyncClients(widget.idServer),
//       _dataService.checkAndSyncEvents(widget.idServer),
//       _dataService.checkAndSyncEventsSessionsTables(widget.idServer),
//       _dataService.checkAndSyncGuests(widget.idServer),
//       _dataService.checkAndSyncUshers(widget.idServer),
//     ];

//     await Future.wait(syncTasks.take(3));
//   }

//   void showLoadingDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 20),
//                 Text("Sync data. Please wait..."),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void hideLoadingDialog(BuildContext context) {
//     Navigator.pop(context);
//   }

//   void _logout(BuildContext context) async {
//     try {
//       bool isInternetConnected = await checkInternetConnection();
//       if (!isInternetConnected) {
//         _showLogoutErrorNotification(
//             context, 'No internet connection. Please check your internet!.');
//         return; // Keluar dari fungsi logout
//       }

//       // Periksa kesehatan server
//       bool isServerReachable = await _checkServerReachability();
//       if (!isServerReachable) {
//         _showLogoutErrorNotification(
//             context, 'Server is bussy. Logout aborted.');
//         return; // Keluar dari fungsi logout
//       }

//       // Pastikan provider masih ada
//       if (!mounted) return;
//       showLoadingDialog(context);
//       await _syncData();

//       final dropdownProvider =
//           Provider.of<DropdownProvider>(context, listen: false);
//       dropdownProvider.stopStatisticsUpdater();

//       final syncProvider = Provider.of<SyncProvider>(context, listen: false);
//       syncProvider.stopSyncing(); // Hentikan sinkronisasi

//       final dbHelper = DatabaseHelper();
//       await dbHelper.clearAllData();

//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.clear();

//       hideLoadingDialog(context);

//       // Navigasi ke UserLoginScreen
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (context) => UserLoginScreen(),
//         ),
//         (route) => false,
//       );
//     } catch (e) {
//       print('Error during logout: $e');
//     }
//   }

//   void _showLogoutErrorNotification(BuildContext context, String message) {
//     if (context.mounted) {
//       final snackBar = SnackBar(
//         content: Text(message),
//         duration: Duration(seconds: 3),
//       );
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     }
//   }

//   void _showLogoutConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Confirmation"),
//           content: Text("Are you sure you want to log out?"),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Tutup dialog
//               },
//               child: Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () {
//                 _logout(context); // Panggil fungsi logout jika dikonfirmasi
//               },
//               child: Text("Logout"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showSelectClientConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Confirmation"),
//           content: Text("Are you sure you want to Select Client?"),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Tutup dialog
//               },
//               child: Text("Not sure"),
//             ),
//             TextButton(
//               onPressed: () {
//                 _client(context); // Panggil fungsi logout jika dikonfirmasi
//               },
//               child: Text("Sure"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showHomeConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Confirmation"),
//           content: Text("Are you sure you want to Home?"),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Tutup dialog
//               },
//               child: Text("Not sure"),
//             ),
//             TextButton(
//               onPressed: () {
//                 _home(context); // Panggil fungsi logout jika dikonfirmasi
//               },
//               child: Text("Sure"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _client(BuildContext context) async {
//     try {
//       // Navigasi ke UserLoginScreen
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (context) => RoleSelectionScreen(
//             idServer: widget.idServer,
//             role: widget.role,
//             name: widget.name,
//           ),
//         ),
//         (route) => false,
//       );
//     } catch (e) {
//       print('Error during logout: $e');
//     }
//   }

//   void _toggleFullscreen() {
//     setState(() {
//       _isFullscreen = !_isFullscreen;
//       if (_isFullscreen) {
//         SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//       } else {
//         SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//       }
//     });
//   }

//   void _stats(BuildContext context) async {
//     try {
//       // Navigasi ke UserLoginScreen
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => UserStatScreenUser(
//             isFullscreen: false,
//             onToggleFullscreen: _toggleFullscreen,
//             idServer: widget.idServer,
//             session: widget.session,
//             event: widget.event,
//             name: widget.name,
//             clientId: widget.clientId,
//             role: widget.role,
//             clientName: widget.clientName,
//           ),
//         ),
//       );
//     } catch (e) {
//       print('Error during logout: $e');
//     }
//   }

//   void _home(BuildContext context) async {
//     try {
//       final dbHelper = DatabaseHelper();
//       await dbHelper.clearPagesTempo();
//       // Navigasi ke halaman Dashboard
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => IntroUserScreen(
//             idServer: widget.idServer,
//             role: widget.role,
//             name: widget.name,
//           ),
//         ),
//       );
//     } catch (e) {
//       print('Error during logout: $e');
//     }
//   }

//   void _guest(BuildContext context) async {
//     try {
//       // Navigasi ke halaman Dashboard
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MDGuestScreenUser(
//             idServer: widget.idServer,
//             name: widget.name,
//             eventId: widget.event.event_id!,
//             clientId: widget.clientId,
//             eventName: widget.event.event_name,
//             sessionId: widget.session.session_id!,
//             role: widget.role,
//             event: widget.event,
//             clientName: widget.clientName,
//             session: widget.session,
//           ),
//         ),
//       );
//     } catch (e) {
//       print('Error during logout: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final printerService = Provider.of<Printer1Service>(context);

//     return Scaffold(
//       appBar: CustomAppBar(
//         title: 'Client: ${widget.clientName}', // Menampilkan nama client
//         actions: [
//           Consumer<Printer1Service>(
//             builder: (context, printerService, child) => IconButton(
//               icon: Icon(
//                 Icons.print,
//                 color: printerService.isPrinterConnected
//                     ? Colors.green
//                     : Colors.red,
//               ),
//               onPressed: () async {
//                 if (printerService.isPrinterConnected) {
//                   printTest();
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: Text('Printer Status'),
//                       content: Text('Printer is connected.'),
//                       actions: [
//                         TextButton(
//                           onPressed: () {
//                             Navigator.of(context).pop();
//                           },
//                           child: Text('OK'),
//                         ),
//                       ],
//                     ),
//                   );
//                 } else {
//                   _showPrinterOptionsModal(context);
//                   // Panggil fungsi untuk menampilkan modal
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         backgroundColor: AppColors.appBarColor,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.teal,
//               ),
//               child: Text(
//                 'Menu',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),

//             ListTile(
//               leading: Icon(Icons.home, color: Colors.white),
//               title: Text('Home', style: AppStyles.dialogContentTextStyle),
//               onTap: () {
//                 // Tambahkan navigasi atau fungsi yang diinginkan
//                 _showHomeConfirmationDialog(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.group, color: Colors.white),
//               title:
//                   Text('Guest List', style: AppStyles.dialogContentTextStyle),
//               onTap: () {
//                 // Tambahkan navigasi atau fungsi yang diinginkan
//                 _guest(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.person_2, color: Colors.white),
//               title: Text(
//                 'Select Client',
//                 style: AppStyles.dialogContentTextStyle,
//               ),
//               onTap: () {
//                 // Tambahkan navigasi atau fungsi yang diinginkan
//                 _showSelectClientConfirmationDialog(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(FontAwesomeIcons.chartPie, color: Colors.white),
//               title: Text(
//                 'Statistic',
//                 style: AppStyles.dialogContentTextStyle,
//               ),
//               onTap: () async {
//                 Navigator.pop(context);
//                 _stats(context);
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.logout, color: Colors.white),
//               title: Text('Logout', style: AppStyles.dialogContentTextStyle),
//               onTap: () async {
//                 // Tambahkan navigasi atau fungsi yang diinginkan
//                 _showLogoutConfirmationDialog(context);
//                 // Navigator.pop(context); // Tutup drawer
//               },
//             ),
//             // Tambahkan item menu lainnya sesuai kebutuhan
//           ],
//         ),
//       ),
//       body: Stack(
//         children: [
//           // Background color
//           Container(
//             color: AppColors.appBarColor,
//           ),
//           // Background image
//           Container(
//             decoration: BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/background.jpg'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           // Gradient overlay
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.black.withOpacity(0.9),
//                   Colors.teal.shade300.withOpacity(0.6),
//                 ],
//                 begin: Alignment.bottomCenter,
//                 end: Alignment.topCenter,
//               ),
//             ),
//           ),
//           // Main content with scroll
//           SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Tampilkan informasi Client, Event, dan Session dengan CardTicket
//                   CardTicket(
//                     headerText: 'C L I E N T',
//                     title: Text(
//                       widget.clientName,
//                       style: AppStyles.titleCardPrimaryTextStyle,
//                     ),
//                     trailing: Icon(Icons.verified_user),
//                     subtitle: Text('Client ID: ${widget.clientId}'),
//                   ),
//                   SizedBox(height: 16),

//                   CardTicket(
//                     headerText: 'E V E N T',
//                     title: Text(
//                       widget.event.event_name,
//                       style: AppStyles.titleCardPrimaryTextStyle,
//                     ),
//                     trailing: Icon(Icons.verified_user),
//                     subtitle: Text('Date: ${widget.event.date}'),
//                   ),
//                   SizedBox(height: 16),

//                   CardTicket(
//                     headerText: 'S E S S I O N',
//                     title: Text(
//                       widget.session.session_name,
//                       style: AppStyles.titleCardPrimaryTextStyle,
//                     ),
//                     trailing: Icon(Icons.verified_user),
//                     subtitle: Text(
//                         'Location : ${widget.session.location} \nTime        : ${widget.session.time}'),
//                   ),
//                   SizedBox(height: 16),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _navigateToScanQRScreen(context, widget.clientId, widget.role);
//         },
//         splashColor: AppColors.gradientEndColor,
//         backgroundColor: AppColors.appBarColor,
//         tooltip: 'Scan QR',
//         child: Icon(
//           Icons.qr_code_scanner,
//           color: AppColors.iconColor,
//         ),
//       ),
//     );
//   }

//   void _showPrinterOptionsModal(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Printer Options'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ElevatedButton(
//                   onPressed: isLoading ? null : _showDeviceSelectionSheet,
//                   child: Text('Select Printer'),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: AppColors.buttonColor,
//                     backgroundColor: AppColors.appBarColor,
//                   ),
//                 ),
//                 SizedBox(height: 16),

//                 // Tombol untuk Connect, Disconnect, dan Print Test
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     CustomActionButton(
//                       icon: Icons.bluetooth,
//                       backgroundColor: AppColors.appBarColor,
//                       iconColor: AppColors.iconColorEdit,
//                       onPressed: isLoading
//                           ? null
//                           : () async {
//                               // Panggil fungsi untuk menghubungkan printer
//                               await connectToPrinter();
//                               final printerService =
//                                   Provider.of<Printer1Service>(context,
//                                       listen: false);
//                               // Periksa apakah printer terhubung
//                               if (printerService.isPrinterConnected) {
//                                 // Jika terhubung, tutup dialog
//                                 Navigator.of(context).pop();
//                               }
//                             },
//                       tooltip: 'Connect Printer',
//                       label: 'Connect',
//                       labelTextStyle: AppStyles.captionTextStyle,
//                     ),
//                     CustomActionButton(
//                       backgroundColor: AppColors.appBarColor,
//                       icon: Icons.bluetooth_disabled,
//                       iconColor: AppColors.iconColorWarning,
//                       onPressed: () {
//                         disconnectPrinter();
//                       },
//                       tooltip: 'Disconnect Printer',
//                       label: 'Disconnect',
//                       labelTextStyle: AppStyles.captionTextStyle,
//                     ),
//                     CustomActionButton(
//                       backgroundColor: AppColors.appBarColor,
//                       icon: Icons.print,
//                       iconColor: AppColors.iconColor,
//                       onPressed: printTest,
//                       tooltip: 'Print Test',
//                       label: 'Feed Test',
//                       labelTextStyle: AppStyles.captionTextStyle,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showDeviceSelectionSheet() {
//     print('Showing device selection sheet...');
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Select Printer',
//                 style: AppStyles.titleTextStyle.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.appBarColor, // Sesuaikan warna teks
//                 ),
//               ),
//               SizedBox(height: 16),
//               Expanded(
//                 child: ListView(
//                   children: devices
//                       .map((device) => ListTile(
//                             title: Text(device.name ?? 'Unknown Device',
//                                 style: AppStyles.captionTextStyle),
//                             onTap: () {
//                               print('Device selected: ${device.name}');
//                               setState(() {
//                                 selectedDevice = device;
//                               });
//                               Navigator.pop(context);
//                             },
//                           ))
//                       .toList(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   print('Search for Bluetooth devices');
//                   setState(() {
//                     getDevices();
//                   });
//                 },
//                 child: Text(
//                   'Search Devices',
//                   selectionColor: AppColors.iconColor,
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.appBarColor,
//                   foregroundColor: AppColors.iconColor,
//                   padding:
//                       EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _navigateToScanQRScreen(
//       BuildContext context, String clientId, String role) {
//     print('Navigating to ScanQRScreen');
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ScanQRScreen(
//           idServer: widget.idServer,
//           name: widget.name,
//           clientId: clientId,
//           role: role,
//           clientName: widget.clientName,
//           event: widget.event,
//           session: widget.session,
//         ),
//       ),
//     );
//   }

//   void _showErrorMessage(BuildContext context, String message) {
//     print('Showing error message: $message');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
// }
