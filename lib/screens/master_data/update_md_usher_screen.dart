import 'dart:convert'; // Import untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../services/database_helper.dart';
import '../../models/usher_model.dart';
import '../../models/client_model.dart'; // Import model client
import '../../widgets/styles.dart';

class UpdateMDUsherScreen extends StatefulWidget {
  final Usher usher;
  final Function() onUpdate;

  UpdateMDUsherScreen({required this.usher, required this.onUpdate});

  @override
  _UpdateMDUsherScreenState createState() => _UpdateMDUsherScreenState();
}

class _UpdateMDUsherScreenState extends State<UpdateMDUsherScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('UpdateMDUsherScreen');

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  List<Client> _clientList = [];
  List<String> _selectedClientIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.usher.name);
    _emailController = TextEditingController(text: widget.usher.email);
    _selectedClientIds = jsonDecode(widget.usher.client_id!).cast<String>();
    _fetchClients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
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

  void _updateUsher() async {
    if (_formKey.currentState!.validate()) {
      try {
        final currentDateTime = DateTime.now().toUtc().toString();

        String clientIdsJson = jsonEncode(_selectedClientIds);

        Usher updatedUsher = Usher(
          usher_id: widget.usher.usher_id,
          client_id: clientIdsJson,
          name: _nameController.text,
          email: _emailController.text,
          password: widget.usher.password, // Retain existing password
          createdAt: widget.usher.createdAt,
          updatedAt: currentDateTime,
        );

        await DatabaseHelper.instance.updateUsher(updatedUsher);
        log.info('Usher ${updatedUsher.name} updated successfully.');

        widget.onUpdate();
        Navigator.of(context).pop();
      } catch (e) {
        log.severe('Failed to update usher: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update usher.'),
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
            'Update Usher',
            style: AppStyles.dialogTitleTextStyle,
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.iconColor),
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
              ),
              SizedBox(height: 10),
              Text(
                'Select Clients',
                style: AppStyles.dialogContentTextStyle,
              ),
              _buildClientChecklist(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: AppStyles.cancelButtonStyle,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          style: AppStyles.addButtonStyle,
          onPressed: _updateUsher,
          child: Text('Update'),
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
