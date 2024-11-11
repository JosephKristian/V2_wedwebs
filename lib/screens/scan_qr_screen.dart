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
  bool flip = true;

  @override
  void initState() {
    super.initState();
    // Log parameter yang diterima
    print('ScanQRScreen initialized with:');
    print('role: ${widget.role}');
    print('name: ${widget.name}');
    print('clientId: ${widget.clientId}');
    print('idServer: ${widget.idServer}');
    print('clientName: ${widget.clientName}');
    print('counterLabel: ${widget.counterLabel}');
    print('event: ${widget.event}');
    print('session: ${widget.session}');
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0, end: 300).animate(_animationController);
  }

  @override
  void dispose() {
    qrController?.dispose();
    _animationController.dispose();
    super.dispose();
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
                        cameraFacing: CameraFacing.front,
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

  // Fungsi untuk melakukan flip camera
  void _flipCamera() {
    if (qrController != null) {
      print('CHECKSCANNER: Flipping camera...');
      qrController!.flipCamera(); // Fungsi flip camera dari controller QRView
    } else {
      print('CHECKSCANNER: qrController is null. Cannot flip camera.');
    }
  }

  Future<void> _flip() async {
    print('CHECKSCANNER: _flip() called.');
    if (qrController == null) {
      print('CHECKSCANNER: qrController is null. Cannot flip camera.');
      return;
    }

    if (Platform.isIOS && flip == true) {
      try {
        print('CHECKSCANNER: Flipping camera for iOS...');
        await qrController!.flipCamera(); // Tunggu sampai flip selesai
        setState(() {
          flip = false; // Update flip state
        });
        print('CHECKSCANNER: Camera flipped successfully.');
      } catch (e) {
        print('CHECKSCANNER: Error flipping camera: $e');
      }
    } else if (!Platform.isIOS) {
      print('CHECKSCANNER: Platform is not iOS, skipping flip.');
    } else if (flip == false) {
      print('CHECKSCANNER: Flip already done, skipping.');
    }
  }

  void _onQRViewCreated(QRViewController controller) async {
    print('CHECKSCANNER: QRView created, initializing controller.');
    qrController = controller;

    controller.scannedDataStream.listen((scanData) async {
      print('CHECKSCANNER: Scanning data...');
      if (!isCameraPaused) {
        _flip();
        setState(() {
          isCameraPaused = true;
          result = scanData;
        });
        print('CHECKSCANNER: QR code scanned: ${scanData.code}');
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

      final urlPattern =
          r"^https:\/\/rsvp\.wed-webs\.com\/tamu\/([a-zA-Z0-9\-]+)$";
      final regExp = RegExp(urlPattern);

      if (regExp.hasMatch(qrCode)) {
        // Jika qrCode adalah URL yang valid, ambil GUESTID
        final guestId = regExp.firstMatch(qrCode)?.group(1);

        if (guestId != null) {
          // Ubah qrCode menjadi GUESTID yang ditemukan dalam URL
          qrCode = guestId;
        }
      }

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
              content: Text(
                  'No matching guest found for the provided QR code. (${qrCode})'),
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
