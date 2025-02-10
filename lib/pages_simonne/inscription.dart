import 'package:flutter/material.dart';
import 'package:informatiqueblog/pages_simonne/connexion.dart';
import 'package:informatiqueblog/pages_simonne/homePage.dart';

class inscription extends StatefulWidget {
  const inscription({super.key});

  @override
  State<inscription> createState() => _inscriptionState();
}

class _inscriptionState extends State<inscription> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("inscription")
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage("assets/image/Person.png"),
                      ),
                      SizedBox(height: 20),
                      // Titre
                      Text(
                        "Inscription",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Rejoignez-nous dès maintenant",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Nom
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.account_circle),
                          hintText: "Votre nom",
                          labelText: "Nom",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Veuillez entrer votre nom";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),

                      // Prénom
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.account_circle),
                          hintText: "Votre prénom",
                          labelText: "Prénom",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Veuillez entrer votre prénom";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),

                      // Email
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.mail),
                          hintText: "Votre adresse email",
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "Veuillez entrer une adresse email valide";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          hintText: "Créer un mot de passe",
                          labelText: "Mot de passe",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return "Le mot de passe doit contenir au moins 6 caractères";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),

                      // Confirmation mot de passe
                      TextFormField(
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: "Confirmer votre mot de passe",
                          labelText: "Confirmation",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return "Les mots de passe ne correspondent pas";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Bouton S'inscrire
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Action après validation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Inscription réussie !"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const homePage()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "S'inscrire",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      // Lien vers Connexion
                      SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) =>  connexion()),(route)   =>false,
                          );

                        },
                        child: Text("Déjà un compte ? Connectez-vous"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
