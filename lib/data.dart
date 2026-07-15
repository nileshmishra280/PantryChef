import 'models.dart';

class RecipeRepository {
  static List<Recipe> seedRecipes() {
    return [
      Recipe(
        id: '1',
        title: 'Quick Pasta',
        cuisine: 'Italian',
        cookTimeMins: 15,
        ingredients: ['pasta', 'tomato', 'garlic', 'olive oil', 'basil'],
        category: 'Pasta',
        steps: ['Boil pasta', 'Cook tomato and garlic', 'Combine and serve'],
      ),
      Recipe(
        id: '2',
        title: 'Egg Fried Rice',
        cuisine: 'Asian',
        cookTimeMins: 12,
        ingredients: ['rice', 'egg', 'soy sauce', 'onion', 'peas', 'sesame oil'],
        category: 'Rice',
        steps: ['Cook rice', 'Scramble egg', 'Stir-fry vegetables', 'Add rice and sauce'],
      ),
      Recipe(
        id: '3',
        title: 'Bean Toast',
        cuisine: 'British',
        cookTimeMins: 8,
        ingredients: ['bread', 'beans', 'butter', 'cheese'],
        category: 'Breakfast',
        steps: ['Toast bread', 'Heat beans', 'Top toast with beans and cheese'],
      ),
      Recipe(
        id: '4',
        title: 'Chicken Salad',
        cuisine: 'American',
        cookTimeMins: 20,
        ingredients: ['chicken', 'lettuce', 'tomato', 'cucumber', 'olive oil'],
        category: 'Salad',
        steps: ['Cook chicken', 'Chop vegetables', 'Toss salad with dressing'],
      ),
      Recipe(
        id: '5',
        title: 'Veggie Stir Fry',
        cuisine: 'Asian',
        cookTimeMins: 18,
        ingredients: ['broccoli', 'carrot', 'bell pepper', 'soy sauce', 'garlic', 'ginger'],
        category: 'Stir Fry',
        steps: ['Chop vegetables', 'Stir-fry with garlic and ginger', 'Add soy sauce and serve'],
      ),
      Recipe(
        id: '6',
        title: 'Tomato Soup',
        cuisine: 'Italian',
        cookTimeMins: 25,
        ingredients: ['tomato', 'onion', 'garlic', 'vegetable broth', 'basil'],
        category: 'Soup',
        steps: ['Sauté onion and garlic', 'Add tomatoes and broth', 'Simmer and blend'],
      ),
      Recipe(
        id: '7',
        title: 'Pancakes',
        cuisine: 'American',
        cookTimeMins: 15,
        ingredients: ['flour', 'milk', 'egg', 'sugar', 'butter'],
        category: 'Breakfast',
        steps: ['Mix batter', 'Cook pancakes on a griddle', 'Serve with toppings'],
      ),
      Recipe(
        id: '8',
        title: 'Shrimp Tacos',
        cuisine: 'Mexican',
        cookTimeMins: 22,
        ingredients: ['shrimp', 'tortilla', 'cabbage', 'lime', 'cilantro'],
        category: 'Tacos',
        steps: ['Cook shrimp', 'Warm tortillas', 'Assemble tacos with slaw and lime'],
      ),
    ];
  }

  static List<PantryItem> seedPantry() {
    return [
      PantryItem(id: 'p1', name: 'pasta', category: 'Grains'),
      PantryItem(id: 'p2', name: 'tomato', category: 'Produce'),
      PantryItem(id: 'p3', name: 'garlic', category: 'Produce'),
      PantryItem(id: 'p4', name: 'egg', category: 'Protein'),
      PantryItem(id: 'p5', name: 'rice', category: 'Grains'),
    ];
  }

  static List<RecipeMatch> matchRecipes(List<PantryItem> pantryItems, List<Recipe> recipes) {
    final pantryNames = pantryItems.map((item) => item.name.toLowerCase()).toSet();

    return recipes.map((recipe) {
      final required = recipe.ingredients
          .where((ingredient) => !ingredient.contains('oil') && !ingredient.contains('salt') && !ingredient.contains('water'))
          .toList();
      final missing = required.where((ingredient) => !pantryNames.contains(ingredient.toLowerCase())).toList();
      return RecipeMatch(recipe: recipe, missingIngredients: missing);
    }).toList()
      ..sort((a, b) {
        final aScore = a.missingIngredients.length;
        final bScore = b.missingIngredients.length;
        if (aScore == bScore) {
          return a.recipe.cookTimeMins.compareTo(b.recipe.cookTimeMins);
        }
        return aScore.compareTo(bScore);
      });
  }
}
