import 'dart:convert';
import 'package:logging/logging.dart'; // Pastikan untuk menambahkan dependency ini
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wedweb/models/angpau_model.dart';
import 'package:wedweb/models/angpau_titipan_model.dart';
import '../models/template_model.dart';
import 'database_helper.dart';
import 'api_service.dart';
import '../models/guest_model.dart';
import '../models/client_model.dart';
import '../models/event_model.dart';
import '../models/session_model.dart';
import '../models/table_model.dart';
import '../models/check_in_model.dart';
import '../models/usher_model.dart';

class DataService {
  final Logger log = Logger('DataService');
  late final String apiUrl;

  DataService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      apiUrl = await ApiService.pathApi();
      log.info('API URL initialized: $apiUrl');
    } catch (e) {
      log.severe('Error initializing API URL: $e');
    }
  }

  Future<bool> checkInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<bool> _checkServerReachability() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      log.severe('Server reachability check failed: $e');
      return false;
    }
  }

  Future<void> syncDeletedRecords(String idServer) async {
    try {
      log.info('====++Starting sync for deleted records for user: $idServer');

      // Mengambil deleted records dari server
      final response = await http.post(
        Uri.parse('$apiUrl/deleted-records'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'idServer': idServer}),
      );

      // Mengecek status respon dari server
      if (response.statusCode == 200) {
        log.info('====++Received response from server: ${response.body}');
        List<dynamic> deletedRecords = jsonDecode(response.body);

        // Memeriksa apakah ada deleted records
        if (deletedRecords.isEmpty) {
          log.info('====++No deleted records received from server.');
          return;
        }

        log.info('====++Processing ${deletedRecords.length} deleted records.');

        for (var record in deletedRecords) {
          String tableName = record['table_name'];
          Map<String, dynamic> data = jsonDecode(record['data']);
          log.info('====++Processing ${tableName} deleted records.');

          String? recordId;
          if (tableName == 'guest') {
            recordId = data['guest_id'];
          } else if (tableName == 'client') {
            recordId = data['client_id'];
          } else if (tableName == 'usher') {
            recordId = data['usher_id'];
          } else if (tableName == 'event') {
            recordId = data['event_id'];
          } else if (tableName == 'session') {
            recordId = data['session_id'];
          } else {
            recordId = 'default_id'; // ID default jika tabel tidak diketahui
          }

          if (recordId != null) {
            try {
              log.info(
                  '====++=======++====++===++====++====++====++====++====++====++====++Checking existence of record ID $recordId in table $tableName.');

              // Cek apakah data terkait ada di database lokal
              bool exists = await DatabaseHelper.instance
                  .recordExists(tableName, recordId);

              if (exists) {
                // Jika ada, hapus data dari database lokal
                log.info(
                    '====++====++====++====++======++===++Record $recordId exists. Deleting from local database for table $tableName.');
                await DatabaseHelper.instance.deleteRecord(tableName, recordId);
                log.info(
                    '===++====++====++======++====++========Successfully deleted record $recordId from local database for table $tableName.');
              } else {
                log.info(
                    '=======++====++======++====++====++====++====++====++====++====++====++Record $recordId does not exist in local database for table $tableName. Skipping deletion.');
              }
            } catch (e) {
              log.severe(
                  'Error processing record ID $recordId for table $tableName: $e');
              // Melanjutkan ke record berikutnya
            }
          } else {
            log.warning(
                '=====++====++=+++++====++====++======++====++====++====++====++====++=====++Record ID is null for table $tableName. Skipping this record.');
          }
        }
        log.info(
            '======++====++===============++====++====++====++====++====++====++====++====++Sync process for deleted records completed successfully.');
      } else {
        log.severe(
            '======++====++==================++====++====++====++====++====++Failed to load deleted records from server: ${response.statusCode}. Response body: ${response.body}');
        throw Exception('====++Failed to load deleted records from server');
      }
    } catch (e) {
      log.severe('Error during syncDeletedRecords: $e');
    }
  }

