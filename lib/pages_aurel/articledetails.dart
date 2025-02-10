import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_aurel/expandableText.dart';
import 'package:informatiqueblog/pages_aurel/listearticles.dart';
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
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'theme_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Articledetails extends StatefulWidget {
  const Articledetails(
      {super.key,
      required this.uid,
      required this.id_article,
      required this.title,
      required this.image,
      required this.content,
      required this.excerpt,
      this.isFavorite = false,
      this.isLiked = false,
      this.onFavoriteToggle,
      this.onLikeToggle,
      this.likes = 0,
      this.shares = 0});

  final String uid;
  final String id_article;
  final String title;
  final String image;
  final String content;
  final String excerpt;
  final bool isFavorite;
  final bool isLiked;
  final int likes;
  final int shares;
  final ValueChanged<bool>? onFavoriteToggle;
  final ValueChanged<bool>? onLikeToggle;

  @override
  State<Articledetails> createState() => _ArticledetailsState();
}

class _ArticledetailsState extends State<Articledetails> {
  late bool isFavorite;
  late bool isLiked;
  late int likes;
  bool isLoading = true;
  bool isProcessing = false;
  bool isProcessingFavorite = false;
  List<Map<String, dynamic>> comments = [];
  List<Map<String, dynamic>> commentsAll = [];

  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "user";

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
    isLiked = widget.isLiked;
    likes = widget.likes;
    _loadcommentaire();
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

