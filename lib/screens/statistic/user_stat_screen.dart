import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'guest_attendance.dart';
import 'not_check_in_yet.dart';
import 'rsvp_pending.dart';
import 'rsvp_attend.dart';
import 'rsvp_unable_attend.dart';
import '../../widgets/styles.dart';
import '../../services/data_service.dart';
import '../../services/dropdown_provider.dart';

class UserStatScreen extends StatefulWidget {
  final String idServer;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  UserStatScreen({
    required this.idServer,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  @override
  _UserStatScreenState createState() => _UserStatScreenState();
}

class _UserStatScreenState extends State<UserStatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isDropdownVisible = true;

  final DataService _dataService = DataService();
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();

    // Fetch clients saat initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dropdownProvider =
          Provider.of<DropdownProvider>(context, listen: false);
      dropdownProvider.fetchClients();

      dropdownProvider.startStatisticsUpdater();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Statistics"),
        actions: [
          IconButton(
            icon: Icon(
              widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            ),
            onPressed: widget.onToggleFullscreen,
          ),
          IconButton(
            icon: Icon(
              _isDropdownVisible
                  ? Icons.filter_alt
                  : Icons.filter_alt_off_sharp,
            ),
            onPressed: () {
              setState(() {
                _isDropdownVisible = !_isDropdownVisible;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: _isDropdownVisible, // Toggle visibility based on state
              child: Consumer<DropdownProvider>(
                builder: (context, dropdownProvider, child) {
                  return Column(
                    children: [
                      // Dropdown untuk clients
                      DropdownSearch<Map<String, dynamic>>(
                        items: dropdownProvider.clients ?? [],
                        itemAsString: (client) => client['name'] ?? 'Unknown',
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Select Client",
                            hintText: "Choose a client",
                          ),
                        ),
                        onChanged: (value) {
                          dropdownProvider.setSelectedClient(value);
                          if (value != null) {
                            print(
                                "Selected Client: ${value['name']}"); // Log client
                            dropdownProvider.fetchEvents(value); // Load events
                          }
                        },
                        selectedItem: dropdownProvider.selectedClient,
                      ),

                      // Dropdown untuk events
                      DropdownSearch<Map<String, dynamic>>(
                        items: dropdownProvider.events ?? [],
                        itemAsString: (event) =>
                            event['event_name'] ?? 'Unknown',
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Select Event",
                            hintText: "Choose an event",
                          ),
                        ),
                        onChanged: (value) {
                          dropdownProvider.setSelectedEvent(value);
                          if (value != null) {
                            print(
                                "Selected Event: ${value['event_name']}"); // Log event
                            dropdownProvider
                                .fetchSessions(value); // Load sessions
                          }
                        },
                        selectedItem: dropdownProvider.selectedEvent,
                      ),

                      // Dropdown untuk sessions
                      DropdownSearch<Map<String, dynamic>>(
                        items: dropdownProvider.sessions ?? [],
                        itemAsString: (session) =>
                            session['session_name'] ?? 'Unknown',
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Select Session",
                            hintText: "Choose a session",
                          ),
                        ),
                        onChanged: (value) {
                          dropdownProvider.setSelectedSession(value);
                          if (value != null) {
                            print(
                                "Selected Session: ${value['session_name']}"); // Log session
                          }
                        },
                        selectedItem: dropdownProvider.selectedSession,
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: Consumer<DropdownProvider>(
                builder: (context, dropdownProvider, child) {
                  final data =
                      dropdownProvider.statisticsData; // Ambil data statistik
                  if (data == null || data.isEmpty) {
                    return Center(child: Text("No data available"));
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
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      "${data['event_name']} | ${data['session_name']}",
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.appBarColor,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: AppColors.gradientEndColor,
                                            offset: Offset(3.3, 3.0),
                                          ),
                                        ],
                                        letterSpacing: 1.5,
                                        wordSpacing: 2.0,
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
                                                color: AppColors.appBarColor,
                                                value: data['total_guests']
                                                    .toDouble(),
                                                title: data['total_guests']
                                                    .toString(),
                                                radius: 210,
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
                                                radius: 70,
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
                                                radius: 70,
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
                                                radius: 70,
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
                                                radius: 70,
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
                                                radius: 70,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
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
                                        elevation: 8.0,
                                        borderRadius: 25.0,
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
                                        borderRadius: 25.0,
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
                                        borderRadius: 25.0,
                                        onTap: () {
                                          // Navigasi ke halaman RSVP Attend
                                          navigateToDetails(context,
                                              'RsvpAttend'); // Hanya dua argumen
                                        },
                                      ),
                                      StatCardCustom(
                                        title: "Total Guests",
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
                                        borderRadius: 25.0,
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
                                        borderRadius: 25.0,
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
        Provider.of<DropdownProvider>(context, listen: false);

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
