import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import '../../services/generate_link_rsvp.dart';
import '../update_guest_screen.dart';
import 'insert_md_guest_screen_user.dart';

import 'guest_detail_screen.dart';
import 'templates_screen.dart';
import 'guest_search.dart';

import '../../screens/master_data/update_md_guest_screen.dart';
import '../../models/guest_model.dart';
import '../../services/database_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/styles.dart';

class MDGuestScreenUser extends StatefulWidget {
  final String eventId;
  final String eventName;
  final Event event;
  final Session session;
  final String idServer;
  final String clientId;
  final String sessionId;
  final String name;
  final String role;
  final String clientName;
  final String counterLabel;

  MDGuestScreenUser(
      {required this.eventId,
      required this.idServer,
      required this.name,
      required this.clientId,
      required this.sessionId,
      required this.event,
      required this.session,
      required this.role,
      required this.clientName,
      required this.counterLabel,
      required this.eventName});

  @override
  _MDGuestScreenUserState createState() => _MDGuestScreenUserState();
}

class _MDGuestScreenUserState extends State<MDGuestScreenUser> {
  late Future<List<Map<String, dynamic>>> _guestsFuture;
  final log = Logger('MDGuestScreenUser');

  Map<String, List<dynamic>> guestSessions = {};

  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredGuests = [];
  Map<String, dynamic>? _selectedSession;
  String searchQuery = '';

  late Future<List<Map<String, dynamic>>> _sessions;
  String filterRsvp = 'all';
  String filterCat = 'all';
  String sortOption = 'name';

  @override
  void initState() {
    super.initState();
    _fetchGuestData();
    _sessions = _fetchSessions();
  }

  @override
  void dispose() {
    _searchController
        .dispose(); // Bersihkan controller ketika widget dihapus dari tree
    super.dispose(); // Pastikan untuk memanggil super.dispose()
  }

  void _filterGuestsBySession() async {
    if (_selectedSession != null) {
      String sessionId = _selectedSession!['session_id'];

      log.info('Filtering guests by sessionId: $sessionId');
      List<Map<String, dynamic>> guestsBySession = await DatabaseHelper.instance
          .getGuestsBySessionIdWhereNotCI(sessionId);

      setState(() {
        filteredGuests = guestsBySession;
      });
    }
  }

