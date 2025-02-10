import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_majoie/admin_dashboard.dart';
import 'package:informatiqueblog/pages_majoie/apropos.dart';
import 'package:informatiqueblog/pages_majoie/auth_screen.dart';
import 'package:informatiqueblog/pages_majoie/contacts.dart';
import 'package:informatiqueblog/pages_majoie/home_screen.dart';
import 'package:informatiqueblog/pages_majoie/profil_user.dart';
import 'package:informatiqueblog/pages_majoie/statistiques.dart';
import 'package:provider/provider.dart';
import '../pages_aurel/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.uid});
  final String uid;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'Français';
  bool _twoFactorAuth = false;
  bool _emailNotifications = true;
  String _selectedTheme = 'Système';

    String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "user";
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchUserData(widget.uid);
  }

      Future<void> fetchUserData(String uid) async {
        setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Récupérer email et fullname
        email = userData['email'] ?? 'Email inconnu';
        fullname = userData['fullname'] ?? 'Nom inconnu';
        image = userData['image'] ?? "";
        role = userData['role'] ?? "user";

        print("Email : $email");
        print("Nom complet : $fullname");
        print("Image complete : $image");
      } else {
        print("L'utilisateur n'existe pas.");
      }
    } catch (e) {
      print("Erreur lors de la récupération des données de l'utilisateur : $e");
    }finally{
      setState(() {
      isLoading = false;
    });
    }
  }


    bool canExit = false; 
  Future<bool> showExitDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
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
                    Icon(Icons.exit_to_app, size: 50, color: Colors.redAccent),
                    SizedBox(height: 15),
                    Text(
                      "Quitter l'application",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          onPressed: () => Navigator.of(context).pop(false), 
                          child: Text("Non", style: TextStyle(fontSize: 16)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true), 
                          child: Text("Oui", style: TextStyle(fontSize: 16, color: Colors.white)),
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


  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    bool isOffline = context.watch<ConnectivityProvider>().isOffline;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        bool shouldExit = await showExitDialog(context);
        if (shouldExit) {
          setState(() {
            canExit = true; 
          });
          if (Platform.isAndroid) {
            SystemNavigator.pop(); 
          } else if (Platform.isIOS) {
            exit(0); 
          }
        }
      },
      child: Scaffold(
        drawer: _mebuildDrawer(),
        appBar: AppBar(
            title: const Text(
              'Catégories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
            ],
          ),
        backgroundColor: const Color(0xFFF5F7FB),
        body:  isOffline
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
                            setState(() {
                              
                            });
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
              :  SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              isMobile
                  ? _buildMobileSettings()
                  : _buildDesktopSettings(),
            ],
          ),
        ),
      ),
    );
  }

  void showAccessDeniedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, 
      barrierLabel: "Accès refusé",
      transitionDuration: Duration(milliseconds: 300), 
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.lock, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  "Accès refusé",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              "Vous n'avez pas les permissions nécessaires pour accéder à cette page.",
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation, 
          child: child,
        );
      },
    );
  }

  Widget _mebuildDrawer() {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            color: context.watch<ThemeProvider>().isDark
                ? Color.fromRGBO(66, 66, 66, 1)
                : Color.fromARGB(255, 15, 70, 119),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: (){
                   Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: UserProfil(uid: widget.uid),
                    );
                  },
                ),
                (route) => false,
              );
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: (image != null || image!.isNotEmpty)
                          ? Image.network(
                              image!,
                              width: 60, 
                              height: 60,
                              fit: BoxFit.cover, 
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                  
                                final totalBytes =
                                    loadingProgress.expectedTotalBytes;
                                final loadedBytes =
                                    loadingProgress.cumulativeBytesLoaded;
                  
                                // Calcul du pourcentage chargé
                                final percentage = totalBytes != null
                                    ? (loadedBytes / totalBytes * 100)
                                        .toStringAsFixed(0)
                                    : null;
                  
                                return SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: totalBytes != null
                                              ? loadedBytes / totalBytes
                                              : null,
                                        ),
                                        //const SizedBox(height: 8),
                                        Text(
                                          percentage != null
                                              ? "$percentage%"
                                              : "Chargement...",
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                // Si même l'image par défaut échoue, afficher une icône
                                return Icon(
                                  Icons.person,
                                  color: Color.fromARGB(255, 15, 70, 119),
                                  size: 35,
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              color: Color.fromARGB(255, 15, 70, 119),
                              size: 35,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  fullname!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.home, color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: HomeScreen(uid: widget.uid),
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.category,
                color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('Catégories'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: CategoriesPage(
                        uid: widget.uid,
                      ),
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person,
                color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('Profil utilisateur'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: UserProfil(
                        uid: widget.uid,
                      ),
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart,
                color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('Statistiques'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: StatisticsPage(
                        uid: widget.uid,
                      ),
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard,
                color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('Dashboard Admin'),
            onTap: () {
              if (role == "admin") {
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
                    "Page d'administration",
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

                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 600),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return FadeTransition(
                        opacity: animation,
                        child: AdminDashboard(
                          uid: widget.uid,
                        ),
                      );
                    },
                  ),
                  (route) => false,
                );
              } else {
                showAccessDeniedDialog(context);
              }
            },
          ),
          const Divider(),
          
          ListTile(
            leading:
                const Icon(Icons.info, color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('À propos'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: AboutPage(
                        uid: widget.uid,
                      ),
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support,
                color: Color.fromARGB(255, 15, 70, 119)),
            title: const Text('Contact'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ContactPage(
                        uid: widget.uid,
                      ),
                    );
                  },
                ),
                (route) => false,
              );
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  setState(() {
                    isLoading = true;
                  });

                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
                 
                  ElegantNotification.info(
                    title: Text(
                      "Info",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 1, 30, 110),
                        fontSize: 16,
                      ),
                    ),
                    description: Text(
                      "Utilisateur déconnecté",
                      style: TextStyle(
                        color: Color.fromARGB(255, 1, 30, 110),
                        fontSize: 14,
                      ),
                    ),
                    icon: Icon(
                      Icons.info_outline,
                      color: Color.fromARGB(255, 1, 30, 110),
                    ),
                    background:
                        Colors.white, 
                    animationDuration: Duration(milliseconds: 300),
                    toastDuration: Duration(seconds: 3),
                    onDismiss: () {
                      print('Notification fermée');
                    },
                  ).show(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return FadeTransition(
                          opacity: animation,
                          child: AuthScreen(),
                        );
                      },
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  print("Erreur ${e}");
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: const Text('Déconnexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 15, 70, 119),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Gérez les paramètres de votre compte',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSettings() {
    return Column(
      children: [
        _buildAccountSettings(),
        const SizedBox(height: 16),
        _buildNotificationSettings(),
        const SizedBox(height: 16),
        _buildAppearanceSettings(),
        const SizedBox(height: 16),
        _buildSecuritySettings(),
        const SizedBox(height: 16),
        _buildLanguageSettings(),
      ],
    );
  }

  Widget _buildDesktopSettings() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAccountSettings(),
              const SizedBox(height: 24),
              _buildNotificationSettings(),
              const SizedBox(height: 24),
              _buildLanguageSettings(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildAppearanceSettings(),
              const SizedBox(height: 24),
              _buildSecuritySettings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return _buildSettingsCard(
      'Compte',
      Column(
        children: [
          _buildSettingsField(
            'Nom d\'utilisateur',
            'admin123',
            onTap: () {
             
            },
          ),
          _buildSettingsField(
            'Email',
            'admin@example.com',
            onTap: () {
              
            },
          ),
          _buildSettingsField(
            'Mot de passe',
            '••••••••',
            onTap: () {
              
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsCard(
      'Notifications',
      Column(
        children: [
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir des notifications push'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notifications par email'),
            subtitle: const Text('Recevoir des notifications par email'),
            value: _emailNotifications,
            onChanged: (bool value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSettingsCard(
      'Apparence',
      Column(
        children: [
          SwitchListTile(
            title: const Text('Mode sombre'),
            subtitle: const Text('Activer le thème sombre'),
            value: _darkMode,
            onChanged: (bool value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          ListTile(
            title: const Text('Thème'),
            subtitle: Text(_selectedTheme),
            trailing: DropdownButton<String>(
              value: _selectedTheme,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTheme = newValue;
                  });
                }
              },
              items: ['Système', 'Clair', 'Sombre']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsCard(
      'Sécurité',
      Column(
        children: [
          SwitchListTile(
            title: const Text('Authentification à deux facteurs'),
            subtitle: const Text('Ajouter une couche de sécurité supplémentaire'),
            value: _twoFactorAuth,
            onChanged: (bool value) {
              setState(() {
                _twoFactorAuth = value;
              });
            },
          ),
          ListTile(
            title: const Text('Sessions actives'),
            subtitle: const Text('Gérer vos sessions connectées'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
             
            },
          ),
          ListTile(
            title: const Text('Historique de connexion'),
            subtitle: const Text('Voir l\'historique des connexions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
             
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return _buildSettingsCard(
      'Langue',
      Column(
        children: [
          ListTile(
            title: const Text('Langue de l\'interface'),
            subtitle: Text(_selectedLanguage),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
              items: ['Français', 'English', 'Español', 'Deutsch']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          content,
        ],
      ),
    );
  }

  Widget _buildSettingsField(
      String label,
      String value, {
        VoidCallback? onTap,
      }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit),
      onTap: onTap,
    );
  }
}