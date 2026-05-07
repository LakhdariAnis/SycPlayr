import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print('DbHelper: Running openDatabase...');
    return await openDatabase(
      path,
      version: 2, // Bumped version to 2 to trigger onUpgrade
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    print('DbHelper: _createDB called. Executing CREATE TABLE...');
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      )
    ''');
    print('DbHelper: CREATE TABLE logic executed.');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print(
      'DbHelper: _upgradeDB called, from version \$oldVersion to \$newVersion. Dropping old table...',
    );
    await db.execute('DROP TABLE IF EXISTS favorites');
    await _createDB(db, newVersion);
  }

  // --- CRUD OPERATIONS ---

  Future<int> addFavoriteTitle(String title) async {
    final db = await instance.database;
    print('DbHelper: Attempting to insert "\\\$title" into SQLite');
    final id = await db.insert('favorites', {'title': title});
    print('DbHelper: Insert successful, returned ID: \\\$id');
    return id;
  }

  Future<List<String>> fetchFavoriteTitles() async {
    final db = await instance.database;
    print('DbHelper: Fetching all titles from SQLite');
    final result = await db.query('favorites', columns: ['title']);
    print('DbHelper: Fetched \\\$result.length rows.');
    return result.map((json) => json['title'] as String).toList();
  }

  Future<int> deleteFavoriteByTitle(String title) async {
    final db = await instance.database;
    print('DbHelper: Attempting to delete "\\\$title" from SQLite');
    final count = await db.delete(
      'favorites',
      where: 'title = ?',
      whereArgs: [title],
    );
    print('DbHelper: Delete successful, rows affected: \\\$count');
    return count;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
