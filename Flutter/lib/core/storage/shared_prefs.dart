import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _prefs;
  
  // Initialize shared preferences
  static Future<SharedPrefs> init() async {
    _prefs = await SharedPreferences.getInstance();
    return SharedPrefs();
  }

  // Get string value
  Future<String?> getString(String key) async {
    return _prefs?.getString(key);
  }

  // Set string value
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  // Get bool value
  Future<bool?> getBool(String key) async {
    return _prefs?.getBool(key);
  }

  // Set bool value
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  // Get int value
  Future<int?> getInt(String key) async {
    return _prefs?.getInt(key);
  }

  // Set int value
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  // Get double value
  Future<double?> getDouble(String key) async {
    return _prefs?.getDouble(key);
  }

  // Set double value
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  // Get string list
  Future<List<String>?> getStringList(String key) async {
    return _prefs?.getStringList(key);
  }

  // Set string list
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    return _prefs?.containsKey(key) ?? false;
  }

  // Remove value
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // Clear all values
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
}