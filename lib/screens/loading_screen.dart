import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/intro_user_screen.dart';
import '../services/database_helper.dart';
import '../services/data_service.dart';

class LoadingScreen extends StatefulWidget {
  final String idServer;
  final String role;
  final String superKey;
  final String name;

  LoadingScreen(
      {required this.idServer,
      required this.role,
      required this.superKey,
      required this.name});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Start the async operation
    _startLoadingProcess();
  }

  Future<void> _startLoadingProcess() async {
    // Tunggu hingga penyisipan selesai
    await _insertIdServer();
    await _syncData();

    // Setelah penyisipan selesai, mulai timer untuk navigasi
    Timer(Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IntroUserScreen(
            idServer: widget.idServer,
            role: widget.role,
            name: widget.name,
          ),
        ),
      );
    });
  }

  Future<void> _syncData() async {
    final _dataService = DataService();
    List<Future<void>> syncTasks = [
      _dataService.checkAndSyncClients(widget.idServer),
      _dataService.checkAndSyncEvents(widget.idServer),
      _dataService.checkAndSyncEventsSessionsTables(widget.idServer),
      _dataService.checkAndSyncGuests(widget.idServer),
      _dataService.checkAndSyncUshers(widget.idServer),
    ];

    await Future.wait(syncTasks.take(2));
  }

  Future<void> _insertIdServer() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.insertIdServer(
        widget.idServer, widget.superKey, widget.role, widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.14, // Rotate full circle
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Transform.scale(
                    scale: 1 + _controller.value, // Scale animation
                    child: Image.asset(
                      'assets/images/background.jpg',
                      width: 120.0,
                      height: 100.0,
                      fit: BoxFit.fill,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
