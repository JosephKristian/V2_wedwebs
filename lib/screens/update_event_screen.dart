import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

class UpdateEventScreen extends StatefulWidget {
  final String eventId;

  UpdateEventScreen({required this.eventId});

  @override
  _UpdateEventScreenState createState() => _UpdateEventScreenState();
}

class _UpdateEventScreenState extends State<UpdateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _eventName = '';
  int _clientId = 0;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _sessions = [];
  List<TextEditingController> _sessionNameControllers = [];
  List<List<TextEditingController>> _tableControllers = [];
  int _sessionCount = 1;
  int _tableCount = 2;

  @override
  void initState() {
    super.initState();
    _loadEventData();
    
  }

  Future<void> _loadEventData() async {
    DatabaseHelper db = DatabaseHelper.instance;
    var event = await db.getEventByEventId(widget.eventId);
    var sessions = await db.getSessionDetails(widget.eventId);

    setState(() {
      _eventName = event['event_name'];
      _clientId = event['client_id'];
      _selectedDate = DateTime.parse(event['date']);
      _sessions = sessions;
      _sessionCount = sessions.length;
      _initializeSessionControllers();
    });
  }

  void _initializeSessionControllers() {
  _sessionNameControllers = List.generate(
    _sessionCount,
    (index) => TextEditingController(text: _sessions[index]['session_name']),
  );

  _tableControllers = List.generate(
    _sessionCount,
    (sessionIndex) {
      // Pastikan tables tidak null
      var tables = _sessions[sessionIndex]['tables'] ?? [];
      return List.generate(
        tables.length,
        (tableIndex) => TextEditingController(
          text: tables[tableIndex]['seat']?.toString() ?? '',
        ),
      );
    },
  );
}


  @override
  void dispose() {
    _sessionNameControllers.forEach((controller) => controller.dispose());
    _tableControllers
        .forEach((list) => list.forEach((controller) => controller.dispose()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Event'),
      ),
      body: FutureBuilder(
        future: _loadEventData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        initialValue: _eventName,
                        label: 'Event Name',
                        onChanged: (value) => _eventName = value,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter event name'
                            : null,
                      ),
                      SizedBox(height: 10),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: DatabaseHelper.instance.getClient(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('No clients found.'));
                          } else {
                            final clients = snapshot.data!;
                            return _buildDropdown(
                              label: 'Client',
                              value: _clientId != 0 ? _clientId : null,
                              items: clients.map((client) {
                                return DropdownMenuItem<int>(
                                  value: client['client_id'],
                                  child: Text(client['name']),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _clientId = value!),
                              validator: (value) => value == null || value == 0
                                  ? 'Please select a client'
                                  : null,
                            );
                          }
                        },
                      ),
                      _buildDatePicker(),
                      SizedBox(height: 10),
                      _buildDropdown(
                        label: 'Number of Sessions',
                        value: _sessionCount,
                        items: List.generate(
                            4,
                            (index) => DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text((index + 1).toString()))),
                        onChanged: (value) {
                          setState(() {
                            _sessionCount = value!;
                            _initializeSessionControllers();
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select number of sessions'
                            : null,
                      ),
                      SizedBox(height: 10),
                      if (_sessionCount > 0) ...[
                        _buildDropdown(
                          label: 'Number of Tables',
                          value: _tableCount,
                          items: List.generate(
                              5,
                              (index) => DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text((index + 1).toString()))),
                          onChanged: (value) {
                            setState(() {
                              _tableCount = value!;
                              _initializeSessionControllers();
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select number of Tables'
                              : null,
                        ),
                      ],
                      ...List.generate(_sessionCount, (sessionIndex) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Session ${sessionIndex + 1}:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  _buildTextField(
                                    controller:
                                        _sessionNameControllers[sessionIndex],
                                    label: 'Enter Session Name',
                                    onChanged: (value) =>
                                        _sessions[sessionIndex]
                                            ['session_name'] = value,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Please enter session name'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildTimePicker(sessionIndex),
                            SizedBox(height: 10),
                            _buildTextField(
                              initialValue: _sessions[sessionIndex]['location'],
                              label: 'Session ${sessionIndex + 1} Location',
                              onChanged: (value) =>
                                  _sessions[sessionIndex]['location'] = value,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter session location'
                                      : null,
                            ),
                            SizedBox(height: 10),
                            _buildTableSwitch(sessionIndex),
                            if (_sessions[sessionIndex]['table_enabled']) ...[
                              ...List.generate(_tableCount, (tableIndex) {
                                return _buildTableField(
                                    sessionIndex, tableIndex);
                              }),
                            ],
                          ],
                        );
                      }),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        child: Text('Update'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null && pickedDate != _selectedDate)
              setState(() {
                _selectedDate = pickedDate;
              });
          },
        ),
        SizedBox(width: 10),
        Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
      ],
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required ValueChanged<String> onChanged,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required FormFieldValidator<T?> validator,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTimePicker(int sessionIndex) {
    String? selectedTime = _sessions[sessionIndex]['time'];
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.access_time),
          onPressed: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(
                DateFormat.jm().parse(selectedTime ?? '12:00 PM'),
              ),
            );
            if (pickedTime != null) {
              setState(() {
                selectedTime = pickedTime.format(context);
                _sessions[sessionIndex]['time'] = selectedTime!;
              });
            }
          },
        ),
        SizedBox(width: 10),
        Text(selectedTime ?? 'Select Time'),
      ],
    );
  }

  Widget _buildTableSwitch(int sessionIndex) {
    bool tableEnabled = _sessions[sessionIndex]['table_enabled'] ?? false;
    return SwitchListTile(
      title: Text('Enable Tables'),
      value: tableEnabled,
      onChanged: (value) {
        setState(() {
          tableEnabled = value;
          _sessions[sessionIndex]['table_enabled'] = value;
        });
      },
    );
  }

  Widget _buildTableField(int sessionIndex, int tableIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: _buildTextField(
        controller: _tableControllers[sessionIndex][tableIndex],
        label: 'Table ${tableIndex + 1} Seat',
        onChanged: (value) => _sessions[sessionIndex]['tables'][tableIndex]
            ['seat'] = value,
        validator: (value) => value == null || value.isEmpty
            ? 'Please enter table seat'
            : null,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // Save the event details
      DatabaseHelper db = DatabaseHelper.instance;
      await db.updateEvents(widget.eventId, {
        'event_name': _eventName,
        'client_id': _clientId,
        'event_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      });

      // Save the session details
      for (int sessionIndex = 0; sessionIndex < _sessionCount; sessionIndex++) {
        var session = _sessions[sessionIndex];
        await db.updateSession(session['session_id'], {
          'session_name': session['session_name'],
          'time': session['time'],
          'location': session['location'],
          'table_enabled': session['table_enabled'] ? 1 : 0,
        });

        if (session['table_enabled']) {
          for (int tableIndex = 0;
              tableIndex < _tableControllers[sessionIndex].length;
              tableIndex++) {
            var table = session['tables'][tableIndex];
            await db.updateTable(table['table_id'], {
              'seat': table['seat'],
            });
          }
        }
      }

      Navigator.pop(context, true);
    }
  }
}
