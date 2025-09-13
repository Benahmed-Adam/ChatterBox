import 'dart:async';

import 'package:chatterbox/pages/group_page.dart';
import 'package:chatterbox/pages/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatterbox/api_request.dart';
import 'package:chatterbox/entities/user.dart';
import 'package:chatterbox/pages/home_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  User? _user;
  bool _loadingUser = true;
  List<Widget> _groupWidgets = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) => _refresh(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      setState(() {
        _loadingUser = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = prefs.getString("user_token");

      if (userId == null || token == null) {
        throw Exception("Identifiants manquants.");
      }

      final user = await getUserInfo(userId, token);
      final groupWidgets = await _buildGroupButtons(user.userId, user.token);

      setState(() {
        _user = user;
        _groupWidgets = groupWidgets;
        _loadingUser = false;
      });
    } catch (e) {
      debugPrint("Erreur lors de l'initialisation : $e");
      setState(() {
        _loadingUser = false;
      });
    }
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    if (userId == null || token == null) {
      return;
    }

    final user = await getUserInfo(userId, token);
    final groupWidgets = await _buildGroupButtons(user.userId, user.token);

    setState(() {
      _user = user;
      _groupWidgets = groupWidgets;
      _loadingUser = false;
    });
  }

  Future<List<Widget>> _buildGroupButtons(int userId, String token) async {
    final List<Widget> widgets = [];
    final List<Color> colors = [
      Colors.blue.shade400,
      Colors.blue.shade200,
      Colors.green.shade400,
      Colors.green.shade200,
      Colors.yellow.shade400,
      Colors.yellow.shade200,
      Colors.orange.shade400,
      Colors.orange.shade200,
      Colors.red.shade400,
      Colors.red.shade200,
    ];
    int i = 0;
    final groups = await getUserGroups(userId, token);

    for (final group in groups) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupPage(
                    groupId: group.groupId,
                    groupName: group.name,
                    refreshFunction: _initializeScreen,
                  ),
                ),
              );
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  group.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      );
      i += 1;
    }

    return widgets;
  }

  Future<void> _disconnect(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_id");
    await prefs.remove("user_token");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ChatterBoxHomePage()),
      (route) => false,
    );
  }

  Future<void> _createGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    if (userId == null || token == null) {
      throw Exception("Identifiants manquants.");
    }

    createBasicGroupChat(userId, token);
    _initializeScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Chargement des données..."),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                strokeWidth: 4,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenue ${_user?.username ?? ''}"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text("Connecté sur $baseUrl"),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        user:
                            _user ??
                            User(
                              userId: -1,
                              username: "Inexistant",
                              token: "none",
                            ),
                        disconnect: _disconnect,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text("Profil"),
              ),
              OutlinedButton.icon(
                onPressed: () => _disconnect(context),
                icon: const Icon(Icons.exit_to_app_outlined),
                label: const Text("Déconnexion"),
              ),
              const Spacer(flex: 10),
            ],
          ),
        ),
      ),
      body: _groupWidgets.isEmpty
          ? const Center(child: Text("Aucun groupe disponible."))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text("Groupes :"),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _groupWidgets.length,
                      itemBuilder: (context, index) {
                        return _groupWidgets[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _createGroup(),
        child: const Icon(Icons.add_box_outlined),
      ),
    );
  }
}
