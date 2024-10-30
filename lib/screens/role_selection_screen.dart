import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedweb/screens/intro_user_screen.dart';
import '../services/api_service.dart';
import '../services/dropdown_provider.dart';
import 'dashboard_user_screen.dart';
import 'select_event.dart';
import '../widgets/custom_app_bar.dart';
import '../services/sync_provider.dart';
import '../widgets/styles.dart';
import '../models/client_model.dart';
import '../services/database_helper.dart';
import '../services/data_service.dart';
import 'statistic/user_stat_screen_user.dart';
import 'user_auth/user_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String idServer;
  final String role;
  final String name;

  RoleSelectionScreen(
      {required this.name, required this.idServer, required this.role});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final log = Logger('_RoleSelectionScreenState');
  final dbHelper = DatabaseHelper();
  List<Client> clients = []; // Daftar klien yang akan ditampilkan
  bool isLoading = true; // Status loading
  bool _isFullscreen = false;
  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _initialize();
    _syncProvider(); // Ambil data klien saat inisialisasi
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

  Future<void> _fetchClients() async {
    log.info('Fetching client IDs from login');
    setState(() {
      isLoading = true; // Set loading ke true saat mengambil data
    });

    try {
      // Ambil client id dari tabel login
      String? jsonClientIds =
          await dbHelper.getClientIdsFromLogin(); // Sesuaikan metode ini
      if (jsonClientIds != null) {
        log.info('Raw client IDs from login: $jsonClientIds');

        // Dekode JSON
        List<String> clientIds = List<String>.from(json.decode(jsonClientIds));

        // Periksa isi dari clientIds
        log.info('Client IDs retrieved: $clientIds');

        // Ambil data klien berdasarkan client id satu per satu
        clients.clear(); // Kosongkan daftar klien sebelum mengisi ulang
        for (String clientId in clientIds) {
          log.info('Fetching client with ID: $clientId');
          Client? client = await dbHelper.getClientById(clientId);
          if (client != null) {
            clients.add(client);
            log.info('Client fetched: ${client.name}');
          } else {
            log.warning('No client found for ID: $clientId');
          }
        }
        setState(() {}); // Perbarui tampilan
      } else {
        log.warning('No client IDs found in login table.');
      }
    } catch (e) {
      log.severe('Error fetching clients: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading ke false setelah selesai
      });
    }
  }

  Future<void> _refreshScreen() async {
    log.info('Refreshing screen...');
    await _fetchClients(); // Ambil data klien terbaru
  }

  void _navigateToSelectSessionScreen(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectEvent(
          idServer: widget.idServer,
          name: widget.name,
          client: client,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info('Building RoleSelectionScreen');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Select Client',
        actions: [
          IconButton(
            onPressed: _syncData,
            icon: Icon(Icons.cloud_sync_outlined),
            color: Colors.white,
          ),
          IconButton(
            onPressed: _refreshScreen,
            icon: Icon(Icons.refresh_outlined),
            color: Colors.white,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.appBarColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.white),
              title: Text('Home', style: AppStyles.dialogContentTextStyle),
              onTap: () {
                // Tambahkan navigasi atau fungsi yang diinginkan
                _showHomeConfirmationDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person_2, color: Colors.white),
              title: Text(
                'Select Client',
                style: AppStyles.dialogContentTextStyle,
              ),
              onTap: () {
                // Tambahkan navigasi atau fungsi yang diinginkan
                _showSelectClientConfirmationDialog(context);
              },
            ),
            // ListTile(
            //   leading: Icon(FontAwesomeIcons.chartPie, color: Colors.white),
            //   title: Text(
            //     'Statistic',
            //     style: AppStyles.dialogContentTextStyle,
            //   ),
            //   onTap: () async {
            //     Navigator.pop(context);
            //     _stats(context);
            //   },
            // ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Logout', style: AppStyles.dialogContentTextStyle),
              onTap: () async {
                // Tambahkan navigasi atau fungsi yang diinginkan
                _showLogoutConfirmationDialog(context);
                // Navigator.pop(context); // Tutup drawer
              },
            ),
            // Tambahkan item menu lainnya sesuai kebutuhan
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.appBarColor,
          ),
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.teal.shade300.withOpacity(0.6),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Content
          Center(
            child: isLoading
                ? CircularProgressIndicator() // Tampilkan loading jika data masih kosong
                : clients.isEmpty
                    ? Text(
                        'No clients found.') // Tampilkan pesan jika tidak ada klien
                    : ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return CardTicket(
                            headerText: 'C L I E N T',
                            title: Text(
                              client.name,
                              style: AppStyles.titleCardPrimaryTextStyle,
                            ),
                            trailing: Icon(
                              Icons.qr_code_scanner_sharp,
                              color: Colors.white70,
                            ),
                            subtitle: Text(client.phone!),
                            onTap: () {
                              log.info(
                                  'Card tapped for client: ${client.name}');
                              _navigateToSelectSessionScreen(client);
                            },
                          );
                        },
                      ),
          ),
        ],
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

  void _showSelectClientConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to Select Client?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Not sure"),
            ),
            TextButton(
              onPressed: () {
                _client(context); // Panggil fungsi logout jika dikonfirmasi
              },
              child: Text("Sure"),
            ),
          ],
        );
      },
    );
  }

  void _showHomeConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to Home?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Not sure"),
            ),
            TextButton(
              onPressed: () {
                _home(context); // Panggil fungsi logout jika dikonfirmasi
              },
              child: Text("Sure"),
            ),
          ],
        );
      },
    );
  }

  void _client(BuildContext context) async {
    try {
      // Navigasi ke UserLoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => RoleSelectionScreen(
            idServer: widget.idServer,
            role: widget.role,
            name: widget.name,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
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

  // void _stats(BuildContext context) async {
  //   try {
  //     // Navigasi ke UserLoginScreen
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => UserStatScreenUser(
  //           isFullscreen: false,
  //           onToggleFullscreen: _toggleFullscreen,
  //           idServer: widget.idServer,

  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error during logout: $e');
  //   }
  // }

  void _home(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.clearPagesTempo();
      // Navigasi ke halaman Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IntroUserScreen(
            idServer: widget.idServer,
            name: widget.name,
            role: 'user',
          ),
        ),
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
