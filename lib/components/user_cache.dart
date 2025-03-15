import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _loggedInKey = "isLoggedIn";

  // Save login state
  static Future<void> saveLoginState(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  // Logout function
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
  }
}
