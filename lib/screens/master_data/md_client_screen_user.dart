import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'md_event_screen.dart';
import 'insert_md_client_screen.dart';
import 'update_md_client_screen.dart';

import '../../services/data_service.dart'; // Pastikan path-nya benar
import '../../services/database_helper.dart';
import '../../models/client_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/styles.dart'; // Import gaya dari styles.dart

class MDClientScreenUser extends StatefulWidget {
  final String role;
  final String idServer;

  MDClientScreenUser({required this.role, required this.idServer});

  @override
  _MDClientScreenUserState createState() => _MDClientScreenUserState();
}

class _MDClientScreenUserState extends State<MDClientScreenUser> {
  final log = Logger('MDClientScreenUser');
  late Future<List<Client>> _clientsFuture = Future.value([]);
  String _searchQuery = '';
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    log.info(
        'Initializing MDClientScreenUser with idServer: ${widget.idServer}');
    _refreshClients();
  }

  Future<void> _refreshClients() async {
    log.info('Refreshing client list');
    _clients.clear(); // Kosongkan daftar klien sebelum mengisi ulang

    try {
      log.info(
          'Fetching client IDs from login'); // Log informasi pengambilan ID klien

      final dbHelper = DatabaseHelper();
      String? jsonClientIds = await dbHelper
          .getClientIdsFromLogin(); // Ambil client ID dari tabel login

      if (jsonClientIds != null) {
        log.info(
            'Raw client IDs from login: $jsonClientIds'); // Log ID klien mentah

        // Dekode JSON
        List<String> clientIds = List<String>.from(json.decode(jsonClientIds));
        log.info(
            'Client IDs retrieved: $clientIds'); // Log ID klien yang diambil

        // Ambil data klien berdasarkan client id satu per satu
        for (String clientId in clientIds) {
          log.info(
              'Fetching client with ID: $clientId'); // Log pengambilan klien
          Map<String, dynamic>? client =
              await dbHelper.getClientForUser(clientId); // Mengambil klien
          if (client != null) {
            _clients.add(client); // Tambahkan klien ke daftar
            log.info(
                'Client fetched: ${client['name']}'); // Log klien yang berhasil diambil
          } else {
            log.warning(
                'No client found for ID: $clientId'); // Log jika klien tidak ditemukan
          }
        }
        List<Client> clientList = _clients.map((clientMap) {
          return Client.fromMap(
              clientMap); // Pastikan ada metode fromMap di kelas Client
        }).toList();
        setState(() {
          // Mengisi _clientsFuture setelah berhasil mengambil data klien
          _clientsFuture = Future.value(
              clientList); // Mengisi _clientsFuture dengan data klien
        });
      } else {
        log.warning(
            'No client IDs found in login table.'); // Log jika tidak ada ID klien
      }
    } catch (e) {
      log.severe('Error fetching clients: $e'); // Log jika terjadi kesalahan
    }
  }

  void _viewGuests(BuildContext context, Client client) {
    log.info('View guests of client: ${client.name}');
    if (client.client_id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MDEventScreen(
                idServer: widget.idServer,
                role: widget.role,
                clientName: client.name,
                clientId: client.client_id!)),
      );
    } else {
      log.warning('Client ID is null for client: ${client.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client ID is null for client ${client.name}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Client List',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.iconColor),
            onPressed: () {
              log.info('Refreshing client list manually');
              _refreshClients();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.iconColor),
                      labelText: 'Search',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                    ),
                    onChanged: (value) {
                      log.info('Search query changed: $value');
                      setState(() {
                        _searchQuery = value;
                        _refreshClients();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _clientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  log.severe('Error fetching clients: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  log.info('Client data fetched successfully');
                  List<Client> clients = snapshot.data!;
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return CardPrimary(
                        title: Text(client.name,
                            style: AppStyles.titleCardPrimaryTextStyle),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${client.email ?? '-'}'),
                            Text('Phone: ${client.phone ?? '-'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButtonGoldList(
                              icon: Icons.person,
                              color: AppColors.iconColor,
                              onPressed: () {
                                log.info(
                                    'Viewing guests of client: ${client.name}');
                                _viewGuests(context, client);
                              },
                              tooltip: 'View Guests',
                            ),
                          ],
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
    );
  }
}
