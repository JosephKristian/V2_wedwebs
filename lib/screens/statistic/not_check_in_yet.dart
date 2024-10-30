import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class NotCheckInYet extends StatefulWidget {
  final String idServer;
  final String sessionId;
  final int totalkey;
  final String guestKey = 'not check-in yet';

  NotCheckInYet(
      {required this.idServer,
      required this.sessionId,
      required this.totalkey});

  @override
  _NotCheckInYetScreenState createState() => _NotCheckInYetScreenState();
}

class _NotCheckInYetScreenState extends State<NotCheckInYet> {
  late Future<List<Map<String, dynamic>>> _guestsFuture;

  @override
  void initState() {
    super.initState();
    _guestsFuture =
        DatabaseHelper.instance.getGuestCI(widget.sessionId, widget.guestKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 146, 61, 55),
        foregroundColor: Color.fromARGB(255, 250, 202, 139),
        title: Text('Not Checked-In Yet (${widget.totalkey})'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _guestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No RSVP pending guests found.'));
          } else {
            List<Map<String, dynamic>> guests = snapshot.data!;
            return ListView.builder(
              itemCount: guests.length,
              itemBuilder: (context, index) {
                final guest = guests[index];
                return ListTile(
                  title: Text(guest['guest_name'] ?? 'No name'),
                  subtitle: Text('Phone: ${guest['phone'] ?? 'N/A'}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
