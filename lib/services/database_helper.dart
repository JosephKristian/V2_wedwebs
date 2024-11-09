import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wedweb/models/angpau_model.dart';
import 'package:wedweb/models/angpau_titipan_model.dart';
import '../models/template_model.dart';
import 'dart:io';
import '../models/check_in_model.dart';
import '../models/client_model.dart';
import '../models/event_model.dart';
import '../models/guest_model.dart';
import '../models/session_model.dart';
import '../models/table_model.dart';
import '../models/usher_model.dart';

class DatabaseHelper {
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  String colDate = 'date';
  String colEventId = 'event_id';
  String colEventName = 'event_name';
  String eventsTable = 'event';
  final log = Logger('DatabaseHelper');

  static Database? _database;
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath(String dbName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return path;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = await getDatabasePath('digital_guestbook.db');
      log.info('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      log.severe('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    log.info('Creating tables...');
    try {
      await db.execute('''
      CREATE TABLE Ushers (
        usher_id TEXT PRIMARY KEY,
        client_id TEXT,
        name TEXT,
        email TEXT,
        password TEXT,
        role TEXT DEFAULT 'user',
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime'))
      )
    ''');
      log.info('Table "USHER" created successfully');

      await db.execute('''
      CREATE TABLE Login (
        id_server TEXT PRIMARY KEY,
        key TEXT,  
        role TEXT,  
        name TEXT,  
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime'))
      )
    ''');
      log.info('Table "Users" created successfully');

      await db.execute('''
      CREATE TABLE Pages_tempo (
        idServer TEXT PRIMARY KEY,
        clientId TEXT,  
        clientName TEXT,  
        role TEXT,  
        event TEXT,  
        session TEXT,  
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime'))
      )
    ''');
      log.info('Table "Users" created successfully');

      await db.execute('''
      CREATE TABLE Users (
        user_id TEXT PRIMARY KEY,     
        role TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime'))
      )
    ''');
      log.info('Table "Users" created successfully');

      await db.execute('''
      CREATE TABLE Client (
        client_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime'))
      )
    ''');
      log.info('Table "Client" created successfully');

      await db.execute('''
      CREATE TABLE Templates (
        template_id TEXT PRIMARY KEY,
        client_id TEXT,
        greeting TEXT,
        opening TEXT,
        link TEXT,
        closing TEXT,
        key TEXT,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime'))
      )
    ''');
      log.info('Table "USHER" created successfully');

      await db.execute('''
      CREATE TABLE Guest (
        guest_id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        guest_qr TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        pax INTEGER DEFAULT 1,
        tables TEXT,
        cat TEXT DEFAULT 'regular',
        cat_label TEXT,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (client_id) REFERENCES Client(client_id)
      )
    ''');
      log.info('Table "Guest" created successfully');

      await db.execute('''
      CREATE TABLE Event (
        event_id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        event_name TEXT NOT NULL,
        date DATE NOT NULL,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (client_id) REFERENCES Client(client_id)
      )
    ''');
      log.info('Table "Event" created successfully');

      await db.execute('''
      CREATE TABLE Session (
        session_id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        session_name TEXT NOT NULL,
        time TEXT NOT NULL,
        location TEXT NOT NULL,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (event_id) REFERENCES Event(event_id)
      )
    ''');
      log.info('Table "Session" created successfully');

      await db.execute('''
      CREATE TABLE Angpau (
        session_id TEXT NOT NULL,
        key TEXT NOT NULL,
        counter INTEGER DEFAULT 0,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        PRIMARY KEY (session_id, key),
        FOREIGN KEY (session_id) REFERENCES Session(session_id)
      )
    ''');

      log.info('Table "Angpau" created successfully');

      await db.execute('''
      CREATE TABLE Angpau_titipan (
        angpau_titipan_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        guest_id TEXT NOT NULL,
        angpau_titipan_name TEXT,
        counter_label TEXT,
        amount TEXT DEFAULT '0',
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (session_id) REFERENCES Session(session_id)
        
      )
    ''');

      log.info('Table "Angpau" created successfully');

      await db.execute('''
      CREATE TABLE 'Table' (
        table_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        table_name TEXT NOT NULL,
        seat INTEGER NOT NULL,
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (session_id) REFERENCES Session(session_id)
      )
    ''');
      log.info('Table "Table" created successfully');

      await db.execute('''
      CREATE TABLE Check_in (
        session_id TEXT NOT NULL,
        guest_id TEXT NOT NULL,
        souvenir TEXT,
        angpau_label TEXT,
        angpau INTEGER,
        pax_checked INTEGER DEFAULT 1,
        meals TEXT,
        note TEXT,
        delivery TEXT DEFAULT 'no',
        guestNo INTEGER DEFAULT 1,
        rsvp TEXT DEFAULT 'pending',
        status TEXT DEFAULT 'not check-in yet',
        synced BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT DEFAULT (datetime('now', 'localtime')),
        PRIMARY KEY (session_id, guest_id),
        FOREIGN KEY (session_id) REFERENCES Session(session_id),
        FOREIGN KEY (guest_id) REFERENCES Guest(guest_id)
      )
    ''');
      log.info('Table "Check_in" created successfully');

      await db.execute('''
          CREATE TABLE deleted_clients (
          client_id STRING PRIMARY KEY,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_clients" created successfully');

      await db.execute('''
          CREATE TABLE deleted_ushers (
          usher_id STRING PRIMARY KEY,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_ushers" created successfully');

      await db.execute('''
          CREATE TABLE deleted_events (
          event_id STRING PRIMARY KEY,
          client_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_events" created successfully');

      await db.execute('''
          CREATE TABLE deleted_guests (
          guest_id STRING PRIMARY KEY,
          client_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_guests" created successfully');

      await db.execute('''
          CREATE TABLE deleted_sessions (
          session_id STRING PRIMARY KEY,
          event_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_sessions" created successfully');

      await db.execute('''
          CREATE TABLE deleted_tables (
          table_id STRING PRIMARY KEY,
          session_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_tables" created successfully');

      await db.execute('''
          CREATE TABLE deleted_check_in (
          session_id TEXT NOT NULL,
          guest_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          deleted_at TEXT
          );
      ''');
      log.info('Table "deleted_check_in" created successfully');

      // Insert dummy data for each table
      await _insertDummyData(db);
    } catch (e) {
      log.severe('Error creating tables: $e');
      rethrow;
    }
  }

  Future<void> _insertDummyData(Database db) async {
    String passwordAdmin =
        '7b77e79744fd7213bf92af2fb62e04bc7236c833d94fa61ae023df74150e8f9d';
    String passwordUser =
        '33adb9cc9633e80ca1361337206b433188ade04d3c962babdb0dd7c41faf5a01';

    // Insert dummy data into Users table
    try {
      await db.insert(
        'Users',
        {
          'user_id': 'admin',
          'role': 'admin',
          'password': passwordAdmin,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert(
        'Users',
        {
          'user_id': 'user',
          'role': 'user',
          'password': passwordUser,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      log.info('DUMMY data inserted into Users table successfully');
    } catch (e) {
      log.severe('Error inserting dummy data into Users table: $e');
      rethrow;
    }
  }

  // ___________________________method______________________________________
  // Client

  // sync
  // Update the synced status of a client by client_id
  Future<int> updateClientSyncedStatus(String clientId, bool synced) async {
    final db = await instance.database;
    return await db.update(
      'Client',
      {
        'synced': synced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'client_id = ?',
      whereArgs: [
        clientId
      ], // Parameterized query to prevent SQL injection and handle UUID properly
    );
  }

  Future<void> updateTemplateClientKey(
      String clientId, Map<String, dynamic> template) async {
    final db = await instance.database;

    // Menetapkan updated_at dengan waktu UTC saat ini
    template['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'templates', // Nama tabel
      template, // Data yang akan diupdate
      where:
          'client_id = ? AND key = ?', // Kondisi update berdasarkan clientId dan key template
      whereArgs: [clientId, template['key']],
    );
  }

  Future<void> updateAllClientsSyncedStatus(List<String> clientIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = clientIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      'UPDATE Client SET synced = 1 WHERE client_id IN ($quotedIds)',
    );
  }

  Future<void> updateAllTemplatesSyncedStatus(List<String> templateIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = templateIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      'UPDATE Templates SET synced = 1 WHERE client_id IN ($quotedIds)',
    );
  }

  Future<void> updateAllUshersSyncedStatus(List<String> usherIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = usherIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      'UPDATE Ushers SET synced = 1 WHERE usher_id IN ($quotedIds)',
    );
  }

  Future<void> updateAllEventsSyncedStatus(List<String> eventIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = eventIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      'UPDATE Event SET synced = 1 WHERE event_id IN ($quotedIds)',
    );
  }

  Future<void> updateAllSessionsSyncedStatus(List<String> sessionIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = sessionIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      'UPDATE Session SET synced = 1 WHERE session_id IN ($quotedIds)',
    );
  }

  Future<void> updateAllTablesSyncedStatus(List<String> tableIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = tableIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      "UPDATE 'Table' SET synced = 1 WHERE table_id IN ($quotedIds)",
    );
  }

  Future<void> updateAllAngpausSyncedStatus(
      List<Map<String, String>> angpauKeys) async {
    final db = await instance.database;

    // Menyiapkan query untuk memperbarui status synced
    final updates = angpauKeys.map((angpau) {
      final sessionId = angpau['session_id'];
      final key = angpau['key'];
      return "('$sessionId', '$key')";
    }).join(',');

    await db.rawUpdate(
      "UPDATE Angpau SET synced = 1 WHERE (session_id, key) IN ($updates)",
    );
  }

  Future<void> updateAllGuestsSyncedStatus(List<String> tableIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID klien
    final quotedIds = tableIds.map((id) => "'$id'").join(',');

    await db.rawUpdate(
      "UPDATE Guest SET synced = 1 WHERE guest_id IN ($quotedIds)",
    );
  }

  Future<void> updateAllCheckInsSyncedStatus(List<String> checkInIds) async {
    final db = await instance.database;

    // Menambahkan tanda kutip pada setiap ID kombinasi session_id dan guest_id
    final quotedIds = checkInIds.map((id) => "'$id'").join(',');

    // Update status sinkronisasi check-in berdasarkan kombinasi session_id dan guest_id
    await db.rawUpdate(
      "UPDATE Check_in SET synced = 1 WHERE session_id || guest_id IN ($quotedIds)",
    );
  }

  Future<String> insertClient(Client client) async {
    final db = await database;
    try {
      // Menginsert client ke database dan mendapatkan ID dari baris yang baru saja dimasukkan
      int id = await db.insert('Client', client.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String clientId = id.toString();

      log.info('Client inserted successfully with ID: $clientId');
      return clientId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<String> insertTemplate(Template template) async {
    final db = await database;
    try {
      // Menginsert client ke database dan mendapatkan ID dari baris yang baru saja dimasukkan
      int id = await db.insert('Templates', template.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String templateId = id.toString();

      log.info('template inserted successfully with ID: $templateId');
      return templateId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<void> insertTemplateDummy(Map<String, dynamic> template) async {
    final db = await database;
    await db.insert('templates', template);
  }

  Future<void> insertEnvelopeEntrust(String sessionId, String guestId,
      String name, String counterLabel) async {
    final db = await database;

    // Generate ID unik untuk angpau_titipan_id (misalnya menggunakan UUID)
    String angpauTitipanId =
        Uuid().v4(); // Pastikan untuk menambahkan paket uuid di pubspec.yaml

    // Ambil nilai counter_label dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String counterLabelFromSP = prefs.getString('angpau_abjad') ?? 'A';

    await db.insert(
      'Angpau_titipan',
      {
        'angpau_titipan_id': angpauTitipanId,
        'session_id': sessionId,
        'guest_id': guestId,
        'angpau_titipan_name': name,
        'counter_label': counterLabelFromSP,
        'amount': '0', // Atau sesuaikan dengan logika Anda
        'synced': 0, // Atur sesuai kebutuhan
      },
      conflictAlgorithm: ConflictAlgorithm.abort, // Jika ada, ganti data
    );
  }

  Future<String> insertUsher(Usher usher) async {
    final db = await database;
    try {
      // Menginsert usher ke database dan mendapatkan ID dari baris yang baru saja dimasukkan
      int id = await db.insert('Ushers', usher.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String usherId = id.toString();

      log.info('Client inserted successfully with ID: $usherId');
      return usherId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert usher');
    }
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    try {
      int result = await db.update(
        'Client',
        client.toMap(),
        where: 'client_id = ?',
        whereArgs: [client.client_id],
      );
      log.info('Client updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating client: $e');
      throw Exception('Failed to update client');
    }
  }

  Future<int> updateTemplate(Template template) async {
    final db = await database;
    try {
      int result = await db.update(
        'Templates',
        template.toMap(),
        where: 'template_id = ?',
        whereArgs: [template.template_id],
      );
      log.info('Client updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating template: $e');
      throw Exception('Failed to update client');
    }
  }

  Future<int> updateUsher(Usher usher) async {
    final db = await database;
    try {
      int result = await db.update(
        'Ushers',
        usher.toMap(),
        where: 'usher_id = ?',
        whereArgs: [usher.usher_id],
      );
      log.info('usher updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating usher: $e');
      throw Exception('Failed to update usher');
    }
  }

  Future<List<Map<String, dynamic>>> getClient() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('Client');
    return maps;
  }

  Future<Map<String, dynamic>?> getClientForUser(String clientId) async {
    final db = await database;

    // Kuery untuk mengambil data klien berdasarkan client_id
    final List<Map<String, dynamic>> maps = await db.query(
      'client',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    // Jika data ditemukan, kembalikan hasilnya, jika tidak, kembalikan null
    if (maps.isNotEmpty) {
      return maps.first; // Mengembalikan peta data klien yang ditemukan
    } else {
      return null; // Jika tidak ada klien ditemukan
    }
  }

  Future<Map<String, dynamic>?> getEventForUser(String clientId) async {
    final db = await database;

    // Kuery untuk mengambil data klien berdasarkan client_id
    final List<Map<String, dynamic>> maps = await db.query(
      'Event',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    // Jika data ditemukan, kembalikan hasilnya, jika tidak, kembalikan null
    if (maps.isNotEmpty) {
      return maps.first; // Mengembalikan peta data klien yang ditemukan
    } else {
      return null; // Jika tidak ada klien ditemukan
    }
  }

  Future<List<Map<String, dynamic>>> getEventSessionsForClients(
      List<String> clientIds) async {
    final db = await database;

    // Menggunakan IN clause untuk mendapatkan event yang sesuai dengan client IDs
    String placeholders = clientIds.map((id) => '?').join(',');

    // Query untuk join tabel Event dan Client berdasarkan client_id
    String query = '''
    SELECT Event.*, Client.name AS client_name
    FROM Event
    INNER JOIN Client ON Event.client_id = Client.client_id
    WHERE Event.client_id IN ($placeholders)
  ''';

    return await db.rawQuery(
        query, clientIds); // Menjalankan query dan mengembalikan data
  }

  Future<List<Map<String, dynamic>>> getGuestRsvp(
      String sessionId, String rsvpKey) async {
    Database db = await instance.database;

    // Define your updated query
    String query = '''
      SELECT 
      C.name AS client_name,
      E.event_name,
      E.date,
      S.session_name,
      S.location,
      S.time,

      -- Total RSVP Pending
      (SELECT COUNT(*) 
      FROM Check_in 
      WHERE rsvp = 'pending' 
        AND session_id = S.session_id) AS total_rsvp_pending,
      
      -- Total Guests for the Session
      (SELECT COUNT(*) 
      FROM Check_in 
      WHERE session_id = S.session_id) AS total_guests,

      -- Details of All Guests
      CI.guest_id,
      G.guest_qr,
      G.name AS guest_name,
      G.email,         
      G.phone,
      G.pax,
      G.tables,
      G.cat

  FROM 
      Session S
  JOIN 
      Event E ON S.event_id = E.event_id
  JOIN 
      Client C ON E.client_id = C.client_id
  JOIN 
      Check_in CI ON S.session_id = CI.session_id
  JOIN 
      Guest G ON CI.guest_id = G.guest_id
  WHERE 
      S.session_id = ?
      AND CI.rsvp = ?;
    ''';

    // Execute the query
    List<Map<String, dynamic>> result =
        await db.rawQuery(query, [sessionId, rsvpKey]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getGuestCI(
      String sessionId, String guestKey) async {
    Database db = await instance.database;

    // Define your query
    String query = '''
        SELECT 
        C.name AS client_name,
        E.event_name,
        E.date,
        S.session_name,
        S.location,
        S.time,

        -- Total RSVP Pending
        (SELECT COUNT(*) 
        FROM Guest 
        WHERE rsvp = 'pending' 
          AND guest_id IN (SELECT guest_id FROM Check_in WHERE session_id = S.session_id)) AS total_rsvp_pending,
        
        -- Total Guests for the Session
        (SELECT COUNT(*) 
        FROM Guest 
        WHERE guest_id IN (SELECT guest_id FROM Check_in WHERE session_id = S.session_id)) AS total_guests,

        -- Details of All Guests
        G.guest_id,
        G.guest_qr,
        G.name AS guest_name,
        G.email,         
        G.phone,
        G.pax,
        G.tables,
        G.cat

    FROM 
        Session S
    JOIN 
        Event E ON S.event_id = E.event_id
    JOIN 
        Client C ON E.client_id = C.client_id
    JOIN 
        Check_in CI ON S.session_id = CI.session_id
    JOIN 
        Guest G ON CI.guest_id = G.guest_id
    WHERE 
        S.session_id = ?
        AND CI.status = ? 
        AND CI.rsvp != '0';
  ''';

    // Execute the query
    List<Map<String, dynamic>> result =
        await db.rawQuery(query, [sessionId, guestKey]);

    return result;
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Client');
    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<List<Template>> getTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Templates');
    return List.generate(maps.length, (i) {
      return Template.fromMap(maps[i]);
    });
  }

  Future<List<Usher>> getUshers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Ushers');
    return List.generate(maps.length, (i) {
      return Usher.fromMap(maps[i]);
    });
  }

  Future<List<Event>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Event');
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  Future<List<Session>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Session');
    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  Future<List<TableModel>> getTables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Table');
    return List.generate(maps.length, (i) {
      return TableModel.fromMap(maps[i]);
    });
  }

  Future<List<AngpauModel>> getAngpau() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Angpau');
    return List.generate(maps.length, (i) {
      return AngpauModel.fromMap(maps[i]);
    });
  }

  Future<List<AngpauTitipanModel>> getEnvelope() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Angpau_titipan');
    return List.generate(maps.length, (i) {
      return AngpauTitipanModel.fromMap(maps[i]);
    });
  }

  Future<List<Guest>> getGuests() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Guest');
    return List.generate(maps.length, (i) {
      return Guest.fromMap(maps[i]);
    });
  }

  Future<List<CheckIn>> getCheckIns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Check_In');
    return List.generate(maps.length, (i) {
      return CheckIn.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getAllClientData() async {
    Database db = await instance.database;
    return await db.query('Client'); // Mengambil semua data dari tabel Client
  }

  Future<List<Map<String, dynamic>>> getAllUsersData() async {
    Database db = await instance.database;
    return await db.query('Users');
  }

  Future<List<Map<String, dynamic>>> getAllEventData() async {
    Database db = await instance.database;
    return await db.query('Event');
  }

  Future<List<Map<String, dynamic>>> getAllSessionData() async {
    Database db = await instance.database;
    return await db.query('Session');
  }

  Future<List<Map<String, dynamic>>> getAllGuestData() async {
    Database db = await instance.database;
    return await db.query('Guest');
  }

  Future<List<Map<String, dynamic>>> getAllTableData() async {
    Database db = await instance.database;
    return await db.query('Table');
  }

  Future<List<Map<String, dynamic>>> getAllCheckInData() async {
    Database db = await instance.database;
    return await db.query('Check_In');
  }

  Future<Map<String, dynamic>> getClientDetails(String clientId) async {
    final db = await database;
    final result = await db.query(
      'Client',
      columns: ['name'],
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
    return result.isNotEmpty ? result.first : {};
  }

  Future<void> deleteClient(String clientId) async {
    final db = await instance.database;
    try {
      await db.delete(
        'Client',
        where: 'client_id = ?',
        whereArgs: [clientId],
      );
      log.info('Client deleted successfully');
    } catch (e) {
      log.severe('Error deleting client: $e');
      throw Exception('Failed to delete client');
    }
  }

  Future<void> deleteUsher(String usherId) async {
    final db = await instance.database;
    try {
      await db.delete(
        'Ushers',
        where: 'usher_id = ?',
        whereArgs: [usherId],
      );
      log.info('Usher deleted successfully');
    } catch (e) {
      log.severe('Error deleting usher: $e');
      throw Exception('Failed to delete usher');
    }
  }

  Future<List<Map<String, dynamic>>> getEventByGuestId(String guestId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT Event.*
      FROM Event
      INNER JOIN Session ON Event.event_id = Session.event_id
      INNER JOIN Check_in ON Session.session_id = Check_in.session_id
      WHERE Check_in.guest_id = ?
    ''', [guestId]);
    return result;
  }

  // guest
  Future<List<Map<String, dynamic>>> getGuestsByEventId(String eventId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT Guest.*
      FROM Guest
      INNER JOIN Check_in ON Guest.guest_id = Check_in.guest_id
      INNER JOIN Session ON Check_in.session_id = Session.session_id
      WHERE Session.event_id = ?
    ''', [eventId]);
    return result;
  }

  // guest
  Future<List<Map<String, dynamic>>> getGuestsBySessionId(
      String sessionId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT Guest.*
      FROM Guest
      INNER JOIN Check_in ON Guest.guest_id = Check_in.guest_id
      INNER JOIN Session ON Check_in.session_id = Session.session_id
      WHERE Session.session_id = ?
    ''', [sessionId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getGuestsBySessionIdWhereCI(
      String sessionId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT Guest.*, 
                      Check_in.angpau_label, 
                      Check_in.created_at, 
                      Angpau_titipan.angpau_titipan_name as angpauTitipan, 
                      Angpau_titipan.amount
      FROM Guest
      INNER JOIN Check_in ON Guest.guest_id = Check_in.guest_id
      INNER JOIN Session ON Check_in.session_id = Session.session_id
      LEFT JOIN Angpau_titipan 
            ON Guest.guest_id = Angpau_titipan.guest_id 
      WHERE Session.session_id = ? 
        AND Check_in.status = 'checked-in';


    ''', [sessionId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getGuestsBySessionIdWhereNotCI(
      String sessionId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT Guest.*
      FROM Guest
      INNER JOIN Check_in ON Guest.guest_id = Check_in.guest_id
      INNER JOIN Session ON Check_in.session_id = Session.session_id
      WHERE Session.session_id = ? AND Check_in.status = 'not check-in yet'
    ''', [sessionId]);
    return result;
  }

  Future<List<Guest>> getGuestsByClientId(String clientId) async {
    final db = await instance.database;

    final result = await db.query(
      'Guest',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    return result.map((json) => Guest.fromMap(json)).toList();
  }

  Future<List<Guest>> getGuest() async {
    final db = await instance.database;
    final guestData = await db.query('Guest');

    return guestData.map((json) => Guest.fromMap(json)).toList();
  }

  Future<void> deleteGuest(String id) async {
    final db = await instance.database;
    await db.delete(
      'Guest',
      where: 'guest_id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> insertGuest(Guest guest) async {
    final db = await instance.database;

    // Menyisipkan data tamu ke database dan mendapatkan ID baris baru
    await db.insert('Guest', guest.toMap());

    // Mengembalikan guest_id yang ditetapkan
    return guest.guest_id;
  }

  Future<int> updateGuest(Guest guest) async {
    final db = await instance.database;

    int result = await db.update(
      'Guest',
      guest.toMap(),
      where: 'guest_id = ?',
      whereArgs: [guest.guest_id],
    );

    return result;
  }

  Future<int> updateCheckIns(CheckIn checkIn) async {
    final db = await instance.database;

    return await db.update(
      'Check_in',
      checkIn.toMap(),
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [checkIn.session_id, checkIn.guest_id],
    );
  }

// tambahan
  Future<Guest?> getGuestById(String guestId) async {
    final db = await database;
    final result =
        await db.query('Guest', where: 'guest_id = ?', whereArgs: [guestId]);
    if (result.isEmpty) {
      // Jika tidak ada hasil, kembalikan null
      return null;
    } else {
      return Guest.fromMap(result.first);
    }
  }

  Future<Client?> getClientById(String clientId) async {
    final db = await database;
    final maps = await db.query(
      'Client',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Template?> getTemplateById(String templateId) async {
    final db = await database;
    final maps = await db.query(
      'Templates',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );

    if (maps.isNotEmpty) {
      return Template.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Usher?> getUsherById(String usherId) async {
    final db = await database;
    final maps = await db.query(
      'Ushers',
      where: 'usher_id = ?',
      whereArgs: [usherId],
    );

    if (maps.isNotEmpty) {
      return Usher.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<CheckIn?> getCheckInById(String sessionId, String guestId) async {
    final db = await database;
    final maps = await db.query(
      'Check_In',
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [sessionId, guestId],
    );

    if (maps.isNotEmpty) {
      return CheckIn.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Event> getEventBySessionId(String sessionId) async {
    final db = await database;
    final result = await db
        .query('Event', where: 'session_id = ?', whereArgs: [sessionId]);
    return Event.fromMap(result.first);
  }

  Future<List<Map<String, dynamic>>> getSessionsByEventId(
      String eventId) async {
    Database db = await instance.database;
    return await db
        .query('Session', where: 'event_id = ?', whereArgs: [eventId]);
  }

  Future<List<Map<String, dynamic>>> getEventsByClientIdForStat(
      String clientId) async {
    Database db = await instance.database;
    return await db
        .query('Event', where: 'client_id = ?', whereArgs: [clientId]);
  }

  Future<Map<String, dynamic>> getStatistics(String session) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final query = '''
          SELECT
    C.name AS client_name,
    E.event_name,
    S.session_name,
    (
        SELECT COUNT(*)
        FROM check_in CI
        WHERE CI.status = 'checked-in'
        AND CI.session_id = S.session_id
    ) AS total_guest_attendance,
    (
        SELECT COUNT(*)
        FROM check_in CI
        WHERE CI.status = 'not check-in yet'
        AND CI.session_id = S.session_id
        AND CI.rsvp != '0'
    ) AS total_not_checked_in,
    (
        SELECT COUNT(*)
        FROM check_in CI
        WHERE CI.rsvp = '1'
        AND CI.session_id = S.session_id
    ) AS total_rsvp_attend,
    (
        SELECT COUNT(*)
        FROM check_in CI
        WHERE CI.rsvp = '0'
        AND CI.session_id = S.session_id
    ) AS total_rsvp_unable_attend,
    (
        SELECT COUNT(*)
        FROM check_in CI
        WHERE CI.rsvp = 'pending'
        AND CI.session_id = S.session_id
    ) AS total_rsvp_pending,
    (
        SELECT COUNT(*)
        FROM check_in CI
        WHERE CI.session_id = S.session_id
    ) AS total_guests,
    SUM(G.pax) AS total_pax,
    SUM(
        CASE
            WHEN CI.status = 'checked-in' THEN CI.pax_checked
            ELSE 0
        END
    ) AS total_pax_checked,
    SUM(
        CASE
            WHEN CI.status = 'not check-in yet' THEN CI.pax_checked
            ELSE 0
        END
    ) AS total_pax_not,
    SUM(
        CASE
            WHEN CI.rsvp = '1' THEN CI.pax_checked
            ELSE 0
        END
    ) AS total_pax_rsvp_attend,
    SUM(
        CASE
            WHEN CI.rsvp = '0' THEN CI.pax_checked
            ELSE 0
        END
    ) AS total_pax_rsvp_not,
    SUM(
        CASE
            WHEN CI.rsvp = 'pending' THEN G.pax
            ELSE 0
        END
    ) AS total_pax_rsvp_pending,
    (

       SUM(CASE WHEN CI.angpau_label != '' THEN 1 ELSE 0 END) +
        -- Hitung jumlah amplop dari angpau_titipan yang cocok dengan session_id dan guest_id
        (
            SELECT COUNT(*)
            FROM angpau_titipan AT
            WHERE AT.session_id = S.session_id
            AND AT.guest_id = CI.guest_id
        )
    ) AS total_envelope 
FROM
    session S
    JOIN event E ON S.event_id = E.event_id
    JOIN client C ON E.client_id = C.client_id
    LEFT JOIN check_in CI ON CI.session_id = S.session_id
    LEFT JOIN guest G ON CI.guest_id = G.guest_id
WHERE
    S.session_id = ?
GROUP BY
    C.name,
    E.event_name,
    S.session_name,
    S.session_id;

        ''';

    final result = await db.rawQuery(query, [session]);

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return {
        'client_name': 'No Client Selected',
        'event_name': 'No Event',
        'total_guest_attendance': 0,
        'total_not_checked_in': 0,
        'total_rsvp_confirmed_attend': 0,
        'total_rsvp_pending': 0,
        'total_guests': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getStatisticsUser(String session) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Ambil nilai counter_label dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String counterLabel = prefs.getString('angpau_abjad') ?? 'A';

    final query = '''
    SELECT
        C.name AS client_name,
        E.event_name,
        S.session_name,
        (
            SELECT COUNT(*)
            FROM check_in CI
            WHERE CI.status = 'checked-in'
            AND CI.session_id = S.session_id
        ) AS total_guest_attendance,
        (
            SELECT COUNT(*)
            FROM check_in CI
            WHERE CI.status = 'not check-in yet'
            AND CI.session_id = S.session_id
            AND CI.rsvp != '0'
        ) AS total_not_checked_in,
        (
            SELECT COUNT(*)
            FROM check_in CI
            WHERE CI.rsvp = '1'
            AND CI.session_id = S.session_id
        ) AS total_rsvp_attend,
        (
            SELECT COUNT(*)
            FROM check_in CI
            WHERE CI.rsvp = '0'
            AND CI.session_id = S.session_id
        ) AS total_rsvp_unable_attend,
        (
            SELECT COUNT(*)
            FROM check_in CI
            WHERE CI.rsvp = 'pending'
            AND CI.session_id = S.session_id
        ) AS total_rsvp_pending,
        (
            SELECT COUNT(*)
            FROM check_in CI
            WHERE CI.session_id = S.session_id
        ) AS total_guests,
        SUM(G.pax) AS total_pax,
        SUM(
            CASE
                WHEN CI.status = 'checked-in' THEN CI.pax_checked
                ELSE 0
            END
        ) AS total_pax_checked,
        SUM(
            CASE
                WHEN CI.status = 'not check-in yet' THEN CI.pax_checked
                ELSE 0
            END
        ) AS total_pax_not,
        SUM(
            CASE
                WHEN CI.rsvp = '1' THEN CI.pax_checked
                ELSE 0
            END
        ) AS total_pax_rsvp_attend,
        SUM(
            CASE
                WHEN CI.rsvp = '0' THEN CI.pax_checked
                ELSE 0
            END
        ) AS total_pax_rsvp_not,
        SUM(
            CASE
                WHEN CI.rsvp = 'pending' THEN G.pax
                ELSE 0
            END
        ) AS total_pax_rsvp_pending,
        (
            SUM(CASE WHEN CI.angpau_label != '' THEN 1 ELSE 0 END) +
            (
                SELECT COUNT(*)
                FROM angpau_titipan AT
                WHERE AT.session_id = S.session_id
            )
        ) AS total_envelope,
        (
          SUM(CASE WHEN CI.angpau_label LIKE ? || '%' THEN 1 ELSE 0 END) +
          (
              SELECT COUNT(*)
              FROM angpau_titipan AT
              WHERE AT.counter_label LIKE ? || '%'

          )
        ) AS total_envelope_counter, 
        (
              SELECT COUNT(*)
              FROM angpau_titipan AT
              WHERE AT.counter_label = ?
          ) AS total_envelope_entrust_counter

      
    FROM
        session S
        JOIN event E ON S.event_id = E.event_id
        JOIN client C ON E.client_id = C.client_id
        LEFT JOIN check_in CI ON CI.session_id = S.session_id
        LEFT JOIN guest G ON CI.guest_id = G.guest_id
    WHERE
        S.session_id = ?
    GROUP BY
        C.name,
        E.event_name,
        S.session_name,
        S.session_id;
''';

    final result = await db
        .rawQuery(query, [counterLabel, counterLabel, counterLabel, session]);

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return {
        'client_name': 'No Client Selected',
        'event_name': 'No Event',
        'total_guest_attendance': 0,
        'total_not_checked_in': 0,
        'total_rsvp_confirmed_attend': 0,
        'total_rsvp_pending': 0,
        'total_guests': 0,
      };
    }
  }

  Future<Map<String, dynamic>?> getGuestDetails(String guestId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final query = '''
      SELECT 
        C.name AS client_name,
        E.event_name,
        E.date,
        S.session_name,
        S.time,
        G.name AS guest_name,
        CI.rsvp,
        CI.angpau_label AS angpau_label,
        CI.pax_checked AS pax_checked,
        CI.meals,
        CI.created_at AS createdAt,
        CI.status
      FROM session S
      JOIN event E ON S.event_id = E.event_id
      JOIN client C ON E.client_id = C.client_id
      JOIN check_in CI ON S.session_id = CI.session_id
      JOIN guest G ON CI.guest_id = G.guest_id        
      WHERE CI.guest_id = ?
      ''';

    try {
      final result = await db.rawQuery(query, [guestId]);

      if (result.isNotEmpty) {
        return {
          'sessions': result, // Ensure this is the correct structure
        };
      } else {
        return null;
      }
    } catch (e) {
      print('Error querying guest details: $e');
      return null;
    }
  }

  Future<List<String>> getSessionIdsByEventId(String eventId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Session',
      columns: ['session_id'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    List<String> sessionIds =
        result.map((row) => row['session_id'] as String).toList();
    return sessionIds;
  }

  Future<List<Map<String, String>>> getSessionIdsAndNamesByEventId(
      String eventId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Session',
      columns: ['session_id', 'session_name'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    // Mengubah hasil query menjadi List Map berisi session_id dan session_name
    List<Map<String, String>> sessions = result.map((row) {
      return {
        'session_id': row['session_id'] as String,
        'session_name': row['session_name'] as String,
      };
    }).toList();

    return sessions;
  }

  Future<List<Map<String, String>>> getSessionIdsAndNamesByGuestId(
      String guestId) async {
    final db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      CI.session_id,
      S.session_name
    FROM 
      Check_in CI
    JOIN 
      Session S ON CI.session_id = S.session_id
    WHERE 
      CI.guest_id = ?
  ''', [guestId]);

    List<Map<String, String>> sessions = result.map((row) {
      return {
        'session_id': row['session_id'] as String,
        'session_name': row['session_name'] as String,
      };
    }).toList();

    return sessions;
  }

  Future<void> insertCheckIn(String sessionId, String guestId) async {
    final db = await database;

    // Convert boolean to int (0 for false, 1 for true)
    bool syncedValue = false;

    await db.insert('Check_in', {
      'session_id': sessionId,
      'guest_id': guestId,
      'status': 'not check-in yet',
      'synced': syncedValue,
      // Tambahkan kolom lain sesuai dengan kebutuhan default value
    });
  }

  Future<void> insertKeyAngpau(String key, String sessionId) async {
    final db = await database;

    // Nilai untuk kolom 'synced'
    bool syncedValue = false;

    // Map data yang akan diinsert
    final data = {
      'session_id': sessionId,
      'key': key,
      'synced': syncedValue ? 1 : 0,
      // Kolom lain dengan nilai default
    };

    try {
      // Coba insert data
      await db.insert(
        'Angpau',
        data,
        conflictAlgorithm:
            ConflictAlgorithm.abort, // Abort jika terjadi konflik
      );
    } catch (e) {
      // Jika insert gagal karena konflik, update data yang ada
      await db.update(
        'Angpau',
        data,
        where: 'session_id = ? AND key = ?',
        whereArgs: [sessionId, key],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getKeys(String sessionId) async {
    final db = await database;

    // Query untuk mengambil data dari tabel 'Angpau' berdasarkan session_id
    return await db.query(
      'Angpau',
      columns: ['key'], // Mengambil kolom 'key' untuk setiap data
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> updateCounterAngpau(
      String sessionId, String key, int counterValue) async {
    final db = await database;

    await db.update(
      'Angpau',
      {
        'counter': counterValue,
        'synced': false,
      },
      where: 'session_id = ? AND key = ?',
      whereArgs: [sessionId, key],
    );
  }

  Future<int> getCounterAngpau(String key, String sessionId) async {
    final db = await database;

    // Ambil nilai counter berdasarkan session_id dan key
    final result = await db.query(
      'Angpau',
      columns: ['counter'],
      where: 'session_id = ? AND key = ?',
      whereArgs: [sessionId, key],
    );

    // Jika data ditemukan, kembalikan nilai counter; jika tidak, kembalikan 0
    if (result.isNotEmpty) {
      return result.first['counter'] as int;
    } else {
      return 9999;
    }
  }

  Future<void> insertIdServer(
      String idServer, String superKey, String role, String name) async {
    final db = await database;
    await db.insert('Login', {
      'id_server': idServer,
      'key': superKey,
      'role': role,
      'name': name,
    });
  }

  Future<String?> insertCheckIns(CheckIn checkIn) async {
    final db = await instance.database;

    // Menyisipkan data tamu ke database dan mendapatkan ID baris baru
    await db.insert('Check_in', checkIn.toMap());

    // Mengembalikan checkIn_id yang ditetapkan
    return checkIn.guest_id;
  }

  Future<Session?> getSessionById(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'Session',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (result.isEmpty) {
      // Jika tidak ada hasil, kembalikan null
      return null;
    } else {
      // Jika ada hasil, kembalikan Session dari hasil pertama
      return Session.fromMap(result.first);
    }
  }

  Future<TableModel?> getTableById(String table_id) async {
    final db = await database;
    final result =
        await db.query('Table', where: 'table_id = ?', whereArgs: [table_id]);
    if (result.isEmpty) {
      // Jika tidak ada hasil, kembalikan null
      return null;
    } else {
      // Jika ada hasil, kembalikan Session dari hasil pertama
      return TableModel.fromMap(result.first);
    }
  }

  Future<AngpauModel?> getAngpauById(String session_id, String key) async {
    final db = await database;
    final result = await db.query('Angpau',
        where: 'session_id = ? AND key = ?', whereArgs: [session_id, key]);
    if (result.isEmpty) {
      // Jika tidak ada hasil, kembalikan null
      return null;
    } else {
      // Jika ada hasil, kembalikan Session dari hasil pertama
      return AngpauModel.fromMap(result.first);
    }
  }

  Future<AngpauTitipanModel?> getEnvelopeById(String id) async {
    final db = await database;
    final result = await db.query('Angpau_titipan',
        where: 'angpau_titipan_id = ?', whereArgs: [id]);
    if (result.isEmpty) {
      // Jika tidak ada hasil, kembalikan null
      return null;
    } else {
      // Jika ada hasil, kembalikan Session dari hasil pertama
      return AngpauTitipanModel.fromMap(result.first);
    }
  }

  Future<TableModel> getTableBySessionId(String sessionId) async {
    final db = await database;
    final result = await db
        .query('Table', where: 'session_id = ?', whereArgs: [sessionId]);
    if (result.isNotEmpty) {
      return TableModel.fromMap(result.first);
    } else {
      return TableModel.empty();
    }
  }

  Future<CheckIn> getCheckInByGuestId(String guestId) async {
    final db = await database;
    final result =
        await db.query('Check_in', where: 'guest_id = ?', whereArgs: [guestId]);
    return CheckIn.fromMap(result.first);
  }

// Method untuk mendapatkan CheckIn berdasarkan session_id dan guest_id
  Future<CheckIn?> getCheckInBySessionAndGuestId(
      String sessionId, String guestId) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Check_in',
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [sessionId, guestId],
    );
    if (maps.isNotEmpty) {
      return CheckIn.fromMap(
          maps.first); // Mengembalikan objek CheckIn dari hasil query pertama
    }

    return null; // Mengembalikan null jika tidak ada hasil
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final result = await db.query('Session');
    return result.map((json) => Session.fromMap(json)).toList();
  }

  Future<void> updateCheckIn(CheckIn checkIn, String updatedAt) async {
    final db = await database;
    bool syncedValue = false;
    // Update data Check_in
    await db.update(
      'Check_in',
      {
        'session_id': checkIn.session_id,
        'guest_id': checkIn.guest_id,
        'souvenir': checkIn.souvenir,
        'angpau': checkIn.angpau,
        'pax_checked': checkIn.pax_checked,
        'meals': checkIn.meals,
        'note': checkIn.note,
        'delivery': checkIn.delivery,
        'guestNo': checkIn.guestNo,
        'status': 'checked-in', // Update status ke 'checked-in'
        'synced': syncedValue, // Update status ke 'checked-in'
        'created_at': updatedAt, // Update status ke 'checked-in'
        'updated_at': updatedAt, // Update status ke 'checked-in'
      },
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [checkIn.session_id, checkIn.guest_id],
    );
  }

  Future<void> updateAngpauCheckIn(
      String label, CheckIn checkIn, String updatedAt) async {
    final db = await database;
    bool syncedValue = false;

    await db.update(
      'Check_in',
      {
        'session_id': checkIn.session_id,
        'guest_id': checkIn.guest_id,
        'angpau_label': label,
        'synced': syncedValue,
        'updated_at': updatedAt,
      },
      where: 'session_id = ? AND guest_id = ?',
      whereArgs: [checkIn.session_id, checkIn.guest_id],
    );
  }

  Future<List<CheckIn>> getAllCheckIns() async {
    final db = await instance.database;
    final result = await db.query('Check_in');

    return result.map((json) => CheckIn.fromMap(json)).toList();
  }

  // Method untuk mengambil nama event berdasarkan ID
  Future<String> getEventNameById(String eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Event', // Nama tabel event
      columns: ['event_name'], // Nama kolom yang ingin diambil
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    if (result.isNotEmpty) {
      return result.first['event_name'] as String;
    } else {
      throw Exception('Event tidak ditemukan dengan ID $eventId');
    }
  }

  // Method untuk mengambil nama client berdasarkan ID
  Future<String> getClientNameById(String clientId) async {
    print('helper $clientId');
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Client',
      columns: ['name'],
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    if (result.isNotEmpty) {
      print('${result.first['name']}');
      return result.first['name'] as String;
    } else {
      throw Exception('Client tidak ditemukan dengan ID $clientId');
    }
  }

  Future<String> getSessionIdByEventId(String eventId) async {
    print('helper $eventId');
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'session',
      columns: ['session_id'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    if (result.isNotEmpty) {
      print('${result.first['session_id']}');
      return result.first['session_id'] as String;
    } else {
      throw Exception('Client tidak ditemukan dengan ID $eventId');
    }
  }

  Future<Event?> getEventByClientId(String clientId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Event',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Session>> getAvailableSessions(
      String guestId, String? eventId) async {
    Database db = await instance.database;

    String query = '''
    SELECT s.*
    FROM Session s
    LEFT JOIN Check_in c ON s.session_id = c.session_id AND c.guest_id = ?
    WHERE c.status = 'not check-in yet' AND c.guest_id = ? AND s.event_id = ?
  ''';

    List<Map<String, dynamic>> maps =
        await db.rawQuery(query, [guestId, guestId, eventId]);

    if (maps.isNotEmpty) {
      return List.generate(maps.length, (i) {
        return Session.fromMap(maps[i]);
      });
    }
    return [];
  }

// join

  Future<int> insertEvents(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Event', row);
  }

  Future<String> insertEvent(Event event) async {
    final db = await database;
    try {
      int id = await db.insert('Event', event.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String eventId = id.toString();

      return eventId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<List<Map<String, dynamic>>> getEventSessions() async {
    Database db = await instance.database;
    return await db.rawQuery('''
        SELECT event.event_id, event.event_name, client.client_id, client.name AS client_name
        FROM event
        JOIN client ON event.client_id = client.client_id

    ''');
  }

  Future<List<Map<String, dynamic>>> getEventsByClientId(
      String clientId) async {
    final db = await database;

    // Query untuk mengambil data event, sesi, dan tabel yang terkait
    final result = await db.rawQuery('''
      SELECT 
        e.event_id,
        e.event_name,
        e.date,
        s.session_id,
        s.session_name,
        s.time,
        s.location,
        t.table_id,
        t.table_name,
        t.seat
      FROM Event e
      LEFT JOIN Session s ON e.event_id = s.event_id
      LEFT JOIN 'Table' t ON s.session_id = t.session_id
      WHERE e.client_id = ?
      ORDER BY e.event_id, s.session_id, t.table_id
    ''', [clientId]);

    return result;
  }

  Future<List<Event>> getEventsByClient(String client) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Event',
      where: 'client_name = ?', // Sesuaikan dengan nama kolom yang sesuai
      whereArgs: [client],
    );
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  // Metode untuk mendapatkan event berdasarkan client_id
  Future<List<Event>> getEventsUseClientId(String clientId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Event',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    return List.generate(maps.length, (i) {
      return Event(
        event_id: maps[i]['event_id'],
        client_id: maps[i]['client_id'],
        event_name: maps[i]['event_name'],
        date: maps[i]['date'],
      );
    });
  }

  // Metode untuk mendapatkan sesi berdasarkan event_id
  Future<List<Session>> getSessionsForEventinqr(
      String eventId, String guestId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.session_id, s.session_name, s.time, s.location
      FROM Session s
      JOIN Check_in ci ON s.session_id = ci.session_id
      WHERE ci.guest_id = ?
        AND ci.status = 'not check-in yet';
    ''', [guestId]);

    return List.generate(maps.length, (i) {
      return Session(
        session_id: maps[i]['session_id'],
        event_id: eventId, // eventId diambil dari parameter metode
        session_name: maps[i]['session_name'],
        time: maps[i]['time'],
        location: maps[i]['location'],
      );
    });
  }

// Metode untuk mendapatkan sesi berdasarkan event_id
  Future<List<Session>> getSessionsForEvent(String eventId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Session',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    return List.generate(maps.length, (i) {
      return Session(
        session_id: maps[i]['session_id'],
        event_id: maps[i]['event_id'],
        session_name: maps[i]['session_name'],
        time: maps[i]['time'],
        location: maps[i]['location'],
      );
    });
  }

  // Metode untuk mendapatkan client_id berdasarkan event_id
  Future<String?> getClientIdByEventId(String eventId) async {
    Database db =
        await instance.database; // Pastikan database sudah diinisialisasi
    var result = await db.rawQuery('''
      SELECT client_id 
      FROM event 
      WHERE event_id = ?
    ''', [eventId]);

    if (result.isNotEmpty) {
      return result.first['client_id'] as String?;
    } else {
      return null; // Return null jika tidak ada hasil
    }
  }

  Future<String?> getClientIdByGuestId(String guestId) async {
    final db = await database;
    var result = await db.query(
      'Guest',
      columns: ['client_id'],
      where: 'guest_id = ?',
      whereArgs: [guestId],
    );

    if (result.isNotEmpty) {
      return result.first['client_id'] as String?;
    }
    return null;
  }

  Future<List<String>> getSessionIdsByGuestId(String guestId) async {
    final db = await database;
    var result = await db.query(
      'Check_in',
      columns: ['session_id'],
      where: 'guest_id = ?',
      whereArgs: [guestId],
    );

    if (result.isNotEmpty) {
      return result.map((row) => row['session_id'] as String).toList();
    }
    return [];
  }

  Future<Event?> getEventById(String eventId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> eventMaps = await db.query(
      eventsTable,
      where: '$colEventId = ?',
      whereArgs: [eventId],
    );

    if (eventMaps.isNotEmpty) {
      return Event.fromMap(eventMaps.first);
    }
    return null;
  }

  // Tambahkan fungsi baru untuk mendapatkan event berdasarkan nama dan client_id
  Future<Map<String, dynamic>?> getEventByNameAndClient(
      String eventName, String clientId) async {
    Database db = await instance.database;
    var result = await db.query(
      'event',
      where: 'event_name = ? AND client_id = ?',
      whereArgs: [eventName, clientId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<String> insertSession(Session session) async {
    final db = await database;
    try {
      int id = await db.insert('Session', session.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String sessionId = id.toString();

      return sessionId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<String> insertTable(TableModel tableModel) async {
    final db = await database;
    try {
      int id = await db.insert('Table', tableModel.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String tableId = id.toString();

      return tableId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<String> insertEnvelope(AngpauTitipanModel angpauTitipanModel) async {
    final db = await database;
    try {
      int id = await db.insert('Angpau_titipan', angpauTitipanModel.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String angpauTitipanId = id.toString();

      return angpauTitipanId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<String> insertAngpau(AngpauModel angpauModel) async {
    final db = await database;
    try {
      int id = await db.insert('Angpau', angpauModel.toMap());

      // Mengubah ID integer menjadi string jika diperlukan
      String tableId = id.toString();

      return tableId;
    } catch (e) {
      log.severe('Failed to insert client: $e');
      throw Exception('Failed to insert client');
    }
  }

  Future<void> insertTableFromDetail(
      String uuid, String sessionId, String tableName, int seat) async {
    final Database db = await instance.database;
    await db.insert('Table', {
      'table_id': uuid,
      'session_id': sessionId,
      'table_name': tableName,
      'seat': seat
    });
  }

  Future<void> insertEventByUsers(
      String uuid, String clientId, String eventName, String date) async {
    final Database db = await instance.database;
    await db.insert('Event', {
      'event_id': uuid,
      'client_id': clientId,
      'event_name': eventName,
      'date': date
    });
  }

  Future<String> insertSessionFromDetail(String uuid, String eventId,
      String sessionName, String time, String location) async {
    final db = await database;

    await db.insert(
      'session',
      {
        'session_id': uuid,
        'event_id': eventId,
        'session_name': sessionName,
        'time': time,
        'location': location,
      },
    );

    return uuid; // Kembalikan nilai uuid sebagai sessionId
  }

  Future<void> addCheckIn(String sessionId, String guestId) async {
    final Database db = await instance.database;
    await db.insert('check_in', {'session_id': sessionId, 'guest_id': guestId});
  }

  Future<void> deleteCheckInByGuestId(String guestId) async {
    final db = await database;
    await db.delete(
      'check_in',
      where: 'guest_id = ?',
      whereArgs: [guestId],
    );
  }

  Future<void> deleteCheckIn(String sessionId, String guestId) async {
    final db = await database;
    await db.delete(
      'check_in',
      where: 'guest_id = ? AND session_id = ?',
      whereArgs: [guestId, sessionId],
    );
  }

  Future<void> deleteCheckInBySessionId(String sessionId) async {
    final db = await database;
    await db.delete(
      'check_in',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<TableModel>> getTablesForSession(String sessionId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db
        .query('Table', where: 'session_id = ?', whereArgs: [sessionId]);
    return maps.map((map) => TableModel.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getTablesForDetailSession(
      String sessionId) async {
    final List<Map<String, dynamic>> tables = await _database!.rawQuery(
      'SELECT * FROM "Table" WHERE session_id = ?',
      [sessionId],
    );
    return tables;
  }

  Future<void> updateTableSeats(
      String tableId, int seats, String updatedAt) async {
    Database db = await instance.database;
    bool syncedValue = false;
    await db.update('Table',
        {'seat': seats, 'synced': syncedValue, 'updated_at': updatedAt},
        where: 'table_id = ?', whereArgs: [tableId]);
  }

  Future<List<Session>?> getSessionByEventId(String eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Session',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    if (result.isNotEmpty) {
      return result
          .map((map) => Session.fromMap(map))
          .toList(); // Mengonversi setiap hasil query menjadi objek Session
    } else {
      return null;
    }
  }

  Future<int> deleteEvent(String eventId) async {
    final db = await instance.database;
    return await db.delete(
      'Event',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Future<int> deleteSessionByEventId(String eventId) async {
    final db = await instance.database;
    return await db.delete(
      'Session',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Future<int> deleteSession(String sessionId) async {
    final db = await instance.database;
    return await db.delete(
      'Session',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> deleteTableWithSession(String sessionId) async {
    final db = await instance.database;
    return await db.delete(
      'Table',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, dynamic>>> getSessionDetails(String event_id) async {
    Database db = await instance.database;
    return await db.rawQuery('''
    SELECT session.session_id, session.session_name, session.time, session.location, event.event_id as event_id, event.event_name, event.date as date, client.client_id, client.name AS client_name, 'table'.table_id, 'table'.table_name, 'table'.seat
    FROM session
    JOIN event ON session.event_id = event.event_id
    JOIN client ON event.client_id = client.client_id
    LEFT JOIN 'table' ON session.session_id = 'table'.session_id
    WHERE event.event_id = ?
  ''', [event_id]);
  }

  // Method to get event by eventId
  Future<Map<String, dynamic>> getEventByEventId(String eventId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'event',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return result.isNotEmpty ? result.first : {};
  }

  // Method to update event
  Future<int> updateEvents(String eventId, Map<String, dynamic> event) async {
    Database db = await instance.database;
    return await db.update(
      'Event',
      event,
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  // Method to update event
  Future<int> updateEvent(Event event) async {
    Database db = await instance.database;
    try {
      int result = await db.update(
        'Event',
        event.toMap(),
        where: 'event_id = ?',
        whereArgs: [event.event_id],
      );
      log.info('Event updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating event: $e');
      throw Exception('Failed to update event');
    }
  }

  // Method to update session
  Future<int> updateSession(
      String sessionId, Map<String, dynamic> session) async {
    Database db = await instance.database;
    return await db.update(
      'sessions',
      session,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> updateSessions(Session session) async {
    Database db = await instance.database;
    try {
      int result = await db.update(
        'Session',
        session.toMap(),
        where: 'session_id = ?',
        whereArgs: [session.session_id],
      );
      log.info('Session updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating session: $e');
      throw Exception('Failed to update session');
    }
  }

  // Cek keberadaan record di tabel berdasarkan ID
  Future<bool> recordExists(String tableName, String id) async {
    final db = await database;

    String columnId;
    if (tableName == 'ushers') {
      columnId = 'usher_id';
    } else if (tableName == 'client') {
      columnId = 'client_id';
    } else if (tableName == 'event') {
      columnId = 'event_id';
    } else if (tableName == 'guest') {
      columnId = 'guest_id';
    } else if (tableName == 'session') {
      columnId = 'session_id';
    } else {
      columnId = 'HAHAH'; // Kolom ID default
    }

    final List<Map<String, dynamic>> result = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    return result
        .isNotEmpty; // Kembalikan true jika record ada, false jika tidak
  }

  // Hapus record di tabel berdasarkan ID
  Future<void> deleteRecord(String tableName, String id) async {
    final db = await database;

    String columnId;
    if (tableName == 'ushers') {
      columnId = 'usher_id';
    } else if (tableName == 'client') {
      columnId = 'client_id';
    } else if (tableName == 'event') {
      columnId = 'event_id';
    } else if (tableName == 'guest') {
      columnId = 'guest_id';
    } else if (tableName == 'session') {
      columnId = 'session_id';
    } else {
      columnId = 'HAHAH'; // Kolom ID default
    }

    await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTemplatesByClientId(
      String clientId) async {
    Database db = await instance.database;

    // Menggunakan where untuk mendapatkan templates berdasarkan client_id
    return await db.query(
      'Templates',
      where: 'client_id = ?', // Kondisi untuk filter
      whereArgs: [clientId], // Parameter untuk kondisi di atas
    );
  }

  Future<int> updateTables(TableModel tableModel) async {
    Database db = await instance.database;
    try {
      int result = await db.update(
        'Table',
        tableModel.toMap(),
        where: 'table_id = ?',
        whereArgs: [tableModel.table_id],
      );
      log.info('Table updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating table: $e');
      throw Exception('Failed to update table');
    }
  }

  Future<int> updateAngpau(AngpauModel angpauModel) async {
    Database db = await instance.database;
    try {
      int result = await db.update(
        'Angpau',
        angpauModel.toMap(),
        where: 'session_id = ? AND key = ?',
        whereArgs: [angpauModel.session_id, angpauModel.key],
      );
      log.info('Table updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating table: $e');
      throw Exception('Failed to update table');
    }
  }

  Future<int> updateEnvelope(AngpauTitipanModel angpauTitipanModel) async {
    Database db = await instance.database;
    try {
      int result = await db.update(
        'Angpau_titipan',
        angpauTitipanModel.toMap(),
        where: 'angpau_titipan_id = ?',
        whereArgs: [angpauTitipanModel.angpau_titipan_id],
      );
      log.info('Envelope updated successfully');
      return result;
    } catch (e) {
      log.severe('Error updating table: $e');
      throw Exception('Failed to update table');
    }
  }

  // Method to update table
  Future<int> updateTable(int tableId, Map<String, dynamic> table) async {
    Database db = await instance.database;
    return await db.update(
      'tables',
      table,
      where: 'table_id = ?',
      whereArgs: [tableId],
    );
  }

  Future<Map<String, dynamic>> getEventDetails(String eventId) async {
    final db = await database;
    var result = await db.query(
      'Event',
      columns: ['event_name', 'client_id', 'date'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return result.isNotEmpty ? result.first : {};
  }

  Future<void> updateEventDetails(
      String eventId, String newName, String newDate, String updatedAt) async {
    final db = await database;

    // Convert boolean to int (0 for false, 1 for true)
    bool syncedValue = false;

    await db.update(
      'Event',
      {
        'event_name': newName,
        'date': newDate,
        'updated_at': updatedAt,
        'synced': syncedValue, // Store as int instead of bool
      },
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllClients() async {
    final db = await database;
    var result = await db.query('Client');
    return result;
  }

  Future<void> updateClientId(
      String eventId, String newClientId, String updatedAt) async {
    final db = await database;
    // Convert boolean to int (0 for false, 1 for true)
    bool syncedValue = false;
    await db.update(
      'Event',
      {
        'client_id': newClientId,
        'updated_at': updatedAt,
        'synced': syncedValue
      },
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Future<Map<String, dynamic>> getSessionDetailsById(String sessionId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Session',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      throw Exception('Session not found');
    }
  }

  Future<List<Map<String, dynamic>>> getTablesBySessionId(
      String sessionId) async {
    final db = await database;
    return await db.query(
      'Table',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<Map<String, dynamic>?> getSessionRelatedData(String sessionId) async {
    final db = await database;

    // Retrieve the event_id from the sessions table
    final sessionResult = await db.query(
      'session',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (sessionResult.isNotEmpty) {
      String? eventId = sessionResult.first['event_id'] as String?;

      // Retrieve the table_id from the tables table (if needed)
      final tableResult = await db.query(
        'table',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      String? tableId = tableResult.isNotEmpty
          ? tableResult.first['table_id'] as String?
          : null;

      return {
        'event_id': eventId,
        'table_id': tableId,
      };
    }

    return null; // Return null if no data found
  }

  Future<List<Map<String, dynamic>>> getCheckInsBySessionId(
      String sessionId) async {
    final db = await database;

    // Query untuk mengambil semua check-in yang terkait dengan session_id tertentu
    final List<Map<String, dynamic>> results = await db.query(
      'Check_in',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    return results; // Mengembalikan hasil query sebagai List<Map<String, dynamic>>
  }

  Future<String?> getClientIdsFromLogin() async {
    final db = await database;
    log.info('Fetching client IDs from login table');

    try {
      // Ambil data dari tabel login
      List<Map<String, dynamic>> result =
          await db.query('login', columns: ['key']);

      log.info('Raw result from login table: $result');

      if (result.isNotEmpty) {
        // Ambil client_id dari kolom 'key'
        String clientIds = result.first['key']
            as String; // Ambil data client_id dari hasil pertama
        log.info('Client IDs retrieved: $clientIds');
        return clientIds; // Mengembalikan data mentah
      } else {
        log.warning('No data found in the login table.');
      }
    } catch (e) {
      log.severe('Error fetching client IDs from login: $e');
    }

    return null; // Jika tidak ada data
  }

  Future<List<Map<String, dynamic>>> getCheckInsByGuestId(
      String guestId) async {
    final db = await database;

    // Query untuk mengambil semua check-in yang terkait dengan session_id tertentu
    final List<Map<String, dynamic>> results = await db.query(
      'Check_in',
      where: 'guest_id = ?',
      whereArgs: [guestId],
    );

    return results; // Mengembalikan hasil query sebagai List<Map<String, dynamic>>
  }

  Future<void> updateSessionDetails(String sessionId, String sessionName,
      String time, String location, String updatedAt) async {
    final db = await database;

    // Convert boolean to int (0 for false, 1 for true)
    bool syncedValue = false;
    await db.update(
      'Session',
      {
        'session_name': sessionName,
        'time': time,
        'location': location,
        'updated_at': updatedAt,
        'synced': syncedValue
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> updateTableDetails(
      String tableId, String tableName, int seat, String updatedAt) async {
    final db = await database;

    // Convert boolean to int (0 for false, 1 for true)
    bool syncedValue = false;
    await db.update(
      'Table',
      {
        'table_name': tableName,
        'seat': seat,
        'updated_at': updatedAt,
        'synced': syncedValue
      },
      where: 'table_id = ?',
      whereArgs: [tableId],
    );
  }

  Future<List<Map<String, dynamic>>> getTableDetails(String sessionId) async {
    final db = await database;
    var res = await db.query(
      'table',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return res;
  }

  Future<Map<String, dynamic>?> getTableDetailsById(
      String tableId, String sessionId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db
        .query('table', where: 'session_id = ?', whereArgs: [sessionId]);
    if (result.isNotEmpty) {
      return result.first; // Return the first map from the list
    } else {
      return null; // Handle case when no data is found
    }
  }

  Future<List<String>> getGuestIdAtCheckInBySessionId(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'Check_in',
      columns: ['guest_id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    // Extract guest_id from the results and return them as a list of strings
    List<String> guestIds =
        results.map((row) => row['guest_id'] as String).toList();

    return guestIds;
  }

// Method untuk menyimpan client yang dihapus
  Future<void> insertDeletedClient(String clientId, String idServer) async {
    final db = await instance.database;
    await db.insert(
      'deleted_clients',
      {
        'client_id': clientId,
        'user_id': idServer,
        'deleted_at': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDeletedUsher(String usherId, String idServer) async {
    final db = await instance.database;
    await db.insert(
      'deleted_ushers',
      {
        'usher_id': usherId,
        'user_id': idServer,
        'deleted_at': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDeletedEvent(
      String eventId, String clientId, String idServer) async {
    final db = await instance.database;
    final log = Logger('DBHELPER'); // Assuming you have a logger instance

    try {
      // Log the start of the insertion
      log.info(
          'Inserting event into deleted_events: eventId=$eventId, clientId=$clientId, userId=$idServer');

      // Perform the insertion
      await db.insert(
        'deleted_events',
        {
          'event_id': eventId,
          'client_id': clientId,
          'user_id': idServer,
          'deleted_at': DateTime.now().toIso8601String()
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Log successful insertion
      log.info(
          'Successfully inserted event into deleted_events: eventId=$eventId');
    } catch (e) {
      // Log any errors that occur
      log.severe('Error inserting event into deleted_events: $e');
    }
  }

  Future<void> insertDeletedTable(
      String tableId, String sessionId, String idServer) async {
    final db = await instance.database;
    await db.insert(
      'deleted_tables',
      {
        'table_id': tableId,
        'session_id': sessionId,
        'user_id': idServer,
        'deleted_at': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDeletedSession(
      String sessionId, String eventId, String idServer) async {
    final db = await instance.database;
    await db.insert(
      'deleted_sessions',
      {
        'session_id': sessionId,
        'event_id': eventId,
        'user_id': idServer,
        'deleted_at': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDeletedGuest(
      String guestId, String? clientId, String idServer) async {
    final db = await instance.database;
    await db.insert(
      'deleted_guests',
      {
        'guest_id': guestId,
        'client_id': clientId,
        'user_id': idServer,
        'deleted_at': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertDeletedCheckIn(
      String? sessionId, String guestId, String idServer) async {
    final db = await instance.database;
    await db.insert(
      'deleted_check_in',
      {
        'session_id': sessionId,
        'guest_id': guestId,
        'user_id': idServer,
        'deleted_at': DateTime.now().toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Method untuk mendapatkan daftar client yang dihapus
  Future<List<Map<String, dynamic>>> getDeletedClients() async {
    final db = await instance.database;
    final result = await db.query('deleted_clients');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeletedUshers() async {
    final db = await instance.database;
    final result = await db.query('deleted_ushers');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeletedTables() async {
    final db = await instance.database;
    final result = await db.query('deleted_tables');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeletedSessions() async {
    final db = await instance.database;
    final result = await db.query('deleted_sessions');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeletedEvents() async {
    final db = await instance.database;
    final result = await db.query('deleted_events');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeletedCheckIns() async {
    final db = await instance.database;
    final result = await db.query('deleted_check_in');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDeletedGuests() async {
    final db = await instance.database;
    final result = await db.query('deleted_guests');
    return result;
  }

// Method untuk menghapus client dari daftar client yang dihapus
  Future<void> removeDeletedClient(String clientId) async {
    final db = await instance.database;
    await db.delete(
      'deleted_clients',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  Future<void> removeDeletedUsher(String usherId) async {
    final db = await instance.database;
    await db.delete(
      'deleted_ushers',
      where: 'usher_id = ? AND user_id = ?',
      whereArgs: [usherId],
    );
  }

  Future<void> removeDeletedTable(
      String tableId, String sessionId, String idServer) async {
    final db = await instance.database;
    await db.delete(
      'deleted_tables',
      where: 'table_id = ? AND session_id = ? AND user_id = ?',
      whereArgs: [tableId, sessionId, idServer],
    );
  }

  Future<void> removeDeletedSession(
      String sessionId, String eventId, String idServer) async {
    final db = await instance.database;
    await db.delete(
      'deleted_sessions',
      where: 'session_id = ? AND event_id = ? AND user_id = ?',
      whereArgs: [sessionId, eventId, idServer],
    );
  }

  Future<void> removeDeletedEvent(
      String eventId, String clientId, String idServer) async {
    final db = await instance.database;
    await db.delete(
      'deleted_events',
      where: 'event_id = ? AND client_id = ? AND user_id = ?',
      whereArgs: [eventId, clientId, idServer],
    );
  }

  Future<void> removeDeletedCheckIn(
      String sessionId, String guestId, String idServer) async {
    final db = await instance.database;
    await db.delete(
      'deleted_check_in',
      where: 'session_id = ? AND guest_id = ? AND user_id = ?',
      whereArgs: [sessionId, guestId, idServer],
    );
  }

  Future<void> removeDeletedGuest(
      String guestId, String clientId, String idServer) async {
    final db = await instance.database;
    await db.delete(
      'deleted_guests',
      where: 'guest_id = ? AND client_id = ? AND user_id = ?',
      whereArgs: [guestId, clientId, idServer],
    );
  }

  Future<String?> getIdServer() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Login',
      columns: ['id_server'],
      limit: 1, // Assuming we only need one entry
    );
    if (maps.isNotEmpty) {
      return maps.first['id_server'] as String?;
    }
    return null;
  }

  Future<String?> getRoleServer() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Login',
      columns: ['role'],
      limit: 1, // Assuming we only need one entry
    );
    if (maps.isNotEmpty) {
      return maps.first['role'] as String?;
    }
    return null;
  }

  Future<String?> getNameServer() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Login',
      columns: ['name'],
      limit: 1, // Assuming we only need one entry
    );
    if (maps.isNotEmpty) {
      return maps.first['name'] as String?;
    }
    return null;
  }

  Future<void> insertPageData(String role, String clientId, String idServer,
      String clientName, Event event, Session session) async {
    final db = await instance.database;

    await db.insert(
      'Pages_tempo',
      {
        'idServer': idServer,
        'clientId': clientId,
        'clientName': clientName,
        'role': role,
        'event': jsonEncode(event.toJson()), // Simpan event sebagai JSON string
        'session':
            jsonEncode(session.toJson()), // Simpan session sebagai JSON string
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getPageData(String idServer) async {
    final db = await instance.database;
    final result = await db.query(
      'Pages_tempo',
      where: 'idServer = ?',
      whereArgs: [idServer],
      limit: 1,
    );

    if (result.isNotEmpty) {
      // Ambil data dari database
      final pageData = result.first;

      // Pastikan kolom 'event' dan 'session' adalah String sebelum di-decode
      final eventJson = pageData['event'];
      final sessionJson = pageData['session'];

      Event event;
      Session session;

      // Pengecekan null dan tipe data sebelum decode
      if (eventJson != null && eventJson is String) {
        event = Event.fromJson(jsonDecode(eventJson));
      } else {
        throw Exception('Invalid event data');
      }

      if (sessionJson != null && sessionJson is String) {
        session = Session.fromJson(jsonDecode(sessionJson));
      } else {
        throw Exception('Invalid session data');
      }

      return {
        'role': pageData['role'],
        'clientId': pageData['clientId'],
        'clientName': pageData['clientName'],
        'event': event,
        'session': session,
        'created_at': pageData['created_at'],
        'updated_at': pageData['updated_at'],
      };
    }
    return null;
  }

  Future<void> clearPagesTempo() async {
    final db = await database;
    await db.delete('Pages_tempo');
  }

  Future<void> clearAllData() async {
    final db = await database;

    await db.delete('Angpau');
    await db.delete('Angpau_titipan');
    await db.delete('Login');
    await db.delete('Pages_tempo');
    await db.delete('deleted_check_in');
    await db.delete('deleted_tables');
    await db.delete('deleted_sessions');
    await db.delete('deleted_guests');
    await db.delete('deleted_events');
    await db.delete('deleted_clients');
    await db.delete('deleted_ushers');
    await db.delete('Check_in');
    await db.delete('Table');
    await db.delete('Session');
    await db.delete('Event');
    await db.delete('Guest');
    await db.delete('Templates');
    await db.delete('Client');
    await db.delete('Ushers');
  }
}
