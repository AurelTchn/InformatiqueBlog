import 'dart:io';

import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/articleUp.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_aurel/pageUpcategorie.dart';
import 'package:informatiqueblog/pages_aurel/updateCategorie.dart';
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
import 'package:intl/intl.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:provider/provider.dart';
import '../pages_aurel/theme_provider.dart';

//Cloudinary
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.uid});
  final String uid;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  File? _pickedImage;
  String _image = 'defaultimage.jpeg';
  bool isLoading = false;
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> contactsAll = [];

  //Variable pour les articles
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedCategory;
  File? _pickedImage1;

  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "";

  int countUsers = 0;
  int countArticles = 0;
  int countCategories = 0;
  int countComments = 0;

  int contactLimite = 3;

  late Future<List<Map<String, String>>> categoriesFuture;
  List<Map<String, String>> filteredCategories = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    categoriesFuture = _loadCategories();
    fetchUserData(widget.uid);
    getUsersCount();
    getArticlesCount();
    getCategoriesCount();
    getCommentsCount();
    _loadcontacts();
  }

  void loadMoreContact()  async{
    contactLimite += 2;
    List<Map<String, dynamic>> fetchedContacts =
          await ApiService().getAllContacts(limite: contactLimite);
    setState(()  {
      contacts = fetchedContacts;
    });
  }

  Future<void> _loadcontacts() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> fetchedContacts =
          await ApiService().getAllContacts(limite: contactLimite);
          List<Map<String, dynamic>> fetchedContactsAll =
          await ApiService().getAllContactsAll();
      setState(() {
        contactsAll = fetchedContactsAll;
        contacts = fetchedContacts;
        print("Voici la liste de contacts ${contacts}");
      });
    } catch (e) {
      print("Erreur lors de la récupération des contacts ${e}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getUsersCount() async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberUsers = await ApiService().getAllUsersCount();
      setState(() {
        countUsers = numberUsers;
      });
    } catch (e) {
      print("Erreur lors de la récupération du nombres d'utilisateur : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getArticlesCount() async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberArticle = await ApiService().getAllArticlesCount();
      setState(() {
        countArticles = numberArticle;
      });
    } catch (e) {
      print("Erreur lors de la récupération du nombres d'articles : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getCategoriesCount() async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberCategorie = await ApiService().getAllCategoriesCount();
      setState(() {
        countCategories = numberCategorie;
      });
    } catch (e) {
      print("Erreur lors de la récupération du nombres de categorie : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getCommentsCount() async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberComments = await ApiService().getAllCommentsCount();
      setState(() {
        countComments = numberComments;
      });
    } catch (e) {
      print("Erreur lors de la récupération du nombres de commentaires : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  Future<List<Map<String, String>>> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les catégories depuis Firestore
      final categories = await ApiService().fetchCategoriesFromFirestore();
      print("Voici la liste des catégories $categories");

      setState(() {
        filteredCategories = categories;
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

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    // Vérification du type et conversion en Timestamp si nécessaire
    Timestamp? date;
    if (timestamp is FieldValue) {
      // Si c'est un FieldValue, on attend un Timestamp après la récupération
      date = Timestamp
          .now();
    } else if (timestamp is Timestamp) {
      date = timestamp;
    }

    // Vérifiez que date n'est pas null avant de formater
    if (date != null) {
      DateTime dateTime = date.toDate(); 
      return DateFormat('dd MMM yyyy, hh:mm a')
          .format(dateTime); 
    }
    return '';
  }

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

  bool canExit = false;

  @override
  Widget build(BuildContext context) {
    // Déterminer si on est sur mobile en fonction de la largeur d'écran
    final bool isMobile = MediaQuery.of(context).size.width < 600;
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
          backgroundColor: context.watch<ThemeProvider>().isDark
              ? Colors.black
              : const Color(0xFFF5F7FB),
          
          appBar: AppBar(
            title: Text(
              textAlign: TextAlign.center,
              'Tableau de bord',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              : isMobile
                  ? _buildMobileLayout()
                  : Row(
                      children: [
                        _buildSidebar(),
                        Expanded(
                          child: _buildMainContent(),
                        ),
                      ],
                    ),
         
        ),
      ),
    );
  }

  // Fonction pour télécharger l'image sur Cloudinary et récupérer l'URL
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

  void _showAddCategoryDialog(BuildContext context) {
    // Fonction pour envoyer les données à Firebase
    Future<void> _createCategory() async {
      try {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);
          String imageUrl = _image; 

          if (_pickedImage != null) {
            print("L'image selectionné est ${_pickedImage}");

            // Si une image a été choisie, on la télécharge sur Cloudinary
            imageUrl =
                await _uploadImageToCloudinary(File(_pickedImage!.path)!);
          }

          // Récupération de Firestore
          CollectionReference categories =
              FirebaseFirestore.instance.collection('categories');

          // Création du document et récupération de son ID
          DocumentReference docRef = categories.doc();
          String uidCategorie = docRef.id; 

          // Données de la catégorie
          final categoryData = {
            'uid_categorie': uidCategorie,
            'nom': _nameController.text,
            'description': _descriptionController.text,
            'image': imageUrl,
          };

          // Ajout des données dans Firestore
          await docRef.set(categoryData);

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
              "Catégorie ajoutée",
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
                  'Nouvelle catégorie',
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
                        child: ElevatedButton(
                          onPressed: (){
                            if(_formKey.currentState!.validate()){
                              _createCategory();
                            }
                          } ,
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
                            'Créer la catégorie',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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

  void _showAddArticleDialog(BuildContext context) {
    // Fonction pour envoyer les données à Firebase
    Future<void> _createArticles() async {
      try {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context); 
          String imageUrl = _image; 

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
          final articleData = {
            'uid': uidArticle,
            'comments': 0,
            'contenu': _contentController.text,
            'id_auteur': 'Techblog',
            'image': imageUrl,
            'likes': 0,
            'pdf': '',
            'shares': 0,
            'sous_titre': _subtitleController.text,
            'titre': _titleController.text,
            'uid_categorie': _selectedCategory,
            'createdAt': FieldValue.serverTimestamp(),
            'updateAt': "",
          };

          // Ajout des données dans Firestore
          await docRef.set(articleData);

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
              "Article ajouté",
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
          _nameController.clear();
          _descriptionController.clear();
          _subtitleController.clear();
          _titleController.clear();
          _contentController.clear();
          _pickedImage1 = null;
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
                    key: _formKey,
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
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.watch<ThemeProvider>().isDark
                                      ? Colors.white
                                      : Colors.blue,
                                )),
                           
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

                        // Sélection de la catégorie
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Catégorie",
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            filled: true,
                            fillColor: context.watch<ThemeProvider>().isDark
                                ? Color.fromRGBO(66, 66, 66, 1)
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          value: _selectedCategory,
                          items: filteredCategories
                              .map((category) => DropdownMenuItem(
                                    value: category[
                                        'id'], 
                                    child: SizedBox(
                                      width: 180,
                                      child: Text(
                                        category['nom'] ?? "Sans nom",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) => value == null
                              ? "Sélectionner la catégorie"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Bouton de soumission
                        Center(
                          child: ElevatedButton(
                            onPressed: (){
                              if(_formKey.currentState!.validate()){
                                _createArticles();
                              }
                            } ,
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
                              'Ajouter l\'article',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildMobileLayout() {
    return _buildMainContent();
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article),
          label: 'Articles',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.comment),
          label: 'Comments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return NavigationRail(
      extended: true,
      backgroundColor: Colors.white,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text(
            'Tableau de bord',
            style: TextStyle(fontSize: 18),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.article),
          label: Text('Articles'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.comment),
          label: Text('Commentaires'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Utilisateurs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.category),
          label: Text('Catégories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Paramètres'),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatCards(),
          /* const SizedBox(height: 16),
          _buildCharts(),
          const SizedBox(height: 16),
          _buildRecentActivities(),
          const SizedBox(height: 16),
          _buildPopularArticles(), */
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Messages des contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 50,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Aucun message reçu",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final theme = Theme.of(context);

                          Color textColor =
                              context.watch<ThemeProvider>().isDark
                                  ? Colors.white70
                                  : Colors.black87;
                          Color titleColor =
                              context.watch<ThemeProvider>().isDark
                                  ? Colors.white
                                  : Colors.black;
                          Color backgroundColor =
                              context.watch<ThemeProvider>().isDark
                                  ? Colors.grey[600]!
                                  : Colors.grey[200]!;

                          Widget buildInfoRow(String label, String value) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$label : ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: titleColor),
                                ),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                        fontSize: 14, color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.watch<ThemeProvider>().isDark
                                    ? Color.fromRGBO(66, 66, 66, 1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  (contact['image'] != null ||
                                          contact['image']!.isNotEmpty)
                                      ? GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        child: Hero(
                                                          tag: "profile_image",
                                                          child:
                                                              InteractiveViewer(
                                                            panEnabled:
                                                                true, 
                                                            boundaryMargin:
                                                                const EdgeInsets
                                                                    .all(20),
                                                            minScale: 0.5,
                                                            maxScale:
                                                                3.0, 
                                                            child: (contact[
                                                                        'image']!) !=
                                                                    ""
                                                                ? Image.network(
                                                                    contact[
                                                                        'image']!,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                    width: double
                                                                        .infinity,
                                                                  )
                                                                : SizedBox(),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 10,
                                                        right: 10,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child:
                                                              const CircleAvatar(
                                                            backgroundColor:
                                                                Colors.black54,
                                                            radius: 18,
                                                            child: Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
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
                                              contact['image']!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;

                                                final totalBytes =
                                                    loadingProgress
                                                        .expectedTotalBytes;
                                                final loadedBytes =
                                                    loadingProgress
                                                        .cumulativeBytesLoaded;

                                                // Calcul du pourcentage chargé
                                                final percentage =
                                                    totalBytes != null
                                                        ? (loadedBytes /
                                                                totalBytes *
                                                                100)
                                                            .toStringAsFixed(0)
                                                        : null;

                                                return SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          value: totalBytes !=
                                                                  null
                                                              ? loadedBytes /
                                                                  totalBytes
                                                              : null,
                                                        ),
                                                        //const SizedBox(height: 8),
                                                        Text(
                                                          percentage != null
                                                              ? "$percentage%"
                                                              : "Chargement...",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 5,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                // Si même l'image par défaut échoue, afficher une icône
                                                return CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor:
                                                      Colors.blueGrey,
                                                  child: Icon(Icons.person,
                                                      color: Colors.white,
                                                      size: 25),
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.blueGrey,
                                          child: Icon(Icons.person,
                                              color: Colors.white, size: 25),
                                        ),
                                  const SizedBox(height: 10),
                                  Text(
                                    contact["fullname"],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  buildInfoRow("Sujet", contact["sujet"]),
                                  buildInfoRow(
                                      "Raison", contact["raison_contact"]),
                                  const SizedBox(height: 5),
                                  Text(
                                    contact["message"],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14, color: textColor),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    formatTimestamp(contact["createdAt"]),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: context
                                                .watch<ThemeProvider>()
                                                .isDark
                                            ? Colors.white60
                                            : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                contactsAll.length > contactLimite
                    ? Center(
                        child: TextButton(
                          onPressed: ()async{loadMoreContact();} ,
                          child: const Text("Plus de contacts"),
                        ),
                      )
                    : SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  Text(
                    'Bienvenue dans votre espace administrateur',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10, 
                alignment: WrapAlignment.center, 
                children: [
                  _buildButton(
                    icon: Icons.add,
                    text: 'Article',
                    onPressed: () {
                      _showAddArticleDialog(context);
                      setState(() {});
                    },
                  ),
                  _buildButton(
                    icon: Icons.edit,
                    text: 'Article',
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 600),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ModifyArticles(uid: widget.uid),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  _buildButton(
                    icon: Icons.add,
                    text: 'Catégorie',
                    onPressed: () {
                      _showAddCategoryDialog(context);
                      setState(() {});
                    },
                  ),
                  _buildButton(
                    icon: Icons.edit,
                    text: 'Catégorie',
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 600),
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ModifyCategorie(uid: widget.uid),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bienvenue dans votre espace administrateur',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _showAddCategoryDialog(context);
                      setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle catégorie'),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://picsum.photos/200'),
                  ),
                ],
              ),
            ],
          );
  }

  // Fonction pour créer des boutons réutilisables
  Widget _buildButton(
      {required IconData icon,
      required String text,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.blue),
        label: Text(text, style: const TextStyle(color: Colors.blue)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 2 : 4;
    final childAspectRatio = isMobile ? 1.3 : 1.5;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Articles totaux',
          countArticles.toString(),
          Icons.article,
          Colors.blue,
          'articles',
        ),
        _buildStatCard(
          'Catégories totales',
          countCategories.toString(),
          Icons.remove_red_eye,
          Colors.green,
          'catégories',
        ),
        _buildStatCard(
          'Commentaires',
          countComments.toString(),
          Icons.comment,
          Colors.orange,
          'commentaires',
        ),
        _buildStatCard(
          'Utilisateurs',
          countUsers.toString(),
          Icons.people,
          Colors.purple,
          'utilisateurs',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.watch<ThemeProvider>().isDark
            ? Color.fromRGBO(66, 66, 66, 1)
            : Colors.white,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            trend,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return isMobile
        ? Column(
            children: [
              _buildLineChart(),
              const SizedBox(height: 16),
              _buildPieChart(),
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildLineChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPieChart(),
              ),
            ],
          );
  }

  Widget _buildLineChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.watch<ThemeProvider>().isDark
            ? Color.fromRGBO(66, 66, 66, 1)
            : Colors.white,
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
          const Text(
            'Statistiques des vues',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(2.6, 2),
                      const FlSpot(4.9, 5),
                      const FlSpot(6.8, 3.1),
                      const FlSpot(8, 4),
                      const FlSpot(9.5, 3),
                      const FlSpot(11, 4),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.watch<ThemeProvider>().isDark
            ? Color.fromRGBO(66, 66, 66, 1)
            : Colors.white,
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
          const Text(
            'Catégories populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue,
                    value: 40,
                    title: 'Web',
                    radius: 50,
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: 30,
                    title: 'Mobile',
                    radius: 50,
                  ),
                  PieChartSectionData(
                    color: Colors.green,
                    value: 15,
                    title: 'DevOps',
                    radius: 50,
                  ),
                  PieChartSectionData(
                    color: Colors.purple,
                    value: 15,
                    title: 'Data',
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.watch<ThemeProvider>().isDark
            ? Color.fromRGBO(66, 66, 66, 1)
            : Colors.white,
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
          const Text(
            'Activités récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildActivityItem(
            'Nouvel article publié',
            'Introduction à Flutter 3.0',
            '2 minutes',
            Icons.article,
            Colors.blue,
          ),
          _buildActivityItem(
            'Nouveau commentaire',
            'Super article sur React Native !',
            '15 minutes',
            Icons.comment,
            Colors.green,
          ),
          _buildActivityItem(
            'Nouvel utilisateur',
            'Jean Dupont a rejoint la plateforme',
            '1 heure',
            Icons.person,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularArticles() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.watch<ThemeProvider>().isDark
            ? Color.fromRGBO(66, 66, 66, 1)
            : Colors.white,
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
          const Text(
            'Articles populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          isMobile ? _buildMobileArticlesList() : _buildDesktopArticlesTable(),
        ],
      ),
    );
  }

  Widget _buildMobileArticlesList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMobileArticleItem(
          'Les bases de React',
          'John Doe',
          '1.2K',
          '2023-12-15',
        ),
        _buildMobileArticleItem(
          'Python pour débutants',
          'Alex Brown',
          '856',
          '2023-12-13',
        ),
        _buildMobileArticleItem(
          'Guide Docker',
          'Sarah Wilson',
          '742',
          '2023-12-12',
        ),
      ],
    );
  }

  Widget _buildMobileArticleItem(
    String title,
    String author,
    String views,
    String date,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  author,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  views,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {},
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopArticlesTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Titre',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Auteur',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Vues',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        _buildTableRow(
          'Les bases de React',
          'John Doe',
          '1.2K',
          '2023-12-15',
        ),
        _buildTableRow(
          'Python pour débutants',
          'Alex Brown',
          '856',
          '2023-12-13',
        ),
        _buildTableRow(
          'Guide Docker',
          'Sarah Wilson',
          '742',
          '2023-12-12',
        ),
      ],
    );
  }

  TableRow _buildTableRow(
    String title,
    String author,
    String views,
    String date,
  ) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(author),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(views),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(date),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {},
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {},
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
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
}
