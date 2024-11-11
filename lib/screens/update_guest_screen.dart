import 'dart:developer';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedweb/screens/envelope_entrust_screen.dart';
import 'package:wedweb/widgets/custom_action_button.dart';
import 'print_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../models/guest_model.dart';
import '../models/client_model.dart';
import '../models/event_model.dart';
import '../models/session_model.dart';
import '../models/check_in_model.dart';
import '../models/table_model.dart';
import '../services/database_helper.dart';
import '../services/printer_service_android.dart'; // Import Printer1Service untuk Android
import '../services/printer_service_ios.dart';
import '../widgets/styles.dart';

class UpdateGuestScreen extends StatefulWidget {
  final String role;
  final String guestId;
  final String idServer;
  final String clientId;
  final String clientName;
  final String counterLabel;
  final String name;
  final Event event;
  final Session session;

  UpdateGuestScreen({
    required this.idServer,
    required this.name,
    required this.guestId,
    required this.role,
    required this.clientId,
    required this.clientName,
    required this.counterLabel,
    required this.event,
    required this.session,
  });

  @override
  _UpdateGuestScreenState createState() => _UpdateGuestScreenState();
}

class _UpdateGuestScreenState extends State<UpdateGuestScreen> {
  Guest? _guest;
  Client? _client;
  Event? _selectedEvent;
  List<Session> _sessions = [];
  Session? _selectedSession;
  List<TableModel> _tables = [];
  TableModel? _selectedTable;
  CheckIn? _checkIn;
  List<dynamic> devices = [];
  dynamic selectedDevice;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late Future<void> _future;
  bool isPrinterConnected = false;
  String? _tablesAtGuest;
  bool _isAngpauChecked = false;
  String _selectedAbjad = 'A';
  int _angpauCounter = 0;
  String? angpauLabel = null;

  @override
  void initState() {
    super.initState();
    _future = _fetchGuestDetails();
    checkPrinterConnection();
    _fetchTablesAtGuest();
    _loadAbjadSetting();
  }

