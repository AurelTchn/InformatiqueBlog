import 'package:flutter/material.dart';
import 'package:informatiqueblog/pages_simonne/historique.dart';
import 'package:informatiqueblog/pages_simonne/inscription.dart';

class connexion extends StatefulWidget {
   const connexion({super.key});

  @override
  State<connexion> createState() => _connexionState();
}

class _connexionState extends State<connexion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("connexion")
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
            padding:  EdgeInsets.all(20),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:  EdgeInsets.symmetric(vertical: 30, horizontal: 25),
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
                        "Bienvenue à nouveau !",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                       SizedBox(height: 5),
                       Text(
                        "Connectez-vous pour continuer",
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                       SizedBox(height: 30),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon:  Icon(Icons.mail),  
                          hintText: "Entrez votre email",
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
                       SizedBox(height: 20),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon:  Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          hintText: "Entrez votre mot de passe",
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
                       SizedBox(height: 20),

                      // Bouton Se connecter
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                  content: Text("Connexion réussie !"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pushReplacement(
                                  context, 
                                MaterialPageRoute(builder: (context) => const historique()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding:  EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:  Text(
                            "Se connecter",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),

                      // Diviseur avec "ou continuer avec"
                      Row(
                        children: [
                           Expanded(
                              child: Divider(thickness: 0.5, color: Colors.grey)),
                           Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("ou continuer avec"),
                          ),
                           Expanded(
                              child: Divider(thickness: 0.5, color: Colors.grey)),
                        ],
                      ),
                       SizedBox(height: 20),

                      // Options Google et Facebook
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SocialLoginButton(
                            imagePath: "assets/image/Google.png",
                            onTap: () {
                              // Action Google
                            },
                          ),
                           SizedBox(width: 20),
                          SocialLoginButton(
                            imagePath: "assets/image/Facebook.png",
                            onTap: () {
                              // Action Facebook
                            },
                          ),
                        ],
                      ),
                       SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                              context, 
                            MaterialPageRoute(builder: (context) =>  inscription()),(route)   =>false,
                          );
 
                        },
                        child:  Text("Pas encore de compte ? Inscrivez-vous"),
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

class SocialLoginButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

   SocialLoginButton({
    Key? key,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:  EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black38),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: Image.asset(imagePath, height: 30),
      ),
    );
  }
}
