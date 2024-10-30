import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/database_helper.dart';
import '../../models/client_model.dart';
import '../../widgets/styles.dart';

class UpdateMDClientScreen extends StatefulWidget {
  final Client client;
  final Function() onUpdate;

  UpdateMDClientScreen({required this.client, required this.onUpdate});

  @override
  _UpdateMDClientScreenState createState() => _UpdateMDClientScreenState();
}

class _UpdateMDClientScreenState extends State<UpdateMDClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('UpdateMDClientScreen');

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String _phoneCompleteNumber = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone);
    _phoneCompleteNumber = widget.client.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateClient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final currentDateTime = DateTime.now()
            .toUtc()
            .toIso8601String(); // Mendapatkan waktu saat ini

        Client updatedClient = Client(
          client_id: widget.client.client_id,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneCompleteNumber,
          created_at:
              widget.client.created_at, // Pertahankan nilai created_at asli
          updated_at: currentDateTime, // Atur updated_at ke waktu saat ini
        );

        await DatabaseHelper.instance.updateClient(updatedClient);
        log.info(
            'Client ${updatedClient.name} updated successfully. ${updatedClient.created_at} | ${updatedClient.updated_at}');

        widget
            .onUpdate(); // Panggil fungsi onUpdate setelah berhasil memperbarui data

        Navigator.of(context).pop(); // Tutup dialog
      } catch (e) {
        log.severe('Failed to update client: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update client.'),
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
            'Update Client',
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
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Name',
                  labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
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
                  labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                ),
                style: AppStyles.dialogContentTextStyle, // Gaya teks
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              IntlPhoneField(
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Phone Number',
                  labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                ),
                style: AppStyles.dialogContentTextStyle, // Gaya teks
                initialCountryCode: 'ID',
                initialValue: _phoneController.text,
                onChanged: (phone) {
                  _phoneCompleteNumber = phone.completeNumber;
                },
              ),
            ],
          ),
        ),
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
          onPressed: _updateClient,
          child: Text('Update'),
        ),
      ],
    );
  }
}
