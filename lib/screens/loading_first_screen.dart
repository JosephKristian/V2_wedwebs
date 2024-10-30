import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wedweb/screens/intro_user_screen.dart';
import 'dashboard_user_screen.dart';
import '../models/session_model.dart';
import 'dashboard_admin_screen.dart';
import 'dashboard_f_user_screen.dart';
import 'user_auth/user_login_screen.dart';
import '../services/database_helper.dart';

class LoadingFirstScreen extends StatefulWidget {
  LoadingFirstScreen();

  @override
  _LoadingFirstScreenState createState() => _LoadingFirstScreenState();
}

class _LoadingFirstScreenState extends State<LoadingFirstScreen>
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

    _navigateBasedOnIdServer();
  }

  Future<Widget> _getNextScreen(String? idServerFromLocalDB,
      String? roleServerFromLocalDB, String? nameServerFromLocalDB) async {
    final dbHelper = DatabaseHelper.instance;

    if (idServerFromLocalDB != null && idServerFromLocalDB.isNotEmpty) {
      // Jika ada data idServer, cek role
      if (roleServerFromLocalDB == 'admin') {
        // Jika role adalah admin, navigasi ke DashboardAdminScreen
        return DashboardAdminScreen(
          idServer: idServerFromLocalDB,
          role: roleServerFromLocalDB!,
          name: nameServerFromLocalDB!,
        );
      } else if (roleServerFromLocalDB == 'usher') {
        // Jika role adalah usher, cek data dari Pages_tempo
        final pageData = await dbHelper.getPageData(idServerFromLocalDB);
        if (pageData != null) {
          // Jika pageData tidak null, ambil session dari data
          final Session session = pageData['session'];

          // Navigasi ke DashboardFUserScreen dengan data yang diperoleh
          return DashboardUserScreen(
            session: session,
            event: pageData['event'], // Ambil event dari pageData
            clientId: pageData['clientId'],
            role: roleServerFromLocalDB!,
            name: nameServerFromLocalDB!,
            idServer: idServerFromLocalDB,
            clientName: pageData['clientName'],
          );
        } else {
          // Jika pageData null, navigasi ke DashboardUserScreen
          return IntroUserScreen(
            idServer: idServerFromLocalDB,
            role: roleServerFromLocalDB!,
            name: nameServerFromLocalDB!,
          );
        }
      } else {
        // Jika role tidak dikenali, navigasi ke UserLoginScreen
        return UserLoginScreen();
      }
    } else {
      // Jika tidak ada data idServer, navigasi ke UserLoginScreen
      return UserLoginScreen();
    }
  }

  Future<void> _navigateBasedOnIdServer() async {
    final dbHelper = DatabaseHelper.instance;
    final idServerFromLocalDB = await dbHelper.getIdServer();
    final roleServerFromLocalDB = await dbHelper.getRoleServer();
    final nameServerFromLocalDB = await dbHelper.getNameServer();

    Timer(Duration(seconds: 6), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return FutureBuilder<Widget>(
              future: _getNextScreen(idServerFromLocalDB, roleServerFromLocalDB,
                  nameServerFromLocalDB),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Tampilkan loading indicator saat menunggu hasil
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Tangani error
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  // Kembalikan widget yang diperoleh dari _getNextScreen
                  return snapshot.data!;
                }
              },
            );
          },
        ),
      );
    });
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
