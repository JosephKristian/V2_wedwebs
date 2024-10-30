import 'package:flutter/material.dart';
import '../../widgets/styles.dart';
import '../../services/data_service.dart';
import '../../services/database_helper.dart';

class GuestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> guest;
  final String idServer;

  const GuestDetailScreen(
      {Key? key, required this.guest, required this.idServer})
      : super(key: key);

  @override
  _GuestDetailScreenState createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  final DataService _dataService = DataService();
  Map<String, dynamic>? _guestDetails;

  @override
  void initState() {
    super.initState();
    _fetchGuestDetails(widget.guest['guest_id']);
  }

  Future<void> _fetchGuestDetails(String guestId) async {
    final dbHelper = DatabaseHelper();
    final details = await dbHelper.getGuestDetails(guestId);
    print('Fetched details: $details'); // Debug output
    setState(() {
      _guestDetails = details;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_guestDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text('Guest Details', style: AppStyles.titleCardPrimaryTextStyle),
          backgroundColor: AppColors.appBarColor,
          foregroundColor: AppColors.backgroundColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final guest = widget.guest;
    final sessions = _guestDetails?['sessions'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Guest Details', style: AppStyles.titleCardPrimaryTextStyle),
        backgroundColor: AppColors.appBarColor,
        foregroundColor: AppColors.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: AppColors.bottomAppBarColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: AppColors.iconColor),
                  title:
                      Text('Name', style: AppStyles.titleCardPrimaryTextStyle),
                  subtitle: Text(
                    guest['name']?.isEmpty ?? true ? '-' : guest['name'],
                    style: AppStyles.bodyTextStyle,
                  ),
                ),
                Divider(color: AppColors.dividerColor),
                ListTile(
                  leading: Icon(Icons.email, color: AppColors.iconColor),
                  title:
                      Text('Email', style: AppStyles.titleCardPrimaryTextStyle),
                  subtitle: Text(
                    guest['email']?.isEmpty ?? true ? '-' : guest['email'],
                    style: AppStyles.bodyTextStyle,
                  ),
                ),
                Divider(color: AppColors.dividerColor),
                ListTile(
                  leading: Icon(Icons.phone, color: AppColors.iconColor),
                  title:
                      Text('Phone', style: AppStyles.titleCardPrimaryTextStyle),
                  subtitle: Text(
                    guest['phone']?.isEmpty ?? true ? '-' : guest['phone'],
                    style: AppStyles.bodyTextStyle,
                  ),
                ),
                Divider(color: AppColors.dividerColor),
                ListTile(
                  leading: Icon(Icons.group, color: AppColors.iconColor),
                  title:
                      Text('Pax', style: AppStyles.titleCardPrimaryTextStyle),
                  subtitle: Text(
                    guest['pax']?.toString().isEmpty ?? true
                        ? '-'
                        : guest['pax'].toString(),
                    style: AppStyles.bodyTextStyle,
                  ),
                ),
                Divider(color: AppColors.dividerColor),
                // Display RSVP status for each session
                if (sessions.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index] as Map<String, dynamic>;
                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                session['rsvp'] == '1'
                                    ? Icons.check_circle
                                    : Icons.pending_actions_rounded,
                                color: session['rsvp'] == '1'
                                    ? AppColors.iconColor
                                    : AppColors.iconColorWarning,
                              ),
                              title: Text(
                                session['session_name'] ?? 'Session',
                                style: AppStyles.titleCardPrimaryTextStyle,
                              ),
                              subtitle: Text(
                                session['rsvp'] == '1'
                                    ? 'Already Confirmed'
                                    : (session['rsvp']?.isEmpty ?? true
                                        ? '-'
                                        : session['rsvp']),
                                style: AppStyles.bodyTextStyle.copyWith(
                                  color: session['rsvp'] == '1'
                                      ? AppColors.textColor
                                      : Colors.red,
                                ),
                              ),
                            ),
                            Divider(color: AppColors.dividerColor),
                          ],
                        );
                      },
                    ),
                  ),
                ListTile(
                  leading: Icon(Icons.category, color: AppColors.iconColor),
                  title: Text('Category',
                      style: AppStyles.titleCardPrimaryTextStyle),
                  subtitle: Text(
                    guest['cat']?.isEmpty ?? true ? '-' : guest['cat'],
                    style: AppStyles.bodyTextStyle,
                  ),
                ),
                Divider(color: AppColors.dividerColor),
                ListTile(
                  leading: Icon(Icons.table_chart, color: AppColors.iconColor),
                  title: Text('Tables',
                      style: AppStyles.titleCardPrimaryTextStyle),
                  subtitle: Text(
                    guest['tables']?.isEmpty ?? true ? '-' : guest['tables'],
                    style: AppStyles.bodyTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
