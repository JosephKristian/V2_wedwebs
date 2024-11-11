import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterServiceIOS with ChangeNotifier {
  PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  BluetoothManager bluetoothManager = BluetoothManager.instance;
  PrinterBluetooth? _selectedDevice;
  List<PrinterBluetooth> _devices = [];
  bool? _isPrinterConnected;
  String? _devicesMsg;
  CapabilityProfile? _profile;

  List<PrinterBluetooth> get devices => _devices;
  PrinterBluetooth? get selectedDevice => _selectedDevice;
  bool? get isPrinterConnected => _isPrinterConnected;

  // Menyimpan perangkat printer ke SharedPreferences
  Future<void> _saveDevice(PrinterBluetooth device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_name', device.name!);
    await prefs.setString('device_address', device.address!);
    await prefs.setString('device_type', device.type.toString());
  }

  // Memuat perangkat printer yang disimpan dari SharedPreferences
  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('device_name');
    String? address = prefs.getString('device_address');
    String? type = prefs.getString('device_type');

    if (name != null && address != null && type != null) {
      final BluetoothDevice device = BluetoothDevice(
        name: name,
        address: address,
        type: int.tryParse(type) ?? 0,
      );

      _selectedDevice = PrinterBluetooth(device);
      notifyListeners();
    }
  }

// Memindai perangkat Bluetooth
  Future<void> getDevices({bool refresh = true}) async {
    if (refresh) {
      _printerManager.startScan(Duration(seconds: 2));
      _printerManager.scanResults.listen((devices) {
        _devices = devices;
        _devicesMsg = _devices.isEmpty ? 'No devices found' : null;
        notifyListeners();
      });

      await Future.delayed(
          Duration(seconds: 2)); // Memperpendek durasi pemindaian
      _printerManager.stopScan();
    }
  }

  // Memilih perangkat printer
  Future<void> selectDevice(PrinterBluetooth device) async {
    _selectedDevice = device;
    await _saveDevice(device); // Simpan perangkat yang dipilih
    _printerManager.selectPrinter(
        device); // Pass the PrinterBluetooth object, not device.device
    notifyListeners();
  }

  // Mengecek status koneksi printer
  Future<void> checkPrinterConnection() async {
    await _loadSavedDevice();
    final profile = await _getProfile();
    debugPrint("PROFILBLUETOOTHDEVICES: ${profile.toString()}");

    bool? isConnected = true;
    _isPrinterConnected = isConnected;
    notifyListeners();
  }

  // Menghubungkan ke printer
  Future<void> connectToPrinter(PrinterBluetooth device) async {
    if (_selectedDevice == null || _selectedDevice != device) {
      try {
        await bluetoothManager.connect(device.device);
        _selectedDevice = device;
        _saveDevice(device); // Simpan ke SharedPreferences
        _printerManager.selectPrinter(device);
        await checkPrinterConnection(); // Cek jika berhasil terhubung
      } catch (e) {
        print('Failed to connect to printer: $e');

        // Jika gagal terhubung, set _isPrinterConnected menjadi false
        _isPrinterConnected = false;
        notifyListeners(); // Memberitahukan perubahan status
      }
    }
  }

  // // Memutuskan koneksi printer
  // Future<void> disconnectPrinter() async {
  //   try {
  //     await bluetoothManager.disconnect();
  //     _selectedDevice = null;
  //     _isPrinterConnected = false;
  //     notifyListeners();
  //   } catch (e) {
  //     print('Failed to disconnect from printer: $e');
  //   }
  // }

  // Mencetak tiket uji
  Future<void> printTest(BuildContext context) async {
    if (_selectedDevice != null) {
      try {
        // Cek koneksi terlebih dahulu
        await checkPrinterConnection();
        if (_isPrinterConnected == false) {
          await connectToPrinter(_selectedDevice!);
        }

        // Setelah memastikan koneksi, baru generate dan print tiket
        final ticket = await _generateTestTicket();
        await _printerManager.printTicket(ticket);

        // Setelah print selesai, tampilkan success dialog
        _showAlert(context, 'Print Successful');
      } catch (e) {
        print('Print failed: $e');
        _showAlert(context, 'Error: $e');
      } finally {
        // Tutup loading dialog setelah proses selesai
        Navigator.pop(context);
      }
    } else {
      _showAlert(context, 'Printer Not Connected');
    }
  }

// Fungsi untuk menampilkan dialog loading
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Agar dialog tidak bisa ditutup dengan mengetuk di luar
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Printing...'),
          content: Row(
            children: [
              CircularProgressIndicator(), // Menampilkan loading spinner
              SizedBox(width: 20),
              Text('Please wait while the ticket is printing...'),
            ],
          ),
        );
      },
    );
  }