// +++++++++++++++++++++++++++++++++++++++++++++++++++++CLIENT+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  Future<void> checkAndSyncClients(String idServer) async {
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await ApiService.syncUsersTempDataToServer(idServer);
      await syncDeletedRecords(idServer);
      await syncDeletedClients();
      await syncClients(idServer);
    } catch (e) {
      log.severe('Failed to sync clients: $e');
    }
  }

  Future<void> syncDeletedClients() async {
    log.info('Checking internet connection...');
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    log.info('Internet connection available. Checking server reachability...');
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable. Sync aborted.');
      return;
    }

    log.info('Syncing deleted clients...');
    try {
      final deletedClients = await DatabaseHelper.instance.getDeletedClients();
      log.info('Fetched deleted clients: $deletedClients');
      for (var client in deletedClients) {
        String clientId = client['client_id'];
        String userId = client['user_id'];
        log.info(
            'Deleting client from server: clientId=$clientId, userId=$userId');
        await deleteClientFromServer(clientId, userId);
        log.info('Client deleted from server: clientId=$clientId');
        await DatabaseHelper.instance.removeDeletedClient(clientId);
        log.info(
            'Removed deleted client from local database: clientId=$clientId');
      }
    } catch (e) {
      log.severe('Failed to sync deleted clients: $e');
    }
  }

  // Fungsi untuk sinkronisasi data client dari server ke lokal
  Future<void> syncClientsFromServer(String idServer) async {
    try {
      log.info('Syncing clients from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_clients'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('Received response from server: ${response.body}');
        List<dynamic> serverClients = jsonDecode(response.body);

        if (serverClients.isEmpty) {
          log.info('No clients data received from server.');
          return;
        }

        for (var clientData in serverClients) {
          Client serverClient = Client.fromJson(clientData);

          // Periksa apakah client dengan ID ini sudah ada di database lokal
          Client? localClient = await DatabaseHelper.instance
              .getClientById(serverClient.client_id!);

          if (localClient != null) {
            // Jika ada, periksa timestamp dan lakukan pembaruan jika perlu
            DateTime serverUpdatedAt = DateTime.parse(serverClient.updated_at!);
            DateTime localUpdatedAt = DateTime.parse(localClient.updated_at!);

            log.warning(
                'Updating SERVER client ${serverUpdatedAt} COMPARISON---------------------------------');
            log.warning(
                'Updating LOCAL client ${localUpdatedAt} COMPARISON---------------------------------');

            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              log.info(
                  'Updating local client ${serverClient.client_id} with new data');
              await DatabaseHelper.instance.updateClient(serverClient);
            } else {
              log.info('Local client ${serverClient.client_id} is up-to-date');
            }
          } else {
            // Jika tidak ada, tambahkan data baru ke database lokal
            log.info(
                'Inserting new client ${serverClient.client_id} into local database');
            await DatabaseHelper.instance.insertClient(serverClient);
          }
        }
      } else {
        log.severe(
            'Failed to load clients from server: ${response.statusCode}');
        throw Exception('Failed to load clients from server');
      }
    } catch (e) {
      log.severe('Error during syncClientsFromServer: $e');
    }
  }

  // Fungsi untuk sinkronisasi data client dari lokal ke server
  Future<void> syncClientsToServer(String idServer) async {
    try {
      log.info('Syncing clients to server with idServer: $idServer');

      // Ambil data klien lokal
      List<Client> localClients = await DatabaseHelper.instance.getClients();
      log.info(
          'Local clients fetched: ${localClients.map((client) => client.toJson()).toList()}');

      // Filter klien yang belum disinkronkan
      List<Client> unsyncedClients =
          localClients.where((client) => !client.synced).toList();
      log.info(
          'Unsynced clients: ${unsyncedClients.map((client) => client.toJson()).toList()}');

      if (unsyncedClients.isEmpty) {
        log.info('No unsynced clients to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'clients': unsyncedClients.map((client) => client.toJson()).toList(),
      };

      log.info('Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_clients'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('Successfully synced clients to server');
        log.info('Server logs: ${responseBody['log'].join('\n')}');
        await _updateStatus(unsyncedClients);
      } else {
        log.severe('Failed to sync clients to server: ${response.statusCode}');
        throw Exception('Failed to sync clients to server');
      }
    } catch (e) {
      log.severe('Error during syncClientsToServer: $e');
    }
  }

  Future<void> _updateStatus(List<Client> unsyncedClients) async {
    // Update status synced setelah berhasil sinkronisasi
    await DatabaseHelper.instance.updateAllClientsSyncedStatus(
        unsyncedClients.map((client) => client.client_id!).toList());
    log.info('Updated synced status for clients');
  }

  // Fungsi untuk sinkronisasi penuh (dua arah)
  Future<void> syncClients(String idServer) async {
    log.info('Starting full sync with idServer: $idServer');
    try {
      await syncClientsFromServer(idServer);
      await syncClientsToServer(idServer);
      log.info('Full sync completed');
    } catch (e) {
      log.severe('Error during full sync: $e');
    }
  }

  // Method to delete a client from the server
  Future<void> deleteClientFromServer(String clientId, String userId) async {
    try {
      log.info(
          'Deleting client from server: clientId=$clientId,userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_clients'),
        body: {
          'client_id': clientId.toString(),
          'user_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['status'] != 'success') {
          log.severe(
              'Failed to delete client from server: ${responseBody['message']}');
          throw Exception('Failed to delete client from server');
        }
        log.info('Client deleted successfully from server: clientId=$clientId');
      } else {
        log.severe(
            'Failed to delete client from server: ${response.statusCode}');
        throw Exception('Failed to delete client from server');
      }
    } catch (e) {
      log.severe('Error during deleteClientFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++CLIENT+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// +++++++++++++++++++++++++++++++++++++++++++++++++++++USHER+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  Future<void> checkAndSyncUshers(String idServer) async {
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await syncDeletedRecords(idServer);
      await syncDeletedUshers();
      await syncUshers(idServer);
    } catch (e) {
      log.severe('Failed to sync ushers: $e');
    }
  }

  Future<void> syncDeletedUshers() async {
    log.info('Checking internet connection...');
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    log.info('Internet connection available. Checking server reachability...');
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable. Sync aborted.');
      return;
    }

    log.info('Syncing deleted ushers...');
    try {
      final deletedUshers = await DatabaseHelper.instance.getDeletedUshers();
      log.info('Fetched deleted ushers: $deletedUshers');
      for (var usher in deletedUshers) {
        String usherId = usher['usher_id'];
        String userId = usher['user_id'];
        log.info(
            'Deleting usher from server: usherId=$usherId, userId=$userId');
        await deleteUsherFromServer(usherId, userId);
        log.info('Usher deleted from server: usherId=$usherId');
        await DatabaseHelper.instance.removeDeletedUsher(usherId);
        log.info('Removed deleted usher from local database: usherId=$usherId');
      }
    } catch (e) {
      log.severe('Failed to sync deleted ushers: $e');
    }
  }

  Future<void> syncUshersFromServer(String idServer) async {
    try {
      log.info('Syncing ushers from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});
      log.info('IDSERVER: ${idServer}');
      final response = await http.post(
        Uri.parse('$apiUrl/get_ushers'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('Received response from server: ${response.body}');
        List<dynamic> serverUshers = jsonDecode(response.body);

        if (serverUshers.isEmpty) {
          log.info('No ushers data received from server.');
          return;
        }

        for (var usherData in serverUshers) {
          Usher serverUsher = Usher.fromJson(usherData);

          // Periksa apakah usher dengan ID ini sudah ada di database lokal
          Usher? localUsher =
              await DatabaseHelper.instance.getUsherById(serverUsher.usher_id);

          if (localUsher != null) {
            // Jika ada, periksa timestamp dan lakukan pembaruan jika perlu
            DateTime serverUpdatedAt = DateTime.parse(serverUsher.updatedAt!);
            DateTime localUpdatedAt = DateTime.parse(localUsher.updatedAt!);

            log.warning(
                'Updating SERVER usher ${serverUpdatedAt} COMPARISON---------------------------------');
            log.warning(
                'Updating LOCAL usher ${localUpdatedAt} COMPARISON---------------------------------');

            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              log.info(
                  'Updating local usher ${serverUsher.usher_id} with new data');
              await DatabaseHelper.instance.updateUsher(serverUsher);
            } else {
              log.info('Local usher ${serverUsher.usher_id} is up-to-date');
            }
          } else {
            // Jika tidak ada, tambahkan data baru ke database lokal
            log.info(
                'Inserting new usher ${serverUsher.usher_id} into local database');
            await DatabaseHelper.instance.insertUsher(serverUsher);
          }
        }
      } else {
        log.severe('Failed to load ushers from server: ${response.statusCode}');
        throw Exception('Failed to load ushers from server');
      }
    } catch (e) {
      log.severe('Error during syncUshersFromServer: $e');
    }
  }

  Future<void> syncUshersToServer(String idServer) async {
    try {
      log.info('Syncing ushers to server with idServer: $idServer');

      // Ambil data usher lokal
      List<Usher> localUshers = await DatabaseHelper.instance.getUshers();
      log.info(
          'Local ushers fetched: ${localUshers.map((usher) => usher.toJson()).toList()}');

      // Filter usher yang belum disinkronkan
      List<Usher> unsyncedUshers =
          localUshers.where((usher) => !usher.synced).toList();
      log.info(
          'Unsynced ushers: ${unsyncedUshers.map((usher) => usher.toJson()).toList()}');

      if (unsyncedUshers.isEmpty) {
        log.info('No unsynced ushers to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'ushers': unsyncedUshers.map((usher) => usher.toJson()).toList(),
      };

      log.info('Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_ushers'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('Successfully synced ushers to server');
        log.info('Server logs: ${responseBody['log'].join('\n')}');
        await _updateUsherStatus(unsyncedUshers);
      } else {
        log.severe('Failed to sync ushers to server: ${response.statusCode}');
        throw Exception('Failed to sync ushers to server');
      }
    } catch (e) {
      log.severe('Error during syncUshersToServer: $e');
    }
  }

  Future<void> _updateUsherStatus(List<Usher> unsyncedUshers) async {
    // Update status synced setelah berhasil sinkronisasi
    await DatabaseHelper.instance.updateAllUshersSyncedStatus(
        unsyncedUshers.map((usher) => usher.usher_id).toList());
    log.info('Updated synced status for ushers');
  }

// Fungsi untuk sinkronisasi penuh (dua arah)
  Future<void> syncUshers(String idServer) async {
    log.info('Starting full sync with idServer: $idServer');
    try {
      await syncUshersFromServer(idServer);
      await syncUshersToServer(idServer);
      log.info('Full sync completed');
    } catch (e) {
      log.severe('Error during full sync: $e');
    }
  }

// Method to delete a usher from the server
  Future<void> deleteUsherFromServer(String usherId, String userId) async {
    try {
      log.info('Deleting usher from server: usherId=$usherId, userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_ushers'),
        body: {
          'usher_id': usherId.toString(),
          'user_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['status'] != 'success') {
          log.severe(
              'Failed to delete usher from server: ${responseBody['message']}');
          throw Exception('Failed to delete usher from server');
        }
        log.info('Usher deleted successfully from server: usherId=$usherId');
      } else {
        log.severe(
            'Failed to delete usher from server: ${response.statusCode}');
        throw Exception('Failed to delete usher from server');
      }
    } catch (e) {
      log.severe('Error during deleteUsherFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++USHER+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++EVENT+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> checkAndSyncEvents(String idServer) async {
    // Check internet connection
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await ApiService.syncUsersTempDataToServer(idServer);
      await syncDeletedRecords(idServer);
      await _syncDeletedEventsTablesSessions();
      await syncEvents(idServer);
      log.info('Client sync successful');
    } catch (e) {
      log.severe('Failed to sync clients: $e');
    }
  }

  Future<void> _syncDeletedEventsTablesSessions() async {
    log.info('Checking server availability...');
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info('Syncing deleted clients...');
    try {
      final deletedTables = await DatabaseHelper.instance.getDeletedTables();
      log.info('Fetched deleted Tables: $deletedTables');
      final deletedSessions =
          await DatabaseHelper.instance.getDeletedSessions();
      log.info('Fetched deleted Sessions: $deletedSessions');
      final deletedEvents = await DatabaseHelper.instance.getDeletedEvents();
      log.info('Fetched deleted Events: $deletedEvents');

      for (var tables in deletedTables) {
        String tableId = tables['table_id'];
        String sessionId = tables['session_id'];
        String userId = tables['user_id'];
        await deleteTableFromServer(tableId, sessionId, userId);
        log.info('Table deleted from server: tableId=$tableId');
        await DatabaseHelper.instance
            .removeDeletedTable(tableId, sessionId, userId);
        log.info('Removed deleted table from local database: table=$tableId');
      }

      for (var sessions in deletedSessions) {
        String sessionId = sessions['session_id'];
        String eventId = sessions['event_id'];
        String userId = sessions['user_id'];
        await deleteSessionFromServer(sessionId, eventId, userId);
        log.info('Session deleted from server: sessionId=$sessionId');
        await DatabaseHelper.instance
            .removeDeletedSession(sessionId, eventId, userId);
        log.info(
            'Removed deleted session from local database: session=$sessionId');
      }

      for (var events in deletedEvents) {
        String eventId = events['event_id'];
        String clientId = events['client_id'];
        String userId = events['user_id'];
        await deleteEventFromServer(eventId, clientId, userId);
        log.info('Event deleted from server: eventId=$eventId');
        await DatabaseHelper.instance
            .removeDeletedEvent(eventId, clientId, userId);
        log.info('Removed deleted event from local database: eventId=$eventId');
      }
    } catch (e) {
      log.severe('Failed to sync deleted data: $e');
    }
  }

  Future<void> syncEventsFromServer(String idServer) async {
    try {
      log.info('Syncing events from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_events'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info(
            'DATA EVENT CHECKKKKKKKKKKKKKKKKKKKK Received response from server: ${response.body}');
        List<dynamic> serverEvents = jsonDecode(response.body);

        if (serverEvents.isEmpty) {
          log.info('No events data received from server.');
          return;
        }

        for (var eventData in serverEvents) {
          Event serverEvent = Event.fromJson(eventData);

          // Periksa apakah event dengan ID ini sudah ada di database lokal
          Event? localEvent =
              await DatabaseHelper.instance.getEventById(serverEvent.event_id!);

          if (localEvent != null) {
            // Jika ada, periksa timestamp dan lakukan pembaruan jika perlu
            DateTime serverUpdatedAt = DateTime.parse(serverEvent.updated_at!);
            DateTime localUpdatedAt = DateTime.parse(localEvent.updated_at!);

            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              // Update data lokal jika data server lebih baru
              log.info(
                  'Updating local event ${serverEvent.event_id} with new data');
              await DatabaseHelper.instance.updateEvent(serverEvent);
            } else {
              log.info('Local event ${serverEvent.event_id} is up-to-date');
            }
          } else {
            // Jika tidak ada, tambahkan data baru ke database lokal
            log.info(
                'Inserting new event ${serverEvent.event_id} into local database');
            await DatabaseHelper.instance.insertEvent(serverEvent);
          }
        }
      } else {
        log.severe('Failed to load events from server: ${response.statusCode}');
        throw Exception('Failed to load events from server');
      }
    } catch (e) {
      log.severe('Error during syncEventsFromServer: $e');
    }
  }

  Future<void> syncEventsToServer(String idServer) async {
    try {
      log.info('Syncing events to server with idServer: $idServer');

      // Ambil data event lokal
      List<Event> localEvents = await DatabaseHelper.instance.getEvents();
      log.info(
          'Local events fetched: ${localEvents.map((event) => event.toJson()).toList()}');

      // Filter event yang belum disinkronkan
      List<Event> unsyncedEvents =
          localEvents.where((event) => !event.synced).toList();
      log.info(
          'Unsynced events: ${unsyncedEvents.map((event) => event.toJson()).toList()}');

      if (unsyncedEvents.isEmpty) {
        log.info('No unsynced events to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'events': unsyncedEvents.map((event) => event.toJson()).toList(),
      };

      log.info('Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_events'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('Successfully synced events to server');
        log.info('Server logs: ${responseBody['log'].join('\n')}');
        await _updateEventStatus(unsyncedEvents);
      } else {
        log.severe('Failed to sync events to server: ${response.statusCode}');
        throw Exception('Failed to sync events to server');
      }
    } catch (e) {
      log.severe('Error during syncEventsToServer: $e');
    }
  }

  Future<void> _updateEventStatus(List<Event> unsyncedEvents) async {
    // Update status synced setelah berhasil sinkronisasi
    await DatabaseHelper.instance.updateAllEventsSyncedStatus(
        unsyncedEvents.map((event) => event.event_id!).toList());
    log.info('Updated synced status for events');
  }

  Future<void> syncEvents(String idServer) async {
    log.info('Starting full sync for events with idServer: $idServer');
    try {
      await syncEventsFromServer(idServer);
      await syncEventsToServer(idServer);
      log.info('Full event sync completed');
    } catch (e) {
      log.severe('Error during full event sync: $e');
    }
  }

  Future<void> deleteEventFromServer(
      String eventId, String clientId, String userId) async {
    try {
      log.info('Deleting event from server: eventId=$eventId,userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_events'),
        body: {
          'event_id': eventId.toString(),
          'client_id': clientId.toString(),
          'user_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['status'] != 'success') {
          log.severe(
              'Failed to delete event from server: ${responseBody['message']}');
          throw Exception('Failed to delete event from server');
        }
        log.info('Event deleted successfully from server: eventId=$eventId');
      } else {
        log.severe(
            'Failed to delete event from server: ${response.statusCode}');
        throw Exception('Failed to delete event from server');
      }
    } catch (e) {
      log.severe('Error during deleteEventFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++EVENT+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // ______________________________________________________JOINMETHOD___________________________________

  Future<void> checkAndSyncEventsSessionsTables(String idServer) async {
    // Check internet connection
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await syncDeletedRecords(idServer);
      await _syncDeletedCheckIn();
      await _syncDeletedTablesSessions();
      await syncEvents(idServer);
      await syncSessions(idServer);
      await syncTables(idServer);
      await syncCheckIns(idServer);
    } catch (e) {
      log.severe('Failed to sync DetailEvent: $e');
    }
  }

  // ______________________________________________________JOINMETHOD__________________________________________________

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++SESSION+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> syncSessionsFromServer(String idServer) async {
    try {
      log.info('Syncing sessions from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_sessions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('Received response from server: ${response.body}');

        List<dynamic> serverSessions;
        try {
          serverSessions = jsonDecode(response.body);
          log.info('Parsed JSON successfully.');
        } catch (e) {
          log.severe('Error decoding JSON: $e');
          return;
        }

        if (serverSessions.isEmpty) {
          log.info('No sessions data received from server.');
          return;
        }

        for (var sessionData in serverSessions) {
          try {
            Session serverSession = Session.fromJson(sessionData);

            // Check if the session already exists in the local database
            Session? localSession = await DatabaseHelper.instance
                .getSessionById(serverSession.session_id!);

            if (localSession != null) {
              DateTime serverUpdatedAt =
                  DateTime.parse(serverSession.updated_at!);
              DateTime localUpdatedAt =
                  DateTime.parse(localSession.updated_at!);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                log.info(
                    'Updating local session ${serverSession.session_id} with new data');
                await DatabaseHelper.instance.updateSessions(serverSession);
              } else {
                log.info(
                    'Local session ${serverSession.session_id} is up-to-date');
              }
            } else {
              log.info(
                  'Inserting new session ${serverSession.session_id} into local database');
              await DatabaseHelper.instance.insertSession(serverSession);
            }
          } catch (e) {
            log.severe('Error processing session data: $e');
          }
        }
      } else {
        log.severe(
            'Failed to load sessions from server: ${response.statusCode}');
        throw Exception('Failed to load sessions from server');
      }
    } catch (e) {
      log.severe('Error during syncSessionsFromServer: $e');
    }
  }

  Future<void> syncSessionsToServer(String idServer) async {
    try {
      log.info('Syncing sessions to server with idServer: $idServer');

      // Fetch local sessions
      List<Session> localSessions = await DatabaseHelper.instance.getSessions();
      log.info(
          'Local sessions fetched: ${localSessions.map((session) => session.toJson()).toList()}');

      // Filter sessions that are not synced
      List<Session> unsyncedSessions =
          localSessions.where((session) => !session.synced).toList();
      log.info(
          'Unsynced sessions: ${unsyncedSessions.map((session) => session.toJson()).toList()}');

      if (unsyncedSessions.isEmpty) {
        log.info('No unsynced sessions to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'sessions':
            unsyncedSessions.map((session) => session.toJson()).toList(),
      };

      log.info('Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_sessions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('Successfully synced sessions to server');
        log.info('Server logs: ${responseBody['log'].join('\n')}');
        await _updateSessionStatus(unsyncedSessions);
      } else {
        log.severe('Failed to sync sessions to server: ${response.statusCode}');
        throw Exception('Failed to sync sessions to server');
      }
    } catch (e) {
      log.severe('Error during syncSessionsToServer: $e');
    }
  }

  Future<void> _updateSessionStatus(List<Session> unsyncedSessions) async {
    await DatabaseHelper.instance.updateAllSessionsSyncedStatus(
      unsyncedSessions.map((session) => session.session_id!).toList(),
    );
    log.info('Updated synced status for sessions');
  }

  Future<void> syncSessions(String idServer) async {
    log.info('Starting full sync for sessions with idServer: $idServer');
    try {
      await syncSessionsFromServer(idServer);
      await syncSessionsToServer(idServer);
      log.info('Full session sync completed');
    } catch (e) {
      log.severe('Error during full session sync: $e');
    }
  }

  Future<void> deleteSessionFromServer(
      String sessionId, String eventId, String userId) async {
    try {
      log.info(
          'Deleting session from server: sessionId=$sessionId, userId=$userId');

      final response = await http.post(
        Uri.parse('$apiUrl/delete_sessions'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'session_id': sessionId,
          'event_id': eventId,
          'user_id': userId,
        },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            log.info(
                'Session deleted successfully from server: sessionId=$sessionId');
          } else {
            log.severe(
                'Failed to delete session from server: ${responseBody['message']}');
            throw Exception('Failed to delete session from server');
          }
        } catch (e) {
          log.severe('Error parsing server response: $e');
          throw Exception('Failed to parse server response');
        }
      } else {
        log.severe(
            'Failed to delete session from server: ${response.statusCode}');
        throw Exception('Failed to delete session from server');
      }
    } catch (e) {
      log.severe('Error during deleteSessionFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++SESSION+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++TABLE+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> _syncDeletedTablesSessions() async {
    log.info('Checking internet connection...');

    // Check internet connection
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    log.info('Checking server availability...');
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info('Syncing deleted tables and sessions...');
    try {
      final deletedTables = await DatabaseHelper.instance.getDeletedTables();
      log.info('Fetched deleted Tables: $deletedTables');
      final deletedSessions =
          await DatabaseHelper.instance.getDeletedSessions();
      log.info('Fetched deleted Sessions: $deletedSessions');

      for (var tables in deletedTables) {
        String tableId = tables['table_id'];
        String sessionId = tables['session_id'];
        String userId = tables['user_id'];
        await deleteTableFromServer(tableId, sessionId, userId);
        log.info('Table deleted from server: tableId=$tableId');
        await DatabaseHelper.instance
            .removeDeletedTable(tableId, sessionId, userId);
        log.info('Removed deleted table from local database: table=$tableId');
      }

      for (var sessions in deletedSessions) {
        String sessionId = sessions['session_id'];
        String eventId = sessions['event_id'];
        String userId = sessions['user_id'];
        await deleteSessionFromServer(sessionId, eventId, userId);
        log.info('Session deleted from server: sessionId=$sessionId');
        await DatabaseHelper.instance
            .removeDeletedSession(sessionId, eventId, userId);
        log.info(
            'Removed deleted session from local database: session=$sessionId');
      }
    } catch (e) {
      log.severe('Failed to sync deleted tables and sessions: $e');
    }
  }

  Future<void> syncTablesFromServer(String idServer) async {
    try {
      log.info('Syncing tables from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_tables'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('Received response from server: ${response.body}');
        List<dynamic> serverTables = jsonDecode(response.body);

        if (serverTables.isEmpty) {
          log.info('No tables data received from server.');
          return;
        }

        for (var tableData in serverTables) {
          log.info('Processing table data: $tableData');

          // Log each field type
          log.info(
              'table_id: ${tableData['table_id']} (${tableData['table_id'].runtimeType})');
          log.info(
              'seat: ${tableData['seat']} (${tableData['seat'].runtimeType})');
          log.info(
              'updated_at: ${tableData['updated_at']} (${tableData['updated_at'].runtimeType})');

          try {
            TableModel serverTable = TableModel.fromJson(tableData);

            // Check if the table already exists in the local database
            TableModel? localTable = await DatabaseHelper.instance
                .getTableById(serverTable.table_id!);

            if (localTable != null) {
              DateTime serverUpdatedAt =
                  DateTime.parse(serverTable.updated_at!);
              DateTime localUpdatedAt = DateTime.parse(localTable.updated_at!);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                log.info(
                    'Updating local table ${serverTable.table_id} with new data');
                await DatabaseHelper.instance.updateTables(serverTable);
              } else {
                log.info('Local table ${serverTable.table_id} is up-to-date');
              }
            } else {
              log.info(
                  'Inserting new table ${serverTable.table_id} into local database');
              await DatabaseHelper.instance.insertTable(serverTable);
            }
          } catch (e) {
            log.severe('Error processing table data: $tableData');
            log.severe('Exception: $e');
          }
        }
      } else {
        log.severe('Failed to load tables from server: ${response.statusCode}');
        throw Exception('Failed to load tables from server');
      }
    } catch (e) {
      log.severe('Error during syncTablesFromServer: $e');
    }
  }

  Future<void> syncTablesToServer(String idServer) async {
    try {
      log.info('Syncing tables to server with idServer: $idServer');

      // Fetch local tables
      List<TableModel> localTables = await DatabaseHelper.instance.getTables();
      log.info(
          'Local tables fetched: ${localTables.map((table) => table.toJson()).toList()}');

      // Filter tables that are not synced
      List<TableModel> unsyncedTables =
          localTables.where((table) => !table.synced).toList();
      log.info(
          'Unsynced tables: ${unsyncedTables.map((table) => table.toJson()).toList()}');

      if (unsyncedTables.isEmpty) {
        log.info('No unsynced tables to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'tables': unsyncedTables.map((table) => table.toJson()).toList(),
      };

      log.info('Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_tables'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('Successfully synced tables to server');
        log.info('Server logs: ${responseBody['log'].join('\n')}');
        await _updateTableStatus(unsyncedTables);
      } else {
        log.severe('Failed to sync tables to server: ${response.statusCode}');
        throw Exception('Failed to sync tables to server');
      }
    } catch (e) {
      log.severe('Error during syncTablesToServer: $e');
    }
  }

  Future<void> _updateTableStatus(List<TableModel> unsyncedTables) async {
    await DatabaseHelper.instance.updateAllTablesSyncedStatus(
      unsyncedTables.map((table) => table.table_id!).toList(),
    );
    log.info('Updated synced status for tables');
  }

  Future<void> syncTables(String idServer) async {
    log.info('Starting full sync for tables with idServer: $idServer');
    try {
      await syncTablesFromServer(idServer);
      await syncTablesToServer(idServer);
      log.info('Full table sync completed');
    } catch (e) {
      log.severe('Error during full table sync: $e');
    }
  }

  Future<void> deleteTableFromServer(
      String tableId, String sessionId, String userId) async {
    try {
      log.info('Deleting table from server: tableId=$tableId, userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_tables'),
        body: {
          'table_id': tableId,
          'session_id': sessionId,
          'user_id': userId,
        },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            log.info(
                'Table deleted successfully from server: tableId=$tableId');
          } else {
            log.severe(
                'Failed to delete table from server: ${responseBody['message']}');
            throw Exception('Failed to delete table from server');
          }
        } catch (e) {
          log.severe('Error parsing server response: $e');
          throw Exception('Failed to parse server response');
        }
      } else {
        log.severe(
            'Failed to delete table from server: ${response.statusCode}');
        throw Exception('Failed to delete table from server');
      }
    } catch (e) {
      log.severe('Error during deleteTableFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++TABLE+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++GUEST+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> _syncDeletedGuest() async {
    log.info('Checking server availability...');
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info('Syncing deleted Guest...');
    try {
      final deletedGuest = await DatabaseHelper.instance.getDeletedGuests();
      log.info('Fetched deleted Guest: $deletedGuest');

      for (var guest in deletedGuest) {
        String guestId = guest['guest_id'];
        String clientId = guest['client_id'];
        String userId = guest['user_id'];
        await deleteGuestFromServer(guestId, clientId, userId);
        log.info('Guest deleted from server: SI=$guestId GI=$clientId');
        await DatabaseHelper.instance
            .removeDeletedGuest(guestId, clientId, userId);
        log.info(
            'Removed deleted table from local database: SI=$guestId GI=$clientId');
      }
    } catch (e) {
      log.severe('Failed to sync deleted data: $e');
    }
  }

  Future<void> checkAndSyncGuests(String idServer) async {
    // Check internet connection
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await syncDeletedRecords(idServer);
      await _syncDeletedCheckIn();
      await _syncDeletedGuest();
      await syncGuests(idServer);
      await syncCheckIns(idServer);
    } catch (e) {
      log.severe('Failed to sync clients: $e');
    }
  }

  Future<void> syncGuestsFromServer(String idServer) async {
    try {
      log.info('Syncing guests from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_guests'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('Received response from server: ${response.body}');
        List<dynamic> serverGuests = jsonDecode(response.body);

        if (serverGuests.isEmpty) {
          log.info('No guests data received from server.');
          return;
        }

        for (var guestData in serverGuests) {
          Guest serverGuest = Guest.fromJson(guestData);

          // Check if the guest already exists in the local database
          Guest? localGuest =
              await DatabaseHelper.instance.getGuestById(serverGuest.guest_id!);

          if (localGuest != null) {
            DateTime serverUpdatedAt = DateTime.parse(serverGuest.updated_at!);
            DateTime localUpdatedAt = DateTime.parse(localGuest.updated_at!);

            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              log.info(
                  'Updating local guest ${serverGuest.guest_id} with new data');
              await DatabaseHelper.instance.updateGuest(serverGuest);
            } else {
              log.info('Local guest ${serverGuest.guest_id} is up-to-date');
            }
          } else {
            log.info(
                'Inserting new guest ${serverGuest.guest_id} into local database');
            await DatabaseHelper.instance.insertGuest(serverGuest);
          }
        }
      } else {
        log.severe('Failed to load guests from server: ${response.statusCode}');
        throw Exception('Failed to load guests from server');
      }
    } catch (e) {
      log.severe('Error during syncGuestsFromServer: $e');
    }
  }

  Future<void> syncGuestsToServer(String idServer) async {
    try {
      log.info(
          '+CHECKGUESTSYNC+ Syncing guests to server with idServer: $idServer');

      // Fetch local guests
      List<Guest> localGuests = await DatabaseHelper.instance.getGuests();
      log.info(
          '+CHECKGUESTSYNC+ Local guests fetched: ${localGuests.map((guest) => guest.toJson()).toList()}');

      // Filter guests that are not synced
      List<Guest> unsyncedGuests =
          localGuests.where((guest) => !guest.synced).toList();
      log.info(
          '+CHECKGUESTSYNC+ Unsynced guests: ${unsyncedGuests.map((guest) => guest.toJson()).toList()}');

      if (unsyncedGuests.isEmpty) {
        log.info('+CHECKGUESTSYNC+ No unsynced guests to send to server.');
        return;
      }

      log.info('+CHECKGUESTSYNC+ IDSCHECK: $idServer');

      final requestBody = {
        'idServer': idServer,
        'guests': unsyncedGuests.map((guest) => guest.toJson()).toList(),
      };

      log.info('+CHECKGUESTSYNC+ Request body for server: $requestBody');

      // Log the request URL, headers, and body
      log.info('+CHECKGUESTSYNC+ Request URL: $apiUrl/sync_guests');
      log.info('+CHECKGUESTSYNC+ Request Headers: ${{
        'Content-Type': 'application/json; charset=UTF-8',
      }}');
      log.info('+CHECKGUESTSYNC+ Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_guests'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('+CHECKGUESTSYNC+ Successfully synced guests to server');
        log.info(
            '+CHECKGUESTSYNC+ Server logs: ${responseBody['log'].join('\n')}');
        await _updateGuestStatus(unsyncedGuests);
      } else {
        log.severe(
            '+CHECKGUESTSYNC+ Failed to sync guests to server: ${response.statusCode}');
        throw Exception('Failed to sync guests to server');
      }
    } catch (e) {
      log.severe('+CHECKGUESTSYNC+ Error during syncGuestsToServer: $e');
    }
  }

  Future<void> _updateGuestStatus(List<Guest> unsyncedGuests) async {
    await DatabaseHelper.instance.updateAllGuestsSyncedStatus(
      unsyncedGuests.map((guest) => guest.guest_id!).toList(),
    );
    log.info('Updated synced status for guests');
  }

  Future<void> syncGuests(String idServer) async {
    log.info('Starting full sync for guests with idServer: $idServer');
    try {
      await syncGuestsFromServer(idServer);
      await syncGuestsToServer(idServer);
      log.info('Full guest sync completed');
    } catch (e) {
      log.severe('Error during full guest sync: $e');
    }
  }

  Future<void> deleteGuestFromServer(
      String guestId, String clientId, String userId) async {
    try {
      log.info('Deleting guest from server: guestId=$guestId, userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_guests'),
        body: {
          'guest_id': guestId,
          'client_id': clientId,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            log.info(
                'Guest deleted successfully from server: guestId=$guestId');
          } else {
            log.severe(
                'Failed to delete guest from server: ${responseBody['message']}');
            throw Exception('Failed to delete guest from server');
          }
        } catch (e) {
          log.severe('Error parsing server response: $e');
          throw Exception('Failed to parse server response');
        }
      } else {
        log.severe(
            'Failed to delete guest from server: ${response.statusCode}');
        throw Exception('Failed to delete guest from server');
      }
    } catch (e) {
      log.severe('Error during deleteGuestFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++GUEST+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++CHECK_IN+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> _syncDeletedCheckIn() async {
    log.info('Checking server availability...');
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    // Optional: Check server reachability if you have an endpoint to test
    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('--SERVER-- is not reachable.');
      return;
    }

    log.info('Syncing deleted CheckIn...');
    try {
      final deletedCheckIn = await DatabaseHelper.instance.getDeletedCheckIns();
      log.info('Fetched deleted CheckIn: $deletedCheckIn');

      for (var checkIn in deletedCheckIn) {
        String sessionId = checkIn['session_id'];
        String guestId = checkIn['guest_id'];
        String userId = checkIn['user_id'];
        await deleteCheckInFromServer(sessionId, guestId, userId);
        log.info('CheckIn deleted from server: SI=$sessionId GI=$guestId');
        await DatabaseHelper.instance
            .removeDeletedCheckIn(sessionId, guestId, userId);
        log.info(
            'Removed deleted table from local database: SI=$sessionId GI=$guestId');
      }
    } catch (e) {
      log.severe('Failed to sync deleted data: $e');
    }
  }

  Future<void> syncCheckInsFromServer(String idServer) async {
    try {
      log.info(
          '===SCIFS=== Syncing check-ins from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_check_ins'), // Updated API endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('===SCIFS=== Received response from server: ${response.body}');
        List<dynamic> serverCheckIns = jsonDecode(response.body);

        if (serverCheckIns.isEmpty) {
          log.info('===SCIFS=== No check-in data received from server.');
          return;
        }

        for (var checkInData in serverCheckIns) {
          CheckIn serverCheckIn = CheckIn.fromJson(checkInData);

          // Check if the check-in already exists in the local database
          CheckIn? localCheckIn = await DatabaseHelper.instance.getCheckInById(
            serverCheckIn.session_id,
            serverCheckIn.guest_id,
          );

          if (localCheckIn != null) {
            DateTime serverUpdatedAt =
                DateTime.parse(serverCheckIn.updated_at!);
            DateTime localUpdatedAt = DateTime.parse(localCheckIn.updated_at!);

            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              log.info(
                  '===SCIFS=== Updating local check-in ${serverCheckIn.session_id} - ${serverCheckIn.guest_id} with new data');
              await DatabaseHelper.instance.updateCheckIns(serverCheckIn);
            } else {
              log.info(
                  '===SCIFS=== Local check-in ${serverCheckIn.session_id} - ${serverCheckIn.guest_id} is up-to-date');
            }
          } else {
            log.info(
                '===SCIFS=== Inserting new check-in ${serverCheckIn.session_id} - ${serverCheckIn.guest_id} into local database');
            await DatabaseHelper.instance.insertCheckIns(serverCheckIn);
          }
        }
      } else {
        log.severe(
            '===SCIFS=== Failed to load check-ins from server: ${response.statusCode}');
        throw Exception('===SCIFS=== Failed to load check-ins from server');
      }
    } catch (e) {
      log.severe('===SCIFS=== Error during syncCheckInsFromServer: $e');
    }
  }

  Future<void> syncCheckInsToServer(String idServer) async {
    try {
      log.info('Syncing che~CI~ck-ins to server with idServer: $idServer');

      // Fetch local check-ins
      List<CheckIn> localCheckIns = await DatabaseHelper.instance.getCheckIns();
      log.info(
          '~CI~Local check-ins fetched: ${localCheckIns.map((checkIn) => checkIn.toJson()).toList()}');

      // Filter check-ins that are not synced
      List<CheckIn> unsyncedCheckIns =
          localCheckIns.where((checkIn) => !checkIn.synced).toList();
      log.info(
          '~CI~Unsynced check-ins: ${unsyncedCheckIns.map((checkIn) => checkIn.toJson()).toList()}');

      if (unsyncedCheckIns.isEmpty) {
        log.info('No unsynced~CI~ check-ins to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'check_ins':
            unsyncedCheckIns.map((checkIn) => checkIn.toJson()).toList(),
      };

      log.info('Request bod~CI~y for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_check_ins'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('Successfull~CI~y synced check-ins to server');
        log.info('Server logs~CI~: ${responseBody['log'].join('\n')}');

        // Optionally, you can handle the logs returned from the server
        List<String> serverLogs = List<String>.from(responseBody['log']);
        // Do something with the logs, e.g., display them or store them
      } else {
        log.severe(
            'Failed to sync check-ins to server: ${response.statusCode}\nResponse body: ${response.body}');
        throw Exception('Failed to sync check-ins to server');
      }
    } catch (e) {
      log.severe('Error during syncCheckInsToServer: $e');
    }
  }

  Future<void> _updateCheckInStatus(List<CheckIn> unsyncedCheckIns) async {
    await DatabaseHelper.instance.updateAllCheckInsSyncedStatus(
      unsyncedCheckIns
          .map((checkIn) => checkIn.session_id + checkIn.guest_id)
          .toList(),
    );
    log.info('Updated synced status for check-ins');
  }

  Future<void> syncCheckIns(String idServer) async {
    log.info('Starting full sync for check-ins with idServer: $idServer');
    try {
      await syncCheckInsFromServer(idServer);
      await syncCheckInsToServer(idServer);
      log.info('Full CheckIn sync completed');
    } catch (e) {
      log.severe('Error during full CheckIn sync: $e');
    }
  }

  Future<void> deleteCheckInFromServer(
      String sessionId, String guestId, String userId) async {
    try {
      log.info(
          'Deleting check-in from server: sessionId=$sessionId, guestId=$guestId, userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_check_ins'), // Updated API endpoint
        body: {
          'session_id': sessionId,
          'guest_id': guestId,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            log.info(
                'Check-in deleted successfully from server: sessionId=$sessionId, guestId=$guestId');
          } else {
            log.severe(
                'Failed to delete check-in from server: ${responseBody['message']}');
            throw Exception('Failed to delete check-in from server');
          }
        } catch (e) {
          log.severe('Error parsing server response: $e');
          throw Exception('Failed to parse server response');
        }
      } else {
        log.severe(
            'Failed to delete check-in from server: ${response.statusCode}');
        throw Exception('Failed to delete check-in from server');
      }
    } catch (e) {
      log.severe('Error during deleteCheckInFromServer: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++CHECK_IN+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++TEMPLATES+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Future<void> checkAndSyncTemplates(String idServer) async {
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await syncTemplatesFromServer(idServer);
      await syncTemplatesToServer(idServer);
    } catch (e) {
      log.severe('Failed to sync templates: $e');
    }
  }

