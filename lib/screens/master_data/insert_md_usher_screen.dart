import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../widgets/styles.dart';
import '../../services/database_helper.dart';
import '../../services/api_service.dart';
import '../../models/usher_model.dart'; // Import model Usher
import '../../models/client_model.dart'; // Import model client

class InsertMDUsherScreen extends StatefulWidget {
  final Function() onInsert;

  InsertMDUsherScreen({required this.onInsert});

  @override
  _InsertMDUsherScreenState createState() => _InsertMDUsherScreenState();
}

class _InsertMDUsherScreenState extends State<InsertMDUsherScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('InsertMDUsherScreen');
  final _uuid = Uuid();
  late final String apiUrl;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _passwordController =
      TextEditingController(); // Controller untuk password

  List<Client> _clientList = [];
  List<String> _selectedClientIds = [];
  bool isLoading = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _clientIdController.dispose();
    _passwordController.dispose(); // Dispose controller password
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
        await http.get(Uri.parse('$apiUrl/check-email-usher?email=$email'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['isUnique'];
    } else {
      throw Exception('Failed to check email uniqueness');
    }
  }

  void _fetchClients() async {
    try {
      List<Client> clients = await DatabaseHelper.instance.getClients();
      setState(() {
        _clientList = clients;
      });
    } catch (e) {
      log.severe('Failed to fetch clients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load clients.'),
        ),
      );
    }
  }

  Future<String> hashPassword(String password) async {
    String apiPath = await ApiService.pathApi();
    final response = await http.post(
      Uri.parse('$apiPath/make_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hashed_password'];
    } else {
      throw Exception('Failed to hash password');
    }
  }

  void _insertUsher() async {
    if (_formKey.currentState!.validate()) {
      bool isUnique = await checkEmailUnique(_emailController.text);

      if (!isUnique) {
        setState(() {
          _emailError = 'Email already exists';
        });
        return; // Hentikan proses jika email sudah ada
      }

      try {
        final currentDateTime = DateTime.now().toUtc().toIso8601String();
        String uuid = _uuid.v4();

        String clientIdsJson = jsonEncode(_selectedClientIds);
        log.info('Inserting new usher with the following details:');
        log.info('Usher ID: $uuid');
        log.info('Name: ${_nameController.text}');
        log.info('Email: ${_emailController.text}');

        // Meng-hash password melalui API
        String hashedPassword = await hashPassword(_passwordController.text);
        log.info('Hashed Password: $hashedPassword');

        Usher newUsher = Usher(
          usher_id: uuid,
          client_id: clientIdsJson,
          name: _nameController.text,
          email: _emailController.text,
          password: hashedPassword,
          createdAt: currentDateTime,
          updatedAt: currentDateTime,
        );

        await DatabaseHelper.instance.insertUsher(newUsher);
        log.info('Usher ${newUsher.name} inserted successfully.');

        widget.onInsert();
        Navigator.of(context).pop(); // Menutup dialog setelah selesai
      } catch (e) {
        log.severe('Failed to insert usher: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert usher.'),
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
            'Add New Usher',
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
                TextFormField(
                  controller: _passwordController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Password',
                  ),
                  style: AppStyles.dialogContentTextStyle,
                  obscureText: true, // Membuat input password tidak terlihat
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                Text(
                  'Select Clients',
                  style: AppStyles.dialogContentTextStyle,
                ),
                _buildClientChecklist(), // Menampilkan checklist client
                SizedBox(height: 10),
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
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text('Currently registering usher'),
                  ],
                )
              : Text('Insert'),
          onPressed: isLoading ? null : _insertUsher,
        ),
      ],
    );
  }

  Widget _buildClientChecklist() {
    if (_clientList.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: _clientList.map((client) {
        return CheckboxListTile(
          title: Text(
            client.name,
            style: AppStyles.dialogContentTextStyle,
          ),
          value: _selectedClientIds.contains(client.client_id),
          onChanged: (bool? isChecked) {
            setState(() {
              if (isChecked != null && isChecked) {
                _selectedClientIds.add(client.client_id!);
              } else {
                _selectedClientIds.remove(client.client_id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
