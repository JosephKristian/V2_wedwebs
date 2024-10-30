// // lib/services/event_service.dart

// import 'database_helper.dart';
// import 'package:sqflite/sqflite.dart';
// import '../models/event_model.dart';

// class EventService {
//   Future<int> addEvent(Event event) async {
//     final db = await DatabaseHelper().database;
//     return await db.insert('events', event.toMap());
//   }

//   Future<List<Event>> getEvents() async {
//     final db = await DatabaseHelper().database;
//     final List<Map<String, dynamic>> maps = await db.query('events');
//     return List.generate(maps.length, (i) {
//       return Event(
//         eventName: maps[i]['eventName'],
//         session: maps[i]['session'],
//       );
//     });
//   }
// }
