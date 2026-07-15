class PantryItem {
  PantryItem({required this.id, required this.name, required this.category});

  final String id;
  final String name;
  final String category;

  Map<String, Object?> toMap() => {
        'name': name,
        'category': category,
      };

  factory PantryItem.fromMap(Map<String, Object?> map, [String? id]) {
    return PantryItem(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
    );
  }
}

class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.cookTimeMins,
    required this.ingredients,
    required this.steps,
    this.category,
  });

  final String id;
  final String title;
  final String cuisine;
  final int cookTimeMins;
  final List<String> ingredients;
  final List<String> steps;
  final String? category;

  Map<String, Object?> toMap() => {
        'title': title,
        'cuisine': cuisine,
        'cookTimeMins': cookTimeMins,
        'ingredients': ingredients,
      'steps': steps,
      'category': category,
      };

  factory Recipe.fromMap(Map<String, Object?> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] as String? ?? '',
      cuisine: map['cuisine'] as String? ?? '',
      cookTimeMins: (map['cookTimeMins'] as int?) ?? 0,
      ingredients: List<String>.from(map['ingredients'] as List<dynamic>? ?? []),
      steps: List<String>.from(map['steps'] as List<dynamic>? ?? []),
      category: map['category'] as String?,
    );
  }
}

class UserProfile {
  UserProfile({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class RecipeMatch {
  RecipeMatch({required this.recipe, required this.missingIngredients})
      : matchType = missingIngredients.isEmpty ? 'Cook Now' : 'Almost';

  final Recipe recipe;
  final List<String> missingIngredients;
  final String matchType;
}
