import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../screens/master_data/md_guest_screen.dart';
import '../../services/database_helper.dart';
import '../../services/data_service.dart';
import '../../widgets/custom_app_bar.dart'; // Import CustomAppBar
import '../../widgets/styles.dart'; // Import CustomAppBar

class MDEventScreen extends StatefulWidget {
  final String role;
  final String idServer;
  final String clientName;
  final String clientId;

  MDEventScreen(
      {required this.idServer,
      required this.role,
      required this.clientName,
      required this.clientId});

  @override
  _MDEventScreenState createState() => _MDEventScreenState();
}

class _MDEventScreenState extends State<MDEventScreen> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  final log = Logger('MDEventScreen');
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredEvents = [];
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  Future<void> _fetchEventData() async {
    _eventsFuture =
        DatabaseHelper.instance.getEventsByClientId(widget.clientId);
  }

  void _filterEvents(String query) {
    List<Map<String, dynamic>> filteredList = [];
    if (query.isNotEmpty) {
      filteredList = filteredEvents.where((event) {
        String eventName = event['event_name'].toString().toLowerCase();
        return eventName.contains(query.toLowerCase());
      }).toList();
    } else {
      filteredList = filteredEvents;
    }
    setState(() {
      filteredEvents = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Events List for ${widget.clientName}',
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.iconColor),
            onPressed: () {
              showSearch(
                context: context,
                delegate: EventSearch(
                  clientId: widget.clientId,
                  events: filteredEvents,
                  idServer: widget.idServer,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _eventsFuture,
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error fetching data',
                    style: AppStyles.errorTextStyle));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No data available',
                    style: AppStyles.emptyDataTextStyle));
          } else {
            Map<String, Map<String, dynamic>> eventMap = {};
            snapshot.data!.forEach((event) {
              String eventId = event['event_id'];
              if (!eventMap.containsKey(eventId)) {
                eventMap[eventId] = {
                  'event_id': eventId,
                  'event_name': event['event_name'],
                  'date': event['date'],
                  'sessions': <Map<String, dynamic>>[],
                };
              }
              bool sessionExists = eventMap[eventId]!['sessions'].any(
                  (session) =>
                      session['session_name'] == event['session_name'] &&
                      session['time'] == event['time'] &&
                      session['location'] == event['location']);

              if (!sessionExists) {
                eventMap[eventId]!['sessions'].add({
                  'session_name': event['session_name'],
                  'time': event['time'],
                  'location': event['location'],
                  'tables': <Map<String, dynamic>>[],
                });
              }

              if (event['table_name'] != null) {
                eventMap[eventId]!['sessions'].last['tables'].add({
                  'table_name': event['table_name'],
                  'seat': event['seat'],
                });
              }
            });

            filteredEvents = eventMap.values.toList();

            return ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                var event = filteredEvents[index];
                return Card(
                  margin: EdgeInsets.all(12),
                  elevation: 6, // Tambahkan elevation untuk efek shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: AppColors.appBarColor,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MDGuestScreen(
                            idServer: widget.idServer,
                            clientId: widget.clientId,
                            eventId: event['event_id'],
                            eventName: event['event_name'],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            event['event_name'],
                            style: AppStyles.titleCardPrimaryTextStyle,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Date: ${event['date']}',
                              style: AppStyles.dialogContentTextStyle),
                        ),
                        SizedBox(height: 8),
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: event['sessions'].length,
                          itemBuilder: (context, sessionIndex) {
                            var session = event['sessions'][sessionIndex];
                            return ListTile(
                              title: Text('Session: ${session['session_name']}',
                                  style: AppStyles.dialogContentTextStyle),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Time: ${session['time']}',
                                      style: AppStyles.dialogContentTextStyle),
                                  Text('Location: ${session['location']}',
                                      style: AppStyles.dialogContentTextStyle),
                                  if (session['tables'].isEmpty)
                                    Text('Tables: None',
                                        style: AppStyles.dialogContentTextStyle)
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: session['tables']
                                          .map<Widget>((table) {
                                        return Text(
                                            'Table: ${table['table_name']} (${table['seat']} seats)',
                                            style: AppStyles
                                                .dialogContentTextStyle);
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class EventSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> events;
  final String idServer; // Add idServer to EventSearch
  final String clientId; // Add idServer to EventSearch

  EventSearch(
      {required this.events, required this.idServer, required this.clientId});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> filteredList = events.where((event) {
      String eventName = event['event_name'].toString().toLowerCase();
      return eventName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        var event = filteredList[index];
        return ListTile(
          title: Text(event['event_name']),
          subtitle: Text('Date: ${event['date']}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MDGuestScreen(
                  idServer: idServer, // Use idServer here
                  clientId: clientId, // Use idServer here
                  eventId: event['event_id'],
                  eventName: event['event_name'],
                ),
              ),
            );
            close(context, event);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Map<String, dynamic>> suggestionList = events.where((event) {
      String eventName = event['event_name'].toString().toLowerCase();
      return eventName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        var event = suggestionList[index];
        return ListTile(
          title: Text(event['event_name']),
          subtitle: Text('Date: ${event['date']}'),
          onTap: () {
            query = event['event_name'].toString();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MDGuestScreen(
                  idServer: idServer, // Use idServer here
                  clientId: clientId, // Use idServer here
                  eventId: event['event_id'],
                  eventName: event['event_name'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
