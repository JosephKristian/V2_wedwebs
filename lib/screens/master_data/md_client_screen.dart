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

class MDClientScreen extends StatefulWidget {
  final String role;
  final String idServer;

  MDClientScreen({required this.role, required this.idServer});

  @override
  _MDClientScreenState createState() => _MDClientScreenState();
}

class _MDClientScreenState extends State<MDClientScreen> {
  final log = Logger('MDClientScreen');
  late Future<List<Client>> _clientsFuture;
  String _searchQuery = '';
  final DataService _dataService = DataService(); // Inisialisasi DataService

  @override
  void initState() {
    super.initState();
    log.info('Initializing MDClientScreen with idServer: ${widget.idServer}');
    _refreshClients();
  }

  Future<void> _refreshClients() async {
    log.info('Refreshing client list');
    setState(() {
      _clientsFuture = DatabaseHelper.instance.getClients().then((clients) {
        log.info('Fetched clients from local database: $clients');
        List<Client> filteredClients = clients.where((client) {
          if (_searchQuery.isNotEmpty &&
              !client.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !client.email
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();
        log.info('Filtered clients: $filteredClients');
        return filteredClients;
      });
    });
  }

  void _editClient(BuildContext context, Client client) {
    log.info('Edit client: ${client.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateMDClientScreen(
          client: client,
          onUpdate: () {
            log.info('Client updated, refreshing client list');
            _refreshClients();
          },
        );
      },
    );
  }

  Future<void> _deleteClient(BuildContext context, Client client) async {
    log.info('Delete client: ${client.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              AppStyles.dialogBackgroundColor, // Warna latar belakang dialog
          title: Text(
            'Confirm Deletion',
            style: AppStyles.dialogTitleTextStyle, // Gaya judul dialog
          ),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Are you sure you want to delete this client? This action cannot be undone.',
              style: AppStyles.dialogContentTextStyle, // Gaya teks konten
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: AppStyles.cancelButtonStyle, // Gaya tombol cancel
              onPressed: () {
                log.info('Delete operation cancelled');
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: AppStyles.buttonTextStyle, // Gaya teks tombol
              ),
            ),
            ElevatedButton(
              style: AppStyles.deleteButtonStyle, // Gaya tombol delete
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  log.info(
                      'Deleting client from local database: ${client.client_id}');
                  await DatabaseHelper.instance.deleteClient(client.client_id!);
                  log.info(
                      'Inserting client into deleted_clients: ${client.client_id}');
                  await DatabaseHelper.instance
                      .insertDeletedClient(client.client_id!, widget.idServer);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Client ${client.name} berhasil dihapus.'),
                      backgroundColor: AppColors
                          .snackBarSuccessColor, // Warna background snackbar
                    ),
                  );
                  log.info('Client ${client.name} deleted successfully');
                  _refreshClients();
                } catch (e) {
                  log.severe('Terjadi kesalahan saat menghapus client: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus client ${client.name}.'),
                      backgroundColor: AppColors
                          .snackBarErrorColor, // Warna background snackbar
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: AppStyles.buttonTextStyle, // Gaya teks tombol
              ),
            ),
          ],
        );
      },
    );
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
            icon: Icon(Icons.add, color: AppColors.iconColor),
            onPressed: () {
              log.info('Opening InsertMDClientScreen');
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return InsertMDClientScreen(
                    onInsert: () {
                      log.info('Client inserted, refreshing client list');
                      _refreshClients();
                    },
                  );
                },
              );
            },
          ),
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
                              icon: Icons.edit,
                              color: AppColors.iconColorEdit,
                              onPressed: () {
                                log.info('Editing client: ${client.name}');
                                _editClient(context, client);
                              },
                              tooltip: 'Edit Client',
                            ),
                            IconButtonGoldList(
                              icon: Icons.delete,
                              color: AppColors.iconColorWarning,
                              onPressed: () {
                                log.info('Deleting client: ${client.name}');
                                _deleteClient(context, client);
                              },
                              tooltip: 'Delete Client',
                            ),
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
