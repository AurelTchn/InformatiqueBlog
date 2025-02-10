import 'dart:io';

import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:informatiqueblog/pages_majoie/home_screen.dart';
import 'package:informatiqueblog/src/bouncing_ball/bouncing_ball.dart';
import 'package:informatiqueblog/src/horizontal_rotating_dots/horizontal_rotating_dots.dart';
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'package:informatiqueblog/src/two_rotating_arc/two_rotating_arc.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../pages_aurel/theme_provider.dart';
//import 'package:awesome_dialog/awesome_dialog.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  final _formeKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool is_Loading = false;
  bool _isPasswordVisible = false;

  Future<void> _registerUse() async {
    if (_formeKey.currentState!.validate()) {
      setState(() {
        is_Loading = true;
      });

      if (!isLogin) {
        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim());

          // Récupérer le `uid` de l'utilisateur
          String uid = userCredential.user!.uid;

          // Ajouter les données de l'utilisateur dans Firestore
          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(uid)
              .set({
            'uid': uid,
            'email': _emailController.text.trim(),
            'fullname':
                _fullnameController.text.trim(),
            'role': "user",
            'bio': "Votre biographie...",
            'location': "Votre location...",
            'createdAt': FieldValue.serverTimestamp(),
          });

          //Ajout de la sous collection

          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(uid)
              .collection('favorite_articles')
              .add({
            'createdAt': FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(uid)
              .collection('liked_articles')
              .add({
            'createdAt': FieldValue.serverTimestamp(),
          });

          ElegantNotification.success(
            title: Text(
              "Succès",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 27, 170, 31),
                fontSize: 16,
              ),
            ),
            description: Text(
              "Inscription réussie",
              style: TextStyle(
                color: Color.fromARGB(255, 27, 170, 31),
                fontSize: 14,
              ),
            ),
            icon: Icon(
              Icons.check_circle,
              color: const Color.fromARGB(255, 27, 170, 31),
            ),
            //background: Color.fromARGB(255, 27, 170, 31),
            borderRadius: BorderRadius.circular(12.0),
            animationDuration: Duration(milliseconds: 300),
            toastDuration: Duration(seconds: 3),
            onDismiss: () {
              print('Message when the notification is dismissed');
            },
          ).show(context);

          setState(() {
            isLogin = !isLogin;
          });
          _fullnameController.clear();
          _emailController.clear();
          _passwordController.clear();
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'Erreur lors de l\'inscription';
          if (e.code == 'email-already-in-use') {
            errorMessage = 'Cet email est déjà utilisé.';
          } else if (e.code == 'weak-password') {
            errorMessage = 'Le mot de passe est trop faible.';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'L\'email est invalide.';
          }
          ElegantNotification.error(
            title: Text(
              "Erreur",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            description: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            icon: Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            //background: Colors.red,
            borderRadius: BorderRadius.circular(12.0),
            animationDuration: Duration(milliseconds: 300),
            toastDuration: Duration(seconds: 3),
            onDismiss: () {
              print('Message when the notification is dismissed');
            },
          ).show(context);
        } finally {
          setState(() {
            is_Loading = false;
          });
        }
      } else {
        try {
          // Connexion via Firebase Authentication
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          // Récupérer le `uid` de l'utilisateur
          String uid = userCredential.user!.uid;

          ElegantNotification.success(
            title: Text(
              "Succès",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 27, 170, 31),
                fontSize: 16,
              ),
            ),
            description: Text(
              "Connexion réussie",
              style: TextStyle(
                color: Color.fromARGB(255, 27, 170, 31),
                fontSize: 14,
              ),
            ),
            icon: Icon(
              Icons.check_circle,
              color: Color.fromARGB(255, 27, 170, 31),
            ),
            //background: Color.fromARGB(255, 27, 170, 31),
            borderRadius: BorderRadius.circular(12.0),
            animationDuration: Duration(milliseconds: 300),
            toastDuration: Duration(seconds: 3),
            onDismiss: () {
              print('Message when the notification is dismissed');
            },
          ).show(context);

          _fullnameController.clear();
          _emailController.clear();
          _passwordController.clear();

          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 600),
              pageBuilder: (context, animation, secondaryAnimation) {
                return FadeTransition(
                  opacity: animation,
                  child: HomeScreen(
                    uid: uid,
                  ),
                );
              },
            ),
            (route) => false,
          );
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'Informations incorrectes';
          if (e.code == 'user-not-found') {
            errorMessage = 'Utilisateur introuvable.';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Mot de passe incorrect.';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Email invalide.';
          }
          print("L'erreur envoyée est ${e.code}");

          ElegantNotification.error(
            title: Text(
              "Erreur",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            description: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            icon: Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            //background: Colors.redAccent,
            borderRadius: BorderRadius.circular(12.0),
            animationDuration: Duration(milliseconds: 300),
            toastDuration: Duration(seconds: 3),
            onDismiss: () {
              print('Message when the notification is dismissed');
            },
          ).show(context);
        } finally {
          setState(() {
            is_Loading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      is_Loading = true;
    });

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    String uid;
    try {
      // Étape 1 : Authentification via Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Utilisateur a annulé l'inscription.");
        return null; 
      }

      // Étape 2 : Obtenir les credentials Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Étape 3 : S'inscrire ou se connecter avec Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Étape 4 : Récupérer l'utilisateur
      final User? user = userCredential.user;

      if (user != null) {
        // Vérifier si l'utilisateur existe déjà dans Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Récupérer le `uid` de l'utilisateur
          uid = userCredential.user!.uid;

          // Ajouter les données de l'utilisateur dans Firestore
          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(uid)
              .set({
            'uid': uid,
            'email': user.email,
            'fullname': user.displayName,
            'role': "user",
            'bio': "Votre biographie...",
            'location': "Votre location...",
            'createdAt': FieldValue.serverTimestamp(), 
          });

          //Ajout de la sous collection

          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(uid)
              .collection('favorite_articles')
              .add({
            'createdAt': FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(uid)
              .collection('liked_articles')
              .add({
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        ElegantNotification.success(
          title: Text(
            "Succès",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 27, 170, 31),
              fontSize: 16,
            ),
          ),
          description: Text(
            "Connexion réussie",
            style: TextStyle(
              color: Color.fromARGB(255, 27, 170, 31),
              fontSize: 14,
            ),
          ),
          icon: Icon(
            Icons.check_circle,
            color: Color.fromARGB(255, 27, 170, 31),
          ),
          //background: Color.fromARGB(255, 27, 170, 31),
          borderRadius: BorderRadius.circular(12.0),
          animationDuration: Duration(milliseconds: 300),
          toastDuration: Duration(seconds: 3),
          onDismiss: () {
            print('Message when the notification is dismissed');
          },
        ).show(context);

        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                child: HomeScreen(
                  uid: userCredential.user!.uid,
                ),
              );
            },
          ),
          (route) => false,
        );

        print("Inscription réussie : ${user.displayName}, ${user.email}");
      } else {
        print("Erreur : Utilisateur non trouvé.");
      }
    } catch (e) {
      String errorMessage = "Absence d'internet ou lente !";
      print("Erreur lors de l'inscription avec Google : $e");
      if (e is FirebaseAuthException) {
        errorMessage = " ${e.message}";
      }
      ElegantNotification.error(
        title: Text(
          "Erreur",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 16,
          ),
        ),
        description: Text(
          "Pas de connexion internet, ou lente !",
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        icon: Icon(
          Icons.error_outline,
          color: Colors.red,
        ),
        //background: Colors.redAccent,
        borderRadius: BorderRadius.circular(12.0),
        animationDuration: Duration(milliseconds: 300),
        toastDuration: Duration(seconds: 3),
        onDismiss: () {
          print('Message when the notification is dismissed');
        },
      ).show(context);
    } finally {
      setState(() {
        is_Loading = false;
      });
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      is_Loading = true;
    });

    final FirebaseAuth _auth = FirebaseAuth.instance;
    String uid;
    print("laaaaaaaaaaaaa");
    try {
      // Étape 1 : Authentification via Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Étape 2 : Récupérer les credentials Facebook
        final AccessToken accessToken = result.accessToken!;
        final AuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        // Étape 3 : S'inscrire ou se connecter avec Firebase
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        // Étape 4 : Récupérer l'utilisateur
        final User? user = userCredential.user;

        if (user != null) {
          // Vérifier si l'utilisateur existe déjà dans Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            // Récupérer le `uid` de l'utilisateur
            uid = userCredential.user!.uid;

            // Ajouter les données de l'utilisateur dans Firestore
            await FirebaseFirestore.instance
                .collection('utilisateurs')
                .doc(uid)
                .set({
              'uid': uid,
              'email': user.email,
              'fullname': user.displayName, 
              'role': "user",
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Ajouter les sous-collections
            await FirebaseFirestore.instance
                .collection('utilisateurs')
                .doc(uid)
                .collection('favorite_articles')
                .add({'createdAt': FieldValue.serverTimestamp()});

            await FirebaseFirestore.instance
                .collection('utilisateurs')
                .doc(uid)
                .collection('liked_articles')
                .add({'createdAt': FieldValue.serverTimestamp()});
          }

          // Redirection vers l'écran d'accueil
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 600),
              pageBuilder: (context, animation, secondaryAnimation) {
                return FadeTransition(
                  opacity: animation,
                  child: HomeScreen(
                    uid: userCredential.user!.uid,
                  ),
                );
              },
            ),
            (route) => false,
          );

          print("Inscription réussie : ${user.displayName}, ${user.email}");
        } else {
          print("Erreur : Utilisateur non trouvé.");
        }
      } else if (result.status == LoginStatus.cancelled) {
        print("Connexion Facebook annulée par l'utilisateur.");
      } else {
        print("Erreur lors de la connexion Facebook : ${result.message}");
      }
    } catch (e) {
      print("Erreur lors de l'inscription avec Facebook : $e");
    } finally {
      setState(() {
        is_Loading = false;
      });
    }
  }

  bool canExit = false;
  Future<bool> showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible:
              false, // Empêche la fermeture en touchant à l'extérieur
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeOutBack,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app,
                          size: 50, color: Colors.redAccent),
                      SizedBox(height: 15),
                      Text(
                        "Quitter l'application",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Êtes-vous sûr de vouloir quitter ?",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false), // Annuler
                            child: Text("Non", style: TextStyle(fontSize: 16)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pop(true), // Quitter
                            child: Text("Oui",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  //const Color(0xFF4A148C)
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    bool isOffline = context.watch<ConnectivityProvider>().isOffline;
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        bool shouldExit = await showExitDialog(context);
        if (shouldExit) {
          setState(() {
            canExit =
                true; 
          });
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else if (Platform.isIOS) {
            exit(0);
          }
        }
      },
      child: LoadingOverlayPro(
        isLoading: is_Loading,
        progressIndicator: Stack(
          alignment: Alignment.center,
          children: [
            ThreeArchedCircle(color: Colors.blue, size: 130),
            ThreeRotatingDots(size: 50, color: Colors.blue)
          ],
        ),
        child: Scaffold(
          backgroundColor: context.watch<ThemeProvider>().isDark
              ? Colors.black
              : Color.fromARGB(255, 15, 48, 119),
          body: isOffline
              ? Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 100, color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          "Aucune connexion Internet",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: Colors.black, 
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), 
                            ),
                            elevation: 5, 
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.black), 
                              SizedBox(width: 8),
                              Text(
                                "Réessayer",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              :  SafeArea(
            child: Stack(children: [
              // Image de fond qui couvre toute la page
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/blog_logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          border: Border.all(
                            color: Colors.blueAccent, 
                            width: 3.0, 
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(
                                20.0), 
                            bottomRight: Radius.circular(
                                20.0), 
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.grey.withOpacity(0.3), 
                              spreadRadius: 4,
                              blurRadius: 8,
                              offset: Offset(0, 3), 
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(
                                16.0), 
                            bottomRight: Radius.circular(12.0),
                          ),
                          child: isLogin
                              ? Image.asset(
                                  'assets/images/login_image.jpg', 
                                  height:
                                      230, 
                                  width: double.infinity,
                                  fit:
                                      BoxFit.cover, 
                                )
                              : Image.asset(
                                  'assets/images/singnup2.png', 
                                  height:
                                      230, 
                                  width: double.infinity, 
                                  fit:
                                      BoxFit.cover, 
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLogin ? 'Connectez-vous' : 'Inscrivez-vous',
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                onPressed: () {
                                  context.read<ThemeProvider>().toggleTheme();
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    color: Colors.white,
                                    context.watch<ThemeProvider>().isDark
                                        ? Icons.light_mode
                                        : Icons.dark_mode,
                                  ),
                                ),
                              ),
                                const SizedBox(width: 10),
                                
                              ],
                            ),
                          ),

                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                isLogin
                                    ? 'Connectez-vous pour continuer votre aventure de découverte'
                                    : 'Commencez dès aujourd\'hui à explorer les tendances technologiques',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Champs de formulaire
                          Form(
                              key: _formeKey,
                              child: Column(children: [
                                !isLogin
                                    ? _buildTextField('Nom complet',
                                        _fullnameController, Icons.person)
                                    : SizedBox(),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    'Email', _emailController, Icons.email,
                                    isEmail: true),
                                const SizedBox(height: 15),
                                _buildTextField('Mot de passe',
                                    _passwordController, Icons.lock,
                                    isPassword: true),
                              ])),

                          const SizedBox(height: 20),
                          // Bouton principal
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _registerUse();
                                
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                shadowColor: Colors.black.withOpacity(0.2),
                                elevation: 5,
                              ),
                              child: Text(
                                isLogin ? 'Se connecter' : 'S\'inscrire',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF0F4677),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Connexion via réseaux sociaux
                          _buildSocialLogin(),
                          const SizedBox(height: 12),
                          // Lien pour basculer entre "Sign In" et "Sign Up"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin
                                    ? 'Pas de compte ? '
                                    : 'Déjà un compte ? ',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _fullnameController.clear();
                                    _emailController.clear();
                                    _passwordController.clear();
                                    isLogin = !isLogin;
                                  });
                                },
                                child: Text(
                                  isLogin ? 'S\'inscrire' : 'Se connecter',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isLogin
                              ? SizedBox(
                                  height: 40,
                                )
                              : SizedBox(
                                  height: 0,
                                )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controllername, IconData icon,
      {bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controllername,
      cursorColor: Colors.white,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: isEmail ? TextInputType.emailAddress : null,
      validator: (value) {
        if (isEmail) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer vorte email';
          }
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Veuillez entrer un email valide.';
          }
          return null;
        } else if (isPassword) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un mot de passe.';
          }
          if (value.length < 6) {
            return 'Le mot de passe doit contenir au moins 6 caractères.';
          }
          return null;
        } else {
          if (!isLogin) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre fullname';
            }
          }
        }
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        //floatingLabelAlignment: FloatingLabelAlignment.start,
        labelText: label,
        contentPadding: EdgeInsets.symmetric(vertical: 10),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color.fromARGB(255, 206, 8, 8)),
        ),
        errorStyle: TextStyle(color: Color.fromARGB(255, 255, 159, 159)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color.fromARGB(255, 206, 8, 8)),
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Colors.white70)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(child: Divider(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton('Google', 'assets/images/google_logo.png',
                () async {
              await _handleGoogleSignIn();
            }),
            
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    String logoPath,
    Future<void> Function() onPressed,
  ) {
    return ElevatedButton(
      onPressed: is_Loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            logoPath,
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4A148C),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
