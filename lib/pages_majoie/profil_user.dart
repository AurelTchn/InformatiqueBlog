import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:informatiqueblog/main.dart';
import 'package:informatiqueblog/pages_aurel/apiservice.dart';
import 'package:informatiqueblog/pages_aurel/articledetails.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_majoie/admin_dashboard.dart';
import 'package:informatiqueblog/pages_majoie/apropos.dart';
import 'package:informatiqueblog/pages_majoie/auth_screen.dart';
import 'package:informatiqueblog/pages_majoie/contacts.dart';
import 'package:informatiqueblog/pages_majoie/home_screen.dart';
import 'package:informatiqueblog/pages_majoie/settings.dart';
import 'package:informatiqueblog/pages_majoie/statistiques.dart';
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:provider/provider.dart';
import '../pages_aurel/theme_provider.dart';

//Cloudinary
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class UserProfil extends StatefulWidget {
  const UserProfil({Key? key, required this.uid}) : super(key: key);
  final String uid;
  @override
  State<UserProfil> createState() => _UserProfilState();
}

class _UserProfilState extends State<UserProfil> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool isLoading = false;
  File? _pickedImage;
  String email = "user@gmail.com";
  String fullname = "User";
  String image = "";
  String role = "user";
  String bio = "Votre biographie";
  String location = "Votre location ...";

  int likedCount = 0;
  int favoriteCount = 0;
  int commentaireCount = 0;
  List<Map<String, dynamic>> filteredArticles = [];

  // Données simulées de l'utilisateur
  final Map<String, dynamic> userData = {
    'name': 'Liza Anderson',
    'email': 'liza@example.com',
    'role': 'Apprenant',
    'joinDate': '10 Jan 2024',
    'profileImage': null,
    'bio':
        'Passionnée par la technologie et le développement web. Toujours en quête de nouvelles connaissances.',
    'location': 'Paris, France',
    'interests': ['Web Development', 'Data Science', 'Mobile Apps', 'AI/ML'],
    'certificates': [
      {
        'name': 'Web Development Fundamentals',
        'date': 'Mars 2024',
        'issuer': 'TechBlog Academy'
      },
      {
        'name': 'Introduction to Data Science',
        'date': 'Février 2024',
        'issuer': 'TechBlog Academy'
      }
    ],
    'achievements': [
      {'name': 'Article Star', 'description': '10 articles publiés'},
      {'name': 'Active Learner', 'description': '5 cours terminés'},
      {'name': 'Community Helper', 'description': '50 commentaires utiles'}
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    fetchUserData(widget.uid);
    getCountLiked(widget.uid);
    getCountFavorite(widget.uid);
    getCountComments(widget.uid);
    getUserFavorite(widget.uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getUserFavorite(String uid) async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> favoriteArticle =
          await ApiService().getUserFavoriteArticles(uid);

      setState(() {
        filteredArticles = favoriteArticle;
      });
    } catch (e) {
      print(
          "Erreur lors de la récupération des articles favoris de l'utilisateur : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getCountLiked(String uid) async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberLikes = await ApiService().getLikedArticlesCount(uid);

      setState(() {
        likedCount = numberLikes;
      });
    } catch (e) {
      print("Erreur lors de la récupération des données de l'utilisateur : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getCountFavorite(String uid) async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberFavorite = await ApiService().getFavoriteArticlesCount(uid);

      setState(() {
        favoriteCount = numberFavorite;
      });
    } catch (e) {
      print("Erreur lors de la récupération des données de l'utilisateur : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getCountComments(String uid) async {
    setState(() {
      isLoading = true;
    });
    try {
      int numberComments = await ApiService().getUserCommentsCount(uid);

      setState(() {
        commentaireCount = numberComments;
      });
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
        bio = userData['bio'] ?? "Votre biographie";
        role = userData['role'] ?? "user";
        location = userData['location'] ?? "Votre location";

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

  void _showModifyUserDialog(
      BuildContext context,
      String userId,
      String initialFullname,
      String initialEmail,
      String initialBio,
      String initialLocation) {
    final _formKey = GlobalKey<FormState>();

    TextEditingController _fullnameController =
        TextEditingController(text: initialFullname);
    TextEditingController _emailController =
        TextEditingController(text: initialEmail);
    TextEditingController _bioController =
        TextEditingController(text: initialBio);
    TextEditingController _locationController =
        TextEditingController(text: initialLocation);
    // Fonction pour envoyer les données à Firebase
    Future<void> _updateUser(String idUser) async {
      try {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          Navigator.pop(context);

          // Récupérer les données actuelles de la catégorie depuis Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(idUser)
              .get();

          if (!userSnapshot.exists) {
            print("Erreur : L'utilisateur n'existe pas.");
            return;
          }

          Map<String, dynamic> categoryData =
              userSnapshot.data() as Map<String, dynamic>;

          String imageUrl = categoryData['image'] ?? 'defaultimage.jpeg';

          if (_pickedImage != null) {
            print("L'image selectionné est ${_pickedImage}");

            // Si une image a été choisie, on la télécharge sur Cloudinary
            imageUrl =
                await _uploadImageToCloudinary(File(_pickedImage!.path)!);
          }

          // Récupération de Firestore
          CollectionReference categories =
              FirebaseFirestore.instance.collection('utilisateurs');

          // Données à mettre à jour
          final updatedUserData = {
            'fullname': _fullnameController.text,
            'email': _emailController.text,
            'image': imageUrl, 
            'bio': _bioController.text,
            'location': _locationController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Mise à jour du document
          await categories.doc(idUser).update(updatedUserData);

          await fetchUserData(widget.uid);
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
              "Information modifiée",
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
        print("Erreur lors de la modification de l'utilisateur ${e}");
      } finally {
        setState(() {
          _fullnameController.clear();
          _emailController.clear();
          _bioController.clear();
          _locationController.clear();
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
            return AlertDialog(
              title: const Text(
                'Modifier les informations',
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
                      controller: _fullnameController,
                      decoration: InputDecoration(
                        labelText: "Fullname de l'utilisateur",
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        labelStyle: TextStyle(
                          color: context.watch<ThemeProvider>().isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        prefixIcon: Icon(Icons.person, color: Colors.teal),
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
                          return 'Veuillez entrer le fullname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        labelStyle: TextStyle(
                          color: context.watch<ThemeProvider>().isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.teal),
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
                          return 'Veuillez entrer l\'email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value)) {
                          return 'Veuillez entrer un email valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Champ de description
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Biographie',
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
                          return 'Veuillez entrer une biographie';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: "Votre location",
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        labelStyle: TextStyle(
                          color: context.watch<ThemeProvider>().isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        prefixIcon:
                            Icon(Icons.location_city, color: Colors.teal),
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
                          return 'Veuillez entrer la locationn';
                        }
                        return null;
                      },
                    ),
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
                        onPressed: () async {
                          await _updateUser(widget.uid);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
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
                    ),
                  ],
                ),
              )),
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
      canPop: false, // Désactive la fermeture immédiate
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        bool shouldExit = await showExitDialog(context);
        if (shouldExit) {
          setState(() {
            canExit =
                true; // Active la fermeture uniquement si l'utilisateur confirme
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
              'Mon Profil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: context.watch<ThemeProvider>().isDark
                ? Colors.black
                : const Color.fromARGB(255, 15, 70, 119),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showModifyUserDialog(
                      context, widget.uid, fullname, email, bio, location);
                  setState(() {});
                },
              ),
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
              :  FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              image != "" || image.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Hero(
                                      tag: "profile_image",
                                      child: InteractiveViewer(
                                        panEnabled:
                                            true, 
                                        boundaryMargin:
                                            const EdgeInsets.all(20),
                                        minScale: 0.5,
                                        maxScale: 3.0, 
                                        child: Image.network(
                                          image!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        radius: 18,
                                        child: Icon(Icons.close,
                                            color: Colors.white, size: 22),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: context.watch<ThemeProvider>().isDark
                            ? Colors.black
                            : Colors.white,
                        child: ClipOval(
                          child: (image != null || image!.isNotEmpty)
                              ? Image.network(
                                  image!,
                                  width: 80, 
                                  height: 80,
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
                                      height: 80,
                                      width: 80,
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
                                    // Si même l'image par défaut échoue, afficher une icône
                                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color.fromARGB(255, 15, 70, 119),
                      child: Text(
                        fullname.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                                  },
                                )
                              : CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color.fromARGB(255, 15, 70, 119),
                      child: Text(
                        fullname.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color.fromARGB(255, 15, 70, 119),
                      child: Text(
                        fullname.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
              // Bouton vert positionné en bas à droite de l'image
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullname,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: context.watch<ThemeProvider>().isDark
          ? Color.fromRGBO(102, 102, 102, 1)
          : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: context.watch<ThemeProvider>().isDark
            ? Colors.white
            : const Color.fromARGB(255, 15, 70, 119),
        unselectedLabelColor: Colors.grey,
        indicatorColor: context.watch<ThemeProvider>().isDark
            ? Colors.white
            : const Color.fromARGB(255, 15, 70, 119),
        tabs: const [
          Tab(text: 'Aperçu'),
          Tab(text: 'Articles favoris'),
          //Tab(text: 'Réalisations'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 500, 
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCertificationsTab(),
          //_buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques personnelles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatisticRow('Articles favoris', favoriteCount.toString()),
            _buildStatisticRow('Articles likés', likedCount.toString()),
            _buildStatisticRow('Commentaires', commentaireCount.toString()),
            //_buildStatisticRow('Temps total d\'apprentissage', '45h'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsTab() {
    if (filteredArticles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top:50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              "Aucun article mis en favoris",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredArticles.length,
      itemBuilder: (context, index) {
        final certificate = filteredArticles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Color.fromARGB(255, 15, 70, 119),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certificate['titre'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${certificate['sous_titre']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Délivré par : ${certificate['id_auteur']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 600),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return FadeTransition(
                            opacity: animation,
                            child: Articledetails(
                              uid: widget.uid,
                              id_article: certificate['id_article']!,
                              title:
                                  certificate['titre'] ?? "Titre indisponible",
                              image:
                                  certificate['image'] ?? "Image indisponible",
                              content: certificate['content'] ??
                                  "Contenu indisponible",
                              excerpt: certificate['sous_titre'] ??
                                  "Contenu indisponible",
                              isFavorite: certificate['isFavorite'],
                              isLiked: certificate['isLiked'],
                              likes:
                                  int.tryParse(certificate['likes']!)!.toInt(),
                              shares:
                                  int.tryParse(certificate['shares']!)!.toInt(),
                            ),
                          );
                        },
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Voir le contenu'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userData['achievements'].length,
      itemBuilder: (context, index) {
        final achievement = userData['achievements'][index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 15, 70, 119).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color.fromARGB(255, 15, 70, 119),
              ),
            ),
            title: Text(
              achievement['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(achievement['description']),
          ),
        );
      },
    );
  }
}
