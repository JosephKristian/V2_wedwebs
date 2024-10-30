import 'dart:convert'; // Import untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../../services/database_helper.dart';
import '../../models/usher_model.dart';
import '../../widgets/styles.dart';
import '../../services/api_service.dart'; // Import API service untuk hashing password

class ResetPasswordMDUsherScreen extends StatefulWidget {
  final Usher usher;
  final Function() onUpdate;

  ResetPasswordMDUsherScreen({required this.usher, required this.onUpdate});

  @override
  _ResetPasswordMDUsherScreenState createState() =>
      _ResetPasswordMDUsherScreenState();
}

class _ResetPasswordMDUsherScreenState
    extends State<ResetPasswordMDUsherScreen> {
  final _formKey = GlobalKey<FormState>();
  final log = Logger('ResetPasswordMDUsherScreen');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  void _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        String newPasswordHashed = await hashPassword(_passwordController.text);
        final currentDateTime = DateTime.now().toIso8601String();

        Usher updatedUsher = Usher(
          usher_id: widget.usher.usher_id,
          client_id: widget.usher.client_id,
          name: widget.usher.name,
          email: widget.usher.email,
          password: newPasswordHashed, // Password baru yang di-hash
          createdAt: widget.usher.createdAt,
          updatedAt: currentDateTime,
        );

        await DatabaseHelper.instance.updateUsher(updatedUsher);
        log.info(
            'Password for Usher ${updatedUsher.name} updated successfully.');

        widget.onUpdate();
        Navigator.of(context).pop();
      } catch (e) {
        log.severe('Failed to update password: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password.'),
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
            'Reset Password Usher',
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
                controller: _passwordController,
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'New Password',
                ),
                style: AppStyles.dialogContentTextStyle,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: AppStyles.inputDecoration.copyWith(
                  labelText: 'Confirm Password',
                ),
                style: AppStyles.dialogContentTextStyle,
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
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
          onPressed: _updatePassword,
          child: Text('Update'),
        ),
      ],
    );
  }
}
