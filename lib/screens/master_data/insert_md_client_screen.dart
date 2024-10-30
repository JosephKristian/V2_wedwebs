import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../widgets/styles.dart';
import '../../services/database_helper.dart';
import '../../models/client_model.dart';

class InsertMDClientScreen extends StatefulWidget {
  final Function() onInsert;

  InsertMDClientScreen({required this.onInsert});

  @override
  _InsertMDClientScreenState createState() => _InsertMDClientScreenState();
}

class _InsertMDClientScreenState extends State<InsertMDClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('InsertMDClientScreen');
  final _uuid = Uuid();
  late final String apiUrl;
  String? _emailError;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _phoneCompleteNumber = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      apiUrl = await ApiService.pathApi();
    } catch (e) {
      print('Error initializing API URL: $e');
    }
  }

  Future<bool> checkEmailUnique(String email) async {
    final response =
        await http.get(Uri.parse('$apiUrl/check-email-client?email=$email'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['isUnique'];
    } else {
      throw Exception('Failed to check email uniqueness');
    }
  }

  void _insertClient() async {
    if (_formKey.currentState!.validate()) {
      // Cek apakah email sudah ada
      bool isUnique = await checkEmailUnique(_emailController.text);

      if (!isUnique) {
        setState(() {
          _emailError = 'Email already exists';
        });
        return; // Hentikan proses jika email sudah ada
      }

      // Jika email unik, lanjutkan proses insert
      try {
        final currentDateTime = DateTime.now().toUtc().toIso8601String();
        String uuid = _uuid.v4();

        // Buat client baru
        Client newClient = Client(
          client_id: uuid,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneCompleteNumber,
          created_at: currentDateTime,
          updated_at: currentDateTime,
        );

        // Masukkan client ke database
        await DatabaseHelper.instance.insertClient(newClient);
        log.info('Client ${newClient.name} inserted successfully.');

        // Data dummy templates
        List<Map<String, String>> templates = [
          {
            'key': 'template1',
            'greeting': 'Hello',
            'opening': 'Welcome to...',
            'link': 'http://example.com',
            'closing': 'Best regards',
          },
          {
            'key': 'template2',
            'greeting': 'Hi',
            'opening': 'We are glad...',
            'link': 'http://example2.com',
            'closing': 'Sincerely',
          },
          {
            'key': 'template3',
            'greeting': 'Dear',
            'opening': 'This is...',
            'link': 'http://example3.com',
            'closing': 'Regards',
          },
          {
            'key': 'template4',
            'greeting': 'Hey',
            'opening': 'Thanks for...',
            'link': 'http://example4.com',
            'closing': 'Cheers',
          },
        ];

        // Masukkan data templates ke tabel
        for (var template in templates) {
          String uuidT = _uuid.v4();
          await DatabaseHelper.instance.insertTemplateDummy({
            'template_id': uuidT,
            'client_id': uuid, // Gunakan client_id dari client yang baru dibuat
            'key': template['key']!,
            'greeting': template['greeting']!,
            'opening': template['opening']!,
            'link': template['link']!,
            'closing': template['closing']!,
            'synced': 0,
            'created_at': currentDateTime,
            'updated_at': currentDateTime,
          });
        }

        widget.onInsert(); // Callback setelah insert
        Navigator.of(context).pop(); // Kembali ke layar sebelumnya
      } catch (e) {
        log.severe('Failed to insert client: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert client.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppStyles.dialogBackgroundColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add New Client',
            style: AppStyles.dialogTitleTextStyle,
          ),
          IconButton(
            icon: Icon(Icons.close),
            color: AppColors.iconColor, // Warna ikon sesuai tema
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).orientation == Orientation.portrait
            ? MediaQuery.of(context).size.width * 0.8
            : MediaQuery.of(context).size.width * 0.5,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Name',
                  ),
                  style: AppStyles.dialogContentTextStyle,
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
                  ),
                  style: AppStyles.dialogContentTextStyle,
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
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      bool isUnique = await checkEmailUnique(value);
                      setState(() {
                        _emailError = isUnique ? null : 'Email already exists';
                      });
                    } else {
                      setState(() {
                        _emailError = null;
                      });
                    }
                  },
                ),
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _emailError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: 10),
                IntlPhoneField(
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Phone Number',
                  ),
                  style: AppStyles.dialogContentTextStyle,
                  initialCountryCode: 'ID',
                  onChanged: (phone) {
                    _phoneCompleteNumber = phone.completeNumber;
                    log.info('Phone number changed: $_phoneCompleteNumber');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: AppStyles.cancelButtonStyle,
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: AppStyles.addButtonStyle,
          child: Text('Insert'),
          onPressed: _insertClient,
        ),
      ],
    );
  }
}
