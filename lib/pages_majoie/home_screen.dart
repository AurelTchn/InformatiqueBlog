import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/articledetails.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_aurel/listearticles.dart';
import 'package:informatiqueblog/pages_majoie/admin_dashboard.dart';
import 'package:informatiqueblog/pages_majoie/apropos.dart';
import 'package:informatiqueblog/pages_majoie/auth_screen.dart';
import 'package:informatiqueblog/pages_majoie/contacts.dart';
import 'package:informatiqueblog/pages_majoie/profil_user.dart';
import 'package:informatiqueblog/pages_majoie/settings.dart';
import 'package:informatiqueblog/pages_majoie/statistiques.dart';
import 'package:informatiqueblog/pages_merveilles/contacts.dart';
import 'package:informatiqueblog/pages_merveilles/profil.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:provider/provider.dart';
import '../pages_aurel/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.uid}) : super(key: key);
  final String uid;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  //Autres déclarations
  int _selectedIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentBannerIndex = 0;
  bool _isSearching = false;
  int count1 = 0;
  int count2 = 0;
  int count3 = 0;
  int count4 = 0;

  bool isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Exemple de liste d'articles pour la recherche
  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Introduction à la Cybersécurité',
      'author': 'John Doe',
      'date': '2024-01-10',
      'content': 'Un article détaillé sur les bases de la cybersécurité...'
    },
    {
      'title': 'Machine Learning pour Débutants',
      'author': 'Jane Smith',
      'date': '2024-01-12',
      'content': 'Découvrez les concepts fondamentaux du machine learning...'
    },
    {
      'title': 'Data Science en 2024',
      'author': 'Mike Johnson',
      'date': '2024-01-14',
      'content': 'Les dernières tendances en data science...'
    },
    // Ajoutez plus d'articles ici
  ];

  List<Map<String, dynamic>> _filteredArticles = [];
  late Future<List<Map<String, String>>> categoriesFuture;
  late Future<List<Map<String, String>>> articlesFuture;
  List<Map<String, String>> filteredCategories = [];
  List<Map<String, String>> filteredArticles = [];
  List<Map<String, String>> filteredLastArticles = [];

  String email = "user@gmail.com";
  String fullname = "User";
  String role = "user";
  String image = "";

  @override
  void initState() {
    super.initState();

    /// Initialisation du contrôleur d'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animation de fade
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Animation de slide
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Animation de scale
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Démarrer l'animation
    _animationController.forward();

    // Initialiser les articles filtrés
    _filteredArticles = _articles;

    categoriesFuture = _loadCategories();

    loadCategoryCounts();

    _loadArticles();

    _loadLastArticles();

    fetchUserData(widget.uid);
  }

  Future<List<Map<String, String>>> _loadLastArticles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les catégories depuis Firestore
      final articles =
          await ApiService().fetchArticlesFromFirestore(widget.uid);
      //print("Voici la liste des catégories $articles");

      filteredLastArticles = articles.length >= 3
          ? articles.sublist(articles.length - 3)
          : articles;

      setState(() {
        isLoading = false;
        //print("Liste des catégories filtrées : $filteredLastArticles");
        //print("Quatre derniers articles : $filteredLastArticles");
      });

      return filteredLastArticles;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur lors du chargement des catégories : $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _loadArticles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les catégories depuis Firestore
      final articles =
          await ApiService().fetchArticlesFromFirestore(widget.uid);
      //print("Voici la liste des articles $articles");

      filteredArticles = articles.take(5).toList();
      setState(() {
        isLoading = false;
        //print("Liste des catégories filtrées : $filteredCategories");
        //print("Quatre derniers articles : $filteredArticles");
      });

      return filteredArticles;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur lors du chargement des catégories : $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les catégories depuis Firestore
      final categories = await ApiService().fetchCategoriesFromFirestore();
      print("Voici la liste des catégories $categories");

      setState(() async {
        filteredCategories =
            categories.isNotEmpty ? categories.take(5).toList() : [];
        for (var category in filteredCategories) {
          int count = await countArticlesInCategory(category['id'].toString());

          // Ajouter le nombre d'articles à la catégorie
          category['countArticle'] = count.toString();
        }

        isLoading = false;
        print("Liste des catégories filtré ${filteredCategories}");
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

  // Fonction pour récupérer les nombres d'articles pour chaque catégorie
  Future<void> loadCategoryCounts() async {
    for (var category in filteredCategories) {
      int count = await countArticlesInCategory(category['id'].toString());

      // Ajouter le nombre d'articles à la catégorie
      category['countArticle'] = count.toString();
    }

    setState(() {
      //print("Les catégories avec compte ${filteredCategories}");
    });
  }

  Future<int> countArticlesInCategory(String categoryUid) async {
    try {
      // Accéder à la collection des articles et filtrer par 'uid_categorie'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('articles') 
          .where('uid_categorie',
              isEqualTo: categoryUid) 
          .get();

      // Retourner le nombre d'articles dans la catégorie
      print("La taille de ${categoryUid} est ${snapshot.size}");
      return snapshot.size;
    } catch (e) {
      print('Erreur lors du compte: $e');
      return 0;
    }
  }

  Widget _buildStars(int likes) {
    int starCount =
        (likes / 3).ceil().clamp(0, 5); 

    return Row(
      children: List.generate(starCount, (index) {
        return const Icon(Icons.star,
            color: Color.fromARGB(255, 235, 200, 5), size: 18);
      }),
    );
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
        print("Le userData ${userData}");
        // Récupérer email et fullname
        email = userData['email'] ?? 'Email inconnu';
        fullname = userData['fullname'] ?? 'Nom inconnu';
        image = userData['image'] ?? "";
        role = userData['role'] ?? "user";

        print("Email : $email");
        print("Nom complet : $fullname");
        print("Image complete : $image");
        print("Role obtenu : $role");
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

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = _articles;
      } else {
        _filteredArticles = _articles
            .where((article) =>
                article['title'].toLowerCase().contains(query.toLowerCase()) ||
                article['content'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Fonction pour formater la date
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    Timestamp? date;
    if (timestamp is FieldValue) {
      date = Timestamp
          .now();
    } else if (timestamp is Timestamp) {
      date = timestamp;
    }

    if (date != null) {
      DateTime dateTime = date.toDate(); 
      return DateFormat('dd MMM yyyy, hh:mm a')
          .format(dateTime); 
    }
    return '';
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
    bool isOffline = context.watch<ConnectivityProvider>().isOffline;
    final isDark = context.watch<ThemeProvider>().isDark;
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
          appBar: AppBar(
            title: Text(
              'Bienvenue à Techblog',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    context.watch<ThemeProvider>().isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                ),
              ),
            ],
            backgroundColor: context.watch<ThemeProvider>().isDark
                ? Colors.black
                : Color.fromARGB(255, 15, 70, 119),
          ),
          drawer: _mebuildDrawer(),
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
              : SafeArea(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              if (_isSearching) _buildSearchBar(),
                              Expanded(
                                child: ListView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    if (!_isSearching) ...[
                                      _buildBanner(),
                                      const SizedBox(height: 24),
                                      _buildCategoriesCarousel(),
                                      const SizedBox(height: 24),
                                      _buildTopCourses(),
                                      const SizedBox(height: 24),
                                    ],
                                    _buildArticles(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          //bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4A148C),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'My Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Blogs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Profile',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearch,
        decoration: InputDecoration(
          hintText: 'Rechercher des articles...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _filteredArticles = _articles;
                _isSearching = false;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
  '📖 Découvrez d\'autres articles intéressants ! ✨',
  style: TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.bold,
    color: Color.fromARGB(255, 15, 70, 119), 
  ),
  textAlign: TextAlign.start, 
),

        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredLastArticles.length,
          itemBuilder: (context, index) {
            final article = filteredLastArticles[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['titre']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Par ${article['id_auteur']} - ${formatTimestamp(article['createdAt'])}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['sous_titre']!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 600),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: Articledetails(
                                  uid: widget.uid,
                                  id_article: article['id_article']!,
                                  title:
                                      article['titre'] ?? "Titre indisponible",
                                  image:
                                      article['image'] ?? "Image indisponible",
                                  content: article['content'] ??
                                      "Contenu indisponible",
                                  excerpt: article['sous_titre'] ??
                                      "Contenu indisponible",
                                  isFavorite: article['isFavorite'] == 'true'
                                      ? true
                                      : false,
                                  isLiked: article['isLiked'] == 'true'
                                      ? true
                                      : false,
                                  likes:
                                      int.tryParse(article['likes']!)!.toInt(),
                                  shares:
                                      int.tryParse(article['shares']!)!.toInt(),
                                ),
                              );
                            },
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Lire la suite'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 15, 70, 119),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person,
                      color: Color.fromARGB(255, 15, 70, 119), size: 35),
                ),
                SizedBox(height: 10),
                Text(
                  'Liza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'liza@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', 0),
          _buildDrawerItem(Icons.play_circle_outline, 'My Courses', 1),
          _buildDrawerItem(Icons.book, 'Blogs', 2),
          _buildDrawerItem(Icons.person, 'My Profile', 3),
          const Divider(),
          _buildDrawerItem(Icons.settings, 'Settings', 4),
          _buildDrawerItem(Icons.help, 'Help & Support', 5),
          _buildDrawerItem(Icons.logout, 'Logout', 6),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        if (index < 4) {
          _onItemTapped(index);
        }
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        const Text(
          'Hello Majoie!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final List<Map<String, String>> banners = [
      {
        'title': 'Protégez vos données en ligne',
        'subtitle': 'Explorez la cybersécurité',
      },
      {
        'title': 'Transformez vos données en actions',
        'subtitle': 'Découvrez la Data Science',
      },
      {
        'title': 'Créez des applications innovantes',
        'subtitle': 'Maîtrisez le développement mobile',
      },
      {
        'title': 'Dominez l’intelligence artificielle',
        'subtitle': 'Apprenez le Machine Learning',
      },
      {
        'title': 'Développez des sites performants',
        'subtitle': 'Plongez dans le développement web',
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: context.watch<ThemeProvider>().isDark
                ? Color.fromRGBO(66, 66, 66, 1)
                : const Color.fromARGB(255, 15, 70, 119),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: banners.length,
                itemBuilder: (context, index, realIndex) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banners[index]['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banners[index]['subtitle']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageRouteBuilder(
                                transitionDuration: Duration(milliseconds: 600),
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: CategoriesPage(uid: widget.uid),
                                  );
                                },
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                context.watch<ThemeProvider>().isDark
                                    ? Colors.black
                                    : const Color(0xFF4A148C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Voir plus...'),
                        ),
                      ],
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 200,
                  viewportFraction: 1,
                  autoPlay: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                ),
              ),
              // Indicateurs de page
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    banners.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentBannerIndex != index
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesCarousel() {
    // Liste des icônes possibles
    final List<IconData> iconList = [
      Icons.web,
      Icons.computer,
      Icons.code,
      Icons.memory,
      Icons.smartphone,
      //Icons.security,
      Icons.build,
      Icons.storage,
    ];
    // Sélectionner une icône aléatoire
    final IconData randomIcon = iconList[Random().nextInt(iconList.length)];
    final categories = [
      {
        'uid_categorie': '9RycdUYMlcOcNm7C56IE',
        'title': 'Intelligence Artificielle',
        'courses': "${count1.toString()} articles actuellement",
        'icon': Icons.psychology
      },
      {
        'uid_categorie': '3WUsEuaxu2QfcCgT2pW4',
        'title': 'Developpement Web',
        'courses': "${count2.toString()} articles actuellement",
        'icon': Icons.web
      },
      {
        'uid_categorie': 'L5VgVS9u9VLiMMnlMrGy',
        'title': 'Developpement mobile',
        'courses': "${count3.toString()} articles actuellement",
        'icon': Icons.mobile_friendly
      },
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category,
                        color: Color.fromARGB(255, 15, 70, 119), size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 15, 70, 119),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '💡 Cliquez sur une catégorie pour en découvrir son contenu !',
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
            const SizedBox(height: 16),
            CarouselSlider(
              options: CarouselOptions(
                height: 130,
                enlargeCenterPage: true,
                autoPlay: true,
              ),
              items: filteredCategories.map((category) {
                return Builder(
                  builder: (BuildContext context) {
                    return InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 600),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: Listearticles(
                                  uid: widget.uid,
                                  categorieId: category['id'].toString()!,
                                  categorieName: category['nom'].toString()!,
                                ),
                              );
                            },
                          ),
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: context.watch<ThemeProvider>().isDark
                              ? Color.fromRGBO(66, 66, 66, 1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(randomIcon,
                                size: 30,
                                color: context.watch<ThemeProvider>().isDark
                                    ? Colors.white
                                    : const Color(0xFF4A148C)),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(category['nom'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  //overflow: TextOverflow.ellipsis,
                                )),
                            Text(
                                "${category['countArticle']} articles actuellement"
                                    as String,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCourses() {
    // Liste des cours : On fera appel à la base de données
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final courses = [
      {
        'title': 'Data Science',
        'rating': '4.6',
        'learners': '10.5k Learners',
        'author': 'John Doe',
        'price': '\$49.99',
        'image': 'assets/images/course_data_science.jpg'
      },
      {
        'title': 'Machine Learning',
        'rating': '4.8',
        'learners': '8.2k Learners',
        'author': 'Jane Smith',
        'price': '\$59.99',
        'image': 'assets/images/course_data_science.jpg'
      },
      {
        'title': 'Web Development',
        'rating': '4.7',
        'learners': '15.3k Learners',
        'author': 'Mike Johnson',
        'price': '\$44.99',
        'image': 'assets/images/course_data_science.jpg'
      },
      {
        'title': 'Mobile Development',
        'rating': '4.5',
        'learners': '12.1k Learners',
        'author': 'Sarah Wilson',
        'price': '\$54.99',
        'image': 'assets/images/course_data_science.jpg'
      },
    ];

    final double itemWidth =
        screenSize.width < 600 ? screenSize.width * 0.8 : 300.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.article,
                        color: Color.fromARGB(255, 15, 70, 119)),
                    const SizedBox(width: 8),
                    const Text(
                      'Quelques articles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 15, 70, 119),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '💡 Cliquez sur un article pour en voir plus de détails et enrichir vos connaissances !',
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
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredArticles.length,
            itemBuilder: (context, index) {
              final course = filteredArticles[index];
              return InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return FadeTransition(
                          opacity: animation,
                          child: Articledetails(
                            uid: widget.uid,
                            id_article: course['id_article']!,
                            title: course['titre'] ?? "Titre indisponible",
                            image: course['image'] ?? "Image indisponible",
                            content:
                                course['content'] ?? "Contenu indisponible",
                            excerpt:
                                course['sous_titre'] ?? "Contenu indisponible",
                            isFavorite:
                                course['isFavorite'] == 'true' ? true : false,
                            isLiked: course['isLiked'] == 'true' ? true : false,
                            likes: int.tryParse(course['likes']!)!.toInt(),
                            shares: int.tryParse(course['shares']!)!.toInt(),
                          ),
                        );
                      },
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: itemWidth,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.watch<ThemeProvider>().isDark
                        ? Color.fromRGBO(66, 66, 66, 1)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: ClipRRect(
                            // Pour appliquer les bords arrondis à l'image
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              course['image']!,
                              fit: BoxFit
                                  .cover,
                              width: double.infinity,
                              height: 120,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
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
                                  height: 120,
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
                                        const SizedBox(height: 8),
                                        Text(
                                          percentage != null
                                              ? "$percentage%"
                                              : "Chargement...",
                                          style: const TextStyle(
                                            fontSize: 16,
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
                                  height: 120.0,
                                  width: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Si même l'image par défaut échoue, afficher une icône
                                    return Container(
                                      height: 120.0,
                                      width: 300.0,
                                      color: context
                                              .watch<ThemeProvider>()
                                              .isDark
                                          ? Color.fromRGBO(102, 102, 102, 1)
                                          : Colors.grey[
                                              300], 
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['titre']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              //overflow: TextOverflow,
                            ),
                            const SizedBox(height: 8),
                            
                            Row(
                              children: [
                                if (int.tryParse(course['likes']!) != null &&
                                    int.parse(course['likes']!) > 0)
                                  _buildStars(int.parse(course[
                                      'likes']!)), 
                                const SizedBox(width: 4),
                               
                                if (course['likes'] != null)
                                  ...() {
                                    final int likess =
                                        int.tryParse(course['likes']!) ?? 0;
                                    if (likess > 0) {
                                      return [
                                        const SizedBox(width: 8),
                                        const Icon(Icons.thumb_up,
                                            size: 18, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text("$likess likes"),
                                      ];
                                    }
                                    return [];
                                  }(),
                                
                              ],
                            ),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatefulWidget {
  final Map<String, String> course;
  final String uid;

  const _CourseCard({Key? key, required this.course, required this.uid})
      : super(key: key);

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool isHovered = false;
  List<Map<String, String>> filteredLastArticles = [];
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadLastArticles();
  }

  Future<List<Map<String, String>>> _loadLastArticles() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les catégories depuis Firestore
      final articles =
          await ApiService().fetchArticlesFromFirestore(widget.uid);
      //print("Voici la liste des catégories $articles");

      // Vérifier s'il y a au moins 4 articles
      filteredLastArticles = articles.length >= 4
          ? articles.sublist(articles.length - 4)
          : articles;

      setState(() {
        isLoading = false;
        //print("Liste des catégories filtrées : $filteredLastArticles");
        //print("Quatre derniers articles : $filteredLastArticles");
      });

      return filteredLastArticles;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur lors du chargement des catégories : $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, isHovered ? -10.0 : 0.0),
        child: Container(
            
            ),
      ),
    );
  }

  Future<Widget> _buildPopularBlogs() async {
    final blogs = [
      {
        'title': 'Exploring the World of Artificial Intelligence',
        'author': 'John Doe',
        'date': '2023-04-15',
        'image': 'assets/images/ai_blog.jpg',
      },
      {
        'title': 'The Future of Cybersecurity: Trends and Challenges',
        'author': 'Jane Smith',
        'date': '2023-04-10',
        'image': 'assets/images/cyber_blog.jpg',
      },
      
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Blogs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredLastArticles.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.asset(
                        blog['image']!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog['title']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'By ${blog['author']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                blog['date']!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
