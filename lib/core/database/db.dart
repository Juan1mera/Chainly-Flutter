import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Db {
  static final Db _instance = Db._internal();
  static Database? _database;

  Db._internal();

  factory Db() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "wallets.db");

    return await openDatabase(
      path,
      version: 1, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE wallets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        currency TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('bank', 'cash')),
        created_at TEXT NOT NULL,
        icon_bank TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        name TEXT NOT NULL UNIQUE,
        monthly_budget REAL DEFAULT 0.0,
        icon TEXT,
        color TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wallet_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income', 'transfer')),
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    // Insertar categoría por defecto
    await db.insert('categories', {
      'name': 'Sin categoría',
      'monthly_budget': 0.0,
    });
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_wallets_is_favorite ON wallets(is_favorite)');
    await db.execute('CREATE INDEX idx_wallets_is_archived ON wallets(is_archived)');
    await db.execute('CREATE INDEX idx_wallets_type ON wallets(type)');
    await db.execute('CREATE INDEX idx_wallets_created_at ON wallets(created_at)');
    await db.execute('CREATE INDEX idx_categories_name ON categories(name)');
    await db.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "wallets.db");
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}