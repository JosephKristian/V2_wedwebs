import 'package:http/http.dart' as http;
import 'dart:convert';

import 'database_helper.dart'; // Import DatabaseHelper

class ApiService {
  static Future<String> _ipAddress() async {
    String ipAddress = '18.140.209.78';
    return ipAddress;
  }
  // static Future<String> _ipAddress() async {
  //   String ipAddress = 'wedwebtest.mooo.com';
  //   return ipAddress;
  // }

  // static Future<String> pathApi() async {
  //   String ipAddress = await _ipAddress();
  //   String pathApi = 'https://$ipAddress/API_Wed_Web';
  //   return pathApi;
  // }
  static Future<String> pathApi() async {
    String ipAddress = await _ipAddress();
    String pathApi = 'http://$ipAddress/api';
    return pathApi;
  }

  static Future<String> ipAddress() async {
    String ipAddress = await _ipAddress();
    String path = 'http://$ipAddress';
    return path;
  }

  // Fungsi untuk mengambil data client dari SQLite dan memetakan ulang untuk sinkronisasi ke server
  static Future<void> syncClientDataToServer(int idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> clientData = await dbHelper.getAllClientData();
    print('Client data fetched from local database: $clientData');

    // Pemetaan data client agar sesuai dengan struktur di server
    List<Map<String, dynamic>> mappedClientData = clientData.map((client) {
      return {
        'client_id': client['client_id'],
        'user_temp_id': client['user_id'],
        'user_id': '$idServer',
        'name': client['name'],
        'email': client['email'],
        'phone': client['phone'],
      };
    }).toList();
    print('Mapped client data for server: $mappedClientData');

    // Mengirim data client yang telah dipetakan ke server
    await syncClientToServer(mappedClientData, idServer);
  }

