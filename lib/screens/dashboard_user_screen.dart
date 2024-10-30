import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import '../widgets/bottom_navigation_page_user.dart';
import '../services/dropdown_provider_user.dart';

class DashboardUserScreen extends StatefulWidget {
  final String role;
  final String idServer;
  final String name;
  final Session session;
  final Event event;
  final String clientName;
  final String clientId;

  DashboardUserScreen(
      {required this.session,
      required this.event,
      required this.clientId,
      required this.clientName,
      required this.name,
      required this.role,
      required this.idServer});

  @override
  _DashboardUserScreenState createState() => _DashboardUserScreenState();
}

class _DashboardUserScreenState extends State<DashboardUserScreen> {
  @override
  Widget build(BuildContext context) {
    // if (widget.role != 'admin') {
    //   return RoleSelectionScreen(
    //     idServer: widget.idServer,
    //   );
    // }

    return ChangeNotifierProvider(
      create: (_) => DropdownProviderUser(),
      child: BottomNavigationPageUser(
        idServer: widget.idServer,
        role: widget.role,
        name: widget.name,
        session: widget.session,
        event: widget.event,
        clientId: widget.clientId,
        clientName: widget.clientName,
      ),
    );
  }
}