// Fungsi untuk sinkronisasi data template dari server ke lokal
  Future<void> syncTemplatesFromServer(String idServer) async {
    try {
      log.info('Syncing templates from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_templates'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info('Received response from server: ${response.body}');
        List<dynamic> serverTemplates = jsonDecode(response.body);

        if (serverTemplates.isEmpty) {
          log.info('No templates data received from server.');
          return;
        }

        for (var templateData in serverTemplates) {
          Template serverTemplate = Template.fromJson(templateData);

          // Periksa apakah template dengan ID ini sudah ada di database lokal
          Template? localTemplate = await DatabaseHelper.instance
              .getTemplateById(serverTemplate.template_id!);

          if (localTemplate != null) {
            // Jika ada, periksa timestamp dan lakukan pembaruan jika perlu
            DateTime serverUpdatedAt =
                DateTime.parse(serverTemplate.updated_at!);
            DateTime localUpdatedAt = DateTime.parse(localTemplate.updated_at!);

            log.warning('Updating SERVER template ${serverUpdatedAt}');
            log.warning('Updating LOCAL template ${localUpdatedAt}');

            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              log.info(
                  'Updating local template ${serverTemplate.template_id} with new data');
              await DatabaseHelper.instance.updateTemplate(serverTemplate);
            } else {
              log.info(
                  'Local template ${serverTemplate.template_id} is up-to-date');
            }
          } else {
            // Jika tidak ada, tambahkan data baru ke database lokal
            log.info(
                'Inserting new template ${serverTemplate.template_id} into local database');
            await DatabaseHelper.instance.insertTemplate(serverTemplate);
          }
        }
      } else {
        log.severe(
            'Failed to load templates from server: ${response.statusCode}');
        throw Exception('Failed to load templates from server');
      }
    } catch (e) {
      log.severe('Error during syncTemplatesFromServer: $e');
    }
  }

