import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../services/database_helper.dart';
import '../../models/guest_model.dart';
import '../../widgets/styles.dart';
import '../../services/generate_link_rsvp.dart';

class InsertMdGuestScreenUser extends StatefulWidget {
  final Function() onInsert;
  final String eventId;
  final String idServer;
  final String clientId;
  final Map<String, dynamic>? guestData;
  final currentDateTime = DateTime.now().toIso8601String();

  InsertMdGuestScreenUser(
      {required this.idServer,
      required this.onInsert,
      required this.eventId,
      required this.clientId,
      this.guestData});

  @override
  _InsertMdGuestScreenUserState createState() =>
      _InsertMdGuestScreenUserState();
}

class _InsertMdGuestScreenUserState extends State<InsertMdGuestScreenUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _paxController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();
  final _uuid = Uuid();
  String _selectedCat = 'REGULAR';
  String _guestQR = '';
  String _phoneCompleteNumber = '';
  String? clientId;
  List<String> _selectedSessionIds = [];
  List<String> sessionIds = [];
  List<Contact> _filteredContacts = [];

  bool isLoading = false;

  Future<List<Map<String, String>>>? _sessionFuture;

  final Logger _logger = Logger('InsertMdGuestScreenUser');
  static const platform = MethodChannel('com.example/storage');

  @override
  void initState() {
    super.initState();
    getClientId();
    _setupLogging();
    _sessionFuture =
        DatabaseHelper.instance.getSessionIdsAndNamesByEventId(widget.eventId);
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  Future<void> getClientId() async {
    try {
      String? fetchedClientId =
          await DatabaseHelper.instance.getClientIdByEventId(widget.eventId);

      if (fetchedClientId != null) {
        setState(() {
          clientId = fetchedClientId;
        });
      } else {
        throw Exception(
            'Client ID tidak ditemukan untuk event ID ${widget.eventId}');
      }
    } catch (e) {
      _logger.severe('Error fetching client ID: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _paxController.dispose();
    super.dispose();
  }

  Future<void> _generateQR() async {
    _guestQR = UniqueKey().toString();
  }

  Future<void> _insertGuest() async {
    try {
      if (_formKey.currentState!.validate() && _selectedSessionIds.isNotEmpty) {
        if (_selectedSessionIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select at least one session.'),
              backgroundColor: AppColors.iconColorWarning,
            ),
          );
          return;
        }

        await _generateQR();
        String uuid = _uuid.v4();

        // Membuat objek Guest baru
        Guest newGuest = Guest(
          guest_id: uuid,
          client_id: widget.clientId,
          guest_qr: _guestQR,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneCompleteNumber,
          pax: int.tryParse(_paxController.text) ?? 1,
          cat: _selectedCat,
          updated_at: widget.currentDateTime,
        );

        // Menyisipkan tamu ke database
        String guestId =
            (await DatabaseHelper.instance.insertGuest(newGuest)) as String;
        _logger.info('Guest inserted with ID: $guestId');

        // Menyisipkan check-in untuk session ID yang dipilih
        for (String sessionId in _selectedSessionIds) {
          await DatabaseHelper.instance.insertCheckIn(sessionId, guestId);
          _logger.info(
              'Inserted check-in for session ID: $sessionId and guest ID: $guestId');
        }

        widget
            .onInsert(); // Memanggil callback onInsert untuk memperbarui data di layar sebelumnya
        Navigator.of(context).pop(true);
      } else {
        _logger.warning('Form validation failed or clientId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form validation failed or clientId is null')),
        );
      }
    } catch (e) {
      _logger.severe('Error inserting guest: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting guest: ${e.toString()}')),
      );
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.isGranted) {
      return;
    }

    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  // Fungsi untuk meminta izin akses kontak
  Future<void> _requestPermission() async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      await Permission.contacts.request();
    }
  }

