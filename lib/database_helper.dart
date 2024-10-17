// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Folders table
    await db.execute('''
      CREATE TABLE Folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Cards table
    await db.execute('''
      CREATE TABLE Cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES Folders (id)
      )
    ''');

    // Insert default folders
    final batch = db.batch();
    batch.insert('Folders', {'name': 'Hearts'});
    batch.insert('Folders', {'name': 'Spades'});
    batch.insert('Folders', {'name': 'Diamonds'});
    batch.insert('Folders', {'name': 'Clubs'});
    await batch.commit();

    // Insert sample cards for each suit
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    for (var suit in suits) {
      for (var value in values) {
        await db.insert('Cards', {
          'name': '$value of $suit',
          'suit': suit,
          'image_url': 'assets/cards/${suit.toLowerCase()}_$value.png',
          'folder_id': null
        });
      }
    }
  }

  // Folder operations
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('Folders');
  }

  Future<int> getCardCount(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM Cards WHERE folder_id = ?',
        [folderId]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>?> getFirstCardInFolder(int folderId) async {
    final db = await database;
    final cards = await db.query(
        'Cards',
        where: 'folder_id = ?',
        whereArgs: [folderId],
        limit: 1
    );
    return cards.isNotEmpty ? cards.first : null;
  }

  // Card operations - Adding the missing methods
  Future<List<Map<String, dynamic>>> getCardsInFolder(int folderId) async {
    final db = await database;
    return await db.query(
      'Cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnassignedCards(String suit) async {
    final db = await database;
    return await db.query(
      'Cards',
      where: 'folder_id IS NULL AND suit = ?',
      whereArgs: [suit],
    );
  }

  Future<bool> canAddCardToFolder(int folderId) async {
    final count = await getCardCount(folderId);
    return count < 6;
  }

  Future<void> assignCardToFolder(int cardId, int folderId) async {
    final db = await database;

    // Check if the folder has less than 6 cards
    if (!await canAddCardToFolder(folderId)) {
      throw Exception('Folder is full (maximum 6 cards)');
    }

    await db.update(
      'Cards',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<void> removeCardFromFolder(int cardId) async {
    final db = await database;
    await db.update(
      'Cards',
      {'folder_id': null},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  // Helper method to check if a folder has minimum required cards
  Future<bool> hasMinimumCards(int folderId) async {
    final count = await getCardCount(folderId);
    return count >= 3;
  }

  // Method to get folder details including card count
  Future<Map<String, dynamic>> getFolderDetails(int folderId) async {
    final db = await database;
    final folders = await db.query(
      'Folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );

    if (folders.isEmpty) {
      throw Exception('Folder not found');
    }

    final folder = folders.first;
    final cardCount = await getCardCount(folderId);

    return {
      ...folder,
      'cardCount': cardCount,
    };
  }

  // Method to get all cards in a suit (both assigned and unassigned)
  Future<List<Map<String, dynamic>>> getAllCardsInSuit(String suit) async {
    final db = await database;
    return await db.query(
      'Cards',
      where: 'suit = ?',
      whereArgs: [suit],
    );
  }
}