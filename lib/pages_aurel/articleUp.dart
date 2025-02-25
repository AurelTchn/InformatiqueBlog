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
import 'package:image_picker/image_picker.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/articledetails.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_aurel/updateCategorie.dart';
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

//Cloudinary
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class ModifyArticles extends StatefulWidget {
  const ModifyArticles({super.key, required this.uid});

  final String uid;

  @override
  State<ModifyArticles> createState() => _ModifyArticlesState();
}

class _ModifyArticlesState extends State<ModifyArticles> {
  bool isLoading = false;
  List<Map<String, dynamic>> articles = [];
  List<Map<String, dynamic>> filteredArticles = [];

  final TextEditingController searchController = TextEditingController();
  List<bool> isItemVisible = [];
  bool isLiked = false;
  bool isProcessing = false;
  bool isProcessingFavorite = false;

  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "";

  @override
  void initState() {
    // TODO: implement initState
    _load_articles();
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _uploadImageToCloudinary(File imageFile) async {
    try {
      print("🔹 Début de l'upload de l'image... ${imageFile}");

      var response = await cloudinary.uploader().upload(
            imageFile,
            params: UploadParams(
              publicId: '${DateTime.now().millisecondsSinceEpoch}',
              uniqueFilename: false,
              folder: 'myimages',
              overwrite: true,
            ),
          );

      print("✅ Upload réussi : ${response?.data?.secureUrl}");
      return response?.data?.secureUrl ?? '';
    } catch (e) {
      print("❌ Erreur lors de l'upload vers Cloudinary: $e");
      return '';
    }
  }

  void _showUpdateArticleDialog(BuildContext context, String idArticle,
      String initialTitle, String initialSubtitle, String initialContent) {
    final _formKey1 = GlobalKey<FormState>();
    final TextEditingController _titleController =
        TextEditingController(text: initialTitle);
    final TextEditingController _subtitleController =
        TextEditingController(text: initialSubtitle);
    final TextEditingController _contentController =
        TextEditingController(text: initialContent);
    String? _selectedCategory;
    File? _pickedImage1;
    // Fonction pour envoyer les données à Firebase
    Future<void> _createArticles() async {
      try {
        if (_formKey1.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);
          // Récupérer les données actuelles de l'article depuis Firestore
          DocumentSnapshot articleSnapshot = await FirebaseFirestore.instance
              .collection('articles')
              .doc(idArticle)
              .get();

          if (!articleSnapshot.exists) {
            print("Erreur : L'article n'existe pas.");
            return;
          }

          Map<String, dynamic> articleData =
              articleSnapshot.data() as Map<String, dynamic>;

          String imageUrl = articleData['image'] ?? 'defaultimage.jpeg';

          if (_pickedImage1 != null) {
            print("L'image selectionné est ${_pickedImage1}");

            // Si une image a été choisie, on la télécharge sur Cloudinary
            imageUrl =
                await _uploadImageToCloudinary(File(_pickedImage1!.path)!);
          } else {
            print("L'image qui n'est pas selectionné est ${_pickedImage1}");
          }

          // Récupération de Firestore
          CollectionReference articles =
              FirebaseFirestore.instance.collection('articles');

          // Création du document et récupération de son ID
          DocumentReference docRef = articles.doc();
          String uidArticle = docRef.id;

          // Données de la catégorie
          final upadtearticleData = {
            'contenu': _contentController.text,
            'image': imageUrl,
            'sous_titre': _subtitleController.text,
            'titre': _titleController.text,
            'updateAt': FieldValue.serverTimestamp(),
          };

          // Mise à jour du document
          await articles.doc(idArticle).update(upadtearticleData);

          await _load_articles();

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
              "Article madifié",
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

          //Navigator.pop(context);
        }
      } catch (e) {
        print("Erreur lors de la création de la catégorie ${e}");
      } finally {
        setState(() {
          _subtitleController.clear();
          _titleController.clear();
          _contentController.clear();
          _pickedImage1 = null;
          isLoading = false;
        });
      }
    }

    Future<void> _deleteArticles() async {
      try {
        if (_formKey1.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);
          // Récupérer les données actuelles de l'article depuis Firestore
          DocumentSnapshot articleSnapshot = await FirebaseFirestore.instance
              .collection('articles')
              .doc(idArticle)
              .get();

          if (!articleSnapshot.exists) {
            print("Erreur : L'article n'existe pas.");
            return;
          }

          FirebaseFirestore firestore = FirebaseFirestore.instance;
          // Supprimer l'article de la collection 'articles'
          await firestore.collection('articles').doc(idArticle).delete();

          // Récupérer tous les utilisateurs
          QuerySnapshot usersSnapshot =
              await firestore.collection('utilisateurs').get();

          WriteBatch batch =
              firestore.batch(); 

          for (var userDoc in usersSnapshot.docs) {
            String userId = userDoc.id;

            // Supprimer dans favorite_articles
            QuerySnapshot favoriteSnapshot = await firestore
                .collection('utilisateurs')
                .doc(userId)
                .collection('favorite_articles')
                .where('uid_article', isEqualTo: idArticle)
                .get();

            for (var favDoc in favoriteSnapshot.docs) {
              batch.delete(favDoc.reference);
            }

            // Supprimer dans liked_articles
            QuerySnapshot likesSnapshot = await firestore
                .collection('utilisateurs')
                .doc(userId)
                .collection('liked_articles')
                .where('uid_article', isEqualTo: idArticle)
                .get();

            for (var likeDoc in likesSnapshot.docs) {
              batch.delete(likeDoc.reference);
            }
          }

          // Appliquer toutes les suppressions en une seule requête
          await batch.commit();

          /* await FirebaseFirestore.instance
              .collection('articles')
              .doc(idArticle)
              .delete();

          QuerySnapshot usersSnapshot =
              await FirebaseFirestore.instance.collection('utilisateurs').get();

          for (var userDoc in usersSnapshot.docs) {
            String userId = userDoc.id;

            // Référence à la sous-collection favorite_articles de cet utilisateur
            CollectionReference favoriteArticlesRef = FirebaseFirestore.instance
                .collection('utilisateurs')
                .doc(userId)
                .collection('favorite_articles');

            // Récupérer tous les documents de la sous-collection
            QuerySnapshot favoriteSnapshot = await favoriteArticlesRef.get();

            for (var favDoc in favoriteSnapshot.docs) {
              Map<String, dynamic> data = favDoc.data() as Map<String, dynamic>;

              // Vérifier si le document contient 'articleId' et si sa valeur correspond à idArticle
              if (data.containsKey('uid_article') &&
                  data['uid_article'] == idArticle) {
                await favoriteArticlesRef.doc(favDoc.id).delete();
              }
            }

            // Référence à la sous-collection favorite_articles de cet utilisateur
            CollectionReference likesArticlesRef = FirebaseFirestore.instance
                .collection('utilisateurs')
                .doc(userId)
                .collection('liked_articles');

            // Récupérer tous les documents de la sous-collection
            QuerySnapshot likesSnapshot = await likesArticlesRef.get();

            for (var likeDoc in likesSnapshot.docs) {
              Map<String, dynamic> data = likeDoc.data() as Map<String, dynamic>;

              // Vérifier si le document contient 'articleId' et si sa valeur correspond à idArticle
              if (data.containsKey('uid_article') &&
                  data['uid_article'] == idArticle) {
                await likesArticlesRef.doc(likeDoc.id).delete();
              }
            }
          } */

          await _load_articles();

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
              "Article supprimé",
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

          //Navigator.pop(context);
        }
      } catch (e) {
        print("Erreur lors de la suppression de l'article ${e}");
      } finally {
        setState(() {
          _subtitleController.clear();
          _titleController.clear();
          _contentController.clear();
          _pickedImage1 = null;
          isLoading = false;
        });
      }
    }

