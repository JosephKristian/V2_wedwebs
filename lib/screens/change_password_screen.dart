import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String idServer;
  final String role;

  ChangePasswordDialog({required this.idServer, required this.role});

  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final log = Logger('_ChangePasswordDialogState');

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmNewPasswordError;

  void validateInputs() async {
    setState(() {
      _oldPasswordError = _oldPasswordController.text.isEmpty ? 'Old password cannot be empty' : null;
      _newPasswordError = _validatePassword(_newPasswordController.text) ? null : 'New password must be a combination of letters and numbers, at least 8 characters long';
      _confirmNewPasswordError = _confirmNewPasswordController.text.isEmpty ? 'Password confirmation cannot be empty' : null;

      if (_newPasswordController.text != _confirmNewPasswordController.text) {
        _confirmNewPasswordError = 'New passwords do not match';
      }
    });

    log.info('Input validation completed: $_oldPasswordError, $_newPasswordError, $_confirmNewPasswordError');

    if (_oldPasswordError == null && _newPasswordError == null && _confirmNewPasswordError == null) {
      String oldPassword = _oldPasswordController.text;
      String newPassword = _newPasswordController.text;

      try {
        log.info('Changing password for user with ID: ${widget.idServer} and role: ${widget.role}');

        AuthService authService = AuthService();
        bool success = await authService.changePassword(widget.idServer, oldPassword, newPassword);

        if (success) {
          log.info('Password successfully changed');
          Navigator.of(context).pop(); // Close dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Password Changed'),
              content: Text('New password has been saved successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          log.warning('Failed to change password');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Failed to change password. Please check your old password.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        log.severe('An error occurred while changing the password: $e');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while changing the password: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      log.warning('Validation failed with errors: $_oldPasswordError, $_newPasswordError, $_confirmNewPasswordError');
    }
  }

  bool _validatePassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    log.info('ChangePasswordDialog widget built');

    return AlertDialog(
      title: Text('Password ${widget.role}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Old Password',
                errorText: _oldPasswordError,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                errorText: _newPasswordError,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmNewPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm New Password',
                errorText: _confirmNewPasswordError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            validateInputs();
          },
          child: Text('Change Password'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
