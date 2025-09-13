import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatterbox/api_request.dart';
import 'dart:async';

class HomeScreenSettings extends StatefulWidget {
  const HomeScreenSettings({super.key});

  @override
  State<HomeScreenSettings> createState() => _HomeScreenSettingsState();
}

class _HomeScreenSettingsState extends State<HomeScreenSettings> {
  List<String> _servers = [];
  String _currentServer = "Aucun serveur sélectionné";
  Map<String, bool> _serverValidity = {};
  bool _isLoadingValidity = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final servers = prefs.getStringList("servers_address") ?? [];
    final current =
        prefs.getString("current_server") ?? "Aucun serveur sélectionné";

    setState(() {
      _servers = servers;
      _currentServer = current;
      _isLoadingValidity = true;
    });

    final Map<String, bool> validity = {};

    for (final server in servers) {
      final isValid = await isValidServer(
        server,
      ).timeout(const Duration(seconds: 2), onTimeout: () => false);
      validity[server] = isValid;
    }

    if (!mounted) return;

    setState(() {
      _serverValidity = validity;
      _isLoadingValidity = false;
      if (_serverValidity[_currentServer] == false) {
        _currentServer = "Aucun serveur sélectionné";
      }
    });
  }

  Future<void> _setCurrentServer(String server) async {
    if (_serverValidity[server] == false) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("current_server", server);
    initBaseUrl();
    if (!mounted) return;
    setState(() {
      _currentServer = server;
    });
  }

  Future<void> _deleteServer(String server) async {
    final prefs = await SharedPreferences.getInstance();
    final isCurrent = (_currentServer == server);

    setState(() {
      _servers.remove(server);
      _serverValidity.remove(server);
      if (isCurrent) {
        _currentServer = "Aucun serveur sélectionné";
      }
    });

    await prefs.setStringList("servers_address", _servers);
    if (isCurrent) {
      await prefs.remove("current_server");
    }
  }

  void _showAddServerDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un serveur"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Adresse du serveur",
            hintText: "https://mon.serveur.com",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();

              if (url.isEmpty || _servers.contains(url)) {
                if (mounted) Navigator.of(context).pop();
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text("Vérification du serveur..."),
                    ],
                  ),
                ),
              );

              bool valid = false;
              try {
                valid = await isValidServer(
                  url,
                ).timeout(const Duration(seconds: 5));
              } catch (_) {
                valid = false;
              }

              if (!mounted) return;

              Navigator.of(context).pop();

              if (!valid) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Erreur"),
                    content: const Text(
                      "Le serveur est invalide ou inaccessible ou n'est pas en https.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final updatedServers = [..._servers, url];
              await prefs.setStringList("servers_address", updatedServers);

              setState(() {
                _servers = updatedServers;
                _serverValidity[url] = valid;
              });

              if (mounted) Navigator.of(context).pop();
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  void _reset() async {
    final prefs = await SharedPreferences.getInstance();

    final uniqueServers = {..._servers, originUrl}.toList();

    await prefs.setString("current_server", originUrl);
    await prefs.setStringList("servers_address", uniqueServers);

    setState(() {
      _currentServer = originUrl;
      _servers = uniqueServers;
      _serverValidity[originUrl] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choix du serveur"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingValidity ? null : _loadServers,
            tooltip: "Rafraîchir les serveurs",
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingValidity) const LinearProgressIndicator(minHeight: 3),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Serveur actuel : $_currentServer",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton(onPressed: _reset, child: const Text("Reset")),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _servers.length,
              itemBuilder: (context, index) {
                final server = _servers[index];
                final isValid = _serverValidity[server] ?? false;
                final isSelected = server == _currentServer;

                return ListTile(
                  title: Text(
                    server,
                    style: TextStyle(
                      color: isValid ? null : Colors.red,
                      fontStyle: isValid ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteServer(server),
                  ),
                  trailing: isValid
                      ? (isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.cloud_done, color: Colors.grey))
                      : const Icon(Icons.warning, color: Colors.red),
                  onTap: isValid ? () => _setCurrentServer(server) : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
