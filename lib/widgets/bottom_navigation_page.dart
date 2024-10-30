import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/data_service.dart';
import '../services/dropdown_provider.dart';
import '../screens/master_data/md_client_screen.dart';
import '../screens/master_data/md_usher_screen.dart';
import '../screens/event_screen.dart';
import '../screens/statistic/user_stat_screen.dart';
import '../screens/user_auth/user_login_screen.dart';
import '../widgets/styles.dart';
import '../widgets/custom_app_bar.dart';
import '../services/database_helper.dart';
import '../services/sync_provider.dart';

class BottomNavigationPage extends StatefulWidget {
  final String idServer;
  final String role;

  BottomNavigationPage({required this.idServer, required this.role});

  @override
  _BottomNavigationPageState createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  int _selectedIndex = 0;
  bool _isFullscreen = false;
  late final List<Widget> _pages;

  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    _pages = [
      UserStatScreen(
        idServer: widget.idServer,
        isFullscreen: _isFullscreen,
        onToggleFullscreen: _toggleFullscreen,
      ),
      MDClientScreen(role: widget.role, idServer: widget.idServer),
      EventScreen(role: widget.role, idServer: widget.idServer),
      MDUsherScreen(role: widget.role, idServer: widget.idServer),
    ];
    _initialize();
    _syncProvider();
  }

  Future<void> _initialize() async {
    try {
      apiUrl = await ApiService.pathApi();
    } catch (e) {
      print('Error initializing API URL: $e');
    }
  }

  void _syncProvider() async {
    final dbHelper = DatabaseHelper();
    String? idServer = await dbHelper.getIdServer();
    if (idServer != null) {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      syncProvider
          .updateIdServer(idServer); // Perbarui idServer dan mulai sinkronisasi
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Widget _buildPageContent(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildBottomNavigationItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      splashColor: AppColors.gradientEndColor,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 4.0), // Kurangi padding vertikal
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.selectedItemColor
                  : AppColors.unselectedItemColor,
            ),
            SizedBox(height: 2), // Kurangi jarak antara Icon dan Text
            Text(
              label,
              style: AppStyles.bottomNavTextStyle.copyWith(
                color: isSelected
                    ? AppColors.selectedItemColor
                    : AppColors.unselectedItemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen
          ? null
          : CustomAppBar(
              title: 'Admin',
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, color: AppColors.iconColor),
                  onPressed: () async {
                    _showLogoutConfirmationDialog(context);
                  },
                ),
              ],
            ),
      body: _pages[_selectedIndex],
      // Menggunakan kustom bottom navigation
      bottomNavigationBar: Visibility(
        visible: _isFullscreen != true, // Toggle visibility based on state
        child: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 9.0,
          child: Container(
            color: AppColors.appBarColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavigationItem(Icons.dashboard, 'Dashboard', 0),
                _buildBottomNavigationItem(Icons.person_pin, 'Client', 1),
                _buildBottomNavigationItem(Icons.event, 'Event', 2),
                _buildBottomNavigationItem(
                    Icons.person_2_outlined, 'Ushers', 3),
              ],
            ),
          ),
          color: AppColors.bottomAppBarColor,
        ),
      ),
    );
  }

  Future<bool> checkInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<bool> _checkServerReachability() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _syncData() async {
    final _dataService = DataService();
    List<Future<void>> syncTasks = [
      _dataService.checkAndSyncClients(widget.idServer),
      _dataService.checkAndSyncEvents(widget.idServer),
      _dataService.checkAndSyncEventsSessionsTables(widget.idServer),
      _dataService.checkAndSyncGuests(widget.idServer),
      _dataService.checkAndSyncUshers(widget.idServer),
    ];

    await Future.wait(syncTasks.take(3));
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
                Text("Sync data. Please wait..."),
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

  void _logout(BuildContext context) async {
    try {
      bool isInternetConnected = await checkInternetConnection();
      if (!isInternetConnected) {
        _showLogoutErrorNotification(
            context, 'No internet connection. Please check your internet!.');
        return; // Keluar dari fungsi logout
      }

      // Periksa kesehatan server
      bool isServerReachable = await _checkServerReachability();
      if (!isServerReachable) {
        _showLogoutErrorNotification(
            context, 'Server is bussy. Logout aborted.');
        return; // Keluar dari fungsi logout
      }

      // Pastikan provider masih ada
      if (!mounted) return;
      showLoadingDialog(context);
      await _syncData();

      final dropdownProvider =
          Provider.of<DropdownProvider>(context, listen: false);
      dropdownProvider.stopStatisticsUpdater();

      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      syncProvider.stopSyncing(); // Hentikan sinkronisasi

      final dbHelper = DatabaseHelper();
      await dbHelper.clearAllData();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      hideLoadingDialog(context);

      // Navigasi ke UserLoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => UserLoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void _showLogoutErrorNotification(BuildContext context, String message) {
    if (context.mounted) {
      final snackBar = SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to log out?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _logout(context); // Panggil fungsi logout jika dikonfirmasi
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
