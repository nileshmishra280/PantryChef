import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'data.dart';
import 'firebase_options.dart';
import 'models.dart';

class FirestoreService {
  static bool available = false;
  static FirebaseFirestore? _firestore;
  static String? _uid;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final authResult = await FirebaseAuth.instance.signInAnonymously();
      _uid = authResult.user?.uid;
      _firestore = FirebaseFirestore.instance;
      _firestore!.settings = const Settings(persistenceEnabled: true);
      available = _uid != null;
      if (available) {
        await saveUserProfile(UserProfile(id: _uid!, createdAt: DateTime.now()));
        await _seedRecipesIfNeeded();
      }
    } catch (_) {
      available = false;
    }
  }

  static Future<void> _seedRecipesIfNeeded() async {
    if (!available) return;

    final snapshot = await _firestore!.collection('recipes').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final recipes = RecipeRepository.seedRecipes();
      final batch = _firestore!.batch();
      for (final recipe in recipes) {
        final ref = _firestore!.collection('recipes').doc(recipe.id);
        batch.set(ref, recipe.toMap());
      }
      await batch.commit();
    }
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    if (!available) return;
    await _firestore!.collection('users').doc(profile.id).set(profile.toMap());
  }

  static Future<List<Recipe>> loadRecipes() async {
    if (!available) {
      return RecipeRepository.seedRecipes();
    }

    try {
      final snapshot = await _firestore!.collection('recipes').get();
      if (snapshot.docs.isEmpty) {
        return RecipeRepository.seedRecipes();
      }
      return snapshot.docs.map((doc) => Recipe.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {
      return RecipeRepository.seedRecipes();
    }
  }

  static Future<List<PantryItem>> loadPantryItems() async {
    if (!available) {
      return RecipeRepository.seedPantry();
    }

    try {
      final snapshot = await _firestore!.collection('pantryItems').where('userId', isEqualTo: _uid).get();
      if (snapshot.docs.isEmpty) {
        final seed = RecipeRepository.seedPantry();
        for (final item in seed) {
          await savePantryItem(item);
        }
        return seed;
      }
      return snapshot.docs
          .map((doc) => PantryItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return RecipeRepository.seedPantry();
    }
  }

  static Future<String?> savePantryItem(PantryItem item) async {
    if (!available) return null;
    final data = item.toMap()..['userId'] = _uid;
    if (item.id.isEmpty) {
      final ref = await _firestore!.collection('pantryItems').add(data);
      return ref.id;
    }
    await _firestore!.collection('pantryItems').doc(item.id).set(data);
    return item.id;
  }

  static Future<void> deletePantryItem(String id) async {
    if (!available || id.isEmpty) return;
    await _firestore!.collection('pantryItems').doc(id).delete();
  }

  static Future<void> saveRecipe(Recipe recipe) async {
    if (!available) return;
    await _firestore!.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  static Future<void> deleteRecipe(String id) async {
    if (!available || id.isEmpty) return;
    await _firestore!.collection('recipes').doc(id).delete();
  }
}
