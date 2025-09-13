import 'package:chatterbox/api_request.dart';
import 'package:flutter/material.dart';
import 'package:chatterbox/utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  var _loading = false;

  void _signUp(String username, String password, BuildContext context) async {
    setState(() {
      _loading = true;
    });
    String status = await register(username, password);
    showSnackBar(context, status, Colors.grey);
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Inscription"), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
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
                                      _signUp(username, password, context);
                                    } else {
                                      showSnackBar(
                                        context,
                                        "Veuillez remplir tous les champs",
                                        Colors.red,
                                      );
                                    }
                                  },
                                  child: const Text("S'inscrire"),
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
                            "Déjà un compte ? Connectez-vous.",
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