// Fungsi untuk sinkronisasi data template dari lokal ke server
  Future<void> syncTemplatesToServer(String idServer) async {
    try {
      log.info(
          'CHECKTOSERVERTEMPLATES Syncing templates to server with idServer: $idServer');

      // Ambil data template lokal
      List<Template> localTemplates =
          await DatabaseHelper.instance.getTemplates();
      log.info(
          'CHECKTOSERVERTEMPLATES Local templates fetched: ${localTemplates.map((template) => template.toJson()).toList()}');

      // Filter template yang belum disinkronkan
      List<Template> unsyncedTemplates =
          localTemplates.where((template) => !template.synced).toList();
      log.info(
          'CHECKTOSERVERTEMPLATES Unsynced templates: ${unsyncedTemplates.map((template) => template.toJson()).toList()}');

      if (unsyncedTemplates.isEmpty) {
        log.info(
            'CHECKTOSERVERTEMPLATES No unsynced templates to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'templates':
            unsyncedTemplates.map((template) => template.toJson()).toList(),
      };

      log.info('CHECKTOSERVERTEMPLATES Request body for server: $requestBody');

      // Log sebelum mengirim request
      log.info(
          'CHECKTOSERVERTEMPLATES Sending POST request to: $apiUrl/sync_templates');
      log.info(
          'CHECKTOSERVERTEMPLATES Request Headers: { Content-Type: application/json; charset=UTF-8 }');
      String jsonBody = jsonEncode(requestBody);
      log.info(
          'CHECKTOSERVERTEMPLATES Request Body Part 1: ${jsonBody.substring(0, jsonBody.length ~/ 2)}');
      log.info(
          'CHECKTOSERVERTEMPLATES Request Body Part 2: ${jsonBody.substring(jsonBody.length ~/ 2)}');

      log.info('CHECKTOSERVERTEMPLATES Full Request Body: $jsonBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_templates'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonBody,
      );

      log.info(
          'CHECKTOSERVERTEMPLATES Server responded with status code: ${response.statusCode}');
      log.info('CHECKTOSERVERTEMPLATES Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info(
            'CHECKTOSERVERTEMPLATES Successfully synced templates to server');
        log.info(
            'CHECKTOSERVERTEMPLATES Server logs: ${responseBody['log'].join('\n')}');

        // Update status template menjadi synced
        await _updateTemplateStatus(unsyncedTemplates);
        log.info('CHECKTOSERVERTEMPLATES Templates status updated to synced.');
      } else {
        log.severe(
            'CHECKTOSERVERTEMPLATES Failed to sync templates to server: ${response.statusCode}');
        log.severe(
            'CHECKTOSERVERTEMPLATES Server response body: ${response.body}');
        throw Exception('Failed to sync templates to server');
      }
    } catch (e) {
      log.severe(
          'CHECKTOSERVERTEMPLATES Error during syncTemplatesToServer: $e');
    }
  }

  Future<void> _updateTemplateStatus(List<Template> unsyncedTemplates) async {
    // Update status synced setelah berhasil sinkronisasi
    await DatabaseHelper.instance.updateAllTemplatesSyncedStatus(
        unsyncedTemplates.map((template) => template.template_id!).toList());
    log.info('Updated synced status for templates');
  }

