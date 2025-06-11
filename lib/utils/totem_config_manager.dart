// lib/utils/totem_config_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class TotemConfigManager {
  static const _zoneIdKey = 'zone_id';
  static const _zoneNameKey = 'zone_name';
  static const _latKey = 'latitude';
  static const _lonKey = 'longitude';
  static const _rfidKey = 'rfid_enabled';

  static Future<void> save({
    required int zoneId,
    required String zoneName,
    required double latitude,
    required double longitude,
    required bool rfidEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_zoneIdKey, zoneId);
    await prefs.setString(_zoneNameKey, zoneName);
    await prefs.setDouble(_latKey, latitude);
    await prefs.setDouble(_lonKey, longitude);
    await prefs.setBool(_rfidKey, rfidEnabled);
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'zone_id': prefs.getInt(_zoneIdKey),
      'zone_name': prefs.getString(_zoneNameKey),
      'latitude': prefs.getDouble(_latKey),
      'longitude': prefs.getDouble(_lonKey),
      'rfid_enabled': prefs.getBool(_rfidKey) ?? false,
    };
  }

  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_zoneIdKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_zoneIdKey);
    await prefs.remove(_zoneNameKey);
    await prefs.remove(_latKey);
    await prefs.remove(_lonKey);
    await prefs.remove(_rfidKey);
  }
}
