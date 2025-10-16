import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'circle_app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // ✅ Central place to create all tables
    await db.execute('''
      CREATE TABLE contact_list(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        public_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_table(
        id String PRIMARY KEY,
        name TEXT,
        public_chat_id TEXT,
        is_group INTEGER NOT NULL CHECK (is_group IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE message(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        msg_pub_id TEXT, 
        message TEXT NOT NULL,
        from_me INTEGER NOT NULL CHECK (from_me IN (0,1)),
        chat_id String NOT NULL,
        status TEXT,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chat_table(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_participants(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id String NOT NULL,
        contact_public_id TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chat_table(id) ON DELETE CASCADE,
        FOREIGN KEY (contact_public_id) REFERENCES contact_list(public_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE media_files(
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        public_id TEXT NOT NULL,
        message_id INTEGER NOT NULL,
        FOREIGN KEY (message_id) REFERENCES message(id) ON DELETE CASCADE
      )
    ''');

    // Later, just add more tables here (message, user, etc.)
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE media_files(
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        public_id TEXT NOT NULL,
        message_id INTEGER NOT NULL,
        FOREIGN KEY (message_id) REFERENCES message(id) ON DELETE CASCADE
      )
    ''');
    }
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
