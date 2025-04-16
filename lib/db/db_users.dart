import 'dart:convert';
import 'dart:io';

class MockDB {
  static final MockDB _instance = MockDB._internal();
  factory MockDB() => _instance;
  MockDB._internal() {
    _loadUsers();
    _loadPlates();
  }

  final Map<String, String> _users = {};
  final Map<String, List<String>> _plates = {};

  final String usersPath = 'assets/data/db_users.csv';
  final String platesPath = 'assets/data/db_plates.csv';

  Future<void> _loadUsers() async {
    final file = File(usersPath);
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    for (var line in lines.skip(1)) {
      final parts = line.split(',');
      if (parts.length >= 2) {
        _users[parts[0]] = parts[1];
        _plates[parts[0]] = [];
      }
    }
  }

  Future<void> _loadPlates() async {
    final file = File(platesPath);
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    for (var line in lines.skip(1)) {
      final parts = line.split(',');
      if (parts.length >= 2) {
        _plates[parts[0]]?.add(parts[1].toUpperCase());
      }
    }
  }

  Future<void> _saveUserToFile(String email, String password) async {
    final file = File(usersPath);
    final exists = await file.exists();
    if (!exists) {
      await file.writeAsString('email,password\n', mode: FileMode.write);
    }
    await file.writeAsString('$email,$password\n', mode: FileMode.append);
  }

  Future<void> _savePlateToFile(String email, String plate) async {
    final file = File(platesPath);
    final exists = await file.exists();
    if (!exists) {
      await file.writeAsString('email,plate\n', mode: FileMode.write);
    }
    await file.writeAsString('$email,${plate.toUpperCase()}\n', mode: FileMode.append);
  }
  
  bool registerUser(String email, String password) {
    if (_users.containsKey(email)) return false;
    _users[email] = password;
    _plates[email] = [];
    _saveUserToFile(email, password);
    return true;
  }

  bool loginUser(String email, String password) {
    return _users[email] == password;
  }

  bool userExists(String email) {
    return _users.containsKey(email);
  }

  List<String> getUserPlates(String email) {
    return _plates[email] ?? [];
  }

  void addPlate(String email, String plate) {
    _plates[email]?.add(plate.toUpperCase());
    _savePlateToFile(email, plate);
  }

  void removePlate(String email, String plate) {
    _plates[email]?.remove(plate.toUpperCase());
    _rewritePlatesFile();
  }

  Future<void> _rewritePlatesFile() async {
    final file = File(platesPath);
    final buffer = StringBuffer('email,plate\n');
    _plates.forEach((email, plateList) {
      for (var plate in plateList) {
        buffer.writeln('$email,$plate');
      }
    });
    await file.writeAsString(buffer.toString());
  }
}
