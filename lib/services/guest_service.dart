// import 'database_helper.dart';
// import '../models/guest_model.dart';
// import 'package:sqflite/sqflite.dart';

// class GuestService {
//   Future<int> addGuest(Guest guest) async {
//     final db = await DatabaseHelper().database;
//     return await db.insert('Guest', guest.toMap());
//   }

//   Future<List<Guest>> getGuests() async {
//     final db = await DatabaseHelper().database;
//     final List<Map<String, dynamic>> maps = await db.query('Guest');

//     return List.generate(maps.length, (i) {
//       return Guest(
//         guest_id: maps[i]['guest_id'],
//         guest_qr: maps[i]['guest_qr'],
//         name: maps[i]['name'],
//         email: maps[i]['email'],
//         clientId: maps[i]['client_id'],
//         phone: maps[i]['phone'],
//         rsvp: maps[i]['rsvp'],
//         pax: maps[i]['pax'],
//         cat: maps[i]['cat'],

//       );
//     });
//   }

//     Future<Guest> getGuestByQR(String qrCode) async {
//     final db = await DatabaseHelper.instance.database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'Guest',
//       where: 'guest_qr = ?',
//       whereArgs: [qrCode], // Pass qrCode as whereArgs
//     );

//     if (maps.isNotEmpty) {
//       return Guest(
//         guest_id: maps[0]['guest_id'],
//         guest_qr: maps[0]['guest_qr'],
//         name: maps[0]['name'],
//         email: maps[0]['email'],
//         clientId: maps[0]['client_id'],
//         phone: maps[0]['phone'],
//         rsvp: maps[0]['rsvp'],
//         pax: maps[0]['pax'],
//         cat: maps[0]['cat'],
//       );
//     } else {
//       throw Exception('Guest not found');
//     }
//   }

//   Future<int> updateGuest(Guest guest) async {
//     final db = await DatabaseHelper().database;
//     return await db.update(
//       'Guest',
//       guest.toMap(),
//       where: 'guest_id = ?',
//       whereArgs: [guest.guest_id],
//     );
//   }

//   Future<int> deleteGuest(int id) async {
//     final db = await DatabaseHelper().database;
//     return await db.delete(
//       'Guest',
//       where: 'guest_id = ?',
//       whereArgs: [id],
//     );
//   }
// }
