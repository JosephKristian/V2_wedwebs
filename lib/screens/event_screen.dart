import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'detail_event_screen.dart';
import 'package:logging/logging.dart';

import '../widgets/styles.dart';
import '../services/data_service.dart';
import '../models/session_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_app_bar.dart';

class EventScreen extends StatefulWidget {
  final String role;
  final String idServer;

  EventScreen({required this.role, required this.idServer});
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final log = Logger('EventScreen');
  late Future<List<Map<String, dynamic>>> _eventSessions;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];
  List<Map<String, dynamic>> _allData = [];
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _refreshEvent();
  }

  void _refreshEvent() {
    _eventSessions = DatabaseHelper.instance.getEventSessions();
    _eventSessions.then((data) {
      setState(() {
        _allData = data;
        _filteredData = data;
      });
      // Debug print to check fetched data
      print("IDSCHECK: ${widget.idServer} event sessions: $data");
    });
  }

  void _filterData(String query) {
    final data = _allData.where((row) {
      final eventName = row['event_name']?.toLowerCase() ?? '';
      final clientName = row['client_name']?.toLowerCase() ?? '';
      return eventName.contains(query) || clientName.contains(query);
    }).toList();

    setState(() {
      _filteredData = data;
    });
  }

  Future<void> _showInsertEventForm() async {
    final TextEditingController eventNameController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    String? selectedClientId;
    List<Map<String, dynamic>> clients = await _fetchClients();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.dialogBackgroundColor,
        title: Text(
          'Add New Event',
          style: AppStyles.dialogTitleTextStyle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: eventNameController,
              decoration:
                  AppStyles.inputDecoration.copyWith(labelText: 'Event Name'),
              style: AppStyles.dialogContentTextStyle,
            ),
            DropdownButtonFormField<String>(
              dropdownColor: Color.fromARGB(255, 50, 48, 39),
              value: selectedClientId,
              onChanged: (String? newValue) {
                selectedClientId = newValue;
              },
              items: clients
                  .map<DropdownMenuItem<String>>((Map<String, dynamic> client) {
                return DropdownMenuItem<String>(
                  value: client['client_id'],
                  child: Text(client['name'],
                      style: AppStyles.dialogContentTextStyle),
                );
              }).toList(),
              decoration:
                  AppStyles.inputDecoration.copyWith(labelText: 'Client Name'),
              style: AppStyles.dialogContentTextStyle,
            ),
            GestureDetector(
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  dateController.text =
                      selectedDate.toLocal().toString().split(' ')[0];
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: dateController,
                  decoration:
                      AppStyles.inputDecoration.copyWith(labelText: 'Date'),
                  style: AppStyles.dialogContentTextStyle,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: AppStyles.cancelButtonStyle,
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: AppStyles.addButtonStyle,
            onPressed: () async {
              String eventName = eventNameController.text;
              String date = dateController.text;

              if (eventName.isNotEmpty &&
                  selectedClientId != null &&
                  date.isNotEmpty) {
                await _insertEventByUsers(selectedClientId!, eventName, date);

                Navigator.of(context).pop(); // Close the dialog
              }
            },
            child: Text('Add Event'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClients() async {
    DatabaseHelper db = DatabaseHelper.instance;
    return await db.getClient();
  }

  Future<void> _insertEventByUsers(
      String clientId, String eventName, String date) async {
    print('Insert with session_id');
    final _uuid = Uuid();
    String uuid = _uuid.v4();
    await DatabaseHelper.instance
        .insertEventByUsers(uuid, clientId, eventName, date);
    _refreshEvent();
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppStyles.dialogBackgroundColor,
            title: Text(
              'Confirm Deletion',
              style: AppStyles.dialogTitleTextStyle,
            ),
            content: Text(
              'Are you sure you want to delete this event? This action cannot be undone.',
              style: AppStyles.dialogContentTextStyle,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // User cancelled
                },
                child: Text(
                  'Cancel',
                  style: AppStyles.buttonTextStyle,
                ),
              ),
              ElevatedButton(
                style: AppStyles.deleteButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop(true); // User confirmed
                },
                child: Text(
                  'Delete',
                  style: AppStyles.buttonTextStyle,
                ),
              )
            ],
          );
        },
      );

      // If user did not confirm, exit early
      if (confirmed != true) {
        return;
      }

      print('Getting sessions');

// Get all sessions related to the event
      List<Session>? sessions =
          await DatabaseHelper.instance.getSessionByEventId(eventId);

      if (sessions == null || sessions.isEmpty) {
        // If no sessions found, directly delete the event
        String? clientId =
            await DatabaseHelper.instance.getClientIdByEventId(eventId);
        print('INSERTING: Deleted Event');
        await DatabaseHelper.instance.insertDeletedEvent(eventId, clientId!,
            widget.idServer); // Insert event into deleted_events
        await DatabaseHelper.instance.deleteEvent(eventId);
        print('Event $eventId deleted (no sessions found)');
      } else {
        // If sessions are found, delete tables and sessions
        for (var session in sessions) {
          String sessionId = session.session_id!;

          // Retrieve tables associated with the session
          final List<Map<String, dynamic>> relatedTables =
              await DatabaseHelper.instance.getTablesBySessionId(sessionId);

          // Insert each related table into deleted_tables
          for (var table in relatedTables) {
            await DatabaseHelper.instance.insertDeletedTable(
                table['table_id'], sessionId, widget.idServer);
          }

          // Insert the session into deleted_sessions
          await DatabaseHelper.instance
              .insertDeletedSession(sessionId, eventId, widget.idServer);

          // Delete tables associated with the session
          await DatabaseHelper.instance.deleteTableWithSession(sessionId);
          print('Tables with session $sessionId deleted');

          // Delete the session itself
          await DatabaseHelper.instance.deleteSession(sessionId);
          print('Session with session_id $sessionId deleted');
        }

        // Insert the event into deleted_events
        String? clientId =
            await DatabaseHelper.instance.getClientIdByEventId(eventId);
        await DatabaseHelper.instance
            .insertDeletedEvent(eventId, clientId!, widget.idServer);

        // Delete event
        await DatabaseHelper.instance.deleteEvent(eventId);
        print('Event $eventId deleted');
      }

// Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event $eventId deleted successfully.'),
          backgroundColor: Colors.red,
        ),
      );

// Refresh event sessions list
      _refreshEvent();
    } catch (e) {
      print('Error deleting event: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Event List ',
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showInsertEventForm, // Show add event form
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshEvent, // Refresh the list
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (query) {
                _filterData(query.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _eventSessions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No sessions found.'));
                } else {
                  return ListView.builder(
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      var row = _filteredData[index];
                      String? sessionId = row['session_id'];
                      String eventId = row['event_id'];
                      String eventName = row['event_name'];
                      String clientName = row['client_name'];

                      return CardPrimary(
                        title: Text(eventName,
                            style: AppStyles.titleCardPrimaryTextStyle),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: $clientName'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButtonGoldList(
                              icon: Icons.delete,
                              color: AppColors.iconColorWarning,
                              onPressed: () {
                                log.info('Deleting event: $eventName');
                                _deleteEvent(eventId);
                              },
                              tooltip: 'Delete Event',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailEventScreen(
                                eventId: eventId,
                                idServer: widget.idServer,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
