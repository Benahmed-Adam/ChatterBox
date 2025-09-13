import 'package:shared_preferences/shared_preferences.dart';

class User {
  final int userId;
  final String username;
  final String token;

  User({required this.userId, required this.username, required this.token});

  factory User.fromJson(Map<String, dynamic> data) {
    int userId = (data["userId"] as num).toInt();
    String username = data["username"] as String;
    String token = data["token"] as String;

    return User(userId: userId, username: username, token: token);
  }

  static Future<void> persist(Map<String, dynamic> data) async {
    String token = data["token"] as String;
    int id = (data["id"] as num).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_token", token);
    await prefs.setInt("user_id", id);
  }
}