  // Fungsi untuk mengirim data client yang telah dipetakan ke server
  static Future<void> syncClientToServer(
      List<Map<String, dynamic>> clientData, int idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_client_to_server'),
        body: {
          'clientData': jsonEncode(clientData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }

  static Future<void> syncUsersTempDataToServer(String idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    try {
      // Mengambil data client dari database lokal
      List<Map<String, dynamic>> usersData = await dbHelper.getAllUsersData();
      print('Users data fetched from local database: $usersData');

      // Pemetaan data client agar sesuai dengan struktur di server
      List<Map<String, dynamic>> mappedUsersData = usersData.map((user) {
        return {
          'user_temp_id': user['user_id'], // Pemetaan ID lokal ke ID server
          'user_id': idServer, // ID server yang dikirimkan
          'name': user['name'],
          'email': user['email'],
          'password': user['password'], // Pertimbangkan keamanan password
          'role': user['role'],
          'created_at': user['created_at'],
          'updated_at': user['updated_at'],
        };
      }).toList();
      print('Mapped user data for server: $mappedUsersData');

      // Mengirim data yang telah dipetakan ke server
      await syncUsersTempToServer(mappedUsersData, idServer);
    } catch (e) {
      print('Error syncing user data to server: $e');
    }
  }

  // Fungsi untuk mengirim data Users yang telah dipetakan ke server
  static Future<void> syncUsersTempToServer(
      List<Map<String, dynamic>> usersData, String idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_users_temp_to_server'),
        body: {
          'usersData': jsonEncode(usersData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }

  // Fungsi untuk mengambil data client dari SQLite dan memetakan ulang untuk sinkronisasi ke server
  static Future<void> syncEventDataToServer(int idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> eventData = await dbHelper.getAllEventData();
    print('Client data fetched from local database: $eventData');

    // Pemetaan data client agar sesuai dengan struktur di server
    List<Map<String, dynamic>> mappedEventData = eventData.map((event) {
      return {
        'event_id': event['event_id'],
        'client_id': event['client_id'],
        'user_id': '$idServer',
        'event_name': event['event_name'],
        'date': event['date'],
      };
    }).toList();
    print('Mapped client data for server: $mappedEventData');

    // Mengirim data client yang telah dipetakan ke server
    await syncEventToServer(mappedEventData, idServer);
  }

  // Fungsi untuk mengirim data client yang telah dipetakan ke server
  static Future<void> syncEventToServer(
      List<Map<String, dynamic>> eventData, int idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_event_to_server'),
        body: {
          'eventData': jsonEncode(eventData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }

  // Fungsi untuk mengambil data client dari SQLite dan memetakan ulang untuk sinkronisasi ke server
  static Future<void> syncGuestDataToServer(int idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> guestData = await dbHelper.getAllGuestData();
    print('Client data fetched from local database: $guestData');

    // Pemetaan data client agar sesuai dengan struktur di server
    List<Map<String, dynamic>> mappedGuestData = guestData.map((guest) {
      return {
        'guest_id': guest['guest_id'],
        'client_id': guest['client_id'],
        'user_id': '$idServer',
        'guest_qr': guest['guest_qr'],
        'name': guest['name'],
        'email': guest['email'],
        'phone': guest['phone'],
        'pax': guest['pax'],
        'tables': guest['tables'],
        'rsvp': guest['rsvp'],
        'cat': guest['cat'],
      };
    }).toList();
    print('Mapped client data for server: $mappedGuestData');

    // Mengirim data client yang telah dipetakan ke server
    await syncGuestToServer(mappedGuestData, idServer);
  }

  // Fungsi untuk mengirim data client yang telah dipetakan ke server
  static Future<void> syncGuestToServer(
      List<Map<String, dynamic>> guestData, int idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_guest_to_server'),
        body: {
          'guestData': jsonEncode(guestData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }

  // Fungsi untuk mengambil data client dari SQLite dan memetakan ulang untuk sinkronisasi ke server
  static Future<void> syncSessionDataToServer(int idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> sessionData = await dbHelper.getAllSessionData();
    print('Client data fetched from local database: $sessionData');

    // Pemetaan data client agar sesuai dengan struktur di server
    List<Map<String, dynamic>> mappedSessionData = sessionData.map((session) {
      return {
        'session_id': session['session_id'],
        'event_id': session['event_id'],
        'user_id': '$idServer',
        'session_name': session['session_name'],
        'time': session['time'],
        'location': session['location'],
      };
    }).toList();
    print('Mapped client data for server: $mappedSessionData');

    // Mengirim data client yang telah dipetakan ke server
    await syncSessionToServer(mappedSessionData, idServer);
  }

  // Fungsi untuk mengirim data client yang telah dipetakan ke server
  static Future<void> syncSessionToServer(
      List<Map<String, dynamic>> sessionData, int idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_session_to_server'),
        body: {
          'sessionData': jsonEncode(sessionData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }

// Fungsi untuk mengambil data client dari SQLite dan memetakan ulang untuk sinkronisasi ke server
  static Future<void> syncTableDataToServer(int idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> tableData = await dbHelper.getAllTableData();
    print('Client data fetched from local database: $tableData');

    // Pemetaan data client agar sesuai dengan struktur di server
    List<Map<String, dynamic>> mappedTableData = tableData.map((table) {
      return {
        'table_id': table['table_id'],
        'session_id': table['session_id'],
        'user_id': '$idServer',
        'table_name': table['table_name'],
        'seat': table['seat'],
      };
    }).toList();
    print('Mapped client data for server: $mappedTableData');

    // Mengirim data client yang telah dipetakan ke server
    await syncTableToServer(mappedTableData, idServer);
  }

  // Fungsi untuk mengirim data client yang telah dipetakan ke server
  static Future<void> syncTableToServer(
      List<Map<String, dynamic>> tableData, int idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_table_to_server'),
        body: {
          'tableData': jsonEncode(tableData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }

  static Future<void> syncCheckInDataToServer(int idServer) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> checkInData = await dbHelper.getAllCheckInData();
    print('Client data fetched from local database: $checkInData');

    // Pemetaan data client agar sesuai dengan struktur di server
    List<Map<String, dynamic>> mappedCheckInData = checkInData.map((checkIn) {
      return {
        'session_id': checkIn['session_id'],
        'guest_id': checkIn['guest_id'],
        'user_id': '$idServer',
        'souvenir': checkIn['souvenir'],
        'angpau': checkIn['angpau'],
        'pax_checked': checkIn['pax_checked'],
        'meals': checkIn['meals'],
        'note': checkIn['note'],
        'delivery': checkIn['delivery'],
        'guestNo': checkIn['guestNo'],
        'status': checkIn['status'],
      };
    }).toList();
    print('Mapped client data for server: $mappedCheckInData');

    // Mengirim data client yang telah dipetakan ke server
    await syncCheckInToServer(mappedCheckInData, idServer);
  }

  // Fungsi untuk mengirim data client yang telah dipetakan ke server
  static Future<void> syncCheckInToServer(
      List<Map<String, dynamic>> checkInData, int idServer) async {
    String apiPath = await pathApi();
    print('API Path for sync: $apiPath');
    try {
      final response = await http.post(
        Uri.parse('$apiPath/sync_check_in_to_server'),
        body: {
          'checkInData': jsonEncode(checkInData),
          'idServer': idServer.toString(), // Mengirimkan idServer
        },
      );

      print('Sync response status: ${response.statusCode}');
      print('Sync response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to sync data to server');
      } else {
        // Optional: Tampilkan pesan sukses
        print('Data synchronized successfully.');
      }
    } catch (e) {
      print('Error during sync to server: $e');
    }
  }
}