    Future<void> _pickImage1() async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print("📸 Image sélectionnée : ${pickedFile.path}");
        setState(() {
          _pickedImage1 = File(pickedFile.path);
        });
      } else {
        print("⚠️ Aucune image sélectionnée !");
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeOutBack,
              ),
              child: AlertDialog(
                title: const Text(
                  'Nouvel article',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Champ Titre
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: "Titre de l'article",
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            filled: true,
                            fillColor: context.watch<ThemeProvider>().isDark
                                ? Color.fromRGBO(66, 66, 66, 1)
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Veuillez entrer un titre'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Champ Sous-titre
                        TextFormField(
                          controller: _subtitleController,
                          decoration: InputDecoration(
                            labelText: "Sous-titre",
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            filled: true,
                            fillColor: context.watch<ThemeProvider>().isDark
                                ? Color.fromRGBO(66, 66, 66, 1)
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Veuillez entrer un sous-titre'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Champ Contenu
                        TextFormField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: "Contenu",
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            filled: true,
                            fillColor: context.watch<ThemeProvider>().isDark
                                ? Color.fromRGBO(66, 66, 66, 1)
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Veuillez entrer le contenu'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Sélection d'image
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Sélectionner une image",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                await _pickImage1();
                                setStateDialog(() {});
                              },
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: context.watch<ThemeProvider>().isDark
                                      ? Color.fromRGBO(66, 66, 66, 1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: _pickedImage1 == null
                                    ? const Icon(Icons.add_a_photo,
                                        size: 40, color: Colors.grey)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(_pickedImage1!,
                                            fit: BoxFit.cover),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey1.currentState!.validate()) {
                                    _createArticles();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Mettre à jour',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.warning_amber_rounded,
                                                  size: 50, color: Colors.red),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Supprimer l'article ?",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: context
                                                          .watch<
                                                              ThemeProvider>()
                                                          .isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Voulez-vous vraiment supprimer cet article ? Cette action est irréversible.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: context
                                                            .watch<
                                                                ThemeProvider>()
                                                            .isDark
                                                        ? Colors.white
                                                        : Colors.black54),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      side: BorderSide(
                                                          color: Colors.grey),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text("Annuler",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.grey)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _deleteArticles();
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text("Supprimer",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );

                                  //_deleteArticles();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                  padding: EdgeInsets.all(12),
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 28, // Icône légèrement plus grande
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _load_articles() async {
    setState(() {
      isLoading = true;
    });
    print("L'identifiant de la personne qui s'est authentifié ${widget.uid}");
    try {
      // Récupérer les articles à partir du backend
      List<Map<String, dynamic>> fetchedArticles =
          await ApiService().fetchArticlesFromFirestore(widget.uid);
      print("Listes des articles $fetchedArticles");
      setState(() {
        isLoading = false;
        articles = fetchedArticles;
        filteredArticles = fetchedArticles;
        isItemVisible = List<bool>.filled(filteredArticles.length, false);
      });
    } catch (e) {
      print('Erreur lors du chargement des articles : $e');
      setState(() {
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
              "Modifier un article",
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
                        "Veuillez cliquer sur l'article à modifier!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
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
                              return VisibilityDetector(
                                  key: Key('category_$index'),
                                  onVisibilityChanged: (visibilityInfo) {
                                    final visiblePercentage =
                                        visibilityInfo.visibleFraction * 100;

                                    if (visiblePercentage > 50 &&
                                        !isItemVisible[index]) {
                                      setState(() {
                                        isItemVisible[index] = true;
                                      });
                                    }
                                  },
                                  child: isItemVisible[index]
                                      ? FadeIn(
                                          duration:
                                              const Duration(milliseconds: 600),
                                          child: _buildArticleCard(
                                            index,
                                            article['id_article'],
                                            article['titre'],
                                            article['image'],
                                            article['content'],
                                            article['sous_titre'],
                                          ),
                                        )
                                      : FadeIn(
                                          duration:
                                              const Duration(milliseconds: 600),
                                          child: _buildArticleCard(
                                            index,
                                            article['id_article'],
                                            article['titre'],
                                            article['image'],
                                            article['content'],
                                            article['sous_titre'],
                                          ),
                                        ));
                            },
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
    String idArticle,
    String title,
    String image,
    String content,
    String sous_titre,
  ) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: () {
        _showUpdateArticleDialog(
            context, idArticle, title, sous_titre, content);
        setState(() {});
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

                    // Calcul du pourcentage chargé
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
                          ? Color.fromRGBO(66, 66, 66, 1)
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
