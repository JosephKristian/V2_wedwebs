import 'dart:async';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as android;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:wedweb/screens/dashboard_user_screen.dart';
import 'package:wedweb/widgets/custom_action_button.dart';
import 'update_guest_screen.dart';
import '../models/guest_model.dart';
import '../services/database_helper.dart';
import '../services/printer_service_android.dart'; // Import Printer1Service
import '../services/printer_service_ios.dart'; // Import PrinterServiceIOS
import '../widgets/custom_app_bar.dart';
import '../widgets/styles.dart';
import '../models/session_model.dart';
import '../models/event_model.dart';

class ScanQRScreen extends StatefulWidget {
  final String role;
  final String clientId;
  final String idServer;
  final String clientName;
  final String counterLabel;
  final String name;
  final Event event;
  final Session session;

  ScanQRScreen({
    required this.role,
    required this.name,
    required this.clientId,
    required this.idServer,
    required this.clientName,
    required this.counterLabel,
    required this.event,
    required this.session,
  });

  @override
  _ScanQRScreenState createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  Barcode? result;
  bool isCameraPaused = false;
  List<dynamic> devices = [];
  dynamic selectedDevice;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0, end: 300).animate(_animationController);
    checkPrinterConnection(); // Check printer connection status on init
  }

  @override
  void dispose() {
    qrController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkPrinterConnection() async {
    if (Platform.isAndroid) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as Printer1Service;
      await printerService.checkPrinterConnection();
    } else if (Platform.isIOS) {
      final printerService =
          Provider.of<Printer1Service>(context, listen: false)
              as PrinterServiceIOS;
      await printerService.checkPrinterConnection();
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardUserScreen(
                    idServer: widget.idServer,
                    role: widget.role,
                    event: widget.event,
                    clientId: widget.clientId,
                    clientName: widget.clientName,
                    session: widget.session,
                    name: widget.name,
                  )),
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Scan QR Code',
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
        body: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      QRView(
                        key: qrKey,
                        overlay: QrScannerOverlayShape(
                          borderColor: AppColors.iconColor,
                          borderRadius: 10,
                          borderLength: 30,
                          borderWidth: 10,
                          cutOutSize: 300,
                        ),
                        onQRViewCreated: _onQRViewCreated,
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: LaserPainter(_animation.value, 300),
                            );
                          },
                        ),
                      ),
                      // Tambahkan tombol flip kamera di pojok kanan atas
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: Icon(Icons.flip_camera_android,
                              color: const Color.fromARGB(255, 158, 158, 158)),
                          onPressed: () {
                            setState(() {
                              _flipCamera(); // Fungsi untuk mengganti kamera
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: AppColors.appBarColor,
                    child: Center(
                      child: (result != null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Data: ${result!.code}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Scan a QR code',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: AppColors.iconColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _flipCamera() {
    if (qrController != null) {
      qrController!.flipCamera(); // Fungsi flip camera dari controller QRView
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;

    controller.flipCamera();

    controller.scannedDataStream.listen((scanData) async {
      if (!isCameraPaused) {
        setState(() {
          isCameraPaused = true;
          result = scanData;
        });
        await _findGuest(scanData.code);
      }
    });
  }

  Future<void> _findGuest(String? qrCode) async {
    if (qrCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR code')),
      );
      _resumeCamera();
      return;
    }

    try {
      final db = await DatabaseHelper().database;

      // Mencari guest berdasarkan qrCode
      final List<Map<String, dynamic>> maps = await db.query(
        'Guest',
        where: 'guest_qr = ?',
        whereArgs: [qrCode],
      );

      if (maps.isNotEmpty) {
        final guest = Guest.fromMap(maps[0]);

        // Mencari client berdasarkan clientId
        final List<Map<String, dynamic>> clientMaps = await db.query(
          'Client',
          where: 'client_id = ?',
          whereArgs: [widget.clientId],
        );

        if (clientMaps.isNotEmpty) {
          if (guest.client_id.isNotEmpty) {
            // Mengecek apakah guest terdaftar untuk sesi yang dipilih
            final List<Map<String, dynamic>> checkInMaps = await db.query(
              'check_in',
              where: 'guest_id = ? AND session_id = ?',
              whereArgs: [guest.guest_id, widget.session.session_id],
            );

            // Mengecek status check-in
            if (checkInMaps.isNotEmpty) {
              final checkInStatus =
                  checkInMaps[0]['status']; // Ambil status dari hasil query

              if (checkInStatus != 'not check-in yet') {
                // Jika statusnya 'checked-in', tampilkan popup
                qrController?.pauseCamera();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Check-in Status'),
                      content: Text('The guest has already checked in.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Tutup dialog
                            _resumeCamera(); // Jalankan kembali kamera
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                // Jika statusnya bukan 'checked-in', lanjutkan ke UpdateGuestScreen
                qrController?.pauseCamera();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateGuestScreen(
                      guestId: guest.guest_id!,
                      idServer: widget.idServer,
                      role: widget.role,
                      name: widget.name,
                      event: widget.event,
                      clientId: widget.clientId,
                      clientName: widget.clientName,
                      counterLabel: widget.counterLabel,
                      session: widget.session,
                    ),
                  ),
                );
                _resumeCamera();
              }
            } else {
              // Jika tidak terdaftar, tampilkan dialog
              qrController?.pauseCamera();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Registration Status'),
                    content:
                        Text('The guest is not registered for this session.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog
                          _resumeCamera(); // Jalankan kembali kamera
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            // Jika tamu tidak milik client, tampilkan dialog
            qrController?.pauseCamera();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Client Mismatch'),
                  content: Text('The guest does not belong to this client.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup dialog
                        _resumeCamera(); // Jalankan kembali kamera
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          // Jika client tidak ditemukan, tampilkan dialog
          qrController?.pauseCamera();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Client Not Found'),
                content: Text('Client not found.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog
                      _resumeCamera(); // Jalankan kembali kamera
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Jika tamu tidak ditemukan, tampilkan dialog
        qrController?.pauseCamera();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Guest Not Found'),
              content:
                  Text('No matching guest found for the provided QR code.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    _resumeCamera(); // Jalankan kembali kamera
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error during database query: $e');
      // Menampilkan dialog untuk kesalahan
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while finding the guest.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  _resumeCamera(); // Jalankan kembali kamera
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      _resumeCamera();
    }
  }

  void _resumeCamera() {
    setState(() {
      isCameraPaused = false;
      result = null;
    });
    qrController?.resumeCamera();
    checkPrinterConnection(); // Refresh printer connection status
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

class LaserPainter extends CustomPainter {
  final double position;
  final double cutOutSize;

  LaserPainter(this.position, this.cutOutSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.iconColorWarning.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final double topOffset = (size.height - cutOutSize) / 2;
    final double leftOffset = (size.width - cutOutSize) / 2;
    final double laserY = topOffset + position;

    if (laserY > topOffset && laserY < topOffset + cutOutSize) {
      for (int i = 0; i < 5; i++) {
        final double offset = i * 10;
        final double opacity = 0.8 - i * 0.15;

        // Draw line above the main laser line
        final double aboveY = laserY - offset;
        if (aboveY > topOffset && aboveY < topOffset + cutOutSize) {
          paint.color = Colors.red.withOpacity(opacity);
          canvas.drawLine(
            Offset(leftOffset, aboveY),
            Offset(leftOffset + cutOutSize, aboveY),
            paint,
          );
        }

        // Draw line below the main laser line
        final double belowY = laserY + offset;
        if (belowY > topOffset && belowY < topOffset + cutOutSize) {
          paint.color = Colors.red.withOpacity(opacity);
          canvas.drawLine(
            Offset(leftOffset, belowY),
            Offset(leftOffset + cutOutSize, belowY),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
