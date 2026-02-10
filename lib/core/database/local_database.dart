import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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

    final db = await openDatabase(
      path,
      version: 3, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    return db;
  }
  

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Crear tabla stores
      await db.execute('''
        CREATE TABLE stores(
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          website TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Agregar columna store_id a transacciones
      await db.execute('ALTER TABLE transactions ADD COLUMN store_id TEXT');
      await db.execute('CREATE INDEX idx_transactions_store ON transactions(store_id)');
      await db.execute('CREATE INDEX idx_stores_user ON stores(user_id)');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE subscriptions ADD COLUMN store_id TEXT');
      await db.execute('CREATE INDEX idx_subscriptions_store ON subscriptions(store_id)');
    }
  }

  Future<void> _createTables(Database db) async {
    // Tabla de wallets
    await db.execute('''
      CREATE TABLE wallets(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        currency TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('bank', 'cash')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        icon_bank TEXT
      )
    ''');

    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        monthly_budget REAL DEFAULT 0.0,
        icon TEXT,
        color TEXT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, name)
      )
    ''');

    // Tabla de stores
    await db.execute('''
      CREATE TABLE stores(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        website TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de transacciones
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL, 
        wallet_id TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income', 'transfer')),
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        category_id TEXT,
        store_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL
      )
    ''');

    // Tabla de suscripciones
    await db.execute('''
      CREATE TABLE subscriptions(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        favicon TEXT,
        created_at TEXT NOT NULL,
        billing_date TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        category_id TEXT,
        store_id TEXT,
        currency TEXT NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL
      )
    ''');

    // Insertar categorías por defecto
    final now = DateTime.now().toIso8601String();
    
    await db.insert('categories', {
      'id': Uuid().v4(),
      'name': 'Sin categoría',
      'monthly_budget': 0.0,
      'user_id': 'system',
      'type': 'expense',
      'color': '#9E9E9E',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('categories', {
      'id': 'subscriptions_category',
      'name': 'Subscriptions',
      'monthly_budget': 0.0,
      'user_id': 'system',
      'type': 'expense',
      'color': '#6200EE', 
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _createIndexes(Database db) async {
    // Índices para wallets
    await db.execute('CREATE INDEX idx_wallets_user ON wallets(user_id)');
    await db.execute('CREATE INDEX idx_wallets_is_favorite ON wallets(is_favorite)');
    await db.execute('CREATE INDEX idx_wallets_is_archived ON wallets(is_archived)');
    await db.execute('CREATE INDEX idx_wallets_type ON wallets(type)');
    await db.execute('CREATE INDEX idx_wallets_created_at ON wallets(created_at)');

    // Índices para categorías
    await db.execute('CREATE INDEX idx_categories_user ON categories(user_id)');
    await db.execute('CREATE INDEX idx_categories_name ON categories(name)');
    await db.execute('CREATE INDEX idx_categories_type ON categories(type)');

    // Índices para stores
    await db.execute('CREATE INDEX idx_stores_user ON stores(user_id)');

    // Índices para transacciones
    await db.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');
    await db.execute('CREATE INDEX idx_transactions_store ON transactions(store_id)');

    // Índices para suscripciones
    await db.execute('CREATE INDEX idx_subscriptions_user ON subscriptions(user_id)');
    await db.execute('CREATE INDEX idx_subscriptions_wallet ON subscriptions(wallet_id)');
    await db.execute('CREATE INDEX idx_subscriptions_store ON subscriptions(store_id)');
  }

  // Métodos genéricos para operaciones CRUD
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Limpiar todos los datos (útil al cerrar sesión)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('wallets');
    await db.delete('transactions');
    await db.delete('categories', where: "id NOT IN ('default_category', 'subscriptions_category')");
    await db.delete('subscriptions');
    await db.delete('stores');
  }

  // Cerrar la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Eliminar la base de datos
  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "wallets.db");
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}