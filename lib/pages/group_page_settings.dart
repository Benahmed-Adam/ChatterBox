import 'package:chatterbox/api_request.dart';
import 'package:chatterbox/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatterbox/entities/user.dart';

class GroupPageSettings extends StatefulWidget {
  const GroupPageSettings({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.reloadFunction,
    required this.changeGroupNameFunction,
    required this.addUserFunction,
  });

  final int groupId;
  final String groupName;
  final Function reloadFunction;
  final Function(String newName) changeGroupNameFunction;
  final Function addUserFunction;

  @override
  State<GroupPageSettings> createState() => _GroupPageSettingsState();
}

class _GroupPageSettingsState extends State<GroupPageSettings> {
  late Future<List<User>> _groupMembersFuture;
  late String _currentGroupName;

  @override
  void initState() {
    super.initState();
    _groupMembersFuture = getGroupMembers(widget.groupId);
    _currentGroupName = widget.groupName;
  }

  void _leaveGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    if (userId == null || token == null) {
      throw Exception("Identifiants manquants.");
    }

    leaveGroupChat(userId, token, widget.groupId);
    showSnackBar(context, "Groupe quitté avec succès", Colors.grey);
  }

  void _showAddUserDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    if (currentUserId == null || token == null) return;

    TextEditingController searchController = TextEditingController();
    List<User> matchingUsers = [];
    bool isLoading = false;

    void _fetchUsers(
      String query,
      void Function(void Function()) setStateDialog,
    ) async {
      setStateDialog(() => isLoading = true);
      final users = await getUserByStartingName(query);
      setStateDialog(() {
        matchingUsers = users.where((u) => u.userId != currentUserId).toList();
        isLoading = false;
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Ajouter un utilisateur"),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: "Rechercher un utilisateur",
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _fetchUsers(value, setStateDialog);
                        } else {
                          setStateDialog(() => matchingUsers = []);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (matchingUsers.isEmpty)
                      const Text("Aucun utilisateur")
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: matchingUsers.length,
                          itemBuilder: (context, index) {
                            final user = matchingUsers[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              tileColor: Colors.grey.shade200,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey,
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Colors.blueAccent,
                              ),
                              onTap: () async {
                                await widget.addUserFunction(user.userId);
                                if (mounted) {
                                  setState(() {
                                    _groupMembersFuture = getGroupMembers(
                                      widget.groupId,
                                    );
                                  });
                                }
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Fermer"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangeGroupNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _currentGroupName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le nom du groupe"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Nouveau nom du groupe",
            hintText: "Entrez un nouveau nom",
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
              final newName = nameController.text.trim();
              if (newName.length < 3 || newName.length > 20) {
                showSnackBar(
                  context,
                  "Le nom doit être entre 3 et 20",
                  Colors.red,
                );
                return;
              }
              await widget.changeGroupNameFunction(newName);
              setState(() => _currentGroupName = newName);
              widget.reloadFunction();
              Navigator.of(context).pop();
              showSnackBar(
                context,
                "Nom du groupe changé avec succès",
                Colors.green,
              );
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paramètre de $_currentGroupName")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                _leaveGroup();
                Navigator.pop(context);
                Navigator.pop(context);
                widget.reloadFunction();
              },
              icon: const Icon(Icons.logout),
              label: const Text("Quitter le groupe"),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.person_add),
              label: const Text("Ajouter un utilisateur"),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showChangeGroupNameDialog,
              icon: const Icon(Icons.edit),
              label: const Text("Changer le nom du groupe"),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Liste des membres",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<User>>(
                future: _groupMembersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text("Erreur lors du chargement."),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Aucun membre dans ce groupe."),
                    );
                  }

                  return ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = snapshot.data![index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        tileColor: Colors.grey.shade200,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Text(
                            member.username[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          member.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
