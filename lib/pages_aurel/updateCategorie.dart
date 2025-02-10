import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'dart:io';

import 'package:loading_overlay_pro/loading_overlay_pro.dart';

final cloudinary = Cloudinary.fromStringUrl(
    'cloudinary://863377355295549:57YFSH3T5JeCVrhrZ_Tl5XWmLGM@drsyadv5i');

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({Key? key}) : super(key: key);

  @override
  _CreateCategoryPageState createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _icon = 'default'; 
  String _image = 'defaultimage.jpeg'; 
  XFile? _pickedImage; 
  bool isLoading = false;

  // Fonction pour envoyer les données à Firebase
  Future<void> _createCategory() async {
    setState(() {
      isLoading = true;
    });
    try {
      if (_formKey.currentState!.validate()) {
        String imageUrl = _image; 

        if (_pickedImage != null) {
          print("L'image selectionné est ${_pickedImage}");
          // Si une image a été choisie, on la télécharge sur Cloudinary
          imageUrl = await _uploadImageToCloudinary(File(_pickedImage!.path)!);
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
          'createdAt': FieldValue.serverTimestamp(), 
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("📸 Image sélectionnée : ${pickedFile.path}");
      setState(() {
        _pickedImage = pickedFile;
      });
    } else {
      print("⚠️ Aucune image sélectionnée !");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayPro(
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
          title: const Text('Créer une catégorie'),
        ),
        body:  Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Champ de nom
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nom de la catégorie'),
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
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  
                  const SizedBox(height: 16),

                  // Sélection d'image
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sélectionner une image (facultatif)'),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _pickedImage == null
                              ? const Icon(Icons.add_a_photo)
                              : Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bouton de soumission
                  Center(
                    child: ElevatedButton(
                      onPressed: _createCategory,
                      child: const Text('Créer la catégorie'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
