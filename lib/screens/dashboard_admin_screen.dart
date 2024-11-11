import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wedwebs/screens/intro_user_screen.dart';
import '../widgets/bottom_navigation_page.dart';
import '../services/dropdown_provider.dart';

class DashboardAdminScreen extends StatefulWidget {
  final String role;
  final String idServer;
  final String name;

  DashboardAdminScreen(
      {required this.name, required this.role, required this.idServer});

  @override
  _DashboardAdminScreenState createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.role != 'admin') {
      return IntroUserScreen(
        idServer: widget.idServer,
        role: widget.role,
        name: widget.name,
      );
    }

    return ChangeNotifierProvider(
      create: (_) => DropdownProvider(),
      child: BottomNavigationPage(
        idServer: widget.idServer,
        role: widget.role,
      ),
    );
  }
}
