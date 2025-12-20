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
      version: 3, // Incrementado para migración v3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // Run data fix for any bad IDs (legacy text vs UUID)
    await _fixInvalidCategoryIds(db);
    
    return db;
  }
  
  Future<void> _fixInvalidCategoryIds(Database db) async {
    try {
      // 1. Find categories with invalid IDs (starting with 'category_')
      final List<Map<String, dynamic>> badCategories = await db.query(
        'categories',
        where: "id LIKE 'category_%'",
      );

      if (badCategories.isEmpty) return;
      
      print('Migrating ${badCategories.length} categories with invalid IDs...');

      for (final cat in badCategories) {
        final oldId = cat['id'] as String;
        final newId = const Uuid().v4();
        
        // 2. Clear pending operations for this bad ID to avoid sync errors
        // We delete them because they contain the bad ID in the payload
        await db.delete(
          'pending_operations',
          where: "record_id = ?",
          whereArgs: [oldId],
        );

        // 3. Update the Category with new UUID
        // We ensure it's marked as NOT synced so it tries to push to Supabase again (with new ID)
        await db.update(
          'categories',
          {'id': newId, 'is_synced': 0}, 
          where: 'id = ?',
          whereArgs: [oldId],
        );

        // 4. Update any Transactions referencing this old Category ID
        await db.update(
          'transactions',
          {'category_id': newId}, // Transactions remain unsynced/synced status, but ID is fixed
          where: 'category_id = ?',
          whereArgs: [oldId],
        );
        
        // Also clear pending operations for transactions referencing this bad ID
        // This is drastic but necessary as the payloads in pending_ops have the old FK
        final pendingTxns = await db.query(
            'pending_operations', 
            where: "table_name = 'transactions' AND data LIKE ?", 
            whereArgs: ['%$oldId%']
        );
        
        for (final op in pendingTxns) {
           await db.delete('pending_operations', where: 'id = ?', whereArgs: [op['id']]);
           // Note: The transaction record itself in 'transactions' table was updated above.
           // Next time sync runs, it might not pick it up if we don't mark it unsynced?
           // Ideally we should mark affected transactions as is_synced=0
           await db.update(
             'transactions',
             {'is_synced': 0},
             where: 'category_id = ?',
             whereArgs: [newId]
           );
        }
      }
      print('Migration of invalid IDs completed.');
    } catch (e) {
      print('Error during ID migration: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración de versión 1 a 2: agregar nuevas columnas para sincronización
      await db.execute('ALTER TABLE wallets ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE wallets ADD COLUMN version INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE wallets ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      
      // Actualizar wallets existentes con valores por defecto
      await db.execute('''
        UPDATE wallets 
        SET updated_at = created_at, 
            version = 1, 
            is_synced = 0 
        WHERE updated_at IS NULL
      ''');

      // Crear tabla de operaciones pendientes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_operations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation_type TEXT NOT NULL,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Actualizar categorías
      await db.execute('ALTER TABLE categories ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE categories ADD COLUMN version INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE categories ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      
      await db.execute('''
        UPDATE categories 
        SET updated_at = datetime('now'), 
            version = 1, 
            is_synced = 0 
        WHERE updated_at IS NULL
      ''');

      // Actualizar transacciones
      await db.execute('ALTER TABLE transactions ADD COLUMN updated_at TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN version INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE transactions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      
      await db.execute('''
        UPDATE transactions 
        SET updated_at = created_at, 
            version = 1, 
            is_synced = 0 
        WHERE updated_at IS NULL
      ''');

      // Migrar IDs de INTEGER a TEXT (UUID)
      // Nota: Esta migración es compleja, por ahora mantenemos INTEGER localmente
      // pero el repository generará UUIDs para Supabase
    }

    if (oldVersion < 3) {
      // Migración v3: Agregar user_id a transacciones para RLS
      print('Iniciando migración v3: user_id en transacciones');
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT');
        
        // Backfill user_id desde wallets
        await db.execute('''
          UPDATE transactions 
          SET user_id = (SELECT user_id FROM wallets WHERE wallets.id = transactions.wallet_id)
        ''');
        
        // Crear índice para user_id
        await db.execute('CREATE INDEX idx_transactions_user ON transactions(user_id)');
        
        print('Migración v3 completada exitosamente');
      } catch (e) {
        print('Error en migración v3: $e');
      }
    }
  }

  Future<void> _createTables(Database db) async {
    // Tabla de wallets actualizada
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
        version INTEGER NOT NULL DEFAULT 1,
        icon_bank TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de categorías actualizada
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
        version INTEGER NOT NULL DEFAULT 1,
        is_synced INTEGER NOT NULL DEFAULT 0,
        UNIQUE(user_id, name)
      )
    ''');

    // Tabla de transacciones actualizada
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Tabla de operaciones pendientes para sincronización
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insertar categoría por defecto
    await db.insert('categories', {
      'id': 'default_category',
      'name': 'Sin categoría',
      'monthly_budget': 0.0,
      'user_id': 'system',
      'type': 'expense',
      'color': '#9E9E9E',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'version': 1,
      'is_synced': 1,
    });
  }

  Future<void> _createIndexes(Database db) async {
    // Índices para wallets
    await db.execute('CREATE INDEX idx_wallets_user ON wallets(user_id)');
    await db.execute('CREATE INDEX idx_wallets_is_favorite ON wallets(is_favorite)');
    await db.execute('CREATE INDEX idx_wallets_is_archived ON wallets(is_archived)');
    await db.execute('CREATE INDEX idx_wallets_type ON wallets(type)');
    await db.execute('CREATE INDEX idx_wallets_created_at ON wallets(created_at)');
    await db.execute('CREATE INDEX idx_wallets_is_synced ON wallets(is_synced)');

    // Índices para categorías
    await db.execute('CREATE INDEX idx_categories_user ON categories(user_id)');
    await db.execute('CREATE INDEX idx_categories_name ON categories(name)');
    await db.execute('CREATE INDEX idx_categories_type ON categories(type)');
    await db.execute('CREATE INDEX idx_categories_is_synced ON categories(is_synced)');

    // Índices para transacciones
    await db.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');
    await db.execute('CREATE INDEX idx_transactions_is_synced ON transactions(is_synced)');

    // Índice para operaciones pendientes
    await db.execute('CREATE INDEX idx_pending_operations_table ON pending_operations(table_name)');
    await db.execute('CREATE INDEX idx_pending_operations_created ON pending_operations(created_at)');
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

  // Métodos para operaciones pendientes
  Future<void> addPendingOperation({
    required String operationType,
    required String tableName,
    required String recordId,
    required String data,
  }) async {
    final db = await database;
    await db.insert('pending_operations', {
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query('pending_operations', orderBy: 'created_at ASC');
  }

  Future<void> removePendingOperation(int id) async {
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_operations SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Obtener registros no sincronizados
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await database;
    return await db.query(table, where: 'is_synced = 0');
  }

  // Limpiar todos los datos (útil al cerrar sesión)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('wallets');
    await db.delete('transactions');
    await db.delete('categories', where: "id != 'default_category'");
    await db.delete('pending_operations');
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