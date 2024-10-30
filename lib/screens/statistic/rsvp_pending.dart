import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_helper.dart';
import '../../services/generate_link_rsvp.dart';

class RsvpPending extends StatefulWidget {
  final String idServer;
  final String sessionId;
  final int totalkey;
  final String rsvpKey = 'pending';

  RsvpPending(
      {required this.idServer,
      required this.sessionId,
      required this.totalkey});

  @override
  _RsvpPendingScreenState createState() => _RsvpPendingScreenState();
}

class _RsvpPendingScreenState extends State<RsvpPending> {
  late Future<List<Map<String, dynamic>>> _guestsFuture;

  @override
  void initState() {
    super.initState();
    _guestsFuture =
        DatabaseHelper.instance.getGuestRsvp(widget.sessionId, widget.rsvpKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 180, 119, 27),
        foregroundColor: Color.fromARGB(255, 250, 202, 139),
        title: Text('RSVP Pending (${widget.totalkey})'),
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
