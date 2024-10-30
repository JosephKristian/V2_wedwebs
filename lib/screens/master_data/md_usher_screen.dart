import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'md_event_screen.dart';
import 'insert_md_usher_screen.dart';
import 'update_md_usher_screen.dart';
import 'reset_password_md_usher_screen.dart';

import '../../services/data_service.dart';
import '../../services/database_helper.dart';
import '../../models/usher_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/styles.dart';

class MDUsherScreen extends StatefulWidget {
  final String role;
  final String idServer;

  MDUsherScreen({required this.role, required this.idServer});

  @override
  _MDUsherScreenState createState() => _MDUsherScreenState();
}

class _MDUsherScreenState extends State<MDUsherScreen> {
  final log = Logger('MDUsherScreen');
  late Future<List<Usher>> _ushersFuture; // Ganti Client dengan Usher
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    log.info('Initializing MDUsherScreen with idServer: ${widget.idServer}');
    _refreshUshers();
  }

  Future<void> _refreshUshers() async {
    log.info('Refreshing usher list');
    setState(() {
      _ushersFuture = DatabaseHelper.instance.getUshers().then((ushers) {
        log.info('Fetched ushers from local database: $ushers');
        List<Usher> filteredUshers = ushers.where((usher) {
          if (_searchQuery.isNotEmpty &&
              !usher.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !usher.email.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();
        log.info('Filtered ushers: $filteredUshers');
        return filteredUshers;
      });
    });
  }

  void _editUsher(BuildContext context, Usher usher) {
    log.info('Edit usher: ${usher.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UpdateMDUsherScreen(
          // Menggunakan UpdateMDUsherScreen
          usher: usher,
          onUpdate: () {
            log.info('Usher updated, refreshing usher list');
            _refreshUshers();
          },
        );
      },
    );
  }

  void _resetPassword(BuildContext context, Usher usher) {
    log.info('ResetPass usher: ${usher.name}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResetPasswordMDUsherScreen(
          // Menggunakan UpdateMDUsherScreen
          usher: usher,
          onUpdate: () {
            log.info('Pass updated, refreshing usher list');
            _refreshUshers();
          },
        );
      },
    );
  }

  Future<void> _deleteUsher(BuildContext context, Usher usher) async {
    log.info('Delete usher: ${usher.name}');
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
              'Are you sure you want to delete this usher? This action cannot be undone.',
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
                      'Deleting usher from local database: ${usher.usher_id}');
                  await DatabaseHelper.instance
                      .deleteUsher(usher.usher_id); // Ganti dengan deleteUsher
                  log.info(
                      'Inserting usher into deleted_ushers: ${usher.usher_id}');
                  await DatabaseHelper.instance.insertDeletedUsher(
                      usher.usher_id,
                      widget.idServer); // Ganti dengan insertDeletedUsher
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usher ${usher.name} berhasil dihapus.'),
                      backgroundColor: AppColors
                          .snackBarSuccessColor, // Warna background snackbar
                    ),
                  );
                  log.info('Usher ${usher.name} deleted successfully');
                  _refreshUshers();
                } catch (e) {
                  log.severe('Terjadi kesalahan saat menghapus usher: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus usher ${usher.name}.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Usher List',
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.iconColor),
            onPressed: () {
              log.info('Opening InsertMDUsherScreen');
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return InsertMDUsherScreen(
                    // Menggunakan InsertMDUsherScreen
                    onInsert: () {
                      log.info('Usher inserted, refreshing usher list');
                      _refreshUshers();
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.iconColor),
            onPressed: () {
              log.info('Refreshing usher list manually');
              _refreshUshers();
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
                        _refreshUshers();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Usher>>(
              future: _ushersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  log.severe('Error fetching ushers: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  log.info('Usher data fetched successfully');
                  List<Usher> ushers = snapshot.data!;
                  return ListView.builder(
                    itemCount: ushers.length,
                    itemBuilder: (context, index) {
                      final usher = ushers[index];
                      return CardPrimary(
                        title: Text(usher.name,
                            style: AppStyles.titleCardPrimaryTextStyle),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${usher.email ?? '-'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButtonGoldList(
                              icon: Icons.lock,
                              color: AppColors.dividerColor,
                              onPressed: () {
                                log.info('reset password: ${usher.name}');
                                _resetPassword(context, usher);
                              },
                              tooltip: 'Reset Password',
                            ),
                            IconButtonGoldList(
                              icon: Icons.edit,
                              color: AppColors.iconColorEdit,
                              onPressed: () {
                                log.info('Editing usher: ${usher.name}');
                                _editUsher(context, usher);
                              },
                              tooltip: 'Edit Usher',
                            ),
                            IconButtonGoldList(
                              icon: Icons.delete,
                              color: AppColors.iconColorWarning,
                              onPressed: () {
                                log.info('Deleting usher: ${usher.name}');
                                _deleteUsher(context, usher);
                              },
                              tooltip: 'Delete Usher',
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
