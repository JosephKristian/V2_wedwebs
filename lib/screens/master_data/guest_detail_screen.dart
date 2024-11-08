import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedweb/models/check_in_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/services/printer_service_android.dart';
import 'package:wedweb/services/printer_service_ios.dart';
import 'package:wedweb/widgets/custom_action_button.dart';
import '../../widgets/styles.dart';
import '../../services/data_service.dart';
import '../../services/database_helper.dart';

class GuestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> guest;
  final String idServer;
  final Session session;

  const GuestDetailScreen(
      {Key? key,
      required this.guest,
      required this.idServer,
      required this.session})
      : super(key: key);

  @override
  _GuestDetailScreenState createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  final DataService _dataService = DataService();
  Map<String, dynamic>? _guestDetails;
  bool _isAngpauChecked = false;
  String _selectedAbjad = 'A';
  String? angpauLabel = null;
  int _angpauCounter = 0;
  CheckIn? _checkIn;
  bool isLoading = false;
  List<dynamic> devices = [];
  dynamic selectedDevice;

  @override
  void initState() {
    super.initState();
    _fetchGuestDetails(widget.guest['guest_id']);
    _loadAbjadSetting();
  }

  Future<void> _getCounter() async {
    final dbHelper = DatabaseHelper.instance;

    // Panggil metode getCounterAngpau dan simpan hasilnya di _angpauCounter
    final counterValue = await dbHelper.getCounterAngpau(
        _selectedAbjad, widget.session.session_id!);

    // Tambahkan log
    print(
        'CHECKANGPAU: Mengambil counter untuk session_id = ${widget.session.session_id}, key = $_selectedAbjad, counter = $counterValue');

    // Atur _angpauCounter menggunakan setState
    setState(() {
      _angpauCounter = counterValue;
    });
  }

  Future<void> _loadAbjadSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAbjad = prefs.getString('angpau_abjad') ?? 'A';
      _getCounter();
    });
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

  Future<void> _fetchGuestDetails(String guestId) async {
    final dbHelper = DatabaseHelper();

    // Menunggu detail dan check-in data secara asinkron di luar setState
    final details = await dbHelper.getGuestDetails(guestId);
    final checkIn = await dbHelper.getCheckInByGuestId(guestId);

    // Setelah semua data asinkron diperoleh, set nilainya di dalam setState
    setState(() {
      _checkIn = checkIn;
      _guestDetails = details;
    });
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
        await printerService.disconnectPrinter();
        print('Printer successfully disconnected');
        _showNotification('Printer successfully disconnected');
      } else {
        print('Printer is already disconnected');
        _showNotification('Printer is already disconnected');
      }
    }
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
                    CustomActionButton(
                      icon: Icons.bluetooth,
                      backgroundColor: AppColors.appBarColor,
                      iconColor: AppColors.iconColorEdit,
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Panggil fungsi untuk menghubungkan printer
                              await connectToPrinter();
                              final printerService =
                                  Provider.of<Printer1Service>(context,
                                      listen: false);
                              // Periksa apakah printer terhubung
                              if (printerService.isPrinterConnected) {
                                // Jika terhubung, tutup dialog
                                Navigator.of(context).pop();
                              }
                            },
                      tooltip: 'Connect Printer',
                      label: 'Connect',
                      labelTextStyle: AppStyles.captionTextStyle,
                    ),
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

  Future<void> _updateEnvelope() async {
    final dbHelper = DatabaseHelper();
    final int counterValue = _angpauCounter + 1;
    final String paddedCounterValue = counterValue.toString().padLeft(3, '0');

    // Update counter angpau dan check-in di database
    await dbHelper.updateCounterAngpau(
        widget.session.session_id!, _selectedAbjad, counterValue);
    final String _angpauLabel = '${_selectedAbjad}$paddedCounterValue';

    await dbHelper.updateAngpauCheckIn(
        _angpauLabel, _checkIn!, DateTime.now().toUtc().toIso8601String());

    // Update UI state dan tampilkan SnackBar
    setState(() {
      angpauLabel = _angpauLabel;
    });

    // Menampilkan SnackBar sukses
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update angpau berhasil!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    print('Update Envelope'); // Debug output
  }

  // Fungsi untuk memformat waktu saja dari createdAt
  String _formatTimeOnly(String createdAt) {
    final dateTimeUtc = DateTime.parse(createdAt).toUtc();

    // Konversi dari UTC ke waktu lokal
    final dateTimeLocal = dateTimeUtc.toLocal();

    // Format untuk menampilkan waktu lokal
    return DateFormat('HH:mm:ss').format(dateTimeLocal);
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final printerService = Provider.of<Printer1Service>(context);
    final iosPrinterService = Provider.of<PrinterServiceIOS>(context);

    if (_guestDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text('Guest Details', style: AppStyles.titleCardPrimaryTextStyle),
          backgroundColor: AppColors.appBarColor,
          foregroundColor: AppColors.backgroundColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Guest Details', style: AppStyles.titleCardPrimaryTextStyle),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: AppColors.backgroundColor,
        actions: [
          Consumer<Printer1Service>(
            builder: (context, printerService, child) => IconButton(
              icon: Icon(
                Icons.print,
                color: printerService.isPrinterConnected
                    ? Colors.green
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
                  _showPrinterOptionsModal(context);
                  // Panggil fungsi untuk menampilkan modal
                }
              },
            ),
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
                            if (widget.guest != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 20, 10, 10),
                                child: Center(
                                  child: Text(
                                    'Guest Details',
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
                                            data: widget.guest['guest_qr'],
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
                                  widget.guest['name'],
                                  style: TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.guest != null)
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
                                          _guestDetails!['sessions'][0]
                                                  ['pax_checked']
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
                                          '${widget.guest['cat']}',
                                          style: AppStyles.titleTextStyle
                                              .copyWith(
                                                  color: AppColors.iconColor,
                                                  fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    if (widget.guest['angpau_label'] != null &&
                                        widget.guest['angpau_label']
                                            .isNotEmpty) ...[
                                      Container(
                                        height: 70,
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
                                            widget.guest['angpau_label'],
                                            style: AppStyles.titleTextStyle
                                                .copyWith(
                                              color: AppColors.iconColor,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_isAngpauChecked)
                                      Container(
                                        padding: EdgeInsets.all(
                                            5.0), // Atur padding di luar ListTile
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border:
                                              Border.all(color: Colors.black),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            'ENVELOPE',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black87,
                                                ),
                                          ),
                                          subtitle: Text(
                                            '$_selectedAbjad${(_angpauCounter + 1).toString().padLeft(3, '0')}',
                                            style: AppStyles.titleTextIconStyle,
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
                                        title: Text('STAT'),
                                        subtitle: Text(
                                          '${_guestDetails!['sessions'][0]['status']} (${_formatTimeOnly(_guestDetails!['sessions'][0]['createdAt'])}) ', // Kosongkan jika tidak ada data, bukan 'None'
                                          style: AppStyles.titleTextStyle
                                              .copyWith(
                                                  color: AppColors.iconColor,
                                                  fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Consumer2<Printer1Service, PrinterServiceIOS>(
                            //   builder: (context, printerService,
                            //           iosPrinterService, child) =>
                            //       Padding(
                            //     padding: EdgeInsets.fromLTRB(80, 10, 80,
                            //         0), // Atur jarak di sekitar tombol
                            //     child: ElevatedButton.icon(
                            //       onPressed: (isAndroid
                            //               ? printerService.isPrinterConnected
                            //               : iosPrinterService
                            //                   .isPrinterConnected!)
                            //           ? () async {
                            //               if (isAndroid) {
                            //                 await printerService
                            //                     .printTicketEnvelope(
                            //                         guest: widget.guest,
                            //                         guestDetails: _guestDetails,
                            //                         checkInTime:
                            //                             '${_guestDetails!['sessions'][0]['status']} (${_formatTimeOnly(_guestDetails!['sessions'][0]['createdAt'])}');
                            //               } else {
                            //                 // await iosPrinterService.printTicket(
                            //                 //   context: context,
                            //                 //   clientName: widget.client!.name,
                            //                 //   guestName: widget
                            //                 //       .guestBeforeUpdate!.name,
                            //                 //   qrCode: widget
                            //                 //       .guestBeforeUpdate!.guest_qr!,
                            //                 //   headcount: widget
                            //                 //       .updatedCheckIn!.pax_checked
                            //                 //       .toString(),
                            //                 //   category:
                            //                 //       widget.guestBeforeUpdate!.cat,
                            //                 //   eventDate: formatDate(
                            //                 //       widget.eventUpdate!.date),
                            //                 //   eventTime:
                            //                 //       widget.sessionUpdate!.time,
                            //                 //   location: widget
                            //                 //       .sessionUpdate!.location,
                            //                 //   sessionName: widget
                            //                 //       .sessionUpdate!.session_name,
                            //                 //   tableName: widget
                            //                 //                   .tableFromGuestDB !=
                            //                 //               null &&
                            //                 //           widget.tableFromGuestDB!
                            //                 //               .isNotEmpty
                            //                 //       ? widget.tableFromGuestDB!
                            //                 //       : (widget.selectedTableUpdate !=
                            //                 //                   null &&
                            //                 //               widget
                            //                 //                   .selectedTableUpdate!
                            //                 //                   .table_name
                            //                 //                   .isNotEmpty
                            //                 //           ? widget
                            //                 //               .selectedTableUpdate!
                            //                 //               .table_name
                            //                 //           : 'None'),
                            //                 // );
                            //               }
                            //             }
                            //           : null,
                            //       icon: Icon(Icons.print),
                            //       label: Text('Print'),
                            //       style: ElevatedButton.styleFrom(
                            //         foregroundColor: AppColors.appBarColor,
                            //         backgroundColor: const Color.fromARGB(
                            //             255, 248, 215, 137),
                            //         padding: EdgeInsets.symmetric(
                            //             vertical: 16,
                            //             horizontal:
                            //                 10), // Atur padding dalam tombol
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(
                            //               7), // Atur sudut rounded
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            SizedBox(
                              height: 15,
                            ),
                            if (widget.guest['angpau_label'].isEmpty) ...[
                              Padding(
                                padding: EdgeInsets.fromLTRB(80, 0, 80,
                                    20), // Atur jarak di sekitar tombol
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _updateEnvelope(); //tombol
                                  },
                                  icon: Icon(Icons.arrow_circle_right_rounded),
                                  label: Text('Update'),
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
                                        text:
                                            '${_guestDetails!['sessions'][0]['date']}  ',
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
                                        text:
                                            '${_guestDetails!['sessions'][0]['time']}  ',
                                        style: TextStyle(
                                          fontWeight: FontWeight
                                              .bold, // Bold untuk waktu
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
                    if (widget.guest['angpau_label'].isEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Untuk memberi jarak antar widget
                        children: [
                          Expanded(
                            // Membuat SwitchListTile mengambil ruang yang tersedia
                            child: SwitchListTile(
                              title: Text('Envelope'),
                              value: _isAngpauChecked,
                              onChanged: (bool value) {
                                setState(() {
                                  _isAngpauChecked = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
