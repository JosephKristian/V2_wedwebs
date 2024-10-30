import 'package:flutter/material.dart';
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/guest_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/services/database_helper.dart';
import 'package:wedweb/widgets/styles.dart';

class EnvelopeEntrustScreen extends StatelessWidget {
  final String idServer;
  final String role;
  final String clientId;
  final String clientName;
  final Event event;
  final Guest guest;
  final Session session;
  final String name;
  final String counterLabel;

  const EnvelopeEntrustScreen({
    Key? key,
    required this.idServer,
    required this.role,
    required this.clientId,
    required this.clientName,
    required this.event,
    required this.guest,
    required this.session,
    required this.name,
    required this.counterLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    return AlertDialog(
      title: Text('Entrust Envelope'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Input nama',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Tutup dialog tanpa menyimpan
          },
          child: Text('Cancel',
              style: TextStyle(
                color: Colors.red,
              )),
        ),
        TextButton(
          onPressed: () async {
            // Logika untuk konfirmasi (misalnya, simpan data)
            String enteredName = nameController.text;
            if (enteredName.isNotEmpty) {
              _insertEnvelopeEntrust(enteredName, context);
              print('Name entered: $enteredName');

              Navigator.of(context).pop();
            } else {
              // Tampilkan pesan kesalahan jika nama kosong
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Field Name Can\'t empty')),
              );
            }
          },
          child: Text('Confirm'),
        ),
      ],
    );
  }

  Future<void> _insertEnvelopeEntrust(String name, BuildContext context) async {
    final dbHelper = DatabaseHelper.instance;
    try {
      await dbHelper.insertEnvelopeEntrust(
        session.session_id!,
        guest.guest_id!,
        name,
        counterLabel,
      );
      // Tampilkan SnackBar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envelope entrusted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // Tampilkan SnackBar kesalahan jika ada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to entrust envelope: $error')),
      );
    }
  }
}
