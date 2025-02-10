import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/listearticles.dart';
import 'package:informatiqueblog/main.dart';
import 'package:informatiqueblog/pages_aurel/variableglobal.dart';
import 'package:informatiqueblog/pages_majoie/admin_dashboard.dart';
import 'package:informatiqueblog/pages_majoie/apropos.dart';
import 'package:informatiqueblog/pages_majoie/auth_screen.dart';
import 'package:informatiqueblog/pages_majoie/contacts.dart';
import 'package:informatiqueblog/pages_majoie/home_screen.dart';
import 'package:informatiqueblog/pages_majoie/profil_user.dart';
import 'package:informatiqueblog/pages_majoie/settings.dart';
import 'package:informatiqueblog/pages_majoie/statistiques.dart';
import 'package:informatiqueblog/pages_merveilles/contacts.dart';
import 'package:informatiqueblog/pages_merveilles/profil.dart';
import 'package:informatiqueblog/src/horizontal_rotating_dots/horizontal_rotating_dots.dart';
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key, required this.uid}) : super(key: key);

  final String uid;
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> filteredCategories = [];
  late Future<List<Map<String, dynamic>>> categoriesFuture;
  late ScrollController _scrollController;
  List<int> _visibleItems = []; 
  final Duration animationDuration = Duration(milliseconds: 500);
  List<Map<String, dynamic>> categories = [];

  List<bool> isItemVisible = []; 
  bool isLoading = false;

  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "user";

  @override
  void initState() {
    super.initState();
    // Charger les catégories au démarrage
    categoriesFuture = _loadCategories();
    isItemVisible = List<bool>.filled(filteredCategories.length, false);
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les catégories depuis Firestore
      categories = await ApiService().fetchCategoriesFromFirestore();
      print("Voici la liste des catégories $categories");

      setState(() {
        filteredCategories = categories;
        isItemVisible = List<bool>.filled(filteredCategories.length, false);
        isLoading = false;
      });

      return categories;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur lors du chargement des catégories : $e');
      return [];
    }
  }

  void _filterCategories(String query) {
    final results = categories
        .where((categorie) =>
            categorie['nom']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      filteredCategories = results;
    });
  }

  bool canExit = false;
  Future<bool> showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible:
              false, 
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
                                Navigator.of(context).pop(false),
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
                                Navigator.of(context).pop(true), 
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
        isLoading: isLoading,
        progressIndicator: Stack(
          alignment: Alignment.center,
          children: [
            ThreeArchedCircle(color: Colors.blue, size: 130),
            ThreeRotatingDots(size: 50, color: Colors.blue)
          ],
        ),
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
              : SingleChildScrollView(
  physics: const BouncingScrollPhysics(),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: TextField(
          onChanged: (query) {
            _filterCategories(query);
          },
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          cursorColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          decoration: InputDecoration(
            hintText: "Rechercher une catégorie...",
            hintStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10.0),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Explorez nos catégories !",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '💡 Sélectionnez une catégorie pour explorer son contenu et enrichir vos connaissances !',
              textAlign: TextAlign.start,
              softWrap: true,
              style: TextStyle(
                fontSize: 14,
                color: context.watch<ThemeProvider>().isDark
                    ? Colors.white70
                    : Colors.grey[700],
              ),
            ),
            
          ],
        ),
      ),
      if (filteredCategories.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  "Aucune catégorie trouvée",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Essayez d'utiliser un autre mot-clé.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
      else
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredCategories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16.0),
          itemBuilder: (context, index) {
            final category = filteredCategories[index];

            return VisibilityDetector(
              key: Key('category_$index'),
              onVisibilityChanged: (visibilityInfo) {
                final visiblePercentage = visibilityInfo.visibleFraction * 100;

                if (visiblePercentage > 50 && !isItemVisible[index]) {
                  setState(() {
                    isItemVisible[index] = true;
                  });
                } else if (visiblePercentage < 8) {
                  isItemVisible[index] = false;
                }
              },
              child: SlideInUp(
                duration: const Duration(milliseconds: 500),
                child: _buildCategoryCard(category),
              ),
            );
          },
        ),
    ],
  ),
),

        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) {
              return FadeTransition(
                opacity: animation,
                child: Listearticles(
                  uid: widget.uid,
                  categorieId: category['id']!,
                  categorieName: category['nom']!,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: isDark ? Colors.grey[850] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        8.0), 
                    child: Image.network(
                      category['image']!,
                      width: 100.0,
                      height: 80.0,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        final totalBytes = loadingProgress.expectedTotalBytes;
                        final loadedBytes =
                            loadingProgress.cumulativeBytesLoaded;

                        // Calcul du pourcentage chargé
                        final percentage = totalBytes != null
                            ? (loadedBytes / totalBytes * 100)
                                .toStringAsFixed(0)
                            : null;

                        return SizedBox(
                          height: 80,
                          width: 100,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: totalBytes != null
                                      ? loadedBytes / totalBytes
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  percentage != null
                                      ? "$percentage%"
                                      : "Chargement...",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        
                        return Image.asset(
                          '0assets/images/defaultimage.jpeg',
                          width: 100.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                          
                            return Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        );
                      },
                    ),
                  )),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['nom'] ?? 'Catégorie inconnue',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      category['description'] ??
                          'Aucune description disponible.',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
                  onTap: () {
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;

                                final totalBytes =
                                    loadingProgress.expectedTotalBytes;
                                final loadedBytes =
                                    loadingProgress.cumulativeBytesLoaded;

                               
                                final percentage = totalBytes != null
                                    ? (loadedBytes / totalBytes * 100)
                                        .toStringAsFixed(0)
                                    : null;

                                return SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: totalBytes != null
                                              ? loadedBytes / totalBytes
                                              : null,
                                        ),
                                        
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
}
