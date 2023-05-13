import 'package:shared_preferences/shared_preferences.dart';

class KeySingleton {
  Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString("APIKey") ?? "";
    return value;
  }

  void save(value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("APIKey", value);
  }

}