// Fungsi untuk sinkronisasi penuh (dua arah)
  Future<void> syncTemplates(String idServer) async {
    log.info('Starting full sync with idServer: $idServer');
    try {
      await syncTemplatesFromServer(idServer);
      await syncTemplatesToServer(idServer);
      log.info('Full sync completed');
    } catch (e) {
      log.severe('Error during full sync: $e');
    }
  }

  // +++++++++++++++++++++++++++++++++++++++++++++++++++++TEMPLATES+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  // +++++++++++++++++++++++++++++++++++++++++++++++++++++ANGPAU+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Future<void> _syncDeletedAngpaus() async {
//   log.info('Checking internet connection...');

//   // Check internet connection
//   bool isConnected = await checkInternetConnection();
//   if (!isConnected) {
//     log.warning('No internet connection available.');
//     return;
//   }

//   // Optional: Check server reachability if you have an endpoint to test
//   log.info('Checking server availability...');
//   bool serverReachable = await _checkServerReachability();
//   if (!serverReachable) {
//     log.warning('--SERVER-- is not reachable.');
//     return;
//   }

//   log.info('Syncing deleted angpaus...');
//   try {
//     final deletedAngpaus = await DatabaseHelper.instance.getDeletedAngpaus();
//     log.info('Fetched deleted Angpaus: $deletedAngpaus');

