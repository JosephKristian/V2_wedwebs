import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Printer1Service with ChangeNotifier {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  BluetoothDevice? _selectedDevice;
  bool _isPrinterConnected = false;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isPrinterConnected => _isPrinterConnected;

  // Notifikasi perubahan koneksi printer
  void _updateConnectionStatus(bool status) {
    print('Updating connection status to $status');
    _isPrinterConnected = status;
    notifyListeners();
  }

  Future<void> getDevices(List<BluetoothDevice> devices) async {
    print('Fetching bonded devices...');
    try {
      devices.addAll(await _printer.getBondedDevices());
      print('Devices fetched: ${devices.length} devices found');
    } catch (e) {
      print('Error fetching devices: $e');
    }
  }

  Future<void> checkPrinterConnection() async {
    print('Checking printer connection status...');
    try {
      bool isConnected = (await _printer.isConnected) ?? false;
      print('Printer connection status: $isConnected');
      _updateConnectionStatus(isConnected);
    } catch (e) {
      print('Error checking printer connection: $e');
    }
  }

  Future<void> connectToPrinter(BluetoothDevice? device) async {
    print('Attempting to connect to printer: ${device?.name}');
    if (device != null) {
      try {
        if (_isPrinterConnected) {
          print('Printer is already connected');
          _updateConnectionStatus(true);
        } else {
          await _printer.connect(device);
          await checkPrinterConnection();
          _selectedDevice = device;
          print('Successfully connected to printer: ${device.name}');
        }
      } catch (e) {
        print('Error connecting to printer: $e');
      }
    } else {
      print('No device selected');
    }
  }

  Future<void> disconnectPrinter() async {
    print('Attempting to disconnect from printer...');
    try {
      await _printer.disconnect();
      await checkPrinterConnection();
      _selectedDevice = null;
      print('Successfully disconnected from printer');
    } catch (e) {
      print('Error disconnecting from printer: $e');
    }
  }

  Future<void> printTest(BuildContext context) async {
    print('Attempting to print test...');
    if (_isPrinterConnected) {
      try {
        _printer.printNewLine();
        print('Test print executed');
      } catch (e) {
        print('Error printing test: $e');
      }
    } else {
      print('Printer not connected');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Printer Not Connected'),
            content: Text('Check your Printer'),
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
  }

  Future<void> printTicket({
    required String clientName,
    required String guestName,
    required String qrCode,
    required String headcount,
    required String category,
    required String catNumber,
    required String eventDate,
    required String eventTime,
    required String location,
    required String sessionName,
    required String tableName,
    required String? angpauLabel,
    required String checkInTime,
  }) async {
    print('Attempting to print ticket...');
    if (_isPrinterConnected) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isQrEnabled = prefs.getBool('qr_enabled') ?? false;
        bool isAngpauEnabled = prefs.getBool('Angpau_enabled') ?? false;

        _printer.printNewLine();
        _printer.printCustom('$clientName', 2, 1);
        _printer.printNewLine();

        if (isQrEnabled) {
          _printer.printQRcode('$qrCode', 250, 205, 1);
        }
        if (isAngpauEnabled) {
          _printer.printCustom('Angpau Label: $angpauLabel', 1, 0);
        }

        _printer.printNewLine();
        _printer.printCustom('Guest Name: $guestName', 1, 0);
        _printer.printCustom('Headcount: $headcount', 1, 0);
        _printer.printNewLine();
        _printer.printCustom('Category: $category', 1, 0);
        _printer.printCustom('Cat. Number: $catNumber', 1, 0);
        _printer.printCustom('Date: $eventDate', 1, 0);
        _printer.printCustom('Check-in time: $eventTime (${checkInTime})', 1, 0);
        _printer.printCustom('Table: $tableName', 1, 0);
        _printer.printCustom('Location: $location', 1, 0);
        _printer.printCustom('Session: $sessionName', 1, 0);
        _printer.printNewLine();
        _printer.printNewLine();
        _printer.printCustom('wedwebs.com', 2, 1);
        _printer.printNewLine();
        _printer.printNewLine();

        print('Ticket printed successfully');
      } catch (e) {
        print('Error printing ticket: $e');
      }
    } else {
      print('Printer not connected');
    }
  }

  Future<void> printTicketEnvelope({
    required Map<String, dynamic> guest,
    required Map<String, dynamic>? guestDetails,
    required String checkInTime,
    String angpauTitipan = '',
  }) async {
    print('Attempting to print ticket...');
    if (_isPrinterConnected) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isQrEnabled = prefs.getBool('qr_enabled') ?? false;

        _printer.printNewLine();
        _printer.printCustom('E-TICKET', 2, 1);

        if (isQrEnabled) {
          _printer.printQRcode('${guest['guest_qr']}', 250, 205, 1);
        }

        _printer.printNewLine();
        _printer.printCustom('Guest Name: ${guest['name']}', 1, 0);
        _printer.printCustom(
            'Headcount: ${guestDetails!['sessions'][0]['pax_checked'].toString()}',
            1,
            0);
        _printer.printCustom('Category: ${guest['cat']}', 1, 0);
        _printer.printCustom('${checkInTime}', 1, 0);
        _printer.printNewLine();
        _printer.printCustom(
            'Angpau Label: ${guestDetails['sessions'][0]['angpau_label'].toString()} (${angpauTitipan})',
            1,
            0);
        _printer.printNewLine();
        _printer.printCustom('WEDWEB.COM', 2, 1);
        _printer.printNewLine();
        _printer.printNewLine();

        print('Ticket printed successfully');
      } catch (e) {
        print('Error printing ticket: $e');
      }
    } else {
      print('Printer not connected');
    }
  }

  Future<void> printTicketEnvelopeBasic({
    required Map<String, dynamic> guest,
    String timeCheckedIn = '',
  }) async {
    print('Attempting to print ticket...');
    if (_isPrinterConnected) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isQrEnabled = prefs.getBool('qr_enabled') ?? false;

        _printer.printNewLine();
        _printer.printCustom('E-TICKET', 2, 1);

        if (isQrEnabled) {
          _printer.printQRcode('${guest['guest_qr']}', 250, 205, 1);
        }

        _printer.printNewLine();
        _printer.printCustom('Guest Name: ${guest['name']}', 1, 0);
        _printer.printCustom('Headcount: ', 1, 0);
        _printer.printCustom('Category: ${guest['cat'] ?? 'blank'}', 1, 0);
        _printer.printCustom('$timeCheckedIn', 1, 0);
        _printer.printNewLine();
        _printer.printCustom(
            'Angpau Label: ${guest['angpau_label']}(${guest['angpauTitipan'] ?? ''})',
            1,
            0);
        _printer.printNewLine();
        _printer.printCustom('WEDWEB.COM', 2, 1);
        _printer.printNewLine();
        _printer.printNewLine();

        print('Ticket printed successfully');
      } catch (e) {
        print('Error printing ticket: $e');
      }
    } else {
      print('Printer not connected');
    }
  }
}
