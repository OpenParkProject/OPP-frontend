import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<Database> openDB() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'my_database.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          age INTEGER
        )
      ''');
    },
  );
}

Future<void> main() async {
  final db = await openDB();

  await insertUser(db, 'Alice', 25);
  await insertUser(db, 'Bob', 30);

  final users = await getUsers(db);
  print(users);

  await updateUser(db, 1, 'Charlie', 35);
  await deleteUser(db, 2);

  final updatedUsers = await getUsers(db);
  print(updatedUsers);

  await db.close();
}

Future<void> insertUser(Database db, String name, int age) async {
  await db.insert('users', {'name': name, 'age': age});
}

Future<List<Map<String, dynamic>>> getUsers(Database db) async {
  return await db.query('users');
}

Future<void> updateUser(Database db, int id, String newName, int newAge) async {
  await db.update(
    'users',
    {'name': newName, 'age': newAge},
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deleteUser(Database db, int id) async {
  await db.delete(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );
}