  Future<void> checkPrinterConnection() async {
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false);
      await printerService.checkPrinterConnection();
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<PrinterServiceIOS>(context, listen: false);
      await printerService.checkPrinterConnection();
    }
  }

  Future<void> _getCounter() async {
    final dbHelper = DatabaseHelper.instance;

    // Panggil metode getCounterAngpau dan simpan hasilnya di _angpauCounter
    final counterValue = await dbHelper.getCounterAngpau(
        _selectedAbjad, widget.session.session_id!);

    // Tambahkan log
    log('CHECKANGPAU: Mengambil counter untuk session_id = ${widget.session.session_id}, key = $_selectedAbjad, counter = $counterValue');

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

  Future<void> _fetchGuestDetails() async {
    final dbHelper = DatabaseHelper.instance;
    _guest = await dbHelper.getGuestById(widget.guestId);
    if (_guest != null) {
      _client = await dbHelper.getClientById(_guest!.client_id);
      _selectedEvent = widget.event;
      _checkIn = await dbHelper.getCheckInByGuestId(widget.guestId);
      _sessions = await dbHelper.getAvailableSessions(
          widget.guestId, _selectedEvent!.event_id);
      _selectedSession = _sessions.firstWhere(
          (session) => session.session_id == widget.session.session_id,
          orElse: () => _sessions.first);
      if (_selectedSession != null) {
        await _fetchTablesForSession(_selectedSession!.session_id!);
      }
    }
    setState(() {});
  }

  Future<void> _fetchTablesForSession(String session_id) async {
    final dbHelper = DatabaseHelper.instance;
    _tables = await dbHelper.getTablesForSession(session_id);
    setState(() {
      _selectedTable = _tables.isNotEmpty ? _tables.first : null;
    });
  }

  Future<void> _fetchTablesAtGuest() async {
    final dbHelper = DatabaseHelper.instance;
    final guest = await dbHelper.getGuestById(widget.guestId);
    _tablesAtGuest = guest?.tables ?? '';
    setState(() {});
  }

  Future<void> _updateCheckIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final dbHelper = DatabaseHelper.instance;
      if (_checkIn != null && _selectedSession != null) {
        _checkIn!.session_id = _selectedSession!.session_id!;
        try {
          if (_selectedTable != null) {
            await dbHelper.updateTableSeats(
                _selectedTable!.table_id!,
                _selectedTable!.seat - _checkIn!.pax_checked,
                DateTime.now().toUtc().toIso8601String());
          }
          await dbHelper.updateCheckIn(
              _checkIn!, DateTime.now().toUtc().toIso8601String());
          if (_isAngpauChecked) {
            final int counterValue = _angpauCounter + 1;
            final String paddedCounterValue =
                counterValue.toString().padLeft(3, '0');
            await dbHelper.updateCounterAngpau(
                widget.session.session_id!, _selectedAbjad, counterValue);
            final String _angpauLabel = '${_selectedAbjad}$paddedCounterValue';

            await dbHelper.updateAngpauCheckIn(_angpauLabel, _checkIn!,
                DateTime.now().toUtc().toIso8601String());
            setState(() {
              angpauLabel = _angpauLabel;
            });
          }

          DateTime now = DateTime.now();
          String formattedTime = DateFormat('HH:mm:ss').format(now);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PrintScreen(
                guestId: widget.guestId,
                idServer: widget.idServer,
                name: widget.name,
                guestBeforeUpdate: _guest,
                eventUpdate: _selectedEvent,
                sessionUpdate: _selectedSession,
                client: _client,
                updatedCheckIn: _checkIn,
                role: widget.role,
                selectedTableUpdate: _selectedTable,
                angpauLabel: angpauLabel,
                catNumber: _checkIn!.note != null && _checkIn!.note!.isNotEmpty
                    ? _checkIn!.note
                    : '-',
                checkInTime: formattedTime,
                tableFromGuestDB: _tablesAtGuest,
                clientId: widget.clientId,
                clientName: widget.clientName,
                counterLabel: widget.counterLabel,
                event: widget.event,
                session: widget.session,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
            ),
          );
        }
      }
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
    String sessionToCheck = widget.session.session_id!;
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'Confirm Guest',
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
                        builder: (context, printerServiceIOS, child) =>
                            IconButton(
                          icon: Icon(
                            Icons.print,
                            color:
                                (printerServiceIOS.isPrinterConnected ?? false)
                                    ? const Color.fromARGB(255, 132, 255, 136)
                                    : Colors.red,
                          ),
                          onPressed: () async {
                            if (printerServiceIOS.isPrinterConnected == true) {
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
                    } else {
                      return Container(); // Return an empty container for unsupported platforms
                    }
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_guest != null)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors
                              .iconColor, // Ganti dengan warna yang diinginkan
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_client?.name ?? ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder(
                              future: SharedPreferences.getInstance(),
                              builder: (context, prefsSnapshot) {
                                if (prefsSnapshot.hasData) {
                                  bool isQrEnabled = prefsSnapshot.data
                                          ?.getBool('qr_enabled') ??
                                      false;
                                  return isQrEnabled
                                      ? Column(
                                          children: [
                                            QrImageView(
                                              data: _guest!.guest_qr!,
                                              size: 120,
                                              backgroundColor: Colors.white,
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        )
                                      : SizedBox.shrink();
                                } else {
                                  return SizedBox.shrink();
                                }
                              },
                            ),
                            Text(
                              '${_selectedEvent?.event_name ?? ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                            ),
                            Text(
                              '${_selectedEvent?.date ?? ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors
                            .iconColor, // Ganti dengan warna yang diinginkan
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: GridView.count(
                        crossAxisCount: 2, // Dua kolom
                        childAspectRatio:
                            2.5, // Mengatur rasio aspek untuk menyesuaikan ukuran
                        shrinkWrap:
                            true, // Agar GridView tidak mengambil lebih banyak ruang dari yang diperlukan
                        physics:
                            NeverScrollableScrollPhysics(), // Menonaktifkan scroll
                        mainAxisSpacing: 16.0, // Jarak vertikal antara item
                        crossAxisSpacing: 16.0, // Jarak horizontal antara item
                        children: [
                          _buildInfoTile(
                            context,
                            title: 'GUEST NAME',
                            value: _guest!.name,
                          ),
                          _buildInfoTile(
                            context,
                            title: 'CATEGORY',
                            value: _guest!.cat,
                          ),
                          _buildInfoTile(
                            context,
                            title: 'DATE',
                            value: _selectedEvent!.date,
                          ),
                          _buildInfoTile(
                            context,
                            title: 'SESSION',
                            value: _selectedSession!.session_name,
                          ),
                          _buildInfoTile(
                            context,
                            title: 'CHECK-IN TIME',
                            value: formattedTime,
                          ),
                          if (_isAngpauChecked)
                            _buildInfoTile(
                              context,
                              title: 'ENVELOPE',
                              value:
                                  '$_selectedAbjad${(_angpauCounter + 1).toString().padLeft(3, '0')}',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Container untuk Dropdown jika belum ada TABLE
                    if (_tables.isNotEmpty && _tablesAtGuest!.isEmpty)
                      ListTile(
                        title: DropdownButtonFormField<TableModel>(
                          decoration: InputDecoration(
                            labelText: 'Table',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: _selectedTable,
                          items: _tables.map((table) {
                            return DropdownMenuItem<TableModel>(
                              value: table,
                              child: Text(
                                '${table.table_name} (Seats: ${table.seat})',
                              ),
                            );
                          }).toList(),
                          onChanged: (TableModel? newValue) {
                            setState(() {
                              _selectedTable = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a table' : null,
                        ),
                      ),

                    ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TextFormField untuk input Pax Checked
                          TextFormField(
                            initialValue:
                                _checkIn?.pax_checked.toString() ?? '0',
                            decoration: InputDecoration(
                              labelText: 'Pax Checked',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the number of pax checked';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _checkIn!.pax_checked = int.parse(value!);
                            },
                          ),
                          const SizedBox(
                              height: 8), // Spacing between input and text
                          // Text untuk menunjukkan Pax Available
                          Text(
                            'Pax Available: ${_checkIn!.rsvp == 'pending' ? _guest!.pax : _checkIn!.pax_checked}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder(
                      future: SharedPreferences.getInstance(),
                      builder: (context, prefsSnapshot) {
                        if (prefsSnapshot.hasData) {
                          bool isMealsEnabled =
                              prefsSnapshot.data?.getBool('meals_enabled') ??
                                  false;
                          return isMealsEnabled
                              ? ListTile(
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Meals',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the number of pax checked';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _checkIn!.meals = value!;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                )
                              : SizedBox.shrink();
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),

                    FutureBuilder(
                      future: SharedPreferences.getInstance(),
                      builder: (context, prefsSnapshot) {
                        if (prefsSnapshot.hasData) {
                          bool isQrEnabled =
                              prefsSnapshot.data?.getBool('Angpau_enabled') ??
                                  false;
                          return isQrEnabled
                              ? Row(
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
                                    SizedBox(
                                      width: 80, // Atur lebar button
                                      child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return EnvelopeEntrustScreen(
                                                idServer: widget.idServer,
                                                role: widget.role,
                                                clientId: widget.clientId,
                                                clientName: widget.clientName,
                                                counterLabel:
                                                    widget.counterLabel,
                                                event: widget.event,
                                                session: widget
                                                    .session, // Ganti dengan instans Session yang sesuai
                                                name: widget.name,
                                                guest: _guest!,
                                              );
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 218, 243, 255),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                8), // Sudut rounded
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                                height:
                                                    8), // Jarak antara ikon dan teks
                                            Icon(Icons.card_giftcard),
                                            SizedBox(
                                                height:
                                                    4), // Jarak antara ikon dan teks
                                            Text(
                                              'Add',
                                              style: TextStyle(
                                                fontSize: 12, // Ukuran font
                                                color: Colors
                                                    .blueGrey, // Warna teks
                                              ),
                                            ),
                                            SizedBox(
                                                height:
                                                    8), // Jarak antara ikon dan teks
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink();
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(AppColors.appBarColor),
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        elevation: MaterialStateProperty.all(4),
                      ),
                      onPressed: _updateCheckIn,
                      child: Text(
                        'Confirm',
                        style: TextStyle(color: AppColors.iconColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildInfoTile(BuildContext context,
      {required String title, required String value}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = constraints.maxWidth *
            0.04; // Ukuran font yang proporsional dengan lebar
        double padding = constraints.maxWidth * 0.02; // Padding proporsional

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
            ),
            subtitle: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize:
                        fontSize * 1.5, // Font size lebih besar untuk subtitle
                    color: AppColors.iconColor,
                  ),
            ),
          ),
        );
      },
    );
  }

  Future<void> printTest() async {
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as Printer1Service;
      await printerService.printTest(context);
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<PrinterServiceIOS>(context, listen: false);
      await printerService.printTest(context);
    }
  }
}
