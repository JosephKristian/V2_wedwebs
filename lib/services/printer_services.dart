import 'dart:async';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as thermal;
import 'package:shared_preferences/shared_preferences.dart';

class PrinterServices {
  final thermal.BlueThermalPrinter _printer = thermal.BlueThermalPrinter.instance;

  Future<void> clearSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('printer_address');
  }

  Future<void> saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_address', address);
  }

  Future<List<thermal.BluetoothDevice>> getBondedDevices() async {
    return await _printer.getBondedDevices();
  }

  Future<String?> loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('printer_address');
  }

  Future<bool> isPrinterConnected() async {
    String? address = await loadSavedAddress();
    if (address == null) {
      print('No saved address found.');
      return false;
    }

    // Memeriksa status koneksi printer secara manual
    List<thermal.BluetoothDevice> devices = await _printer.getBondedDevices();
    for (var device in devices) {
      if (device.address == address) {
        final isConnected = await _printer.isConnected;
        print('Checking connection for device ${device.name} (${device.address}): $isConnected');
        return isConnected ?? false;
      }
    }
    print('Device with address $address not found.');
    return false;
  }

  Future<void> feedPrinter(String address) async {
    try {
      List<int> feedCommand = [0x1B, 0x64, 0x02]; // ESC d n command (feed n lines), where n = 2

      print('Sending feed command: $feedCommand to printer with address: $address');

      final List<thermal.BluetoothDevice> devices = await _printer.getBondedDevices();
      thermal.BluetoothDevice? device;
      for (var d in devices) {
        if (d.address == address) {
          device = d;
          break;
        }
      }

      if (device != null) {
        final isConnected = await _printer.isConnected;
        if (!isConnected!) {
          await _printer.connect(device);
        }

        await _printer.writeBytes(Uint8List.fromList(feedCommand));
        await Future.delayed(Duration(milliseconds: 500));

        if (!isConnected!) {
          await _printer.disconnect();
        }
        print('Feed command sent to printer.');
      } else {
        print('Device not found.');
      }
    } catch (e) {
      print('Error sending feed command: $e');
    }
  }

  Future<void> connectToSavedDevice() async {
    String? address = await loadSavedAddress();
    if (address != null) {
      final List<thermal.BluetoothDevice> devices = await _printer.getBondedDevices();
      thermal.BluetoothDevice? device;
      for (var d in devices) {
        if (d.address == address) {
          device = d;
          break;
        }
      }

      if (device != null) {
        try {
          bool isConnected = await _printer.isConnected ?? false;
          print('Current connection status before connecting: $isConnected');
          if (!isConnected) {
            await _printer.connect(device);
            print('Connected to device: ${device.address}');
            isConnected = await _printer.isConnected ?? false;
            print('Connection status after connecting: $isConnected');
            await feedPrinter(address);
          } else {
            print('Device is already connected.');
          }
        } catch (e) {
          print('Failed to connect to device: $e');
        }
      } else {
        print('Device not found.');
      }
    }
  }
}
