import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../models/guest_model.dart';
import '../../services/database_helper.dart';
import '../../widgets/styles.dart';

class UpdateMDGuestScreen extends StatefulWidget {
  final Guest guest;
  final Function onUpdate;
  final String eventId;
  final String idServer;

  UpdateMDGuestScreen(
      {required this.guest,
      required this.onUpdate,
      required this.eventId,
      required this.idServer});

  @override
  _UpdateMDGuestScreenState createState() => _UpdateMDGuestScreenState();
}

class _UpdateMDGuestScreenState extends State<UpdateMDGuestScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('UpdateMDGuestScreen');

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _paxController;
  late TextEditingController _tablesAtGuestController;

  String _phoneCompleteNumber = '';
  String? _selectedCat;

  late Future<List<Map<String, String>>> _sessionFuture;
  late Future<List<Map<String, String>>> _sessionValue;

  List<String> _selectedSessionIds = [];
  @override
  void initState() {
    super.initState();

    _selectedCat = widget.guest.cat;
    _nameController = TextEditingController(text: widget.guest.name);
    _emailController = TextEditingController(text: widget.guest.email);
    _phoneCompleteNumber = widget.guest.phone ?? '';
    _paxController = TextEditingController(text: widget.guest.pax.toString());
    _tablesAtGuestController = TextEditingController(text: widget.guest.tables);
    _sessionFuture =
        DatabaseHelper.instance.getSessionIdsAndNamesByEventId(widget.eventId);
    _sessionValue = DatabaseHelper.instance
        .getSessionIdsAndNamesByGuestId(widget.guest.guest_id!);

    _sessionValue.then((value) {
      setState(() {
        _selectedSessionIds =
            value.map((session) => session['session_id']!).toList();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _paxController.dispose();
    _tablesAtGuestController.dispose();
    super.dispose();
  }

  Future<void> _updateGuest() async {
    if (_selectedSessionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one session.'),
          backgroundColor: AppColors.iconColorWarning,
        ),
      );
      return;
    } else {
      if (_formKey.currentState!.validate() ||
          _selectedSessionIds.isNotEmpty) {}
      final currentDateTime = DateTime.now().toIso8601String();
      Guest updatedGuest = widget.guest.copyWith(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneCompleteNumber,
          pax: int.tryParse(_paxController.text) ?? 1,
          cat: _selectedCat,
          tables: _tablesAtGuestController.text,
          synced: false,
          updated_at: currentDateTime);

      try {
        await DatabaseHelper.instance.updateGuest(updatedGuest);
        log.info('Guest ${updatedGuest.name} updated successfully.');

        final List<Map<String, dynamic>> relatedCheckIns = await DatabaseHelper
            .instance
            .getCheckInsByGuestId(widget.guest.guest_id!);
        for (var checkIn in relatedCheckIns) {
          await DatabaseHelper.instance.insertDeletedCheckIn(
              checkIn['session_id'], widget.guest.guest_id!, widget.idServer);
        }
        await DatabaseHelper.instance
            .deleteCheckInByGuestId(widget.guest.guest_id!);

        for (String sessionId in _selectedSessionIds) {
          print('c=$sessionId');
          await DatabaseHelper.instance
              .insertCheckIn(sessionId, widget.guest.guest_id!);
        }
        setState(() {});
        widget.onUpdate();
        Navigator.of(context).pop();
      } catch (e) {
        log.severe('Failed to update guest: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update guest.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppStyles.dialogBackgroundColor, // Latar belakang dialog
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Update Guest',
            style: AppStyles.dialogTitleTextStyle, // Gaya judul dialog
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.iconColor), // Warna ikon
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: FutureBuilder<List<Map<String, String>>>(
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
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: AppStyles.inputDecoration.copyWith(
                        labelText: 'Name',
                        labelStyle:
                            AppStyles.dialogContentTextStyle, // Gaya label
                      ),
                      style: AppStyles.dialogContentTextStyle, // Gaya teks
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
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
                    SizedBox(height: 10),
                    IntlPhoneField(
                      decoration: AppStyles.inputDecoration.copyWith(
                        labelText: 'Phone Number',
                        labelStyle:
                            AppStyles.dialogContentTextStyle, // Gaya label
                      ),
                      style: AppStyles.dialogContentTextStyle, // Gaya teks
                      initialCountryCode: 'ID',
                      initialValue: _phoneCompleteNumber,
                      onChanged: (phone) {
                        setState(() {
                          _phoneCompleteNumber = phone.completeNumber;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _paxController,
                      decoration: AppStyles.inputDecoration.copyWith(
                        labelText: 'PAX',
                        labelStyle:
                            AppStyles.dialogContentTextStyle, // Gaya label
                      ),
                      style: AppStyles.dialogContentTextStyle, // Gaya teks
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color.fromARGB(255, 50, 48, 39),
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
                        labelStyle: AppStyles.dialogContentTextStyle,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _tablesAtGuestController,
                      decoration: AppStyles.inputDecoration.copyWith(
                        labelText: 'Tables',
                        labelStyle:
                            AppStyles.dialogContentTextStyle, // Gaya label
                      ),
                      style: AppStyles.dialogContentTextStyle, // Gaya teks
                    ),
                    // Checklist untuk Session ID dan Session Name
                    SizedBox(height: 16),
                    Text(
                      'Select Sessions',
                      style: AppStyles.dialogContentTextStyle,
                    ),
                    ...sessions.map((session) {
                      bool isSelected =
                          _selectedSessionIds.contains(session['session_id']);
                      return CheckboxListTile(
                        title: Text(
                          session['session_name']!,
                          style: AppStyles.dialogContentTextStyle,
                        ),
                        value: isSelected,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedSessionIds.add(session['session_id']!);
                            } else {
                              _selectedSessionIds
                                  .remove(session['session_id']!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          }
        },
      ),
      actions: [
        TextButton(
          style: AppStyles.cancelButtonStyle, // Gaya tombol cancel
          onPressed: () {
            Navigator.of(context).pop(); // Tutup dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          style: AppStyles.addButtonStyle, // Gaya tombol update
          onPressed: _updateGuest,
          child: Text('Update'),
        ),
      ],
    );
  }
}
