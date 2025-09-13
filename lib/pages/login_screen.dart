import 'package:chatterbox/api_request.dart';
import 'package:chatterbox/pages/user_screen.dart';
import 'package:chatterbox/utils.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _loading = false;

  void _login(String username, String password, BuildContext context) async {
    setState(() {
      _loading = true;
    });
    String status = await login(username, password);
    showSnackBar(context, status, Colors.grey);
    setState(() {
      _loading = false;
    });
    if (status == "Connexion réussie") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => UserScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Connexion"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 32),
                  Form(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: "Nom d'utilisateur",
                            hintText: "Entrez votre nom d'utilisateur",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Mot de passe",
                            hintText: "Entrez votre mot de passe",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: !_loading
                              ? FilledButton(
                                  onPressed: () {
                                    String username = usernameController.text;
                                    String password = passwordController.text;

                                    if (username.isNotEmpty &&
                                        password.isNotEmpty) {
                                      _login(username, password, context);
                                    } else {
                                      showSnackBar(
                                        context,
                                        "Veuillez remplir tout les champs",
                                        Colors.red,
                                      );
                                    }
                                  },
                                  child: const Text("Se connecter"),
                                )
                              : Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blueGrey,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Pas encore de compte ? Inscrivez-vous.",
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
