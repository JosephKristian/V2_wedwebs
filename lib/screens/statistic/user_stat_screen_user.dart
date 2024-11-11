import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/widgets/custom_app_bar.dart';
import 'guest_attendance.dart';
import 'not_check_in_yet.dart';
import 'rsvp_pending.dart';
import 'rsvp_attend.dart';
import 'rsvp_unable_attend.dart';
import '../../widgets/styles.dart';
import '../../services/data_service.dart';
import '../../services/dropdown_provider_user.dart';

class UserStatScreenUser extends StatefulWidget {
  final String idServer;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final String role;
  final String name;
  final Session session;
  final Event event;
  final String clientName;
  final String counterLabel;
  final String clientId;

  UserStatScreenUser({
    required this.idServer,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.session,
    required this.event,
    required this.clientId,
    required this.clientName,
    required this.counterLabel,
    required this.name,
    required this.role,
  });

  @override
  _UserStatScreenUserState createState() => _UserStatScreenUserState();
}

class _UserStatScreenUserState extends State<UserStatScreenUser>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isDropdownVisible = false;
  String _selectedAbjad = 'A';
  final DataService _dataService = DataService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dropdownProvider =
          Provider.of<DropdownProviderUser>(context, listen: false);
      // Setting initial data pada provider tanpa perlu memilih dropdown lagi
      dropdownProvider.setSelectedClient(
          {'client_id': widget.clientId, 'name': widget.clientName});
      dropdownProvider.setSelectedEvent({
        'event_id': widget.event.event_id,
        'event_name': widget.event.event_name
      });
      dropdownProvider.setSelectedSession({
        'session_id': widget.session.session_id,
        'session_name': widget.session.session_name
      });
      dropdownProvider.startStatisticsUpdater();
      _loadAbjadSetting();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  Future<void> _loadAbjadSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAbjad = prefs.getString('angpau_abjad') ?? 'A';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Consumer<DropdownProviderUser>(
                builder: (context, dropdownProvider, child) {
                  final data =
                      dropdownProvider.statisticsData; // Ambil data statistik
                  if (data == null || data.isEmpty) {
                    return Center(
                        child: Text(
                      "No data available. select session on filter button first!",
                      style: AppStyles.drawerItemTextStyle,
                      textAlign: TextAlign.center,
                    ));
                  } else {
                    print("Statistics Data: $data"); // Log data statistik
                    return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _animation.value,
                            child: ListView(
                              key: ValueKey<Map<String, dynamic>>(data),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: screenWidth * 0.12),
                                  child: Center(
                                    child: Text(
                                      "${data['event_name']}",
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.iconColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                AspectRatio(
                                  aspectRatio: 1.6,
                                  child: Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 1.6,
                                        child: PieChart(
                                          PieChartData(
                                            sections: [
                                              PieChartSectionData(
                                                color: Colors.white,
                                                value: data['total_guests']
                                                    .toDouble(),
                                                title:
                                                    'Total Invitation ${data['total_guests']}'
                                                        .toString(),
                                                radius: 210,
                                                titleStyle: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      AspectRatio(
                                        aspectRatio: 1.6,
                                        child: PieChart(
                                          PieChartData(
                                            sections: [
                                              PieChartSectionData(
                                                color: Color.fromARGB(
                                                    255, 36, 89, 134),
                                                value:
                                                    (data['total_guest_attendance']
                                                            ?.toDouble()) ??
                                                        0.0,
                                                radius: 35,
                                                title:
                                                    (data['total_guest_attendance']
                                                            ?.toString()) ??
                                                        '0',
                                                titleStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              PieChartSectionData(
                                                color: Color.fromARGB(
                                                    255, 146, 61, 55),
                                                value:
                                                    (data['total_not_checked_in']
                                                            ?.toDouble()) ??
                                                        0.0,
                                                radius: 35,
                                                title:
                                                    (data['total_not_checked_in']
                                                            ?.toString()) ??
                                                        '0',
                                                titleStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              PieChartSectionData(
                                                color: Color.fromARGB(
                                                    255, 94, 126, 95),
                                                value:
                                                    (data['total_rsvp_attend']
                                                            ?.toDouble()) ??
                                                        0.0,
                                                radius: 35,
                                                title:
                                                    (data['total_rsvp_attend']
                                                            ?.toString()) ??
                                                        '0',
                                                titleStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              PieChartSectionData(
                                                color: Color.fromARGB(
                                                    255, 210, 71, 117),
                                                value:
                                                    (data['total_rsvp_unable_attend']
                                                            ?.toDouble()) ??
                                                        0.0,
                                                radius: 35,
                                                title:
                                                    (data['total_rsvp_unable_attend']
                                                            ?.toString()) ??
                                                        '0',
                                                titleStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              PieChartSectionData(
                                                color: Color.fromARGB(
                                                    255, 180, 119, 27),
                                                value:
                                                    (data['total_rsvp_pending']
                                                            ?.toDouble()) ??
                                                        0.0,
                                                radius: 35,
                                                title:
                                                    (data['total_rsvp_pending']
                                                            ?.toString()) ??
                                                        '0',
                                                titleStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 25),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 20.0),
                                  child: GridView.count(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: [
                                      StatCardCustom(
                                        title: "Guest Attendance",
                                        value: data['total_guest_attendance']
                                            .toString(),
                                        valuePax: (data['total_pax_checked']
                                            .toString()),
                                        cardColor:
                                            Color.fromARGB(255, 36, 89, 134),
                                        elevation: 3.0,
                                        borderRadius: 10.0,
                                        onTap: () {
                                          // Navigasi ke halaman Guest Attendance
                                          navigateToDetails(context,
                                              'GuestAttendance'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardCustom(
                                        title: "Not Checked-In Yet",
                                        value: data['total_not_checked_in']
                                            .toString(),
                                        valuePax:
                                            (data['total_pax_not'].toString()),
                                        cardColor:
                                            Color.fromARGB(255, 146, 61, 55),
                                        elevation: 8.0,
                                        borderRadius: 10.0,
                                        onTap: () {
                                          // Navigasi ke halaman Not Checked In Yet
                                          navigateToDetails(context,
                                              'NotCheckInYet'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardCustom(
                                        title: "RSVP Attend",
                                        value: data['total_rsvp_attend']
                                            .toString(),
                                        valuePax: (data['total_pax_rsvp_attend']
                                            .toString()),
                                        cardColor:
                                            Color.fromARGB(255, 94, 126, 95),
                                        elevation: 8.0,
                                        borderRadius: 10.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Attend
                                          navigateToDetails(context,
                                              'RsvpAttend'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardCustom(
                                        title: "Total Guests",
                                        elevation: 8.0,
                                        borderRadius: 10.0,
                                        value: data['total_guests'].toString(),
                                        valuePax:
                                            (data['total_pax'].toString()),
                                      ),
                                      StatCardCustom(
                                        title: "RSVP Pending",
                                        value: data['total_rsvp_pending']
                                            .toString(),
                                        valuePax:
                                            (data['total_pax_rsvp_pending']
                                                .toString()),
                                        cardColor:
                                            Color.fromARGB(255, 180, 119, 27),
                                        elevation: 8.0,
                                        borderRadius: 10.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Pending
                                          navigateToDetails(context,
                                              'RsvpPending'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardCustom(
                                        title: "RSVP Unable Attend",
                                        value: data['total_rsvp_unable_attend']
                                            .toString(),
                                        valuePax: (data['total_pax_rsvp_not']
                                            .toString()),
                                        cardColor:
                                            Color.fromARGB(255, 210, 71, 117),
                                        elevation: 8.0,
                                        borderRadius: 10.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Unable Attend
                                          navigateToDetails(context,
                                              'RsvpUnableAttend'); // Hanya dua argumen
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: GridView.count(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: [
                                      StatCardAngpau(
                                        title: "Total Envelope",
                                        angpauCount:
                                            (data['total_envelope'].toString()),
                                        elevation: 8.0,
                                        borderRadius: 5.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Unable Attend
                                          navigateToDetails(context,
                                              'RsvpUnableAttend'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardAngpau(
                                        title:
                                            "Envelope Counter ${_selectedAbjad}",
                                        angpauCount:
                                            (data['total_envelope_counter']
                                                .toString()),
                                        elevation: 8.0,
                                        borderRadius: 5.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Unable Attend
                                          navigateToDetails(context,
                                              'RsvpUnableAttend'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardAngpau(
                                        title: "Envelope Entrust",
                                        angpauCount: (data[
                                                'total_envelope_entrust_counter']
                                            .toString()),
                                        elevation: 8.0,
                                        borderRadius: 5.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Unable Attend
                                          navigateToDetails(context,
                                              'RsvpUnableAttend'); // Hanya dua argumen
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navigateToDetails(BuildContext context, String routeName) {
    final dropdownProvider =
        Provider.of<DropdownProviderUser>(context, listen: false);

    // Cek jika selectedSession tidak null dan mengandung session_id
    if (dropdownProvider.selectedSession != null &&
        dropdownProvider.selectedSession!.containsKey('session_id')) {
      String sessionId = dropdownProvider.selectedSession!['session_id'];
      print('sid= $sessionId');

      // Ambil key dari statistics berdasarkan routeName
      int? key;
      switch (routeName) {
        case 'GuestAttendance':
          key = dropdownProvider.statisticsData?['total_guest_attendance'];
          break;
        case 'NotCheckInYet':
          key = dropdownProvider.statisticsData?['total_not_checked_in'];
          break;
        case 'RsvpAttend':
          key = dropdownProvider.statisticsData?['total_rsvp_attend'];
          break;
        case 'RsvpPending':
          key = dropdownProvider.statisticsData?['total_rsvp_pending'];
          break;
        case 'RsvpUnableAttend':
          key = dropdownProvider.statisticsData?['total_rsvp_unable_attend'];
          break;
        default:
          print('Invalid route name');
          return; // Tidak ada rute yang cocok
      }

      print('key= $key');

      Widget page;
      switch (routeName) {
        case 'GuestAttendance':
          page = GuestAttendance(
              sessionId: sessionId, totalkey: key!, idServer: widget.idServer);
          break;
        case 'NotCheckInYet':
          page = NotCheckInYet(
              sessionId: sessionId, totalkey: key!, idServer: widget.idServer);
          break;
        case 'RsvpAttend':
          page = RsvpAttend(
              sessionId: sessionId, totalkey: key!, idServer: widget.idServer);
          break;
        case 'RsvpPending':
          page = RsvpPending(
              sessionId: sessionId, totalkey: key!, idServer: widget.idServer);
          break;
        case 'RsvpUnableAttend':
          page = RsvpUnableAttend(
              sessionId: sessionId, totalkey: key!, idServer: widget.idServer);
          break;
        default:
          return; // Tidak ada rute yang cocok
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    } else {
      print('Session ID not found');
    }
  }
}
