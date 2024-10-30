import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';

class PrinterServiceIOS with ChangeNotifier {
  final BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  BluetoothDevice? _selectedDevice;
  bool? _isPrinterConnected;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool? get isPrinterConnected => _isPrinterConnected;

  // Notifikasi perubahan koneksi printer
  void _updateConnectionStatus(bool? status) {
    _isPrinterConnected = status;
    notifyListeners();
  }

  Future<void> getDevices() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));
    bluetoothPrint.scanResults.listen((devices) {
      // Handle list of discovered devices
      // Update your devices list here
    });
  }

  Future<void> checkPrinterConnection() async {
    bool? isConnected = await bluetoothPrint.isConnected;
    _updateConnectionStatus(isConnected);
  }

  Future<void> connectToPrinter(BluetoothDevice? device) async {
    if (device != null) {
      try {
        await bluetoothPrint.connect(device);
        _selectedDevice = device;
        await checkPrinterConnection();
      } catch (e) {
        print('Failed to connect to printer: $e');
      }
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      await bluetoothPrint.disconnect();
      await checkPrinterConnection();
      _selectedDevice = null;
    } catch (e) {
      print('Failed to disconnect from printer: $e');
    }
  }

  Future<void> printTest(BuildContext context) async {
    if (_isPrinterConnected == true) {
      try {
        final List<LineText> list = [];
        list.add(LineText(type: LineText.TYPE_TEXT, content: ''));
        await bluetoothPrint.printReceipt({}, list);
      } catch (e) {
        print('Print failed: $e');
      }
    } else {
      // Menampilkan dialog jika printer tidak terhubung
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
    required BuildContext context,
    required String clientName,
    required String guestName,
    required String qrCode,
    required String headcount,
    required String category,
    required String eventDate,
    required String eventTime,
    required String location,
    required String sessionName,
    required String tableName,
  }) async {
    if (_isPrinterConnected!) {
      try {
        final List<LineText> list = [];

        // Menambahkan berbagai LineText ke dalam list
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: clientName,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
        list.add(LineText(
          type: LineText.TYPE_QRCODE,
          content: qrCode,
          size: 250,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Guest Name: $guestName',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Headcount: $headcount',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Category: $category',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Date: $eventDate',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Time: $eventTime',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Location: $location',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Session: $sessionName',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Table: $tableName',
            align: LineText.ALIGN_LEFT));
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'WEDWEB.COM',
          align: LineText.ALIGN_CENTER,
          weight: 1,
          linefeed: 2,
        ));
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '',
        )); // Feed line

        // Jika Anda ingin menambahkan gambar
        // ByteData data = await rootBundle.load("assets/images/guide3.png");
        // List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        // String base64Image = base64Encode(imageBytes);
        // list.add(LineText(type: LineText.TYPE_IMAGE, content: base64Image, align: LineText.ALIGN_CENTER, linefeed: 1));

        await bluetoothPrint.printReceipt({}, list);
      } catch (e) {
        print('Print failed: $e');
      }
    } else {
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
}
