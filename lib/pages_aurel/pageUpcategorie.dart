import 'dart:io';

import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
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

//Cloudinary
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class ModifyCategorie extends StatefulWidget {
  const ModifyCategorie({Key? key, required this.uid}) : super(key: key);

  final String uid;
  @override
  State<ModifyCategorie> createState() => _ModifyCategorieState();
}

class _ModifyCategorieState extends State<ModifyCategorie>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> filteredCategories = [];
  List<Map<String, dynamic>> categories = [];
  late Future<List<Map<String, dynamic>>> categoriesFuture;
  late ScrollController _scrollController;
  List<int> _visibleItems = [];
  final Duration animationDuration = Duration(milliseconds: 500);

  List<bool> isItemVisible = [];
  bool isLoading = false;

  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "user";

  File? _pickedImage;

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

  void _showAddCategoryDialog(BuildContext context, String categoryId,
      String initialName, String initialDescription) {
    final _formKey = GlobalKey<FormState>();

    TextEditingController _nameController =
        TextEditingController(text: initialName);
    TextEditingController _descriptionController =
        TextEditingController(text: initialDescription);
    // Fonction pour envoyer les données à Firebase
    Future<void> _updateCategory(String idCategorie) async {
      try {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);

          // Récupérer les données actuelles de la catégorie depuis Firestore
          DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(idCategorie)
              .get();

          if (!categorySnapshot.exists) {
            print("Erreur : La catégorie n'existe pas.");
            return;
          }

          Map<String, dynamic> categoryData =
              categorySnapshot.data() as Map<String, dynamic>;

          String imageUrl = categoryData['image'] ?? 'defaultimage.jpeg';

          if (_pickedImage != null) {
            print("L'image selectionné est ${_pickedImage}");

            // Si une image a été choisie, on la télécharge sur Cloudinary
            imageUrl =
                await _uploadImageToCloudinary(File(_pickedImage!.path)!);
          }

          // Récupération de Firestore
          CollectionReference categories =
              FirebaseFirestore.instance.collection('categories');

          // Données à mettre à jour
          final updatedCategoryData = {
            'nom': _nameController.text,
            'description': _descriptionController.text,
            'image': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Mise à jour du document
          await categories.doc(idCategorie).update(updatedCategoryData);

          await _loadCategories();
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
              "Catégorie modifiée",
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
        }
      } catch (e) {
        print("Erreur lors de la création de la catégorie ${e}");
      } finally {
        setState(() {
          _nameController.clear();
          _descriptionController.clear();
          _pickedImage = null;
          isLoading = false;
        });
      }
    }

    Future<void> _deleteCategory(String idCategorie) async {
      try {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);

          // Récupérer les données actuelles de la catégorie depuis Firestore
          DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
              .collection('categories')
              .doc(idCategorie)
              .get();

          if (!categorySnapshot.exists) {
            print("Erreur : La catégorie n'existe pas.");
            return;
          }

          await FirebaseFirestore.instance
              .collection('categories')
              .doc(idCategorie)
              .delete();

          await _loadCategories();
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
              "Catégorie supprimée",
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
        }
      } catch (e) {
        print("Erreur lors de la création de la catégorie ${e}");
      } finally {
        setState(() {
          _nameController.clear();
          _descriptionController.clear();
          _pickedImage = null;
          isLoading = false;
        });
      }
    }

    Future<void> _pickImage() async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print("📸 Image sélectionnée : ${pickedFile.path}");
        setState(() {
          _pickedImage = File(pickedFile.path);
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
                  'Modifier une catégorie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                    child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Champ de nom
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Nom de la catégorie",
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          labelStyle: TextStyle(
                            color: context.watch<ThemeProvider>().isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          prefixIcon: Icon(Icons.category, color: Colors.teal),
                          filled: true,
                          fillColor: context.watch<ThemeProvider>().isDark
                              ? Colors.grey[900]
                              : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                                const BorderSide(color: Colors.teal, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nom de la catégorie';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ de description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          filled: true,
                          fillColor: context.watch<ThemeProvider>().isDark
                              ? Colors.grey[900]
                              : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sélection d'image
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sélectionner une image',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              await _pickImage();
                              setStateDialog(() {});
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: context.watch<ThemeProvider>().isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: _pickedImage == null
                                  ? const Icon(Icons.add_a_photo,
                                      size: 40, color: Colors.grey)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bouton de soumission
                      Center(
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  await _updateCategory(categoryId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Mettre à jour',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                                        borderRadius: BorderRadius.circular(16),
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
                                              "Supprimer la catégorie ?",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: context
                                                        .watch<ThemeProvider>()
                                                        .isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Voulez-vous vraiment supprimer cette catégorie ? Cette action est irréversible.",
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
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    side: BorderSide(
                                                        color: Colors.grey),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: Text("Annuler",
                                                      style: TextStyle(
                                                          color: Colors.grey)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _deleteCategory(categoryId);
                                                    Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: Text("Supprimer",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );

                                //_deleteCategory(categoryId);
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
                                size: 28, 
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            );
          },
        );
      },
    );
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
            title: const Text(
              'Modifier une catégorie',
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: TextField(
                        onChanged: (query) {
                          _filterCategories(query);
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
                          hintText: "Rechercher une catégorie...",
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
                    const SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 5.0),
                      child: Text(
                        "Veuillez cliquer sur la catégorie à modifier !",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredCategories.isEmpty
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
                                    "Aucune catégorie trouvée",
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
                          : ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredCategories.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16.0),
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];

                                return VisibilityDetector(
                                    key: Key('category_$index'),
                                    onVisibilityChanged: (visibilityInfo) {
                                      final visiblePercentage =
                                          visibilityInfo.visibleFraction * 100;

                                      if (visiblePercentage > 50 &&
                                          !isItemVisible[index]) {
                                        // Marquer l'élément comme visible
                                        setState(() {
                                          isItemVisible[index] = true;
                                        });
                                      } else if (visiblePercentage < 8) {
                                        // Réinitialiser l'état pour rejouer l'animation si l'élément quitte la vue
                                        isItemVisible[index] = false;
                                      }
                                    },
                                    child: isItemVisible[index]
                                        ? SlideInUp(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            child: _buildCategoryCard(category),
                                          )
                                        : SlideInUp(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            child: _buildCategoryCard(category),
                                          ));
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: () {
        _showAddCategoryDialog(context, category['id']!, category['nom']!,
            category['description']!);
        setState(() {});
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
                    borderRadius: BorderRadius.circular(8.0),
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
                          height: 100,
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
                        // Si l'image ne peut pas être chargée, afficher l'image par défaut depuis le backend
                        return Image.network(
                          '0assets/images/defaultimage.jpeg',
                          width: 100.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Si même l'image par défaut échoue, afficher une icône
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
}
