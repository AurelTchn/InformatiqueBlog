import 'dart:convert';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/articledetails.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
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
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'theme_provider.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:http/http.dart' as http;

class Listearticles extends StatefulWidget {
  const Listearticles(
      {super.key,
      required this.categorieId,
      required this.categorieName,
      required this.uid});

  final String categorieId;
  final String categorieName;
  final String uid;

  @override
  State<Listearticles> createState() => _ListearticlesState();
}

class _ListearticlesState extends State<Listearticles> {
  bool isLoading = false;
  List<Map<String, dynamic>> articles = [];
  List<Map<String, dynamic>> filteredArticles = [];

  final TextEditingController searchController = TextEditingController();
  List<bool> isItemVisible = [];
  bool isLiked = false;
  bool isProcessing = false;
  bool isProcessingFavorite = false;
  late Future<List<Map<String, dynamic>>> articleFuture;

  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "user";

  @override
  void initState() {
    super.initState();
    // TODO: implement initState

    articleFuture = _load_articles();
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

  Future<List<Map<String, dynamic>>> _load_articles() async {
    setState(() {
      isLoading = true;
    });
    print("L'identifiant de la personne qui s'est authentifié ${widget.uid}");
    try {
      List<Map<String, dynamic>> fetchedArticles = await ApiService()
          .fetchArticlesByCategoryFromFirestore(widget.categorieId, widget.uid);
      //print("Listes des articles $fetchedArticles");
      setState(() {
        articles = fetchedArticles;
        filteredArticles = fetchedArticles;
        //isItemVisible = List<bool>.filled(filteredArticles.length, false);
      });
      return articles;
    } catch (e) {
      print('Erreur lors du chargement des articles : $e');
      return [];
    } finally {
      setState(() {
        filteredArticles = articles;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> comments = [
    {
      "author": "Franck Ridoane",
      "text": "J'aime de tout coeur ce article. Du courage à vous !"
    }
  ];
  final TextEditingController commentController = TextEditingController();

  void toggleLike(int index) async {
    final article = articles[index];
    final idArticle = article['id_article'];

    String idUtilisateur = widget.uid;
    if (isProcessing) return;
    try {
      if (isProcessing == true) {
      } else {
        isProcessing = true;
        setState(() {
          articles[index]['isLiked'] = !articles[index]['isLiked'];

          if (articles[index]['isLiked']) {
            articles[index]['likes'] += 1;
          } else {
            articles[index]['likes'] -= 1;
          }
        });
        final userRef = FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(idUtilisateur);
        final articleRef =
            FirebaseFirestore.instance.collection('articles').doc(idArticle);

        final likedArticleSnapshot =
            await userRef.collection('liked_articles').doc(idArticle).get();
        if (likedArticleSnapshot.exists) {
          isProcessing = true;
          await userRef.collection('liked_articles').doc(idArticle).delete();

          await articleRef.update({'likes': FieldValue.increment(-1)});
        } else {
          isProcessing = true;
          await userRef.collection('liked_articles').doc(idArticle).set({
            'uid_article': idArticle,
            'liked_at': FieldValue.serverTimestamp(),
          });

          await articleRef.update({'likes': FieldValue.increment(1)});
        }
      }
    } catch (e) {
      print("Erreur ${e}");
    } finally {
      isProcessing = false;
    }
  }

  void addComment(String comment, int index) async {
    final article = articles[index];
    final idArticle = article['id_article'];

    String idUtilisateur = widget.uid;
    if (comment.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      try {
        // Récupérer le 'fullname' de l'utilisateur avec son uid
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(idUtilisateur)
            .get();

        if (userDoc.exists) {
          String fullname = userDoc['fullname'];
          final idCommentaire =
              FirebaseFirestore.instance.collection('commentaires').doc().id;

          // Ajouter le commentaire dans Firestore
          await FirebaseFirestore.instance
              .collection('commentaires')
              .doc(idCommentaire)
              .set({
            'id_commentaire': idCommentaire,
            'contenu': comment,
            'id_utilisateur': idUtilisateur,
            'id_article': idArticle,
            'author': fullname,
            'image': image,
            'created_at': FieldValue.serverTimestamp(),
          });

          final articleRef =
              FirebaseFirestore.instance.collection('articles').doc(idArticle);

          // Incrémenter le compteur de likes dans la collection des articles
          await articleRef.update({'comments': FieldValue.increment(1)});
          setState(() async {
            commentController.clear();
            article['comments'] = article['comments'] + 1;

            //Réactualiser les articles
            List<Map<String, dynamic>> fetchedArticles = await ApiService()
                .fetchArticlesByCategoryFromFirestore(
                    widget.categorieId, widget.uid);

            articles = fetchedArticles;
            filteredArticles = fetchedArticles;
            //isItemVisible = List<bool>.filled(filteredArticles.length, false);
          });
        }
      } catch (e) {
        print("Erreur lors de l'ajout de commentaire ${e}");
      } finally {
        setState(() {
          isLoading = false;
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
              "Commentaire envoyé",
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
        });
      }
    }
  }

  void shareArticle(int index) {
    setState(() {
      articles[index]['shares']++;
    });
  }

  void toggleFavorite(int index) async {
    final article = articles[index];
    final idArticle = article['id_article'];

    String idUtilisateur = widget.uid;
    print("L'uid de l'utilisateur est ${widget.uid}");
    if (isProcessingFavorite) return;
    try {
      if (isProcessingFavorite == true) {
      } else {
        isProcessingFavorite = true;
        setState(() {
          articles[index]['isFavorite'] = !articles[index]['isFavorite'];
        });
        final userRef = FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(idUtilisateur);
        final articleRef =
            FirebaseFirestore.instance.collection('articles').doc(idArticle);

        // Vérifier si l'article est déjà ajouté au favoris par l'utilisateur
        final likedArticleSnapshot =
            await userRef.collection('favorite_articles').doc(idArticle).get();
        if (likedArticleSnapshot.exists) {
          isProcessingFavorite = true;
          // Si le document existe, l'utilisateur a déjà mis l'article au favoris, donc on supprime le favoris
          await userRef.collection('favorite_articles').doc(idArticle).delete();
        } else {
          isProcessingFavorite = true;
          // Sinon, l'utilisateur n'a pas mis cet article en favoris, donc on ajoute un favoris
          await userRef.collection('favorite_articles').doc(idArticle).set({
            'uid_article': idArticle,
            'favorite_at': FieldValue.serverTimestamp(),
          });

          /*  setState(() {
            articles[index]['isFavorite'] = !articles[index]['isFavorite'];
          }); */
        }
      }
    } catch (e) {
      print("Erreur ${e}");
    } finally {
      isProcessingFavorite = false;
    }
  }

  void _filterArticles(String query) {
    final results = articles
        .where((article) =>
            article['titre']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      filteredArticles = results;
    });
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            canExit = true;
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
            title: Text(
              widget.categorieName,
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
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, color: Colors.black),
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
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: TextField(
                        onChanged: (query) {
                          _filterArticles(query);
                        },
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        cursorColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                        decoration: InputDecoration(
                          hintText: "Rechercher un article...",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 5.0),
                      child: Text(
                        "Découvrez nos derniers articles !",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 5.0),
                      child: Text(
                        '💡Cliquez sur un article pour parcourir son contenu et enrichir vos connaissances !',
                        textAlign: TextAlign.start,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.watch<ThemeProvider>().isDark
                              ? Colors.white70
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    filteredArticles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 80,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white54
                                      : Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Aucun article trouvé",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
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
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredArticles.length,
                            itemBuilder: (context, index) {
                              final article = filteredArticles[index];

                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                builder: (context, opacityValue, child) {
                                  return Opacity(
                                    opacity: opacityValue,
                                    child: _buildArticleCard(
                                      index,
                                      article['titre'],
                                      article['image'],
                                      article['contenu'],
                                      article['sous_titre'],
                                      article['isFavorite'],
                                      article['isLiked'],
                                      article['likes'],
                                      article['shares'],
                                      article['comments'],
                                    ),
                                  );
                                },
                              );
                            },
                          ) 
                          /* ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredArticles.length,
                      itemBuilder: (context, index) {
                        final article = filteredArticles[index];
                        return VisibilityDetector(
                          key: Key('category_$index'),
                          onVisibilityChanged: (visibilityInfo) {
                            final visiblePercentage =
                                visibilityInfo.visibleFraction * 100;

                            if (visiblePercentage > 20 &&
                                !isItemVisible[index]) {
                             
                              setState(() {
                                isItemVisible[index] = true;
                              });
                            } 
                          },
                          child: isItemVisible[index]
                              ? SlideInLeft(
                                  duration: const Duration(milliseconds: 600),
                                  child: _buildArticleCard(
                                      index,
                                      article['titre'],
                                      article['image'],
                                      article['contenu'],
                                      article['sous_titre'],
                                      article['isFavorite'],
                                      article['isLiked'],
                                      article['likes'],
                                      article['shares'],
                                      article['comments']),
                                )
                              : Opacity(
                                  opacity:
                                      0.0,
                                  child: _buildArticleCard(
                                      index,
                                      article['titre'],
                                      article['image'],
                                      article['contenu'],
                                      article['sous_titre'],
                                      article['isFavorite'],
                                      article['isLiked'],
                                      article['likes'],
                                      article['shares'],
                                      article['comments']),
                                ),
                        );
                      },
                    ), */
                  ],
                ),
        ),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recherche'),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
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
                    background: Colors.white,
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

  Widget _buildArticleCard(
      int index,
      String title,
      String image,
      String content,
      String sous_titre,
      bool isFavorite,
      bool isLiked,
      int likes,
      int shares,
      int comments) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
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
                  id_article: articles[index]['id_article'],
                  title: title ?? "Titre indisponible",
                  image: image ?? "Image indisponible",
                  content: content ?? "Contenu indisponible",
                  excerpt: sous_titre ?? "Contenu indisponible",
                  isFavorite: isFavorite,
                  isLiked: isLiked,
                  likes: likes,
                  shares: shares,
                ),
              );
            },
          ),
          (route) => false,
        );
      },
      child: Card(
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: "article-${index}",
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  image,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    final totalBytes = loadingProgress.expectedTotalBytes;
                    final loadedBytes = loadingProgress.cumulativeBytesLoaded;

                    final percentage = totalBytes != null
                        ? (loadedBytes / totalBytes * 100).toStringAsFixed(0)
                        : null;

                    return SizedBox(
                      height: 220,
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
                    return Container(
                      height: 250,
                      color: context.watch<ThemeProvider>().isDark
                          ? Color.fromRGBO(102, 102, 102, 1)
                          : Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ) ??
                        TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 5),
                  Text(
                    sous_titre,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton Like
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => toggleLike(index),
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                          color: isLiked ? Colors.blue : Colors.grey,
                        ),
                        iconSize: 28.0,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${likes} Likes',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16.0)),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 20.0,
                                  right: 20.0,
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          20.0,
                                  top: 20.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Titre
                                    const Text(
                                      'Ajouter un commentaire',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),

                                    // Champ de texte pour le commentaire
                                    TextField(
                                      controller: commentController,
                                      autofocus: true,
                                      minLines: 4,
                                      maxLines: 8,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Écrivez votre commentaire ici...",
                                        hintStyle: TextStyle(
                                          fontSize: 14.0,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white60
                                              : Colors.black45,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 14.0,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),

                                    const SizedBox(height: 20.0),

                                    // Boutons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Bouton Annuler
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            'Annuler',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),

                                        // Bouton Ajouter
                                        ElevatedButton(
                                          onPressed: () {
                                            final comment =
                                                commentController.text.trim();
                                            if (comment.isEmpty) {
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
                                                  "Commentaire vide",
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
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                animationDuration:
                                                    Duration(milliseconds: 300),
                                                toastDuration:
                                                    Duration(seconds: 3),
                                                onDismiss: () {
                                                  print(
                                                      'Message when the notification is dismissed');
                                                },
                                              ).show(context);
                                            } else {
                                              Navigator.pop(context);
                                              print("Je suis là");
                                              addComment(comment, index);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context
                                                    .watch<ThemeProvider>()
                                                    .isDark
                                                ? Color.fromRGBO(66, 66, 66, 1)
                                                : Colors.blue,
                                            foregroundColor: Colors.white,
                                            elevation: 2.0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0,
                                              vertical: 12.0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                          ),
                                          child: const Text(
                                            'Ajouter',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.comment,
                          color: Colors.green,
                        ),
                        iconSize: 28.0,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${comments} Comments',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final result = await Share.share(
                            '📢 *${title}*\n\n${sous_titre}\n\nEn savoir plus :\n${content}',
                            subject: 'Partagez cet article',
                          );
                          if (result.status == ShareResultStatus.success) {
                            // L'utilisateur a effectivement partagé
                            shareArticle(index);
                          }
                          shareArticle(index);
                        },
                        icon: const Icon(
                          Icons.share,
                          color: Colors.blue,
                        ),
                        iconSize: 28.0,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        ' Shares',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      IconButton(
                        onPressed: () => toggleFavorite(index),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        iconSize: 28.0,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        isFavorite ? 'Favoris' : 'Non Favoris',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              color: Color(0xFF4A148C),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF4A148C), size: 35),
                ),
                SizedBox(height: 10),
                Text(
                  'Liza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
}
