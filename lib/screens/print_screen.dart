import 'dart:async';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedweb/widgets/custom_action_button.dart';
import '../widgets/styles.dart';

import '../models/event_model.dart';
import '../models/session_model.dart';
import '../models/guest_model.dart';
import '../models/client_model.dart';
import '../models/check_in_model.dart';
import '../models/table_model.dart';
import '../services/printer_service_android.dart';
import '../services/printer_service_ios.dart'; // Import service untuk iOS
import '../widgets/custom_app_bar.dart';
import 'scan_qr_screen.dart';

class PrintScreen extends StatefulWidget {
  final String guestId;
  final String idServer;
  final String? angpauLabel;
  final String? catNumber;
  final String? checkInTime;
  final Guest? guestBeforeUpdate;
  final Event? eventUpdate;
  final Session? sessionUpdate;
  final Client? client;
  final CheckIn? updatedCheckIn;
  final String role;
  final TableModel? selectedTableUpdate;
  final String? tableFromGuestDB;
  final String clientId;
  final String clientName;
  final String counterLabel;
  final String name;
  final Event event;
  final Session session;

  PrintScreen({
    required this.guestId,
    required this.idServer,
    required this.angpauLabel,
    required this.catNumber,
    required this.checkInTime,
    required this.guestBeforeUpdate,
    required this.eventUpdate,
    required this.sessionUpdate,
    required this.client,
    required this.updatedCheckIn,
    required this.role,
    required this.selectedTableUpdate,
    required this.tableFromGuestDB,
    required this.clientId,
    required this.clientName,
    required this.counterLabel,
    required this.name,
    required this.event,
    required this.session,
  });

  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final log = Logger('PrintScreen');
  List<dynamic> devices = [];
  dynamic selectedDevice;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrinterConnection();
    });
  }

  Future<void> _requestPermissions() async {
    // Pastikan hanya dijalankan di Android
    if (Platform.isAndroid) {
      if (await Permission.locationWhenInUse.request().isGranted) {
        // Permissions granted
        print('Location permission granted');
      } else {
        _showDialog('Permissions not granted');
      }
    }
  }

  Future<void> _checkPrinterConnection() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      Provider.of<Printer1Service>(context, listen: false)
          .checkPrinterConnection();
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      Provider.of<PrinterServiceIOS>(context, listen: false)
          .checkPrinterConnection();
    }
  }

  String formatDate(String dateStr) {
    final DateTime dateTime = DateTime.parse(dateStr);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      // final printerService =
      //     Provider.of<PrinterServiceIOS>(context, listen: false);
      // List<ios.BluetoothDevice> devicesIOS = await printerService.getDevices();
      // setState(() {
      //   devices = devicesIOS; // Update devices here
      // });
      // print('Devices fetched');
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
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final printerService = Provider.of<Printer1Service>(context);
    final iosPrinterService = Provider.of<PrinterServiceIOS>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'E-TICKET',
        actions: [
          Builder(
            builder: (context) {
              // Check if the platform is Android or iOS and choose the appropriate consumer
              if (Platform.isAndroid) {
                return Consumer<Printer1Service>(
                  builder: (context, printerService, child) => IconButton(
                    icon: Icon(
                      Icons.print,
                      color: printerService.isPrinterConnected
                          ? const Color.fromARGB(255, 132, 255, 136)
                          : Colors.red,
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
                        _showPrinterOptionsModal(
                            context); // Show printer options modal
                      }
                    },
                  ),
                );
              } else if (Platform.isIOS) {
                return Consumer<PrinterServiceIOS>(
                  builder: (context, printerServiceIOS, child) => IconButton(
                    icon: Icon(
                      Icons.print,
                      color: (printerServiceIOS.isPrinterConnected ??
                              false) // Anggap false sebagai true, null sebagai false
                          ? const Color.fromARGB(255, 132, 255, 136)
                          : Colors.red,
                    ),
                    onPressed: () async {
                      // Menganggap false sebagai true dan null sebagai false
                      if ((printerServiceIOS.isPrinterConnected ?? false) ==
                          true) {
                        printTest();
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
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.iconColor,
                        borderRadius:
                            BorderRadius.circular(12.0), // Mengatur sudut
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.1), // Warna bayangan
                            spreadRadius: 2, // Jarak penyebaran bayangan
                            blurRadius: 5, // Seberapa kabur bayangan
                            offset: Offset(0, 3), // Posisi bayangan
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.client != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 20, 10, 10),
                                child: Center(
                                  child: Text(
                                    widget.eventUpdate!.event_name,
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            FutureBuilder(
                              future: SharedPreferences.getInstance(),
                              builder: (context, prefsSnapshot) {
                                if (prefsSnapshot.hasData) {
                                  bool isQrEnabled = prefsSnapshot.data
                                          ?.getBool('qr_enabled') ??
                                      false;
                                  return isQrEnabled
                                      ? Center(
                                          child: QrImageView(
                                            data: widget
                                                .guestBeforeUpdate!.guest_qr!,
                                            version: QrVersions.auto,
                                            size: 200.0,
                                          ),
                                        )
                                      : Container();
                                } else {
                                  return Container();
                                }
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Text(
                                  widget.guestBeforeUpdate!.name,
                                  style: TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.guestBeforeUpdate != null)
                              Padding(
                                padding: EdgeInsets.all(20.0),
                                child: GridView.count(
                                  crossAxisCount: 2, // Dua kolom
                                  childAspectRatio:
                                      1.5, // Mengatur rasio aspek untuk menyesuaikan ukuran
                                  shrinkWrap:
                                      true, // Agar GridView tidak mengambil lebih banyak ruang dari yang diperlukan
                                  physics:
                                      NeverScrollableScrollPhysics(), // Menonaktifkan scroll
                                  mainAxisSpacing:
                                      16.0, // Jarak vertikal antara item
                                  crossAxisSpacing:
                                      16.0, // Jarak horizontal antara item
                                  children: [
                                    Container(
                                      height:
                                          70, // Atur tinggi Container sesuai kebutuhan
                                      padding: EdgeInsets.all(
                                          5.0), // Atur padding di luar ListTile
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Warna latar belakang
                                        border: Border.all(
                                            color:
                                                Colors.black), // Border hitam
                                        borderRadius: BorderRadius.circular(
                                            12.0), // Atur sudut rounded
                                      ),
                                      child: ListTile(
                                        title: Text('PAX'),
                                        subtitle: Text(
                                          widget.updatedCheckIn!.pax_checked
                                              .toString(),
                                          style: AppStyles.titleTextStyle
                                              .copyWith(
                                                  color: AppColors.iconColor,
                                                  fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height:
                                          70, // Atur tinggi Container sesuai kebutuhan
                                      padding: EdgeInsets.all(
                                          5.0), // Atur padding di luar ListTile
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Warna latar belakang
                                        border: Border.all(
                                            color:
                                                Colors.black), // Border hitam
                                        borderRadius: BorderRadius.circular(
                                            12.0), // Atur sudut rounded
                                      ),
                                      child: ListTile(
                                        title: Text('CATEGORY'),
                                        subtitle: Text(
                                          widget.guestBeforeUpdate?.cat ??
                                              'None',
                                          style: AppStyles.titleTextStyle
                                              .copyWith(
                                                  color: AppColors.iconColor,
                                                  fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height:
                                          70, // Atur tinggi Container sesuai kebutuhan
                                      padding: EdgeInsets.all(
                                          5.0), // Atur padding di luar ListTile
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Warna latar belakang
                                        border: Border.all(
                                            color:
                                                Colors.black), // Border hitam
                                        borderRadius: BorderRadius.circular(
                                            12.0), // Atur sudut rounded
                                      ),
                                      child: ListTile(
                                        title: Text('LABEL ANGPAU'),
                                        subtitle: Text(
                                          widget.angpauLabel ?? '-',
                                          style: AppStyles.titleTextStyle
                                              .copyWith(
                                                  color: AppColors.iconColor,
                                                  fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height:
                                          70, // Atur tinggi Container sesuai kebutuhan
                                      padding: EdgeInsets.all(
                                          5.0), // Atur padding di luar ListTile
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Warna latar belakang
                                        border: Border.all(
                                            color:
                                                Colors.black), // Border hitam
                                        borderRadius: BorderRadius.circular(
                                            12.0), // Atur sudut rounded
                                      ),
                                      child: ListTile(
                                        title: Text('TABLE'),
                                        subtitle: Text(
                                          (widget.tableFromGuestDB
                                                      ?.isNotEmpty ==
                                                  true)
                                              ? widget.tableFromGuestDB!
                                              : (widget
                                                          .selectedTableUpdate
                                                          ?.table_name
                                                          ?.isNotEmpty ==
                                                      true)
                                                  ? widget.selectedTableUpdate!
                                                      .table_name
                                                  : '', // Kosongkan jika tidak ada data, bukan 'None'
                                          style: AppStyles.titleTextStyle
                                              .copyWith(
                                                  color: AppColors.iconColor,
                                                  fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    FutureBuilder(
                                      future: SharedPreferences.getInstance(),
                                      builder: (context, prefsSnapshot) {
                                        if (prefsSnapshot.hasData) {
                                          bool isMealsEnabled = prefsSnapshot
                                                  .data
                                                  ?.getBool('meals_enabled') ??
                                              false;
                                          return isMealsEnabled
                                              ? Container(
                                                  height:
                                                      70, // Atur tinggi Container sesuai kebutuhan
                                                  padding: EdgeInsets.all(
                                                      5.0), // Atur padding di luar ListTile
                                                  decoration: BoxDecoration(
                                                    color: Colors
                                                        .white, // Warna latar belakang
                                                    border: Border.all(
                                                        color: Colors
                                                            .black), // Border hitam
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0), // Atur sudut rounded
                                                  ),
                                                  child: ListTile(
                                                    title: Text('MEALS'),
                                                    subtitle: Text(
                                                      widget.updatedCheckIn!
                                                          .meals!,
                                                      style: AppStyles
                                                          .titleTextStyle
                                                          .copyWith(
                                                              color: AppColors
                                                                  .iconColor,
                                                              fontSize: 18),
                                                    ),
                                                  ),
                                                )
                                              : SizedBox.shrink();
                                        } else {
                                          return SizedBox.shrink();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 16),
                            Consumer2<Printer1Service, PrinterServiceIOS>(
                              builder: (context, printerService,
                                      iosPrinterService, child) =>
                                  Padding(
                                padding: EdgeInsets.fromLTRB(80, 10, 80,
                                    0), // Atur jarak di sekitar tombol
                                child: ElevatedButton.icon(
                                  onPressed: (isAndroid
                                          ? printerService.isPrinterConnected
                                          : iosPrinterService
                                              .isPrinterConnected!)
                                      ? () async {
                                          if (isAndroid) {
                                            await printerService.printTicket(
                                              checkInTime: widget.checkInTime!,
                                              clientName: widget.client!.name,
                                              angpauLabel:
                                                  (widget.angpauLabel != null &&
                                                          widget.angpauLabel!
                                                              .isNotEmpty)
                                                      ? widget.angpauLabel
                                                      : null,
                                              catNumber: widget.catNumber!,
                                              guestName: widget
                                                  .guestBeforeUpdate!.name,
                                              qrCode: widget
                                                  .guestBeforeUpdate!.guest_qr!,
                                              headcount: widget
                                                  .updatedCheckIn!.pax_checked
                                                  .toString(),
                                              category:
                                                  widget.guestBeforeUpdate!.cat,
                                              eventDate: formatDate(
                                                  widget.eventUpdate!.date),
                                              eventTime:
                                                  widget.sessionUpdate!.time,
                                              location: widget
                                                  .sessionUpdate!.location,
                                              sessionName: widget
                                                  .sessionUpdate!.session_name,
                                              tableName: widget
                                                              .tableFromGuestDB !=
                                                          null &&
                                                      widget.tableFromGuestDB!
                                                          .isNotEmpty
                                                  ? widget.tableFromGuestDB!
                                                  : (widget.selectedTableUpdate !=
                                                              null &&
                                                          widget
                                                              .selectedTableUpdate!
                                                              .table_name
                                                              .isNotEmpty
                                                      ? widget
                                                          .selectedTableUpdate!
                                                          .table_name
                                                      : 'None'),
                                            );
                                          } else {
                                            await iosPrinterService.printTicket(
                                                clientName: widget.client!.name,
                                                guestName: widget
                                                    .guestBeforeUpdate!.name,
                                                qrCode: widget
                                                    .guestBeforeUpdate!
                                                    .guest_qr!,
                                                headcount: widget.updatedCheckIn!.pax_checked
                                                    .toString(),
                                                category: widget
                                                    .guestBeforeUpdate!.cat,
                                                catNumber: widget.catNumber!,
                                                eventDate: formatDate(
                                                    widget.eventUpdate!.date),
                                                eventTime:
                                                    widget.sessionUpdate!.time,
                                                location: widget
                                                    .sessionUpdate!.location,
                                                sessionName: widget
                                                    .sessionUpdate!
                                                    .session_name,
                                                tableName: widget.tableFromGuestDB != null && widget.tableFromGuestDB!.isNotEmpty
                                                    ? widget.tableFromGuestDB!
                                                    : (widget.selectedTableUpdate != null &&
                                                            widget
                                                                .selectedTableUpdate!
                                                                .table_name
                                                                .isNotEmpty
                                                        ? widget
                                                            .selectedTableUpdate!
                                                            .table_name
                                                        : 'None'),
                                                angpauLabel: (widget.angpauLabel != null && widget.angpauLabel!.isNotEmpty) ? widget.angpauLabel : null,
                                                checkInTime: widget.checkInTime!);
                                          }
                                        }
                                      : null,
                                  icon: Icon(Icons.print),
                                  label: Text('Print'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: AppColors.appBarColor,
                                    backgroundColor: AppColors.iconColor,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal:
                                            10), // Atur padding dalam tombol
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          7), // Atur sudut rounded
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.fromLTRB(80, 0, 80,
                                  20), // Atur jarak di sekitar tombol
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ScanQRScreen(
                                              clientId:
                                                  widget.client!.client_id!,
                                              role: widget.role,
                                              name: widget.name,
                                              idServer: widget.idServer,
                                              clientName: widget.clientName,
                                              counterLabel: widget.counterLabel,
                                              event: widget.event,
                                              session: widget.session,
                                            )),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                icon: Icon(Icons.arrow_circle_right_rounded),
                                label: Text('Next'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.lightGreen,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.iconColor,
                        borderRadius:
                            BorderRadius.circular(12.0), // Mengatur sudut
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.1), // Warna bayangan
                            spreadRadius: 2, // Jarak penyebaran bayangan
                            blurRadius: 5, // Seberapa kabur bayangan
                            offset: Offset(0, 3), // Posisi bayangan
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(
                              10.0), // Padding di seluruh container
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'DATE: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .normal, // Normal font untuk "DATE: "
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${widget.eventUpdate!.date} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .bold, // Bold untuk tanggal
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'TIME: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .normal, // Normal font untuk "TIME: "
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${widget.sessionUpdate!.time} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .bold, // Bold untuk waktu
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'SESSION: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .normal, // Normal font untuk "SESSION: "
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${widget.sessionUpdate!.session_name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .bold, // Bold untuk nama sesi
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Anda bisa menambahkan elemen lain di bawah ini
                              // Text(
                              //   'Informasi tambahan...',
                              //   style: TextStyle(
                              //     fontSize: 18,
                              //     color: Colors.white,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