// Fungsi pembantu untuk mempermudah penggunaan dialog alert
  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: Text(message)),
    );
  }

  Future<CapabilityProfile> _getProfile() async {
    if (_profile == null) {
      _profile = await CapabilityProfile.load();
    }
    return _profile!;
  }

  // Membuat tiket uji
  Future<List<int>> _generateTestTicket() async {
    final profile = await _getProfile();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'Test Print',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.text(
      'Thank you',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.cut();

    return bytes;
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

    if (_isPrinterConnected!) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isQrEnabled = prefs.getBool('qr_enabled') ?? false;

        // Ambil profile printer
        final profile = await _getProfile();
        final generator = Generator(PaperSize.mm80, profile);
        List<int> bytes = [];

        // Menambahkan teks utama
        bytes += generator.text(
          '$clientName',
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
        );
        bytes += generator.feed(1);

        // Menambahkan QR Code jika diaktifkan
        if (isQrEnabled) {
          bytes += generator.qrcode(qrCode);
        }

        bytes += generator.feed(1);

        // Menambahkan detail lainnya
        bytes += generator.text(
          'Guest Name: $guestName',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Headcount: $headcount',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);
        bytes += generator.text(
          'Category: $category',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Cat. Number: $catNumber',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Date: $eventDate',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Check-in time: $eventTime ($checkInTime)',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);
        bytes += generator.text(
          'Location: $location',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Session: $sessionName',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);
        bytes += generator.text(
          'Table: $tableName',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Angpau Label: $angpauLabel',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(2);

        // Menambahkan footer
        bytes += generator.text(
          'wedwebs.com',
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
        );
        bytes += generator.feed(2);
        bytes += generator.cut();

        // Mengirimkan tiket yang sudah jadi ke printer
        await _printerManager.printTicket(bytes);

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

    if (_isPrinterConnected!) {
      try {
        // Ambil preferences untuk QR code enable/disable
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isQrEnabled = prefs.getBool('qr_enabled') ?? false;

        // Ambil profile printer dan buat generator
        final profile = await _getProfile();
        final generator = Generator(PaperSize.mm80, profile);
        List<int> bytes = [];

        // Menambahkan header
        bytes += generator.text(
          'E-TICKET',
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
        );
        bytes += generator.feed(1);

        // Menambahkan QR Code jika diaktifkan
        if (isQrEnabled) {
          bytes += generator.qrcode('${guest['guest_qr']}');
        }

        bytes += generator.feed(1);

        // Menambahkan informasi lainnya
        bytes += generator.text(
          'Guest Name: ${guest['name']}',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Headcount: ${guestDetails!['sessions'][0]['pax_checked'].toString()}',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Category: ${guest['cat']}',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          '$checkInTime',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);

        bytes += generator.text(
          'Angpau Label: ${guestDetails['sessions'][0]['angpau_label'].toString()} (${angpauTitipan})',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);

        // Footer
        bytes += generator.text(
          'WEDWEB.COM',
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
        );
        bytes += generator.feed(2);
        bytes += generator.cut();

        // Mengirim tiket ke printer
        await _printerManager.printTicket(bytes);
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

    if (_isPrinterConnected!) {
      try {
        // Ambil preferences untuk QR code enable/disable
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isQrEnabled = prefs.getBool('qr_enabled') ?? false;

        // Ambil profile printer dan buat generator
        final profile = await _getProfile();
        final generator = Generator(PaperSize.mm80, profile);
        List<int> bytes = [];

        // Menambahkan header
        bytes += generator.text(
          'E-TICKET',
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
        );
        bytes += generator.feed(1);

        // Menambahkan QR Code jika diaktifkan
        if (isQrEnabled) {
          bytes += generator.qrcode('${guest['guest_qr']}');
        }

        bytes += generator.feed(1);

        // Menambahkan informasi lainnya
        bytes += generator.text(
          'Guest Name: ${guest['name']}',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Headcount: ', // Jika tidak ada headcount, bisa dikosongkan atau ditambahkan data lain
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          'Category: ${guest['cat'] ?? 'blank'}',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.text(
          '$timeCheckedIn',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);

        bytes += generator.text(
          'Angpau Label: ${guest['angpau_label']} (${guest['angpauTitipan'] ?? ''})',
          styles: PosStyles(align: PosAlign.left),
        );
        bytes += generator.feed(1);

        // Footer
        bytes += generator.text(
          'WEDWEB.COM',
          styles: PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2),
        );
        bytes += generator.feed(2);
        bytes += generator.cut();

        // Mengirim tiket ke printer
        await _printerManager.printTicket(bytes);
        print('Ticket printed successfully');
      } catch (e) {
        print('Error printing ticket: $e');
      }
    } else {
      print('Printer not connected');
    }
  }

  @override
  void dispose() {
    _printerManager.stopScan();
    super.dispose();
  }
}
