import 'package:flutter/material.dart';

void main() {
  runApp(FotoBlogApp());
}

class FotoBlogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserProfilePage(),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Barre latérale
          Container(
            width: 250,
            color: Colors.teal[900],
            child: Column(
              children: [
                SizedBox(height: 40),
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                // Texte de bienvenue
                Text(
                  'Salut, Merveilles !',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Menu
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuItem(context, 'Accueil', Icons.home),
                      _buildMenuItem(
                          context, 'Télécharger une photo', Icons.file_upload),
                      _buildMenuItem(
                          context, 'Changer la photo de profil', Icons.photo),
                      _buildMenuItem(
                          context, 'Changer le mot de passe', Icons.lock),
                      _buildMenuItem(context, 'Se déconnecter', Icons.logout),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenu principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    'Vos articles !',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Grille des images
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 0,
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.grey[200], 
                        );
                      },
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

  // Fonction pour créer un élément du menu
  Widget _buildMenuItem(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
        // Ajouter ici la navigation ou les actions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title cliqué !')),
        );
      },
    );
  }
}
