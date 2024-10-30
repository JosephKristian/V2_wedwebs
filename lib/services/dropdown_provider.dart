import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class DropdownProvider with ChangeNotifier {
  Map<String, dynamic>? _selectedClient;
  Map<String, dynamic>? _selectedEvent;
  Map<String, dynamic>? _selectedSession;
  Map<String, dynamic>? _statisticsData;

  List<Map<String, dynamic>>? _clients;
  List<Map<String, dynamic>>? _events;
  List<Map<String, dynamic>>? _sessions;

  Map<String, dynamic>? get selectedClient => _selectedClient;
  Map<String, dynamic>? get selectedEvent => _selectedEvent;
  Map<String, dynamic>? get selectedSession => _selectedSession;
  Map<String, dynamic>? get statisticsData => _statisticsData;

  List<Map<String, dynamic>>? get clients => _clients;
  List<Map<String, dynamic>>? get events => _events;
  List<Map<String, dynamic>>? get sessions => _sessions;
  bool _isActive = true;

  // Method untuk memuat data clients
  Future<void> fetchClients() async {
    final dbHelper = DatabaseHelper();
    _clients = await dbHelper.getClient();
    print("Fetched Clients: $_clients"); // Log client yang diambil
    notifyListeners();
  }

  // Method untuk memuat data events berdasarkan client yang dipilih
  Future<void> fetchEvents(Map<String, dynamic> client) async {
    final dbHelper = DatabaseHelper();
    _events = await dbHelper.getEventsByClientIdForStat(client['client_id']);
    print(
        "Fetched Events for Client ID ${client['client_id']}: $_events"); // Log events yang diambil
    notifyListeners();
  }

  // Method untuk memuat data sessions berdasarkan event yang dipilih
  Future<void> fetchSessions(Map<String, dynamic> event) async {
    final dbHelper = DatabaseHelper();
    _sessions = await dbHelper.getSessionsByEventId(event['event_id']);
    print(
        "Fetched Sessions for Event ID ${event['event_id']}: $_sessions"); // Log sessions yang diambil
    notifyListeners();
  }

  // Method untuk mengatur pilihan client
  Future<void> setSelectedClient(Map<String, dynamic>? client) async {
    _selectedClient = client;
    _events = null; // Reset events saat client berubah
    _sessions = null; // Reset sessions saat client berubah
    _selectedEvent = null; // Reset event saat client berubah
    print("Selected Client: ${client?['name']}"); // Log client yang dipilih
    notifyListeners();

    if (client != null) {
      await fetchEvents(client); // Memuat events baru
    }
  }

  // Method untuk mengatur pilihan event
  Future<void> setSelectedEvent(Map<String, dynamic>? event) async {
    _selectedEvent = event;
    _sessions = null; // Reset sessions saat event berubah
    _selectedSession = null; // Reset session saat event berubah
    print("Selected Event: ${event?['event_name']}"); // Log event yang dipilih
    notifyListeners();

    if (event != null) {
      await fetchSessions(event); // Memuat sessions baru
    }
  }

  // Method untuk mengatur pilihan session
  void setSelectedSession(Map<String, dynamic>? session) {
    _selectedSession = session;
    print(
        "Selected Session: ${session?['session_name']}"); // Log session yang dipilih
    notifyListeners();

    // Optional: Jika Anda ingin memperbarui statistik saat session dipilih, bisa panggil fetchStatistics di sini
    fetchStatistics(session);
  }

  Timer? _timer; // Tambahkan variabel timer

  // Method untuk memulai timer
  void startStatisticsUpdater() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      if (_selectedSession != null && _isActive) {
        fetchStatistics(_selectedSession); // Perbarui statistik
      }
    });
  }

  void stopStatisticsUpdater() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _isActive = false; // Set status menjadi tidak aktif saat dihapus
    stopStatisticsUpdater(); // Hentikan timer saat objek dihapus
    super.dispose();
  }

  // Optional: Method untuk memuat statistik berdasarkan session yang dipilih
  Future<void> fetchStatistics(Map<String, dynamic>? session) async {
    if (session != null && _isActive) {
      final dbHelper = DatabaseHelper();

      if (!_isActive) return;
      // Ganti dengan logika Anda untuk mendapatkan statistik
      final statistics = await dbHelper.getStatistics(session['session_id']);
      print(
          "Fetched Statistics for Session ID ${session['session_id']}: $statistics"); // Log statistik yang diambil
      _statisticsData = statistics;
      notifyListeners();
    } else {
      // Set default statistics jika session null
      print(
          "No session selected, no statistics to fetch."); // Log jika session null
    }
  }
}
