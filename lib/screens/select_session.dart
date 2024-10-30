import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../widgets/custom_app_bar.dart';
import 'dashboard_user_screen.dart';
import '../widgets/styles.dart';
import '../models/session_model.dart';
import '../models/event_model.dart';
import '../models/client_model.dart';
import '../services/database_helper.dart';
import '../services/data_service.dart';

class SelectSession extends StatefulWidget {
  final String idServer;
  final String name;
  final Event event;
  final Client client;
  final String role; // Role bisa "user" atau yang lain

  SelectSession(
      {required this.idServer,
      required this.event,
      required this.name,
      required this.client,
      required this.role});

  @override
  _SelectSessionState createState() => _SelectSessionState();
}

class _SelectSessionState extends State<SelectSession> {
  final log = Logger('_SelectSessionState');
  final dbHelper = DatabaseHelper();
  List<Session>? sessions = []; // Daftar session yang akan ditampilkan
  bool isLoading = true; // Status loading

  @override
  void initState() {
    super.initState();
    _fetchSessions(); // Panggil fungsi untuk mengambil data session saat inisialisasi
  }

  Future<void> _refreshScreen() async {
    log.info('Refreshing screen...');
    await _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    log.info('Fetching sessions for event: ${widget.event.event_name}');
    setState(() {
      isLoading = true; // Set loading ke true saat mengambil data
    });

    try {
      // Logika pengambilan data session dari database sesuai event_id
      String eventId = widget.event.event_id!;
      List<Session>? sessions =
          await dbHelper.getSessionByEventId(eventId); // Sesuaikan metode ini

      setState(() {
        this.sessions = sessions; // Update daftar session yang diperoleh
      });
    } catch (e) {
      log.severe('Error fetching sessions: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading ke false setelah selesai
      });
    }
  }

  void _navigateToDashboardUserScreen(Session session) {
    // Logika navigasi ke halaman berikutnya
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardUserScreen(
          session: session,
          event: widget.event,
          name: widget.name,
          clientId: widget.client.client_id!,
          role: widget.role,
          idServer: widget.idServer,
          clientName: widget.client.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    log.info('Building SelectEvent');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Select Event',
        actions: [
          IconButton(
            onPressed: _refreshScreen,
            icon: Icon(Icons.refresh_outlined),
            color: Colors.white,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.appBarColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),

            // Tambahkan item menu lainnya sesuai kebutuhan
          ],
        ),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator() // Tampilkan loading jika data masih kosong
            : sessions!.isEmpty
                ? Text(
                    'No sessions found.',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87), // Tambahkan gaya pada pesan
                  ) // Tampilkan pesan jika tidak ada klien
                : SingleChildScrollView(
                    // Membungkus dengan SingleChildScrollView
                    child: Padding(
                      padding: const EdgeInsets.all(
                          16.0), // Padding di sekitar konten
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Menjaga konten tetap di tengah
                        children: [
                          Image.asset(
                            'assets/images/logo.png', // Sesuaikan dengan lokasi logo di proyekmu
                            height: 200, // Sesuaikan ukuran logo
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Hello Usher ${widget.name},\nYou have been assigned to Client:',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87, // Warna sesuai gambar
                            ),
                            textAlign: TextAlign
                                .center, // Memastikan teks berada di tengah
                          ),

                          SizedBox(height: 30),
                          Text(
                            widget.client.name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.iconColor,
                            ),
                          ),
                          SizedBox(height: 30),
                          Text(
                            'Please select the Event & Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87, // Warna sesuai gambar
                            ),
                            textAlign: TextAlign
                                .center, // Memastikan teks berada di tengah
                          ),
                          SizedBox(height: 10),
                          Container(
                            width: screenWidth *
                                0.7, // Atur lebar sesuai persentase layar
                            child: TextField(
                              controller: TextEditingController(
                                  text: widget.event
                                      .event_name), // Text diambil dari widget
                              enabled:
                                  false, // Membuat TextField tidak bisa diedit
                              decoration: InputDecoration(
                                labelText: 'Event',
                                labelStyle: TextStyle(
                                  color: AppColors.iconColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 205, 193,
                                        164), // Warna border default
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: AppColors
                                        .iconColor, // Warna border saat TextField aktif
                                    width:
                                        1.0, // Lebar border saat tidak difokuskan
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: AppColors.iconColor,
                                    width: 2.0, // Lebar border saat difokuskan
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            width: screenWidth * 0.7,
                            child: GestureDetector(
                              onTap: () {
                                // Trigger dropdown manually
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                              },
                              child: DropdownButtonFormField<String>(
                                value: sessions!.length == 1
                                    ? sessions![0].session_name
                                    : null,
                                hint: Text('Select a session'),
                                isExpanded: true,
                                items: sessions!.map((session) {
                                  return DropdownMenuItem<String>(
                                    value: session.session_name,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            session.session_name,
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.iconColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  log.info('Selected event: $value');
                                  // Navigasi atau tindakan lainnya di sini
                                  final selectedEvent = sessions!.firstWhere(
                                      (c) => c.session_name == value);
                                  _navigateToDashboardUserScreen(selectedEvent);
                                },
                                decoration: InputDecoration(
                                  labelText: 'sessions',
                                  labelStyle: TextStyle(
                                      color: AppColors.iconColor,
                                      fontWeight: FontWeight.bold),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.iconColor,
                                      width: 2.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.iconColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: AppColors.iconColor,
                                      width: 2.0,
                                    ),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 12.0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                              height:
                                  30), // Menambahkan jarak sebelum elemen berikutnya
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