  Future<void> _loadcommentaire() async {
    setState(() {
      isLoading = true;
    });
    try {
      print("L'uid de l'article est ${widget.id_article}");
      List<Map<String, dynamic>> fetchedComments =
          await ApiService().getAllComments(widget.id_article);
      setState(() {
        commentsAll = fetchedComments;
      });
    } catch (e) {
      print("Erreur lors de la récupération des commentaires ${e}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    print("Commentaires récupérés : $comments");
  }

  void toggleFavorite() async {
    String idUtilisateur = widget.uid;
    if (isProcessingFavorite) return;
    try {
      if (isProcessingFavorite == true) {
      } else {
        isProcessingFavorite = true;
        setState(() {
          isFavorite = !isFavorite;
        });
        final userRef = FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(idUtilisateur);
        final articleRef = FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.id_article);

        final likedArticleSnapshot = await userRef
            .collection('favorite_articles')
            .doc(widget.id_article)
            .get();
        if (likedArticleSnapshot.exists) {
          isProcessingFavorite = true;
          await userRef
              .collection('favorite_articles')
              .doc(widget.id_article)
              .delete();
        } else {
          isProcessingFavorite = true;
          await userRef
              .collection('favorite_articles')
              .doc(widget.id_article)
              .set({
            'uid_article': widget.id_article,
            'favorite_at': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print("Erreur ${e}");
    } finally {
      isProcessingFavorite = false;
    }
  }

  void toggleLike() async {
    String idUtilisateur = widget.uid;
    if (isProcessing) return;
    try {
      if (isProcessing == true) {
      } else {
        print("Je suis là");
        isProcessing = true;
        setState(() {
          isLiked = !isLiked;
          if (isLiked) {
            likes += 1;
          } else {
            likes -= 1;
          }
        });
        final userRef = FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(idUtilisateur);
        final articleRef = FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.id_article);

        final likedArticleSnapshot = await userRef
            .collection('liked_articles')
            .doc(widget.id_article)
            .get();
        if (likedArticleSnapshot.exists) {
          isProcessing = true;

          await userRef
              .collection('liked_articles')
              .doc(widget.id_article)
              .delete();

          await articleRef.update({'likes': FieldValue.increment(-1)});
        } else {
          isProcessing = true;

          await userRef
              .collection('liked_articles')
              .doc(widget.id_article)
              .set({
            'uid_article': widget.id_article,
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

  void addComment(String comment) async {
    setState(() {
      isLoading = true;
    });
    try {
      String idUtilisateur = widget.uid;
      if (comment.isNotEmpty) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(idUtilisateur)
            .get();

        if (userDoc.exists) {
          String fullname = userDoc['fullname'];
          final idCommentaire =
              FirebaseFirestore.instance.collection('commentaires').doc().id;

          await FirebaseFirestore.instance
              .collection('commentaires')
              .doc(idCommentaire)
              .set({
            'id_commentaire': idCommentaire,
            'contenu': comment,
            'id_utilisateur': idUtilisateur,
            'id_article': widget.id_article,
            'author': fullname,
            'image': image,
            'created_at': FieldValue.serverTimestamp(),
          });

          final articleRef = FirebaseFirestore.instance
              .collection('articles')
              .doc(widget.id_article);

          // Incrémenter le compteur de likes dans la collection des articles
          await articleRef.update({'comments': FieldValue.increment(1)});
          setState(() {
            commentController.clear();
          });
          List<Map<String, dynamic>> fetchedComments =
              await ApiService().getAllComments(widget.id_article);
          setState(() {
            comments = fetchedComments;
            commentsAll = fetchedComments;
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
            borderRadius: BorderRadius.circular(12.0),
            animationDuration: Duration(milliseconds: 300),
            toastDuration: Duration(seconds: 3),
            onDismiss: () {
              print('Message when the notification is dismissed');
            },
          ).show(context);
        }
      }
    } catch (e) {
      print("Erreur lors de l'ajout de commentaire ${e}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  final TextEditingController commentController = TextEditingController();

  // Fonction pour formater la date
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    Timestamp? date;
    if (timestamp is FieldValue) {
      date = Timestamp.now();
    } else if (timestamp is Timestamp) {
      date = timestamp;
    }

    if (date != null) {
      DateTime dateTime = date.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }
    return '';
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

  int commentsLimit = 3;

  void loadMoreComments() {
    setState(() {
      commentsLimit += 2;
    });
  }

  bool canDeleteComment(String idUtilisateur) {
    if (idUtilisateur == widget.uid) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> showDeleteConfirmationDialog(
      BuildContext context, String idCommentaire) async {
    Future<void> onDeleteComment(String idCommentaire) async {
      try {
        setState(() {
          isLoading = true;
        });
        Navigator.pop(context);

        DocumentSnapshot commentaireSnapshot = await FirebaseFirestore.instance
            .collection('commentaires')
            .doc(idCommentaire)
            .get();

        if (!commentaireSnapshot.exists) {
          print("Erreur : Le commentaire n'existe pas.");
          return;
        }

        await FirebaseFirestore.instance
            .collection('commentaires')
            .doc(idCommentaire)
            .delete();

        final articleRef = FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.id_article);
        await articleRef.update({'comments': FieldValue.increment(-1)});

        List<Map<String, dynamic>> fetchedComments =
            await ApiService().getAllComments(widget.id_article);
        setState(() {
          comments = fetchedComments;
          commentsAll = fetchedComments;
        });
      } catch (e) {
        print("Erreur lors de la suppression du commentaire ${e}");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 50, color: Colors.red),
                const SizedBox(height: 10),
                Text(
                  "Supprimer commentaire ?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.watch<ThemeProvider>().isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Voulez-vous vraiment supprimer ce commentaire ? Cette action est irréversible.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: context.watch<ThemeProvider>().isDark
                          ? Colors.white
                          : Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          Text("Annuler", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
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
                            "Suppression en cours ",
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

                        await onDeleteComment(idCommentaire);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Supprimer",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showEditingDialog(
      BuildContext context, String idCommentaire, String initialText) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _textController =
        TextEditingController(text: initialText);
    Future<void> _updateCommentaire(String idCommentaire) async {
      try {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);

          // Récupérer les données actuelles de la catégorie depuis Firestore
          DocumentSnapshot commentaireSnapshot = await FirebaseFirestore
              .instance
              .collection('commentaires')
              .doc(idCommentaire)
              .get();

          if (!commentaireSnapshot.exists) {
            print("Erreur : Le commentaire n'existe pas.");
            return;
          }

          Map<String, dynamic> commentaireData =
              commentaireSnapshot.data() as Map<String, dynamic>;

          // Récupération de Firestore
          CollectionReference commentaires =
              FirebaseFirestore.instance.collection('commentaires');

          // Données à mettre à jour
          final updatedCategoryData = {
            'contenu': _textController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Mise à jour du document
          await commentaires.doc(idCommentaire).update(updatedCategoryData);

          List<Map<String, dynamic>> fetchedComments =
              await ApiService().getAllComments(widget.id_article);
          setState(() {
            comments = fetchedComments;
            _textController.clear();
          });
        }
      } catch (e) {
        print("Erreur lors de la modification du commentaire ${e}");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Modifier le commentaire',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.watch<ThemeProvider>().isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),

                    // Formulaire
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _textController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Votre commentaire",
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          labelStyle: TextStyle(
                            color: context.watch<ThemeProvider>().isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          prefixIcon: Icon(Icons.comment, color: Colors.teal),
                          filled: true,
                          fillColor: context.watch<ThemeProvider>().isDark
                              ? Colors.grey[900]
                              : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.teal, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un commentaire';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Boutons d'actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey),
                          ),
                          child: Text("Annuler",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
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
                                  "Modification en cours",
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
                                  print(
                                      'Message when the notification is dismissed');
                                },
                              ).show(context);

                              await _updateCommentaire(idCommentaire);
                              //Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Text("Mettre à jour",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                widget.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Hero(
                          tag: "article-${widget.title}",
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            child: Image.network(
                              widget.image,
                              height: 250,
                              width: double.infinity,
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
                                  height: 250,
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
                                  height: 250.0,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 250.0,
                                      color:
                                          context.watch<ThemeProvider>().isDark
                                              ? Color.fromRGBO(102, 102, 102, 1)
                                              : Colors.grey[300],
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: toggleLike,
                                        icon: Icon(
                                          isLiked
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_off_alt,
                                          color: isLiked
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${likes} Likes',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: toggleFavorite,
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorite
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        isFavorite ? 'Favoris' : 'Non Favoris',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Share.share(
                                    '📢 *${widget.title}*\n\n${widget.excerpt}\n\nEn savoir plus :\n${widget.content}',
                                    subject: 'Partagez cet article',
                                  );
                                },
                                icon: const Icon(
                                  Icons.share,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text("Partager"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 0, 60, 255),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            textAlign: TextAlign.center,
                            widget.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 70 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: /* Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              textAlign: TextAlign.justify,
                              widget.content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ), */
                              ExpandableText(content: widget.content),
                        ),
                        const Divider(thickness: 1, color: Colors.grey),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Commentaires sur l'article",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: ApiService().getAllCommentsStream(
                                      widget.id_article,
                                      limit: commentsLimit),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Erreur : ${snapshot.error}"));
                                    }

                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Aucun commentaire",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    List<Map<String, dynamic>> comments =
                                        snapshot.data!;
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: comments.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              (comments[index]['image'] !=
                                                          null ||
                                                      comments[index]['image']!
                                                          .isNotEmpty)
                                                  ? GestureDetector(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return Dialog(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              child: Stack(
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            15),
                                                                    child: Hero(
                                                                      tag:
                                                                          "profile_image",
                                                                      child:
                                                                          InteractiveViewer(
                                                                        panEnabled:
                                                                            true,
                                                                        boundaryMargin: const EdgeInsets
                                                                            .all(
                                                                            20),
                                                                        minScale:
                                                                            0.5,
                                                                        maxScale:
                                                                            3.0,
                                                                        child: (comments[index]['image']!) !=
                                                                                ""
                                                                            ? Image.network(
                                                                                comments[index]['image']!,
                                                                                fit: BoxFit.contain,
                                                                                width: double.infinity,
                                                                              )
                                                                            : SizedBox(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Positioned(
                                                                    top: 10,
                                                                    right: 10,
                                                                    child:
                                                                        GestureDetector(
                                                                      onTap: () =>
                                                                          Navigator.pop(
                                                                              context),
                                                                      child:
                                                                          const CircleAvatar(
                                                                        backgroundColor:
                                                                            Colors.black54,
                                                                        radius:
                                                                            18,
                                                                        child: Icon(
                                                                            Icons
                                                                                .close,
                                                                            color:
                                                                                Colors.white,
                                                                            size: 22),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: ClipOval(
                                                        child: Image.network(
                                                          comments[index]
                                                              ['image']!,
                                                          width: 35,
                                                          height: 35,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context,
                                                              child,
                                                              loadingProgress) {
                                                            if (loadingProgress ==
                                                                null)
                                                              return child;

                                                            final totalBytes =
                                                                loadingProgress
                                                                    .expectedTotalBytes;
                                                            final loadedBytes =
                                                                loadingProgress
                                                                    .cumulativeBytesLoaded;

                                                            final percentage = totalBytes !=
                                                                    null
                                                                ? (loadedBytes /
                                                                        totalBytes *
                                                                        100)
                                                                    .toStringAsFixed(
                                                                        0)
                                                                : null;

                                                            return SizedBox(
                                                              width: 35,
                                                              height: 35,
                                                              child: Stack(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                children: [
                                                                  SizedBox(
                                                                    width: 25,
                                                                    height: 25,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      value: totalBytes !=
                                                                              null
                                                                          ? loadedBytes /
                                                                              totalBytes
                                                                          : null,
                                                                      backgroundColor: Colors
                                                                          .grey
                                                                          .shade300,
                                                                      valueColor: AlwaysStoppedAnimation<
                                                                              Color>(
                                                                          Colors
                                                                              .blueGrey),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return CircleAvatar(
                                                              radius: 18,
                                                              backgroundColor:
                                                                  Colors
                                                                      .blueGrey,
                                                              child: Icon(
                                                                  Icons.person,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 18),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    )
                                                  : CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor:
                                                          Colors.blueGrey,
                                                      child: Icon(Icons.person,
                                                          color: Colors.white,
                                                          size: 18),
                                                    ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[800]
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        comments[index]
                                                            ["author"],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        comments[index]["text"],
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            formatTimestamp(
                                                                comments[index][
                                                                    "created_at"]),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Colors
                                                                      .white60
                                                                  : Colors
                                                                      .black54,
                                                            ),
                                                          ),
                                                          if (canDeleteComment(
                                                              comments[index][
                                                                  "id_utilisateur"]))
                                                            IconButton(
                                                              icon: Icon(
                                                                  size: 18,
                                                                  Icons.edit,
                                                                  color: const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      112,
                                                                      90,
                                                                      16)),
                                                              onPressed:
                                                                  () async {
                                                                await showEditingDialog(
                                                                    context,
                                                                    comments[
                                                                            index]
                                                                        [
                                                                        "id_commentaire"],
                                                                    comments[
                                                                            index]
                                                                        [
                                                                        "text"]);
                                                              },
                                                            ),
                                                          if (canDeleteComment(
                                                              comments[index][
                                                                  "id_utilisateur"]))
                                                            IconButton(
                                                              icon: Icon(
                                                                  size: 18,
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red),
                                                              onPressed:
                                                                  () async {
                                                                await showDeleteConfirmationDialog(
                                                                    context,
                                                                    comments[
                                                                            index]
                                                                        [
                                                                        "id_commentaire"]);
                                                              },
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                              commentsAll.length > commentsLimit
                                  ? Center(
                                      child: TextButton(
                                        onPressed: loadMoreComments,
                                        child:
                                            const Text("Plus de commentaires"),
                                      ),
                                    )
                                  : SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (image != null || image!.isNotEmpty)
                                      ? ClipOval(
                                          child: Image.network(
                                            image!,
                                            width: 35,
                                            height: 35,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;

                                              final totalBytes = loadingProgress
                                                  .expectedTotalBytes;
                                              final loadedBytes =
                                                  loadingProgress
                                                      .cumulativeBytesLoaded;

                                              final percentage =
                                                  totalBytes != null
                                                      ? (loadedBytes /
                                                              totalBytes *
                                                              100)
                                                          .toStringAsFixed(0)
                                                      : null;

                                              return SizedBox(
                                                width: 35,
                                                height: 35,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 25,
                                                      height: 25,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        value:
                                                            totalBytes != null
                                                                ? loadedBytes /
                                                                    totalBytes
                                                                : null,
                                                        backgroundColor: Colors
                                                            .grey.shade300,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors
                                                                    .blueGrey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    Colors.blueGrey,
                                                child: Icon(Icons.person,
                                                    color: Colors.white,
                                                    size: 18),
                                              );
                                            },
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.blueGrey,
                                          child: Icon(Icons.person,
                                              color: Colors.white, size: 18),
                                        ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: commentController,
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        hintText: "Ajoutez un commentaire...",
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () async {
                                      if (commentController.text.isNotEmpty) {
                                        addComment(commentController.text);
                                      } else {
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
                                          toastDuration: Duration(seconds: 3),
                                          onDismiss: () {
                                            print(
                                                'Message when the notification is dismissed');
                                          },
                                        ).show(context);
                                      }
                                    },
                                    icon: const Icon(Icons.send,
                                        color:
                                            Color.fromARGB(255, 15, 70, 119)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
      ),
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
}