//     for (var angpau in deletedAngpaus) {
//       String angpauId = angpau['angpau_id'];
//       String sessionId = angpau['session_id'];
//       String userId = angpau['user_id'];
//       await deleteAngpauFromServer(angpauId, sessionId, userId);
//       log.info('Angpau deleted from server: angpauId=$angpauId');
//       await DatabaseHelper.instance.removeDeletedAngpau(angpauId, sessionId, userId);
//       log.info('Removed deleted angpau from local database: angpauId=$angpauId');
//     }
//   } catch (e) {
//     log.severe('Failed to sync deleted angpaus: $e');
//   }
// }

  Future<void> checkAndSyncAngpaus(String idServer) async {
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await syncAngpaus(idServer);
    } catch (e) {
      log.severe('Failed to sync ANGPAU: $e');
    }
  }

  Future<void> syncAngpausFromServer(String idServer) async {
    try {
      log.info(
          '+++ANGPAU+++ Syncing angpaus from server with idServer: $idServer');
      final body = jsonEncode({'idServer': idServer});

      final response = await http.post(
        Uri.parse('$apiUrl/get_angpaus'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        log.info(
            '+++ANGPAU+++ Received response from server: ${response.body}');
        List<dynamic> serverAngpaus = jsonDecode(response.body);

        if (serverAngpaus.isEmpty) {
          log.info('+++ANGPAU+++ No angpaus data received from server.');
          return;
        }

        for (var angpauData in serverAngpaus) {
          log.info('+++ANGPAU+++ Processing angpau data: $angpauData');

          try {
            AngpauModel serverAngpau = AngpauModel.fromJson(angpauData);

            // Check if the angpau already exists in the local database
            AngpauModel? localAngpau = await DatabaseHelper.instance
                .getAngpauById(serverAngpau.session_id, serverAngpau.key);

            if (localAngpau != null) {
              DateTime serverUpdatedAt =
                  DateTime.parse(serverAngpau.updated_at!);
              DateTime localUpdatedAt = DateTime.parse(localAngpau.updated_at!);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                log.info(
                    '+++ANGPAU+++ Updating local angpau ${serverAngpau.session_id} with new data');
                await DatabaseHelper.instance.updateAngpau(serverAngpau);
              } else {
                log.info(
                    '+++ANGPAU+++ Local angpau ${serverAngpau.session_id} is up-to-date');
              }
            } else {
              log.info(
                  '+++ANGPAU+++ Inserting new angpau ${serverAngpau.session_id} into local database');
              await DatabaseHelper.instance.insertAngpau(serverAngpau);
            }
          } catch (e) {
            log.severe(
                '+++ANGPAU+++ Error processing angpau data: $angpauData');
            log.severe('+++ANGPAU+++ Exception: $e');
          }
        }
      } else {
        log.severe(
            '+++ANGPAU+++ Failed to load angpaus from server: ${response.statusCode}');
        throw Exception('Failed to load angpaus from server');
      }
    } catch (e) {
      log.severe('+++ANGPAU+++ Error during syncAngpausFromServer: $e');
    }
  }

  Future<void> syncAngpausToServer(String idServer) async {
    try {
      log.info(
          '+++ANGPAU+++ Syncing angpaus to server with idServer: $idServer');

      // Fetch local angpaus
      List<AngpauModel> localAngpaus =
          await DatabaseHelper.instance.getAngpau();
      log.info(
          '+++ANGPAU+++ Local angpaus fetched: ${localAngpaus.map((angpau) => angpau.toJson()).toList()}');

      // Filter angpaus that are not synced
      List<AngpauModel> unsyncedAngpaus =
          localAngpaus.where((angpau) => !angpau.synced).toList();
      log.info(
          '+++ANGPAU+++ Unsynced angpaus: ${unsyncedAngpaus.map((angpau) => angpau.toJson()).toList()}');

      if (unsyncedAngpaus.isEmpty) {
        log.info('+++ANGPAU+++ No unsynced angpaus to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'angpaus': unsyncedAngpaus.map((angpau) => angpau.toJson()).toList(),
      };

      log.info('+++ANGPAU+++ Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_angpaus'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('+++ANGPAU+++ Successfully synced angpaus to server');
        log.info('+++ANGPAU+++ Server logs: ${responseBody['log'].join('\n')}');
        await _updateAngpauStatus(unsyncedAngpaus);
      } else {
        log.severe(
            '+++ANGPAU+++ Failed to sync angpaus to server: ${response.statusCode}');
        throw Exception('Failed to sync angpaus to server');
      }
    } catch (e) {
      log.severe('+++ANGPAU+++ Error during syncAngpausToServer: $e');
    }
  }

  Future<void> _updateAngpauStatus(List<AngpauModel> unsyncedAngpaus) async {
    final List<Map<String, String>> angpauKeys = [];

    // Mengumpulkan session_id dan key dari setiap angpau yang belum disinkronisasi
    for (var angpau in unsyncedAngpaus) {
      angpauKeys.add({
        'session_id': angpau.session_id,
        'key': angpau.key,
      });
    }

    // Memperbarui status synced untuk semua angpau sekaligus
    await DatabaseHelper.instance.updateAllAngpausSyncedStatus(angpauKeys);

    log.info('+++ANGPAU+++ Updated synced status for angpaus');
  }

  Future<void> syncAngpaus(String idServer) async {
    log.info(
        '+++ANGPAU+++ Starting full sync for angpaus with idServer: $idServer');
    try {
      await syncAngpausFromServer(idServer);
      await syncAngpausToServer(idServer);
      log.info('+++ANGPAU+++ Full angpau sync completed');
    } catch (e) {
      log.severe('+++ANGPAU+++ Error during full angpau sync: $e');
    }
  }

  Future<void> deleteAngpauFromServer(
      String angpauId, String sessionId, String userId) async {
    try {
      log.info(
          'Deleting angpau from server: angpauId=$angpauId, userId=$userId');
      final response = await http.post(
        Uri.parse('$apiUrl/delete_angpau'),
        body: {
          'angpau_id': angpauId,
          'session_id': sessionId,
          'user_id': userId,
        },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['status'] == 'success') {
            log.info(
                'Angpau deleted successfully from server: angpauId=$angpauId');
          } else {
            log.severe(
                'Failed to delete angpau from server: ${responseBody['message']}');
            throw Exception('Failed to delete angpau from server');
          }
        } catch (e) {
          log.severe('Error parsing server response: $e');
          throw Exception('Failed to parse server response');
        }
      } else {
        log.severe(
            'Failed to delete angpau from server: ${response.statusCode}');
        throw Exception('Failed to delete angpau from server');
      }
    } catch (e) {
      log.severe('Error during deleteAngpauFromServer: $e');
    }
  }
  // +++++++++++++++++++++++++++++++++++++++++++++++++++++ANGPAU+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++++++++++++++++++++++++++++++++++++++++++++++++++ENVELOPEENTRUST+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Future<void> _syncDeletedAngpaus() async {
