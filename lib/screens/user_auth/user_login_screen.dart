import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/styles.dart';
import '../../screens/loading_screen.dart';

import '../../services/api_service.dart';

class UserLoginScreen extends StatefulWidget {
  @override
  _UserLoginScreenState createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // State for password visibility

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email cannot be empty')),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid email format')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password cannot be empty')),
      );
      return;
    }

    // Tampilkan loading indicator
    showLoadingDialog(context);
    try {
      String apiPath = await ApiService.pathApi();
      print('API Path: $apiPath');
      final response = await http.post(
        Uri.parse('$apiPath/login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Handle successful login
        String idServer = responseData['user_id'];
        String role = responseData['role'];
        String key = responseData['key'];
        String name = responseData['name'];
        String message = responseData['message'] ?? 'Login successful';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        try {} catch (e) {}
        hideLoadingDialog(context); // Stop loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingScreen(
                idServer: idServer, role: role, superKey: key, name: name),
          ),
        );
      } else {
        // Handle login error
        String error = responseData['error'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        hideLoadingDialog(context); // Stop loading on error
      }
    } catch (e) {
      // Handle other errors, such as network issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      hideLoadingDialog(context); // Stop loading on exception
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Checking..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        // Menggunakan SingleChildScrollView untuk scroll
        child: Center(
          // Memastikan konten berada di tengah
          child: Padding(
            padding: AppStylesNew.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png', // Sesuaikan dengan lokasi logo di proyekmu
                  height: 200, // Sesuaikan ukuran logo
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome to Wedwebs!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Warna sesuai gambar
                  ),
                  textAlign:
                      TextAlign.center, // Memastikan teks berada di tengah
                ),
                SizedBox(height: 30),
                Container(
                  width:
                      screenWidth * 0.7, // Atur lebar sesuai persentase layar
                  child: TextField(
                    controller: _emailController,
                    decoration: AppStylesNew.emailInputDecoration,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width:
                      screenWidth * 0.7, // Atur lebar sesuai persentase layar
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: AppStylesNew.passwordInputDecoration(
                      _obscurePassword,
                      _togglePasswordVisibility,
                    ), // Gunakan style password dari style.dart
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login',
                      style: AppStylesNew
                          .loginButtonText), // Gunakan style tombol dari style.dart
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors
                        .iconColor, // Warna tombol sesuai gambar (emas)
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.29, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Atur radius sesuai kebutuhan
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
