import 'dart:async';
import 'package:flutter/material.dart';
import 'data_service.dart';

class SyncProvider with ChangeNotifier {
  String? _idServer; // Menggunakan variabel _idServer untuk menyimpan idServer
  final DataService _dataService;
  Timer? _syncTimer;

  SyncProvider() : _dataService = DataService(); // Inisialisasi DataService

  void updateIdServer(String idServer) {
    _idServer = idServer;
    startSyncing(); // Memulai sinkronisasi ketika idServer diperbarui
  }

  void _syncData() {
    if (_idServer != null) {
      _dataService.checkAndSyncClients(_idServer!);
      _dataService.checkAndSyncEvents(_idServer!);
      _dataService.checkAndSyncEventsSessionsTables(_idServer!);
      _dataService.checkAndSyncGuests(_idServer!);
      _dataService.checkAndSyncTemplates(_idServer!);
      _dataService.checkAndSyncAngpaus(_idServer!);
      _dataService.checkAndSyncEnvelope(_idServer!);
      _dataService.checkAndSyncUshers(_idServer!);
    }
  }

  void startSyncing() {
    _syncData(); // Melakukan sinkronisasi data segera
    _syncTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      _syncData(); // Melakukan sinkronisasi data secara berkala
    });
  }

  void stopSyncing() {
    _syncTimer?.cancel();
  }

  @override
  void dispose() {
    stopSyncing();
    super.dispose();
  }
}
