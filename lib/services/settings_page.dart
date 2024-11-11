import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_bus/event_bus.dart';
import 'package:wedweb/models/event_model.dart';
import 'package:wedweb/models/session_model.dart';
import 'package:wedweb/screens/dashboard_user_screen.dart';
import 'package:wedweb/services/abjad_event.dart';
import 'package:wedweb/services/database_helper.dart';

class SettingsPage extends StatefulWidget {
  final String role;
  final String idServer;
  final String clientId;
  final String clientName;
  final String name;
  final Event event;
  final Session session;

  SettingsPage({
    required this.idServer,
    required this.name,
    required this.role,
    required this.clientId,
    required this.clientName,
    required this.event,
    required this.session,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isQrEnabled = false;
  bool _isAngpauEnabled = false;
  bool _isCNEnabled = false;
  EventBus eventBus = EventBus();
  String _selectedAbjad = 'A'; // Abjad default
  List<String> _abjadList = List.generate(
      26, (index) => String.fromCharCode(65 + index)); // Abjad A-Z

  @override
  void initState() {
    super.initState();
    _loadQrStatus();
    _loadCNStatus();
    _loadAngpauStatus();
    _loadAbjadSetting(); // Load abjad setting saat inisialisasi
  }

  Future<void> _loadQrStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isQrEnabled = prefs.getBool('qr_enabled') ?? false;
    });
  }

  Future<void> _loadCNStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCNEnabled = prefs.getBool('CN_enabled') ?? false;
    });
  }

  Future<void> _loadAngpauStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAngpauEnabled = prefs.getBool('Angpau_enabled') ?? false;
    });
  }

  Future<void> _loadAbjadSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAbjad =
          prefs.getString('angpau_abjad') ?? 'A'; // Ambil abjad yang disimpan
    });
  }

  Future<void> _toggleQr(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isQrEnabled = value;
      prefs.setBool('qr_enabled', value);
    });
  }

  Future<void> _toggleCN(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCNEnabled = value;
      prefs.setBool('CN_enabled', value);
    });
  }

  Future<void> _toggleAngpau(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAngpauEnabled = value;
      prefs.setBool('Angpau_enabled', value);
    });
  }

  Future<void> _saveAbjadSetting(String abjad) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'angpau_abjad', abjad); // Simpan abjad di SharedPreferences

    final dbHelper =
        DatabaseHelper.instance; // Gunakan instance dari DatabaseHelper
    await dbHelper.insertKeyAngpau(
        abjad, widget.session.session_id!); // Simpan ke database
    eventBus.fire(AbjadEvent(abjad));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Tambahkan padding
        child: Column(
          children: [
            ListTile(
              title: Text('Enable QR Code'),
              trailing: Switch(
                value: _isQrEnabled,
                onChanged: (value) {
                  _toggleQr(value);
                },
              ),
            ),
            ListTile(
              title: Text('Enable Category Number'),
              trailing: Switch(
                value: _isCNEnabled,
                onChanged: (value) {
                  _toggleCN(value);
                },
              ),
            ),
            ListTile(
              title: Text('Enable Angpau'),
              trailing: Switch(
                value: _isAngpauEnabled,
                onChanged: (value) {
                  _toggleAngpau(value);
                },
              ),
            ),
            const SizedBox(height: 16), // Spasi antara ListTile dan Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Pilih Abjad Angpau',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedAbjad,
              items: _abjadList.map((abjad) {
                return DropdownMenuItem<String>(
                  value: abjad,
                  child: Text(abjad),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedAbjad = newValue!;
                });
                _saveAbjadSetting(newValue!);
                _navigateToDashboardUserScreen();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDashboardUserScreen() {
    // Logika navigasi ke halaman berikutnya
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardUserScreen(
          session: widget.session,
          event: widget.event,
          name: widget.name,
          clientId: widget.clientId,
          role: widget.role,
          idServer: widget.idServer,
          clientName: widget.name,
        ),
      ),
    );
  }
}
