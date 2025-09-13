import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatterbox/api_request.dart';
import 'package:chatterbox/pages/home_screen.dart';
import 'package:chatterbox/pages/user_screen.dart';

void main() {
  runApp(const ChatterBoxApp());
}

class ChatterBoxApp extends StatefulWidget {
  const ChatterBoxApp({super.key});

  @override
  State<ChatterBoxApp> createState() => _ChatterBoxAppState();
}

class _ChatterBoxAppState extends State<ChatterBoxApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    initBaseUrl();
    _checkIfUserLoggedIn();
  }

  void _showSnackBar(String message, Color color) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _checkIfUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasVariables =
        prefs.containsKey("user_id") && prefs.containsKey("user_token");

    bool isLoggedIn;

    if (hasVariables) {
      final userId = prefs.getInt("user_id");
      final token = prefs.getString("user_token");

      if (userId == null || token == null) {
        throw Exception("Identifiants manquants.");
      }

      final a = await getUserInfo(userId, token);

      if (a.userId == -1) {
        isLoggedIn = false;
        _showSnackBar("Vous avez été déconnecté", Colors.red);
        prefs.remove("user_id");
        prefs.remove("user_token");
      } else {
        isLoggedIn = true;
      }
    } else {
      isLoggedIn = false;
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatterBox',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: _isLoggedIn ? const UserScreen() : const ChatterBoxHomePage(),
    );
  }
}
