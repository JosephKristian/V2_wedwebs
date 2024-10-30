import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../services/database_helper.dart';
import '../services/data_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/styles.dart';

class DetailEventScreen extends StatefulWidget {
  final String eventId;
  final String idServer;
  final currentDateTime = DateTime.now().toUtc().toIso8601String();

  DetailEventScreen({required this.eventId, required this.idServer});

  @override
  _DetailEventScreenState createState() => _DetailEventScreenState();
}

class _DetailEventScreenState extends State<DetailEventScreen> {
  final DataService _dataService = DataService();
  final log = Logger('DetailEventScreen');
  final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
  }

  void _refreshScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DetailEventScreen(
          eventId: widget.eventId,
          idServer: widget.idServer,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchEventDetails(String eventId) async {
    DatabaseHelper db = DatabaseHelper.instance;
    return await db.getEventDetails(eventId);
  }

  Future<Map<String, dynamic>> _fetchClientDetails(String clientId) async {
    DatabaseHelper db = DatabaseHelper.instance;
    return await db.getClientDetails(clientId);
  }

  Future<List<Map<String, dynamic>>> _fetchSessionDetails(
      String eventId) async {
    DatabaseHelper db = DatabaseHelper.instance;
    return await db.getSessionDetails(eventId);
  }

  void _editEvent() async {
    final TextEditingController _eventNameController = TextEditingController();
    final TextEditingController _eventDateController = TextEditingController();
    final String currentEventName = await _fetchCurrentEventName();
    final DateTime currentEventDate = await _fetchCurrentEventDate();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    _eventNameController.text = currentEventName;
    _eventDateController.text =
        DateFormat('yyyy-MM-dd').format(currentEventDate);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor:
                  AppStyles.dialogBackgroundColor, // Latar belakang dialog
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Event',
                    style: AppStyles.dialogTitleTextStyle, // Gaya judul dialog
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppColors.iconColor), // Warna ikon close
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey, // Jika Anda menggunakan validasi form
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _eventNameController,
                        decoration: AppStyles.inputDecoration.copyWith(
                          labelText: 'Event Name',
                          labelStyle:
                              AppStyles.dialogContentTextStyle, // Gaya label
                        ),
                        style: AppStyles.dialogContentTextStyle, // Gaya teks
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the event name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _eventDateController,
                        decoration: AppStyles.inputDecoration.copyWith(
                          labelText: 'Event Date',
                          labelStyle:
                              AppStyles.dialogContentTextStyle, // Gaya label
                        ),
                        style: AppStyles.dialogContentTextStyle, // Gaya teks
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: currentEventDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            _eventDateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          }
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
                  style: AppStyles.addButtonStyle, // Gaya tombol save
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      String newEventName = _eventNameController.text;
                      String newEventDate = _eventDateController.text;
                      String updatedAt = widget.currentDateTime;
                      await _updateEventDetails(
                          newEventName, newEventDate, updatedAt);
                      _dataService
                          .checkAndSyncEventsSessionsTables(widget.idServer);
                      setState(() {}); // Refresh the screen to reflect changes
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            ));
  }

  Future<String> _fetchCurrentEventName() async {
    DatabaseHelper db = DatabaseHelper.instance;
    var eventDetails = await db.getEventDetails(widget.eventId);
    return eventDetails['event_name'] ?? '';
  }

  Future<DateTime> _fetchCurrentEventDate() async {
    DatabaseHelper db = DatabaseHelper.instance;
    var eventDetails = await db.getEventDetails(widget.eventId);
    return DateTime.parse(eventDetails['date']);
  }

  Future<void> _updateEventDetails(
      String newName, String newDate, String updatedAt) async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.updateEventDetails(widget.eventId, newName, newDate, updatedAt);
  }

  void _editClient() async {
    print('Fetching all clients...');
    DatabaseHelper db = DatabaseHelper.instance;
    List<Map<String, dynamic>> clients = await db.getAllClients();
    print('Clients fetched: $clients');

    Map<String, dynamic> currentEvent =
        await db.getEventDetails(widget.eventId);
    String? currentClientId = currentEvent['client_id'];
    print('Current client ID: $currentClientId');

    if (currentClientId == null) {
      // Handle case where currentClientId is null, if necessary.
      print('Current client ID is null.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? selectedClientId = currentClientId;
        print('Showing dialog with current client ID: $currentClientId');

        return AlertDialog(
          backgroundColor: AppStyles
              .dialogBackgroundColor, // Gaya latar belakang dialog dari AppStyles
          title: Text(
            'Edit Client',
            style: AppStyles
                .dialogTitleTextStyle, // Gaya teks judul dari AppStyles
          ),
          content: DropdownButtonFormField<String>(
            value: currentClientId,
            dropdownColor: Color.fromARGB(255, 50, 48, 39),
            onChanged: (String? newValue) {
              setState(() {
                selectedClientId = newValue;
                print('Selected client ID: $selectedClientId');
              });
            },
            items: clients
                .map<DropdownMenuItem<String>>((Map<String, dynamic> client) {
              return DropdownMenuItem<String>(
                value: client['client_id'],
                child: Text(client['name']),
              );
            }).toList(),
            decoration: InputDecoration(
              labelText: 'Select Client',
              border:
                  OutlineInputBorder(), // Tambahkan border untuk tampilan yang lebih baik
            ),
            style: AppStyles.bodyTextStyle, // Gaya teks dropdown dari AppStyles
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Logging: Dialog cancelled by user
                print('INFO: Edit client dialog cancelled by user');
                Navigator.of(context).pop();
              },
              style: AppStyles
                  .cancelButtonStyle, // Gaya tombol batal dari AppStyles
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    Colors.blueAccent, // Warna tombol dari AppStyles
              ),
              onPressed: () async {
                if (selectedClientId != null &&
                    selectedClientId != currentClientId) {
                  await db.updateClientId(widget.eventId, selectedClientId!,
                      widget.currentDateTime);
                  setState(() {}); // Refresh the screen to reflect changes
                  // Logging: Client ID updated
                  print('INFO: Client ID updated to: $selectedClientId');
                  Navigator.of(context).pop();
                } else {
                  // Logging: No change in client ID
                  print('INFO: No change in client ID.');
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTablesForSession(
      String sessionId) async {
    final List<Map<String, dynamic>> tables =
        await DatabaseHelper.instance.getTablesForDetailSession(sessionId);
    // Ensure no duplicate entries
    var uniqueTables = tables.toSet().toList();
    return uniqueTables;
  }

  Future<void> _insertTable(
      String sessionId, String tableName, int seat) async {
    print('Insert with session_id ');
    String uuid = _uuid.v4();
    await DatabaseHelper.instance
        .insertTableFromDetail(uuid, sessionId, tableName, seat);
    setState(() {});
  }

  Future<void> _insertSession(
      String eventId, String sessionName, String time, String location) async {
    print('Insert with $eventId $sessionName $time $location');

    String uuidSession = _uuid.v4();
    String newSessionId = await DatabaseHelper.instance.insertSessionFromDetail(
        uuidSession, eventId, sessionName, time, location);

    String sessionIdTemp =
        await DatabaseHelper.instance.getSessionIdByEventId(eventId);
    print('fetch $sessionIdTemp success');
    // Getting the list of guest IDs associated with a session ID
    List<String> guestIds = await DatabaseHelper.instance
        .getGuestIdAtCheckInBySessionId(sessionIdTemp);
    print('fetch guest id: $guestIds');

    for (String guestId in guestIds) {
      await DatabaseHelper.instance.insertCheckIn(newSessionId, guestId);
    }
    setState(() {});
  }

  void _editSession(String sessionId, String? tableId) {
    if (tableId != null) {
      print(
          'Edit session button pressed with sessionId: $sessionId and tableId: $tableId');
      // Fetch tables associated with the session
      _fetchTablesForSession(sessionId).then((tables) {
        // Tables available, show form to edit session and table details
        _showEditForm(sessionId, tables);
      });
    } else {
      print('Edit session button pressed with sessionId: $sessionId');
      _showEditForm(sessionId, []);
      // Handle case where session does not have a table
    }
  }

  Future<void> _showInsertSessionForm(String eventId) async {
    final TextEditingController sessionNameController = TextEditingController();
    final TextEditingController sessionLocationController =
        TextEditingController();
    final TextEditingController sessionTimeController = TextEditingController();
    TimeOfDay? selectedTime;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.dialogBackgroundColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add New Session',
              style: AppStyles.dialogTitleTextStyle, // Gaya teks judul
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.iconColor), // Warna ikon
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: sessionNameController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Session Name',
                    labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                  ),
                  style: AppStyles.dialogContentTextStyle, // Gaya teks
                ),
                SizedBox(height: 10),
                TextField(
                  controller: sessionTimeController,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () async {
                        selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          sessionTimeController.text =
                              selectedTime!.format(context);
                        }
                      },
                    ),
                  ),
                  style: AppStyles.dialogContentTextStyle, // Gaya teks
                  readOnly: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: sessionLocationController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Location',
                    labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                  ),
                  style: AppStyles.dialogContentTextStyle, // Gaya teks
                ),
              ],
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
            child: Text('Add Session'),
            onPressed: () async {
              String sessionName = sessionNameController.text;
              String sessionTime = sessionTimeController.text;
              String sessionLocation = sessionLocationController.text;

              if (sessionName.isNotEmpty &&
                  sessionTime.isNotEmpty &&
                  sessionLocation.isNotEmpty) {
                await _insertSession(
                    eventId, sessionName, sessionTime, sessionLocation);
                Navigator.of(context).pop(); // Close the dialog
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInsertTableForm(String sessionId) async {
    final TextEditingController tableNameController = TextEditingController();
    final TextEditingController seatController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles
            .dialogBackgroundColor, // Gunakan warna latar belakang dialog dari AppStyles
        title: Text(
          'Add New Table',
          style:
              AppStyles.dialogTitleTextStyle, // Gaya teks judul dari AppStyles
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableNameController,
              decoration: AppStyles.inputDecoration.copyWith(
                labelText: 'Table Name',
                labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
              ),
              style: AppStyles.dialogContentTextStyle, // Gaya teks
            ),
            SizedBox(height: 10),
            TextField(
              controller: seatController,
              decoration: AppStyles.inputDecoration.copyWith(
                labelText: 'Seat',
                labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
              ),
              keyboardType: TextInputType.number,
              style: AppStyles.dialogContentTextStyle, // Gaya teks
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Logging: Dialog cancelled by user
              print('INFO: Add table dialog cancelled by user');
              Navigator.of(context).pop(); // Close the dialog
            },
            style: AppStyles.cancelButtonStyle, // Gaya tombol batal
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor:
                  Colors.blueAccent, // Gunakan warna dari AppStyles
            ),
            onPressed: () async {
              String tableName = tableNameController.text;
              int seatCount = int.tryParse(seatController.text) ?? 0;

              if (tableName.isNotEmpty && seatCount > 0) {
                // Logging: Adding table
                print(
                    'INFO: Adding new table with name: $tableName and seat count: $seatCount');

                await _insertTable(sessionId, tableName, seatCount);

                // Logging: Table added successfully
                print(
                    'INFO: New table added successfully with name: $tableName');
                Navigator.of(context).pop(); // Close the dialog
              } else {
                // Logging: Validation failed
                print(
                    'WARNING: Validation failed. Table name is empty or seat count is zero.');
              }
            },
            child: Text('Add Table'),
          ),
        ],
      ),
    );
  }

  void _showEditForm(
      String sessionId, List<Map<String, dynamic>> tables) async {
    final TextEditingController sessionNameController = TextEditingController();
    final TextEditingController sessionTimeController = TextEditingController();
    final TextEditingController sessionLocationController =
        TextEditingController();

    // Logging: Show form initialization
    print(
        'INFO: Initializing edit form for sessionId: $sessionId with tables: ${tables.map((e) => e['table_name']).toList()}');

    _fetchCurrentSessionDetails(sessionId).then((sessionDetails) {
      // Logging: Fetched current session details
      print(
          'INFO: Fetched session details for sessionId: $sessionId - $sessionDetails');

      sessionNameController.text = sessionDetails['session_name'];
      sessionTimeController.text = sessionDetails['time'];
      sessionLocationController.text = sessionDetails['location'];
    }).catchError((error) {
      // Logging: Error fetching session details
      print(
          'ERROR: Failed to fetch session details for sessionId: $sessionId - $error');
    });

    List<TextEditingController> tableNameControllers = [];
    List<TextEditingController> seatControllers = [];

    if (tables.isNotEmpty) {
      for (int i = 0; i < tables.length; i++) {
        tableNameControllers.add(TextEditingController());
        seatControllers.add(TextEditingController());

        tableNameControllers[i].text = tables[i]['table_name'];
        seatControllers[i].text = tables[i]['seat'].toString();
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles
            .dialogBackgroundColor, // Gunakan warna latar belakang dialog dari AppStyles
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Edit Session${tables.isNotEmpty ? ' and Table' : ''}',
              style: AppStyles
                  .dialogTitleTextStyle, // Gaya teks judul dari AppStyles
            ),
            IconButton(
              icon: Icon(Icons.close,
                  color:
                      AppColors.iconColor), // Gunakan warna ikon dari AppColors
              onPressed: () {
                // Logging: Dialog closed by user
                print('INFO: Edit form dialog closed by user');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).orientation == Orientation.portrait
                ? MediaQuery.of(context).size.width * 0.8
                : MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: sessionNameController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Session Name',
                    labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                  ),
                  style: AppStyles.dialogContentTextStyle, // Gaya teks
                ),
                SizedBox(height: 10),
                TextField(
                  controller: sessionTimeController,
                  decoration: InputDecoration(
                    labelText: 'Session Time',
                    labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () async {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          sessionTimeController.text =
                              selectedTime.format(context);
                        }
                      },
                    ),
                  ),
                  style: AppStyles.dialogContentTextStyle, // Gaya teks
                  readOnly: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: sessionLocationController,
                  decoration: AppStyles.inputDecoration.copyWith(
                    labelText: 'Session Location',
                    labelStyle: AppStyles.dialogContentTextStyle, // Gaya label
                  ),
                  style: AppStyles.dialogContentTextStyle, // Gaya teks
                ),
                SizedBox(height: 20),
                if (tables.isNotEmpty) ...[
                  Text(
                    'Tables',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  for (int i = 0; i < tables.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: tableNameControllers[i],
                            decoration: AppStyles.inputDecoration.copyWith(
                              labelText: 'Table Name',
                              labelStyle: AppStyles
                                  .dialogContentTextStyle, // Gaya label
                            ),
                            style:
                                AppStyles.dialogContentTextStyle, // Gaya teks
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  int currentSeat =
                                      int.tryParse(seatControllers[i].text) ??
                                          0;
                                  if (currentSeat > 0) {
                                    seatControllers[i].text =
                                        (currentSeat - 1).toString();
                                    // Logging: Seat decremented
                                    print(
                                        'INFO: Decremented seat for table ${tableNameControllers[i].text} to ${seatControllers[i].text}');
                                  }
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: seatControllers[i],
                                  decoration:
                                      AppStyles.inputDecoration.copyWith(
                                    labelText: 'Seat',
                                    labelStyle: AppStyles
                                        .dialogContentTextStyle, // Gaya label
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: AppStyles
                                      .dialogContentTextStyle, // Gaya teks
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  int currentSeat =
                                      int.tryParse(seatControllers[i].text) ??
                                          0;
                                  seatControllers[i].text =
                                      (currentSeat + 1).toString();
                                  // Logging: Seat incremented
                                  print(
                                      'INFO: Incremented seat for table ${tableNameControllers[i].text} to ${seatControllers[i].text}');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Logging: Cancel button pressed
              print('INFO: Edit form dialog cancelled by user');
              Navigator.of(context).pop();
            },
            style: AppStyles.cancelButtonStyle, // Gaya tombol batal
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor:
                  Colors.blueAccent, // Gunakan warna dari AppStyles
            ),
            onPressed: () async {
              String newSessionName = sessionNameController.text;
              String newSessionTime = sessionTimeController.text;
              String newSessionLocation = sessionLocationController.text;

              List<Map<String, dynamic>> updatedTables = [];

              // Logging: Saving changes
              print(
                  'INFO: Saving changes for sessionId: $sessionId with new values: Name: $newSessionName, Time: $newSessionTime, Location: $newSessionLocation');

              if (tables.isNotEmpty) {
                for (int i = 0; i < tables.length; i++) {
                  String newTableName = tableNameControllers[i].text;
                  int newSeat = int.tryParse(seatControllers[i].text) ?? 0;

                  await _updateSessionAndTableDetails(
                    sessionId,
                    newSessionName,
                    newSessionTime,
                    newSessionLocation,
                    tables[i]['table_id'],
                    newTableName,
                    newSeat,
                  );

                  updatedTables.add({
                    'table_id': tables[i]['table_id'],
                    'table_name': newTableName,
                    'seat': newSeat,
                  });

                  // Logging: Table details updated
                  print(
                      'INFO: Updated tableId: ${tables[i]['table_id']} to name: $newTableName with seat: $newSeat');
                }
              }

              if (tables.isEmpty) {
                await _updateSession(
                  sessionId,
                  newSessionName,
                  newSessionTime,
                  newSessionLocation,
                );
              }
              setState(() {});
              // Logging: Form saved and dialog closed
              print('INFO: Edit form changes saved for sessionId: $sessionId');
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCurrentSessionDetails(
      String sessionId) async {
    // Fetch current session details from the database
    // Replace with your database fetching logic
    DatabaseHelper db = DatabaseHelper.instance;
    return await db.getSessionDetailsById(sessionId);
  }

  Future<Map<String, dynamic>?> _fetchCurrentTableDetails(
      String tableId, String sessionId) async {
    DatabaseHelper db = DatabaseHelper.instance;
    return await db.getTableDetailsById(tableId, sessionId);
  }

  Future<void> _updateSession(String sessionId, String sessionName,
      String sessionTime, String sessionLocation) async {
    // Initialize the DatabaseHelper
    DatabaseHelper db = DatabaseHelper.instance;
    await db.updateSessionDetails(
      sessionId,
      sessionName,
      sessionTime,
      sessionLocation,
      widget.currentDateTime,
    );
    print('UPDATE JUST SESSION');
    setState(() {});
    ();
  }

  Future<void> _updateSessionAndTableDetails(
    String sessionId,
    String sessionName,
    String sessionTime,
    String sessionLocation,
    String tableId,
    String tableName,
    int seat,
  ) async {
    // Initialize the DatabaseHelper
    DatabaseHelper db = DatabaseHelper.instance;

    // Log the start of the update process
    print(
        'INFO: Starting update for sessionId: $sessionId and tableId: $tableId');

    try {
      // Log the session update attempt
      print('INFO: Updating session details with values: '
          'Name: $sessionName, Time: $sessionTime, Location: $sessionLocation');

      // Update session details
      await db.updateSessionDetails(
        sessionId,
        sessionName,
        sessionTime,
        sessionLocation,
        widget.currentDateTime,
      );

      // Log the success of session update
      print(
          'INFO: Successfully updated session details for sessionId: $sessionId');

      // Log the table update attempt
      print('INFO: Updating table details with values: '
          'tableId: $tableId, Name: $tableName, Seats: $seat');

      // Update table details
      await db.updateTableDetails(
          tableId, tableName, seat, widget.currentDateTime);

      // Log the success of table update
      print('INFO: Successfully updated table details for tableId: $tableId');
    } catch (error) {
      // Log any error encountered during the update
      print('ERROR: Failed to update session or table details - $error');
      rethrow; // Optionally rethrow the error to handle it further up the call stack
    }
  }

  void _deleteSession(String sessionId) async {
    // Show confirmation dialog before deleting
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppStyles.dialogBackgroundColor,
          title: Text(
            'Confirm Deletion',
            style: AppStyles.dialogTitleTextStyle,
          ),
          content: Text(
              'Are you sure you want to delete this session and all related tables?',
              style: AppStyles.dialogContentTextStyle),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: AppStyles.buttonTextStyle),
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Return false to indicate cancellation
              },
            ),
            ElevatedButton(
              style: AppStyles.deleteButtonStyle,
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Return true to indicate confirmation
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      // Proceed with deleting the session and related tables
      print('Delete session button pressed with sessionId: $sessionId');

      try {
        // Retrieve the related eventId, tableId(s), and check-in(s)
        final List<Map<String, dynamic>> relatedTables =
            await DatabaseHelper.instance.getTablesBySessionId(sessionId);
        final Map<String, dynamic>? sessionData =
            await DatabaseHelper.instance.getSessionRelatedData(sessionId);
        final List<Map<String, dynamic>> relatedCheckIns =
            await DatabaseHelper.instance.getCheckInsBySessionId(sessionId);

        // Ensure that related data is found
        if (sessionData != null) {
          String? eventId = sessionData['event_id'];

          if (eventId != null) {
            // Insert each related check-in into deletedCheckIn
            for (var checkIn in relatedCheckIns) {
              await DatabaseHelper.instance.insertDeletedCheckIn(
                  checkIn['session_id'], checkIn['guest_id'], widget.idServer);
            }

            // Only insert and delete related tables if they are found
            if (relatedTables.isNotEmpty) {
              for (var table in relatedTables) {
                await DatabaseHelper.instance.insertDeletedTable(
                    table['table_id'], sessionId, widget.idServer);
              }

              // Delete related tables
              await DatabaseHelper.instance.deleteTableWithSession(sessionId);
            }

            // Insert the session into deletedSessions
            await DatabaseHelper.instance
                .insertDeletedSession(sessionId, eventId, widget.idServer);

            // Delete the check-ins and session from the local database
            await DatabaseHelper.instance.deleteCheckInBySessionId(sessionId);
            await DatabaseHelper.instance.deleteSession(sessionId);

            // Optionally, show a success message or refresh the data
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Session, related check-ins, and tables deleted successfully')),
            );

            // Refresh the UI or state if needed
            setState(() {});
          } else {
            // Handle case where eventId is not found in sessionData
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: Event ID not found in session data.')),
            );
          }
        } else {
          // Handle case where related session data is not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Session data not found.')),
          );
        }
      } catch (e) {
        // Handle any errors that occur during deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting session: $e')),
        );
      }
    } else {
      // Handle the case where deletion is canceled
      print('Deletion canceled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detail Event Session',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: _refreshScreen, // Show add event form
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchEventDetails(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No details found.'));
          } else {
            Map<String, dynamic> eventDetails = snapshot.data!;
            String eventName = eventDetails['event_name'] ?? 'N/A';
            DateTime eventDate = DateTime.parse(
                eventDetails['date'] ?? DateTime.now().toString());
            String clientId = eventDetails['client_id'];

            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchClientDetails(clientId),
              builder: (context, clientSnapshot) {
                if (clientSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (clientSnapshot.hasError) {
                  return Center(child: Text('Error: ${clientSnapshot.error}'));
                } else if (!clientSnapshot.hasData) {
                  return Center(child: Text('Client details not found.'));
                } else {
                  String clientName = clientSnapshot.data?['name'] ?? 'N/A';

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSessionDetails(widget.eventId),
                    builder: (context, sessionSnapshot) {
                      if (sessionSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (sessionSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${sessionSnapshot.error}'));
                      } else {
                        List<Map<String, dynamic>> sessionData =
                            sessionSnapshot.data ?? [];

                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CardPrimaryWithoutTitle(
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildEventDetail(
                                          eventName, eventDate, _editEvent),
                                      Divider(),
                                      _buildDetailRow('Client Name:',
                                          clientName, _editClient),
                                      Divider(),
                                      Row(
                                        children: [
                                          Text(
                                            'Sessions:',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors
                                                  .iconColor, // Warna sesuai styles.dart
                                            ),
                                          ),
                                          Spacer(), // Menambahkan Spacer untuk mendorong tombol ke kanan
                                          IconButtonGoldList(
                                            icon: Icons.add_rounded,
                                            color: AppColors
                                                .iconColor, // Warna sesuai styles.dart
                                            onPressed: () async {
                                              await _showInsertSessionForm(
                                                  widget.eventId);
                                              _fetchSessionDetails(widget
                                                  .eventId); // Refresh data setelah menambahkan session
                                            },
                                            tooltip: 'Add Session',
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 8),
                                      if (sessionData.isEmpty)
                                        Text('No session details found',
                                            style: AppStyles
                                                .bodyTextStyle), // Gaya teks dari styles.dart
                                      ..._buildSessionDetails(sessionData),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildEventDetail(
      String eventName, DateTime eventDate, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Name:',
                  style: AppStyles.titleCardPrimaryTextStyle.copyWith(
                    fontSize: 18,
                    color: AppColors.iconColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  eventName,
                  style: AppStyles.bodyTextStyle.copyWith(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Date: ${eventDate.toLocal().toString().split(' ')[0]}', // Format the date for display
                  style: AppStyles.bodyTextStyle.copyWith(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButtonGoldList(
            icon: Icons.edit,
            color: AppColors.iconColorEdit,
            onPressed: onEdit,
            tooltip: 'Edit',
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String content, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title',
                  style: AppStyles.titleCardPrimaryTextStyle.copyWith(
                    fontSize: 18,
                    color: AppColors.iconColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: AppStyles.bodyTextStyle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          IconButtonGoldList(
            icon: Icons.edit,
            color: AppColors.iconColorEdit,
            onPressed: onEdit,
            tooltip: 'Edit',
          )
        ],
      ),
    );
  }

  List<Widget> _buildSessionDetails(List<Map<String, dynamic>> data) {
    List<Widget> sessionWidgets = [];
    Map<String, List<Map<String, dynamic>>> sessionGroups = {};

    for (var row in data) {
      String sessionId = row['session_id'];
      if (!sessionGroups.containsKey(sessionId)) {
        sessionGroups[sessionId] = [];
      }
      sessionGroups[sessionId]!.add(row);
    }

    sessionGroups.forEach((
      sessionId,
      sessions,
    ) {
      var session = sessions[0];
      String tableDetails = sessions
          .map((s) => s['table_name'] != null
              ? '\n             - ${s['table_name']} \n                seat available: ${s['seat']}'
              : 'none')
          .join(' \n');

      sessionWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          color: AppColors
              .backgroundColor, // Ganti dengan warna latar belakang yang diinginkan
          child: Card(
            elevation: 4,
            color: AppColors.appBarColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session['session_name']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.iconColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Time: ${session['time']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Location: ${session['location']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tables: $tableDetails',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButtonGoldList(
                        icon: Icons.edit,
                        color: AppColors.iconColorEdit,
                        onPressed: () => _editSession(
                            sessionId, session['table_id'] as String?),
                        tooltip: 'Edit Session',
                      ),
                      SizedBox(width: 8),
                      IconButtonGoldList(
                        icon: Icons.add_to_photos_outlined,
                        color: AppColors.iconColor,
                        onPressed: () async {
                          await _showInsertTableForm(sessionId);
                          // Optionally refresh the data here if needed
                          setState(() {
                            // Optionally update any state variables if needed
                          });
                        },
                        tooltip: 'Add Table',
                      ),
                      SizedBox(width: 8),
                      IconButtonGoldList(
                        icon: Icons.delete,
                        color: AppColors.iconColorWarning,
                        onPressed: () => _deleteSession(sessionId),
                        tooltip: 'Delete Session',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    });

    return sessionWidgets;
  }
}
