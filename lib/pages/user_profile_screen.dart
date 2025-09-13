import 'package:chatterbox/api_request.dart';
import 'package:chatterbox/utils.dart';
import 'package:flutter/material.dart';
import 'package:chatterbox/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    super.key,
    required this.user,
    required this.disconnect,
  });

  final User user;
  final Function disconnect;

  void _resetToken(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Réinitialiser le token"),
        content: const Text(
          "Cette opération vous déconnectera de toutes les autres sessions actives.\n\nSouhaitez-vous continuer ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getInt("user_id");
              final token = prefs.getString("user_token");

              if (userId == null || token == null) {
                showSnackBar(context, "Identifiants manquants.", Colors.red);
                return;
              }

              final msg = await resetToken(userId, token);
              showSnackBar(context, msg, Colors.orange);
              disconnect(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Continuer"),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer de mot de passe"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nouveau mot de passe",
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = controller.text.trim();
              if (newPassword.isEmpty) {
                showSnackBar(context, "Mot de passe invalide.", Colors.red);
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getInt("user_id");
              final token = prefs.getString("user_token");

              if (userId == null || token == null) {
                showSnackBar(context, "Identifiants manquants.", Colors.red);
                return;
              }

              final msg = await changePassword(userId, token, newPassword);
              Navigator.of(context).pop();
              showSnackBar(context, msg, Colors.green);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Suppression définitive"),
        content: const Text(
          "Cette action est irréversible. Êtes-vous sûr de vouloir supprimer votre compte ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getInt("user_id");
              final token = prefs.getString("user_token");

              if (userId == null || token == null) {
                Navigator.of(context).pop();
                showSnackBar(context, "Identifiants manquants.", Colors.red);
                return;
              }

              final code = await deleteAccount(userId, token);
              Navigator.of(context).pop();
              if (code == 200) {
                showSnackBar(
                  context,
                  "Compte supprimé avec succès",
                  Colors.green,
                );
              } else {
                showSnackBar(context, "Une erreur est survenue", Colors.red);
              }

              disconnect(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil de ${user.username}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _changePassword(context),
              label: const Text("Changer de mot de passe"),
              icon: const Icon(Icons.lock),
            ),
            OutlinedButton.icon(
              onPressed: () => _resetToken(context),
              label: const Text("Reset le token"),
              icon: const Icon(Icons.vpn_key),
            ),
            OutlinedButton.icon(
              onPressed: () => _deleteAccount(context),
              label: const Text("Supprimer le compte"),
              icon: const Icon(Icons.delete_forever),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
