import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../widgets/custom_app_bar.dart';
import 'select_session.dart';
import '../widgets/styles.dart';
import '../models/event_model.dart';
import '../models/client_model.dart';
import '../services/database_helper.dart';
import '../services/data_service.dart';

class SelectEvent extends StatefulWidget {
  final String idServer;
  final String name;
  final Client client;

  SelectEvent(
      {required this.name, required this.idServer, required this.client});

  @override
  _SelectEventState createState() => _SelectEventState();
}

class _SelectEventState extends State<SelectEvent> {
  final log = Logger('_SelectEventState');
  final dbHelper = DatabaseHelper();
  List<Event> events = []; // Daftar event yang akan ditampilkan
  bool isLoading = true; // Status loading

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Panggil fungsi untuk mengambil data event saat inisialisasi
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

    await Future.wait(syncTasks.take(3));
  }

  Future<void> _fetchEvents() async {
    log.info('Fetching events for client: ${widget.client.name}');
    setState(() {
      isLoading = true; // Set loading ke true saat mengambil data
    });

    try {
      // Logika pengambilan data event dari database sesuai client_id
      String clientId = widget.client.client_id!;
      List<Event> events =
          await dbHelper.getEventsUseClientId(clientId); // Sesuaikan metode ini

      setState(() {
        this.events = events; // Update daftar event yang diperoleh
      });
    } catch (e) {
      log.severe('Error fetching events: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading ke false setelah selesai
      });
    }
  }

  Future<void> _refreshScreen() async {
    log.info('Refreshing screen...');
    await _fetchEvents();
  }

  void _navigateToSelectSessionScreen(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectSession(
          role: 'user',
          name: widget.name,
          idServer: widget.idServer,
          event: event,
          client: widget.client,
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
      body: Center(
        child: isLoading
            ? CircularProgressIndicator() // Tampilkan loading jika data masih kosong
            : events.isEmpty
                ? Text(
                    'No events found.',
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
                          SizedBox(height: 20),
                          Container(
                            width: screenWidth * 0.7,
                            child: GestureDetector(
                              onTap: () {
                                // Trigger dropdown manually
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                              },
                              child: DropdownButtonFormField<String>(
                                value: events.length == 1
                                    ? events[0].event_name
                                    : null,
                                hint: Text('Select a event'),
                                isExpanded: true,
                                items: events.map((event) {
                                  return DropdownMenuItem<String>(
                                    value: event.event_name,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            event.event_name,
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
                                  final selectedEvent = events
                                      .firstWhere((c) => c.event_name == value);
                                  _navigateToSelectSessionScreen(selectedEvent);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Events',
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