//   log.info('Checking internet connection...');

//   // Check internet connection
//   bool isConnected = await checkInternetConnection();
//   if (!isConnected) {
//     log.warning('No internet connection available.');
//     return;
//   }

//   // Optional: Check server reachability if you have an endpoint to test
//   log.info('Checking server availability...');
//   bool serverReachable = await _checkServerReachability();
//   if (!serverReachable) {
//     log.warning('--SERVER-- is not reachable.');
//     return;
//   }

//   log.info('Syncing deleted angpaus...');
//   try {
//     final deletedAngpaus = await DatabaseHelper.instance.getDeletedAngpaus();
//     log.info('Fetched deleted Angpaus: $deletedAngpaus');

//     for (var angpau in deletedAngpaus) {
//       String angpauId = angpau['angpau_id'];
//       String sessionId = angpau['session_id'];
//       String userId = angpau['user_id'];
//       await deleteAngpauFromServer(angpauId, sessionId, userId);
//       log.info('Angpau deleted from server: angpauId=$angpauId');
//       await DatabaseHelper.instance.removeDeletedAngpau(angpauId, sessionId, userId);
//       log.info('Removed deleted angpau from local database: angpauId=$angpauId');
//     }
//   } catch (e) {
//     log.severe('Failed to sync deleted angpaus: $e');
//   }
// }

  Future<void> checkAndSyncEnvelope(String idServer) async {
    bool isConnected = await checkInternetConnection();
    if (!isConnected) {
      log.warning('No internet connection available.');
      return;
    }

    bool serverReachable = await _checkServerReachability();
    if (!serverReachable) {
      log.warning('Server is not reachable.');
      return;
    }

    log.info(
        'Internet connection available. Starting sync with idServer: $idServer');
    try {
      await syncEnvelope(idServer);
    } catch (e) {
      log.severe('Failed to sync ANGPAU: $e');
    }
  }

  Future<void> syncEnvelopeFromServer(String idServer) async {
    try {
      log.info(
          '+++ENVELOPEENTRUST+++ Syncing angpaus from server with idServer: $idServer');

      final body = jsonEncode({'idServer': idServer});
      log.info(
          '+++ENVELOPEENTRUST+++ Sending request to server: $apiUrl/get_angpau_titipan with body: $body');

      final response = await http.post(
        Uri.parse('$apiUrl/get_angpau_titipan'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      log.info(
          '+++ENVELOPEENTRUST+++ Received response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        log.info(
            '+++ENVELOPEENTRUST+++ Received response from server: ${response.body}');
        List<dynamic> serverEnvelope = jsonDecode(response.body);

        if (serverEnvelope.isEmpty) {
          log.info(
              '+++ENVELOPEENTRUST+++ No angpaus data received from server.');
          return;
        }

        log.info(
            '+++ENVELOPEENTRUST+++ Processing ${serverEnvelope.length} angpau records from server.');

        for (var envelopeData in serverEnvelope) {
          log.info(
              '+++ENVELOPEENTRUST+++ Processing angpau data: $envelopeData');

          try {
            AngpauTitipanModel serverEnvelope =
                AngpauTitipanModel.fromJson(envelopeData);
            log.info(
                '+++ENVELOPEENTRUST+++ Converted envelope data to model: $serverEnvelope');

            // Check if the angpau already exists in the local database
            AngpauTitipanModel? localEnvelope = await DatabaseHelper.instance
                .getEnvelopeById(serverEnvelope.angpau_titipan_id);
            log.info(
                '+++ENVELOPEENTRUST+++ Checking local database for angpau ID: ${serverEnvelope.angpau_titipan_id}');

            if (localEnvelope != null) {
              DateTime serverUpdatedAt =
                  DateTime.parse(serverEnvelope.updated_at!);
              DateTime localUpdatedAt =
                  DateTime.parse(localEnvelope.updated_at!);
              log.info(
                  '+++ENVELOPEENTRUST+++ Local updated at: $localUpdatedAt, Server updated at: $serverUpdatedAt');

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                log.info(
                    '+++ENVELOPEENTRUST+++ Updating local angpau ${serverEnvelope.angpau_titipan_id} with new data');
                await DatabaseHelper.instance.updateEnvelope(serverEnvelope);
                log.info(
                    '+++ENVELOPEENTRUST+++ Successfully updated local angpau ${serverEnvelope.angpau_titipan_id}');
              } else {
                log.info(
                    '+++ENVELOPEENTRUST+++ Local angpau ${serverEnvelope.angpau_titipan_id} is up-to-date');
              }
            } else {
              log.info(
                  '+++ENVELOPEENTRUST+++ Inserting new angpau ${serverEnvelope.angpau_titipan_id} into local database');
              await DatabaseHelper.instance.insertEnvelope(serverEnvelope);
              log.info(
                  '+++ENVELOPEENTRUST+++ Successfully inserted new angpau ${serverEnvelope.angpau_titipan_id}');
            }
          } catch (e) {
            log.severe(
                '+++ENVELOPEENTRUST+++ Error processing angpau data: $envelopeData');
            log.severe('+++ENVELOPEENTRUST+++ Exception: $e');
          }
        }
      } else {
        log.severe(
            '+++ENVELOPEENTRUST+++ Failed to load angpaus from server: ${response.statusCode}');
        throw Exception('Failed to load angpaus from server');
      }
    } catch (e) {
      log.severe(
          '+++ENVELOPEENTRUST+++ Error during syncEnvelopeFromServer: $e');
    }
  }

  Future<void> syncEnvelopeToServer(String idServer) async {
    try {
      log.info(
          '+++ENVELOPEENTRUST+++ Syncing angpaus to server with idServer: $idServer');

      // Fetch local angpaus
      List<AngpauTitipanModel> localEnvelope =
          await DatabaseHelper.instance.getEnvelope();
      log.info(
          '+++ENVELOPEENTRUST+++ Local angpaus fetched: ${localEnvelope.map((angpau) => angpau.toJson()).toList()}');

      // Filter angpaus that are not synced
      List<AngpauTitipanModel> unsyncedEnvelope =
          localEnvelope.where((angpau) => !angpau.synced).toList();
      log.info(
          '+++ENVELOPEENTRUST+++ Unsynced angpaus: ${unsyncedEnvelope.map((angpau) => angpau.toJson()).toList()}');

      if (unsyncedEnvelope.isEmpty) {
        log.info(
            '+++ENVELOPEENTRUST+++ No unsynced angpaus to send to server.');
        return;
      }

      final requestBody = {
        'idServer': idServer,
        'angpau_titipan':
            unsyncedEnvelope.map((angpau) => angpau.toJson()).toList(),
      };

      log.info('+++ENVELOPEENTRUST+++ Request body for server: $requestBody');

      final response = await http.post(
        Uri.parse('$apiUrl/sync_angpau_titipan'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        log.info('+++ENVELOPEENTRUST+++ Successfully synced angpaus to server');
        log.info(
            '+++ENVELOPEENTRUST+++ Server logs: ${responseBody['log'].join('\n')}');
        await _updateEnvelopeStatus(unsyncedEnvelope);
      } else {
        log.severe(
            '+++ENVELOPEENTRUST+++ Failed to sync angpaus to server: ${response.statusCode}');
        throw Exception('Failed to sync angpaus to server');
      }
    } catch (e) {
      log.severe('+++ENVELOPEENTRUST+++ Error during syncAngpausToServer: $e');
    }
  }

  Future<void> _updateEnvelopeStatus(
      List<AngpauTitipanModel> unsyncedEnvelope) async {
    final List<Map<String, String>> angpauKeys = [];

    // Mengumpulkan session_id dan key dari setiap angpau yang belum disinkronisasi
    for (var angpau in unsyncedEnvelope) {
      angpauKeys.add({
        'angpau_titipan_id': angpau.angpau_titipan_id,
      });
    }

    // Memperbarui status synced untuk semua angpau sekaligus
    await DatabaseHelper.instance.updateAllAngpausSyncedStatus(angpauKeys);

    log.info('+++ENVELOPE+++ Updated synced status for angpaus');
  }

  Future<void> syncEnvelope(String idServer) async {
    log.info(
        '+++Envelope+++ Starting full sync for angpaus with idServer: $idServer');
    try {
      await syncEnvelopeFromServer(idServer);
      await syncEnvelopeToServer(idServer);
      log.info('+++ANGPAU+++ Full angpau sync completed');
    } catch (e) {
      log.severe('+++ANGPAU+++ Error during full angpau sync: $e');
    }
  }

  // Future<void> deleteAngpauFromServer(
  //     String angpauId, String sessionId, String userId) async {
  //   try {
  //     log.info(
  //         'Deleting angpau from server: angpauId=$angpauId, userId=$userId');
  //     final response = await http.post(
  //       Uri.parse('$apiUrl/delete_angpau'),
  //       body: {
  //         'angpau_id': angpauId,
  //         'session_id': sessionId,
  //         'user_id': userId,
  //       },
  //     );

  //     // Check if response is successful
  //     if (response.statusCode == 200) {
  //       try {
  //         final responseBody = json.decode(response.body);
  //         if (responseBody['status'] == 'success') {
  //           log.info(
  //               'Angpau deleted successfully from server: angpauId=$angpauId');
  //         } else {
  //           log.severe(
  //               'Failed to delete angpau from server: ${responseBody['message']}');
  //           throw Exception('Failed to delete angpau from server');
  //         }
  //       } catch (e) {
  //         log.severe('Error parsing server response: $e');
  //         throw Exception('Failed to parse server response');
  //       }
  //     } else {
  //       log.severe(
  //           'Failed to delete angpau from server: ${response.statusCode}');
  //       throw Exception('Failed to delete angpau from server');
  //     }
  //   } catch (e) {
  //     log.severe('Error during deleteAngpauFromServer: $e');
  //   }
  // }
  // +++++++++++++++++++++++++++++++++++++++++++++++++++++ENVELOPEENTRUST+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
}