  Future<void> _fetchGuestDetails(String guestId) async {
    final dbHelper = DatabaseHelper();
    final details = await dbHelper.getGuestDetails(guestId);

    // Simpan data sesi berdasarkan guest_id
    if (mounted) {
      setState(() {
        guestSessions[guestId] = details?['sessions'] as List<dynamic>? ?? [];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSessions() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getSessionsByEventId(widget.eventId);
  }

  Future<void> _fetchGuestData({String? sessionId}) async {
    log.info(
        'Fetching guest data for eventId: ${widget.eventId} with sessionId: $sessionId');

    setState(() {
      // Ambil tamu berdasarkan sessionId atau eventId
      _guestsFuture = (sessionId != null)
          ? DatabaseHelper.instance.getGuestsBySessionIdWhereNotCI(sessionId)
          : DatabaseHelper.instance
              .getGuestsBySessionIdWhereNotCI(widget.sessionId);
    });
  }

  void _filterGuests(String query) {
    log.info('Filtering guests with query: $query');
    List<Map<String, dynamic>> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = filteredGuests.where((guest) {
        String guestName = guest['name'].toString().toLowerCase();
        return guestName.contains(query.toLowerCase());
      }).toList();
    } else {
      filteredList = filteredGuests;
    }
    setState(() {
      filteredGuests = filteredList;
    });
  }

  void _addGuest() async {
    // Mendapatkan daftar session ID berdasarkan eventId
    List<String> sessionIds =
        (await DatabaseHelper.instance.getSessionIdsByEventId(widget.eventId))
            .cast<String>();

    if (sessionIds.isNotEmpty) {
      log.info('Session IDs for event ${widget.eventId}: $sessionIds');
      log.info('Navigating to InsertMDGuestScreenUser to add a guest');

      // Tampilkan InsertMDGuestScreenUser di dalam AlertDialog
      bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog.adaptive(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          backgroundColor: AppColors.appBarColor,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 1.9, // Lebih lebar
              minWidth:
                  MediaQuery.of(context).size.width * 1.9, // Minimal lebar
              maxHeight: MediaQuery.of(context).size.width * 1.9, // Lebih lebar
              minHeight:
                  MediaQuery.of(context).size.width * 1.9, // Minimal lebar
            ),
            child: InsertMdGuestScreenUser(
              idServer: widget.idServer,
              clientId: widget.clientId,
              onInsert: _fetchGuestData,
              eventId: widget.eventId,
            ),
          ),
        ),
      );

      // Periksa apakah hasilnya benar dan memperbarui daftar tamu jika diperlukan
      if (result != null && result) {
        log.info('Guest added successfully, refreshing guest list');
        _fetchGuestData();
      }
    } else {
      // Tampilkan notifikasi jika tidak ada session ID
      log.warning('No session IDs found for event ${widget.eventId}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Create a session for the related event first!"),
        ),
      );
    }
  }

  void _viewGuestDetails(Map<String, dynamic> guest) {
    log.info('Viewing details for guest: ${guest['guest_id']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestDetailScreen(
          guest: guest,
          idServer: widget.idServer,
          session: widget.session,
        ),
      ),
    );
  }

  void _editGuest(Map<String, dynamic> guest) async {
    log.info(
        'Navigating to UpdateMDGuestScreen to edit guest: ${guest['guest_id']}');
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => UpdateMDGuestScreen(
        guest: Guest.fromMap(
            guest), // Ensure you have a fromMap constructor in Guest model
        onUpdate: _fetchGuestData,
        eventId: widget.eventId,
        idServer: widget.idServer,
      ),
    );
    if (result != null && result) {
      log.info('Guest edited successfully, refreshing guest list');
      _fetchGuestData();
    } else {
      log.info('Edit guest canceled, refreshing guest list');
      _fetchGuestData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addGuest,
        child: Icon(Icons.add),
        backgroundColor: AppColors.iconColor,
        foregroundColor: AppColors.appBarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Column(
                children: [
                  // TextField untuk pencarian nama
                  TextField(
                    controller:
                        _searchController, // Menghubungkan controller ke TextField
                    decoration: InputDecoration(
                      labelText: 'Search by name', // Label pada TextField
                      prefixIcon: Icon(Icons
                          .search), // Icon search di bagian kiri TextFields
                    ),
                    // Fungsi yang dipanggil setiap kali pengguna mengetik sesuatu
                    onChanged: (value) {
                      setState(() {
                        // Mengubah searchQuery menjadi teks yang diketikkan
                        searchQuery = value
                            .toLowerCase(); // Mengubah ke huruf kecil agar pencarian tidak case-sensitive
                      });
                    },
                  ),
                  SizedBox(height: 10), // Jarak antara TextField dan Dropdown
                  Row(
                    children: [
                      SizedBox(width: 14),
                      SingleChildScrollView(
                        scrollDirection:
                            Axis.vertical, // Mengatur arah gulir horizontal
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end, // Mengatur elemen ke kanan
                          children: [
                            Container(
                              width: 80, // Mengatur lebar untuk dropdown RSVP
                              child: DropdownButton<String>(
                                value: filterRsvp,
                                isExpanded:
                                    true, // Mengatur dropdown agar mengambil ruang penuh
                                icon: Icon(Icons.filter_list),
                                items: <String>[
                                  'all',
                                  'confirmed',
                                  'pending'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    filterRsvp =
                                        newValue!; // Update filterRsvp saat dropdown berubah
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Container(
                              width:
                                  80, // Mengatur lebar untuk dropdown kategori
                              child: DropdownButton<String>(
                                value: filterCat,
                                isExpanded:
                                    true, // Mengatur dropdown agar mengambil ruang penuh
                                icon: Icon(Icons.category),
                                items: <String>[
                                  'all',
                                  'BLANK',
                                  'REGULAR',
                                  'VIP',
                                  'VVIP'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    filterCat =
                                        newValue!; // Update filterCat saat dropdown kategori berubah
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: FutureBuilder(
                future: _guestsFuture, // Mengambil data tamu dari Future
                builder: (context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  // Jika data masih dalam proses loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    log.info(
                        'Waiting for guest data to load'); // Log untuk debugging
                    return Center(
                        child:
                            CircularProgressIndicator()); // Menampilkan spinner loading
                  }
                  // Jika terjadi error saat mengambil data
                  else if (snapshot.hasError) {
                    log.severe(
                        'Error fetching guest data: ${snapshot.error}'); // Log error
                    return Center(
                        child: Text(
                            'Error fetching data')); // Menampilkan pesan error
                  }
                  // Jika tidak ada data tamu yang tersedia
                  else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    log.info(
                        'No guests available for eventId: ${widget.eventId}'); // Log informasi
                    return Center(
                        child: Text(
                            'No guests available')); // Menampilkan pesan tidak ada tamu
                  } else {
                    // Memasukkan data tamu ke dalam filteredGuests
                    filteredGuests = snapshot.data!.toSet().toList();

                    // Filter berdasarkan pencarian nama
                    filteredGuests = filteredGuests
                        .where((guest) => guest['name']
                            .toString()
                            .toLowerCase()
                            .contains(
                                searchQuery)) // Filter tamu yang namanya mengandung teks dari `searchQuery`
                        .toList();

                    log.info(
                        'Guest data loaded successfully with ${filteredGuests.length} guests'); // Log ketika data tamu berhasil diambil

                    // Menampilkan daftar tamu menggunakan ListView.builder
                    return ListView.builder(
                      itemCount: filteredGuests
                          .length, // Jumlah item tamu yang ditampilkan
                      itemBuilder: (context, index) {
                        var guest = filteredGuests[index]; // Data tamu per item
                        var guestId = guest['guest_id']
                            .toString(); // Mengambil ID tamu sebagai string

                        // Ambil data sesi hanya jika belum diambil sebelumnya
                        if (!guestSessions.containsKey(guestId)) {
                          _fetchGuestDetails(
                              guestId); // Panggil fungsi untuk mengambil detail sesi tamu
                        }

                        var sessions = guestSessions[guestId] ??
                            []; // Mendapatkan sesi tamu dari guestSessions

                        if (filterRsvp != 'all') {
                          if (filterRsvp == 'confirmed') {
                            bool confirmedData = sessions
                                .any((session) => session['rsvp'] == 'pending');
                            if (confirmedData) {
                              return SizedBox
                                  .shrink(); // Kembalikan widget kosong jika ada sesi dengan rsvp == '0'
                            }
                          } else {
                            bool pendingData = sessions
                                .any((session) => session['rsvp'] != 'pending');
                            if (pendingData) {
                              return SizedBox
                                  .shrink(); // Kembalikan widget kosong jika ada sesi dengan rsvp == '0'
                            }
                          }
                        }

                        // Filter berdasarkan kategori jika filterCat bukan 'all'
                        if (filterCat != 'all' && guest['cat'] != filterCat) {
                          return SizedBox
                              .shrink(); // Jika kategori tidak sesuai, tidak menampilkan item
                        }

                        // Widget Dismissible untuk mengedit atau menghapus tamu
                        return Dismissible(
                          key:
                              Key(guestId), // Kunci unik untuk setiap item tamu
                          background: Container(
                            color: AppColors
                                .iconColorEdit, // Background warna untuk edit
                            alignment:
                                Alignment.centerLeft, // Ikon di sebelah kiri
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.edit,
                                color: Colors.white), // Ikon edit
                          ),
                          secondaryBackground: Container(
                            color: AppColors
                                .iconColorEdit, // Background warna untuk hapus
                            alignment:
                                Alignment.centerRight, // Ikon di sebelah kanan
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.edit,
                                color: Colors.white), // Ikon hapus
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _editGuest(
                                  guest); // Panggil fungsi edit jika diswipe ke kanan
                            } else {
                              _editGuest(
                                  guest); // Panggil fungsi hapus jika diswipe ke kiri
                            }
                          },
                          child: CardTicket(
                            // Widget untuk menampilkan informasi tamu di dalam card
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guest['name'], // Menampilkan nama tamu
                                  style: AppStyles
                                      .titleCardPrimaryTextStyle, // Gaya teks
                                ),
                                Text(
                                  guest['cat'] ??
                                      'Blank', // Menampilkan kategori tamu
                                  style:
                                      AppStyles.dialogTitleTextStyle.copyWith(
                                    fontWeight:
                                        FontWeight.bold, // Gaya teks tebal
                                    fontSize: 16, // Ukuran teks
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // Membatasi teks agar tidak melampaui batas
                                ),
                                SizedBox(height: 5),
                                if (sessions.isNotEmpty)
                                  for (var session
                                      in sessions) // Iterasi melalui sesi tamu
                                    Row(
                                      children: [
                                        Icon(
                                          session['rsvp'] == '1'
                                              ? Icons
                                                  .event_available_rounded // Ikon jika RSVP 'hadir'
                                              : session['rsvp'] == '0'
                                                  ? Icons
                                                      .calendar_today // Ikon jika RSVP 'tidak hadir'
                                                  : Icons
                                                      .pending, // Ikon jika RSVP 'pending'
                                          color: session['rsvp'] == '1'
                                              ? AppColors.iconColor
                                              : session['rsvp'] == '0'
                                                  ? Colors.red
                                                  : Colors
                                                      .orange, // Warna ikon berdasarkan status RSVP
                                          size: 20,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          '${session['session_name']}${session['rsvp'] == '1' ? '' : session['rsvp'] == '0' ? '' : ''}', // Teks nama sesi dan status RSVP
                                          style:
                                              AppStyles.dialogContentTextStyle,
                                          overflow: TextOverflow
                                              .ellipsis, // Batasi teks panjang
                                          softWrap:
                                              false, // Tidak membungkus teks
                                        ),
                                        SizedBox(width: 10),
                                      ],
                                    )
                                else
                                  Text(
                                    'No RSVP data available', // Jika tidak ada data RSVP
                                    style: AppStyles.dialogContentTextStyle,
                                    overflow: TextOverflow
                                        .ellipsis, // Batasi teks panjang
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sessions.isNotEmpty)
                                  for (var session
                                      in sessions) // Iterasi melalui sesi tamu
                                    Row(
                                      children: [
                                        SizedBox(width: 2),
                                        Icon(
                                          session['status'] == 'checked-in'
                                              ? FontAwesomeIcons
                                                  .solidCheckCircle // Ikon check-in
                                              : session['status'] ==
                                                      'not check-in yet'
                                                  ? FontAwesomeIcons
                                                      .timesCircle // Ikon tidak check-in
                                                  : session['rsvp'] == '0'
                                                      ? Icons
                                                          .calendar_today // Ikon RSVP tidak hadir
                                                      : Icons
                                                          .pending, // Default untuk status lain
                                          color: session['status'] ==
                                                  'checked-in'
                                              ? Colors
                                                  .green // Warna hijau untuk check-in
                                              : session['status'] ==
                                                      'not check-in yet'
                                                  ? Colors
                                                      .red // Warna merah untuk belum check-in
                                                  : session['rsvp'] == '0'
                                                      ? Colors
                                                          .red // Warna merah untuk tidak hadir
                                                      : Colors
                                                          .orange, // Warna oranye untuk status pending
                                          size:
                                              16, // Ukuran ikon lebih kecil, sesuai dengan ukuran teks
                                        ),
                                        SizedBox(width: 5),
                                        if (session['rsvp'] == '0')
                                          Text(
                                            'Guest cannot attend', // Teks jika tamu tidak hadir
                                            style: AppStyles
                                                .dialogContentTextStyle
                                                .copyWith(
                                              fontSize:
                                                  12, // Ukuran teks lebih kecil
                                              color: Colors.red.withOpacity(
                                                  0.6), // Warna teks faded
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          )
                                        else
                                          Text(
                                            session['status'] == 'checked-in'
                                                ? 'Checked-in' // Teks jika check-in
                                                : session['status'] ==
                                                        'not check-in yet'
                                                    ? 'Not check-in yet' // Teks jika belum check-in
                                                    : session[
                                                        'status'], // Status lain
                                            style: AppStyles
                                                .dialogContentTextStyle
                                                .copyWith(
                                              fontSize:
                                                  12, // Ukuran teks lebih kecil
                                              color: session['status'] ==
                                                      'checked-in'
                                                  ? Colors.green.withOpacity(
                                                      0.6) // Faded hijau
                                                  : session['status'] ==
                                                          'not check-in yet'
                                                      ? Colors.red.withOpacity(
                                                          0.6) // Faded merah
                                                      : Colors.orange.withOpacity(
                                                          0.6), // Faded oranye
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        SizedBox(width: 10),
                                      ],
                                    )
                                else
                                  Text(
                                    'No RSVP data available', // Jika tidak ada data RSVP
                                    style: AppStyles.dialogContentTextStyle
                                        .copyWith(
                                      fontSize: 12, // Ukuran teks lebih kecil
                                      color: Colors.grey.withOpacity(
                                          0.6), // Warna teks faded abu-abu
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            leadingIcon: CircleAvatar(
                                backgroundColor:
                                    const Color.fromARGB(255, 216, 103, 23),
                                child: Icon(
                                  FontAwesomeIcons.userGroup,
                                  color: AppColors.appBarColor,
                                )), // Ikon di bagian kiri

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateGuestScreen(
                                    guestId: guest['guest_id']!,
                                    idServer: widget.idServer,
                                    name: widget.name,
                                    role: widget.role,
                                    event: widget.event,
                                    clientId: widget.clientId,
                                    clientName: widget.clientName,
                                    counterLabel: widget.counterLabel,
                                    session: widget.session,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGuestSelection(Map<String, dynamic> guest) async {
    log.info('Adding guest: ${guest['guest_id']} to check-in for all sessions');
    List<Map<String, dynamic>> sessions =
        await DatabaseHelper.instance.getSessionsByEventId(widget.eventId);
    if (sessions.isNotEmpty) {
      sessions.forEach((session) async {
        String sessionId = session['session_id'];
        String guestId = guest['guest_id'];
        await DatabaseHelper.instance.addCheckIn(sessionId, guestId);
      });
      log.info('Guest added to check-in for all sessions successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest checked in for all sessions')),
      );
    } else {
      log.warning('No sessions found for event: ${widget.eventId}');
    }
  }
}