// Fungsi untuk mengambil nomor telepon dari kontak
  Future<void> _pickContact() async {
    setState(() {
      isLoading = true; // Tampilkan indikator loading
    });

    // Minta izin untuk mengakses kontak
    if (await FlutterContacts.requestPermission()) {
      try {
        List<Contact> contacts =
            await FlutterContacts.getContacts(withProperties: true);
        _filteredContacts = contacts.toList(); // Simpan semua kontak di awal

        Contact? selectedContact = await showModalBottomSheet<Contact>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    // TextField untuk pencarian
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          // Filter kontak berdasarkan input
                          setState(() {
                            _filteredContacts = contacts.where((contact) {
                              return contact.displayName
                                      .toLowerCase()
                                      .contains(value.toLowerCase()) ||
                                  contact.phones.any(
                                      (phone) => phone.number.contains(value));
                            }).toList();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Search Contacts',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return ListTile(
                            leading: (contact.photoOrThumbnail != null &&
                                    contact.photoOrThumbnail!.isNotEmpty)
                                ? CircleAvatar(
                                    backgroundImage:
                                        MemoryImage(contact.photoOrThumbnail!))
                                : CircleAvatar(child: Icon(Icons.person)),
                            title: Text(contact.displayName ?? 'No Name'),
                            subtitle: Text(contact.phones.isNotEmpty
                                ? contact.phones.first.number
                                : 'No phone number'),
                            onTap: () {
                              Navigator.pop(context, contact);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );

        // Cek jika ada kontak yang dipilih dan memiliki nomor telepon
        if (selectedContact != null && selectedContact.phones.isNotEmpty) {
          // Memformat nomor telepon
          setState(() {
            _phoneCompleteNumber = selectedContact.phones.first.number;
            _phoneController.text = _phoneCompleteNumber;
          });
        }
      } catch (e) {
        // Tangani error jika terjadi
        print('Error fetching contacts: $e');
      } finally {
        setState(() {
          isLoading = false; // Sembunyikan loading setelah modal muncul
        });
      }
    } else {
      // Jika izin tidak diberikan, tunjukkan pesan
      setState(() {
        isLoading = false; // Sembunyikan loading
      });
      // Tampilkan pesan izin tidak diberikan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access contacts is denied.')),
      );
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('+62')) {
      return phoneNumber.replaceFirst('+62', ''); // Hilangkan +62
    } else if (phoneNumber.startsWith('0')) {
      return phoneNumber.replaceFirst('0', ''); // Hilangkan 0
    }
    return phoneNumber; // Jika tidak ada awalan yang dihilangkan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBarColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        foregroundColor: AppColors.iconColor,
        title: Text(
          'Insert Guest',
          style: AppStyles.titleCardPrimaryTextStyle,
        ),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sessions found.'));
          } else {
            List<Map<String, String>> sessions = snapshot.data!;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.appBarColor, // Warna latar belakang kartu
              ),
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: AppStyles.inputDecoration.copyWith(
                            labelText: 'Name',
                            labelStyle:
                                AppStyles.dialogContentTextStyle, // Gaya label
                          ),
                          style: AppStyles.dialogContentTextStyle, // Gaya teks
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a name'
                              : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: AppStyles.inputDecoration.copyWith(
                            labelText: 'Email',
                            labelStyle:
                                AppStyles.dialogContentTextStyle, // Gaya label
                          ),
                          style: AppStyles.dialogContentTextStyle, // Gaya teks
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),
                        IntlPhoneField(
                          controller: _phoneController,
                          decoration: AppStyles.inputDecoration.copyWith(
                            labelText: 'Phone Number',
                            labelStyle: AppStyles.dialogContentTextStyle,
                            suffixIcon: isLoading
                                ? CircularProgressIndicator() // Tampilkan loading saat isLoading true
                                : IconButton(
                                    icon: Icon(Icons.contacts,
                                        color: AppColors.iconColor),
                                    onPressed: isLoading
                                        ? null
                                        : _pickContact, // Blokir jika loading
                                  ),
                          ),
                          style: AppStyles.dialogContentTextStyle,
                          initialCountryCode: 'ID',
                          onChanged: (phone) =>
                              _phoneCompleteNumber = phone.completeNumber,
                        ),

                        SizedBox(height: 16),
                        TextFormField(
                          controller: _paxController,
                          decoration: AppStyles.inputDecoration.copyWith(
                            labelText: 'Pax',
                            labelStyle:
                                AppStyles.dialogContentTextStyle, // Gaya label
                          ),
                          style: AppStyles.dialogContentTextStyle, // Gaya teks
                          keyboardType: TextInputType.number,
                          validator: (value) => value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null
                              ? 'Please enter a valid number'
                              : null,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          dropdownColor: Color.fromARGB(255, 50, 48, 39),
                          value: _selectedCat,
                          items: ['REGULAR', 'VIP', 'VVIP']
                              .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    style: AppStyles.dialogContentTextStyle,
                                  )))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCat = value!),
                          decoration: AppStyles.inputDecoration.copyWith(
                            labelText: 'Category',
                            labelStyle:
                                AppStyles.dialogContentTextStyle, // Gaya label
                          ),
                        ),
                        // Checklist untuk Session ID dan Session Name
                        SizedBox(height: 16),
                        Text(
                          'Select Sessions',
                          style: AppStyles.dialogContentTextStyle,
                        ),
                        ...sessions.map((session) {
                          return CheckboxListTile(
                            title: Text(
                              session['session_name']!, // Tampilkan nama sesi
                              style: AppStyles.dialogContentTextStyle,
                            ),
                            value: _selectedSessionIds
                                .contains(session['session_id']),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedSessionIds.add(session[
                                      'session_id']!); // Simpan session_id
                                } else {
                                  _selectedSessionIds
                                      .remove(session['session_id']!);
                                }
                              });
                            },
                          );
                        }).toList(),

                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _insertGuest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.iconColor,
                            foregroundColor: AppColors.gradientEndColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Insert Guest',
                              style: AppStyles.buttonTextStyle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
