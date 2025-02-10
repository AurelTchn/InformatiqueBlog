import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:informatiqueblog/pages_aurel/variableglobal.dart';

class ApiService {
  Future<List<Map<String, String>>> fetchCategoriesFromFirestore() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      List<Map<String, String>> categories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id, 
          'nom': data['nom']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'icon': data['icon']?.toString() ?? '',
          'image': data['image']?.toString() ?? 'defaultimage.jpeg',
        };
      }).toList();

      return categories;
    } catch (e) {
      print(e);
      throw Exception(
          'Erreur lors de la récupération des catégories depuis Firestore');
    }
  }

  Future<List<Map<String, String>>> fetchArticlesFromFirestore(userId) async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('articles').get();

      List<String> likedArticles = await getLikedArticles(userId);
      List<String> favoriteArticles = await getFavoriteArticles(userId);

      List<Map<String, String>> articles = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return {
          'id_article': doc.id,
          'titre': data['titre']?.toString() ?? '',
          'image': data['image']?.toString() ?? 'defaultimage.jpeg',
          'sous_titre': data['sous_titre']?.toString() ?? '',
          'likes': data['likes']?.toString() ?? '0',
          'shares': data['shares']?.toString() ?? '0',
          'content': data['contenu']?.toString() ?? '',
          'comments': data['comments']?.toString() ?? '',
          'id_categorie': data['uid_categorie']?.toString() ?? '',
          'id_auteur': data['id_auteur']?.toString() ?? '',
          'date_publication': data['date_publication']?.toString() ?? '',
          'isLiked': likedArticles.contains(doc.id) ? 'true' : 'false',
          'isFavorite': favoriteArticles.contains(doc.id) ? 'true' : 'false',
        };
      }).toList();

      return articles;
    } catch (e) {
      print(e);
      throw Exception(
          'Erreur lors de la récupération des articles depuis Firestore');
    }
  }

  Future<List<String>> getLikedArticles(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('liked_articles')
          .get();

      List<String> likedArticles = [];
      for (var doc in snapshot.docs) {
        final data =
            doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('uid_article')) {
          likedArticles.add(data['uid_article'] as String);
        } else {
          print('Document sans le champ uid_article : ${doc.id}');
        }
      }

      return likedArticles;
    } catch (e) {
      print('Erreur lors de la récupération des articles likés : $e');
      return [];
    }
  }

  Future<List<String>> getFavoriteArticles(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('favorite_articles')
          .get();

      List<String> favoriteArticles = [];
      for (var doc in snapshot.docs) {
        final data =
            doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('uid_article')) {
          favoriteArticles.add(data['uid_article'] as String);
        } else {
          print('Document sans le champ uid_article : ${doc.id}');
        }
      }

      return favoriteArticles;
    } catch (e) {
      print('Erreur lors de la récupération des articles favoris : $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchArticlesByCategoryFromFirestore(
      String categoryId, String userId) async {
    try {
      QuerySnapshot articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('uid_categorie', isEqualTo: categoryId)
          .get();

      print("Liste des articles par catégorie ${articlesSnapshot}");

      List<String> likedArticles = await getLikedArticles(userId);
      List<String> favoriteArticles = await getFavoriteArticles(userId);

      List<Map<String, dynamic>> articles = articlesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print("les uid des article likés ${likedArticles}");
        return {
          'id_article': doc.id,
          'titre': data['titre']?.toString() ?? '',
          'sous_titre': data['sous_titre']?.toString() ?? '',
          'contenu': data['contenu']?.toString() ?? '',
          'shares': data['shares'] != null ? data['shares'] as int : 0,
          'comments': data['comments'] != null ? data['comments'] as int : 0,
          'likes': data['likes'] != null ? data['likes'] as int : 0,
          'image': data['image']?.toString() ?? 'defaultimage.jpeg',
          'pdf': data['pdf']?.toString() ?? '',
          'id_categorie': data['uid_categorie']?.toString() ?? '',
          'id_auteur': data['id_auteur']?.toString() ?? '',
          'date_publication': data['date_publication']?.toString() ?? '',
          'isLiked': likedArticles.contains(doc.id) ? true : false,
          'isFavorite': favoriteArticles.contains(doc.id) ? true : false,
        };
      }).toList();

      return articles;
    } catch (e) {
      print('Erreur lors de la récupération des articles : $e');
      throw Exception(
          'Erreur lors de la récupération des articles depuis Firestore');
    }
  }

  Future<List<Map<String, dynamic>>> getAllComments(String articleId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('commentaires')
          .where('id_article', isEqualTo: articleId)
          .orderBy('created_at',
              descending:
                  true)
          .get();

      List<Map<String, dynamic>> comments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "author": data[
              'author'],
          "text": data['contenu'],
          "image": data['image'],
          "created_at": data['created_at'], 
        };
      }).toList();

      return comments;
    } catch (e) {
      print("Erreur lors de la récupération des commentaires : $e");
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getAllCommentsStream(String articleId, {int limit = 5}) {
  return FirebaseFirestore.instance
      .collection('commentaires')
      .where('id_article', isEqualTo: articleId) 
      .orderBy('created_at', descending: true)
      .limit(limit) 
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            "id_commentaire": data['id_commentaire'],
            "id_utilisateur": data['id_utilisateur'],
            "author": data['author'],
            "text": data['contenu'],
            "image": data['image'] ?? "",
            "created_at": data['created_at'],
          };
        }).toList();
      });
}

    Future<List<Map<String, dynamic>>> getAllContactsAll() async {
    try {

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('contacts')
          .orderBy('createdAt',
              descending:
                  true)
          .get();

      List<Map<String, dynamic>> comments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "createdAt": data[
              'createdAt'], 
          "email": data['email'],
          "fullname": data['fullname'],
          "message": data['message'],
          "sujet": data['sujet'],
          "image": data['image'],
          "raison_contact": data['raison_contact'],
        };
      }).toList();

      return comments;
    } catch (e) {
      print("Erreur lors de la récupération des contacts : $e");
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> getAllContacts({limite= 3}) async {
    try {

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('contacts')
          .orderBy('createdAt',
              descending:
                  true)
                  .limit(limite)
          .get();


      List<Map<String, dynamic>> comments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "createdAt": data[
              'createdAt'],
          "email": data['email'],
          "fullname": data['fullname'],
          "message": data['message'],
          "sujet": data['sujet'],
          "image": data['image'],
          "raison_contact": data['raison_contact'],
        };
      }).toList();

      return comments;
    } catch (e) {
      print("Erreur lors de la récupération des contacts : $e");
      return [];
    }
  }

  Future<int> getLikedArticlesCount(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('liked_articles')
          .get();

      return snapshot.size - 1;
    } catch (e) {
      print('Erreur lors de la récupération du nombre d\'articles likés : $e');
      return 0;
    }
  }

  Future<int> getFavoriteArticlesCount(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('favorite_articles')
          .get();

      return snapshot.size - 1;
    } catch (e) {
      print(
          'Erreur lors de la récupération du nombre des articles favoris : $e');
      return 0;
    }
  }

  Future<int> getUserCommentsCount(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('commentaires')
          .where('id_utilisateur', isEqualTo: userId)
          .get();

      return snapshot.size;
    } catch (e) {
      print('Erreur lors de la récupération du nombre de commentaires : $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getUserFavoriteArticles(
      String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('favorite_articles')
          .get();

      List<String> favoriteArticlesT = await getFavoriteArticles(userId);
      if (favoriteArticlesT.isEmpty) {
        return [];
      }

      List<String> likesArticlesT = await getLikedArticles(userId);

      List<Map<String, dynamic>> favoriteArticles = [];

      for (String articleId in favoriteArticlesT) {
        DocumentSnapshot articleSnapshot = await FirebaseFirestore.instance
            .collection('articles')
            .doc(articleId)
            .get();

        if (articleSnapshot.exists) {
          final data = articleSnapshot.data() as Map<String, dynamic>? ?? {};

          favoriteArticles.add({
            'id_article': articleSnapshot.id,
            'titre': data['titre']?.toString() ?? '',
            'image': data['image']?.toString() ?? 'defaultimage.jpeg',
            'sous_titre': data['sous_titre']?.toString() ?? '',
            'likes': data['likes']?.toString() ?? '0',
            'shares': data['shares']?.toString() ?? '0',
            'content': data['contenu']?.toString() ?? '',
            'comments': data['comments']?.toString() ?? '',
            'id_categorie': data['uid_categorie']?.toString() ?? '',
            'id_auteur': data['id_auteur']?.toString() ?? '',
            'date_publication': data['date_publication']?.toString() ?? '',
            'isFavorite': true,
            'isLiked':
                likesArticlesT.contains(articleSnapshot.id) ? true : false,
          });
        }
      }

      return favoriteArticles;
    } catch (e) {
      print('Erreur lors de la récupération des articles favoris : $e');
      return [];
    }
  }

  Future<int> getAllUsersCount() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('utilisateurs').get();

      return snapshot.size;
    } catch (e) {
      print('Erreur lors de la récupération du nombre d\'utilisateurs : $e');
      return 0;
    }
  }

  Future<int> getAllArticlesCount() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('articles').get();

      return snapshot.size;
    } catch (e) {
      print('Erreur lors de la récupération du nombre d\'articles : $e');
      return 0;
    }
  }

  Future<int> getAllCategoriesCount() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      return snapshot.size;
    } catch (e) {
      print('Erreur lors de la récupération du nombre d\'categories : $e');
      return 0;
    }
  }

  Future<int> getAllCommentsCount() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('commentaires').get();

      return snapshot.size;
    } catch (e) {
      print('Erreur lors de la récupération du nombre d\'commentaires : $e');
      return 0;
    }
  }

}
