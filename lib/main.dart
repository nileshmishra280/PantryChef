import 'package:flutter/material.dart';
import 'data.dart';
import 'firestore_service.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirestoreService.init();
  runApp(const PantryChefApp());
}

class PantryChefApp extends StatelessWidget {
  const PantryChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PantryChef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PantryHomePage(),
    );
  }
}

class PantryHomePage extends StatefulWidget {
  const PantryHomePage({super.key});

  @override
  State<PantryHomePage> createState() => _PantryHomePageState();
}

class _PantryHomePageState extends State<PantryHomePage> {
  final TextEditingController _pantryController = TextEditingController();
  final TextEditingController _recipeSearchController = TextEditingController();
  late List<PantryItem> _pantryItems = [];
  late List<Recipe> _recipes = [];
  bool _loading = true;
  int _selectedIndex = 0;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pantryItems = await FirestoreService.loadPantryItems();
    final recipes = await FirestoreService.loadRecipes();
    setState(() {
      _pantryItems = pantryItems;
      _recipes = recipes;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pantryController.dispose();
    super.dispose();
  }

  Future<void> _addPantryItem() async {
    final value = _pantryController.text.trim();
    if (value.isEmpty) return;

    final item = PantryItem(id: '', name: value.toLowerCase(), category: 'Other');
    setState(() {
      _pantryItems.add(item);
      _pantryController.clear();
    });

    final savedId = await FirestoreService.savePantryItem(item);
    if (savedId != null) {
      setState(() {
        final index = _pantryItems.indexOf(item);
        if (index != -1) {
          _pantryItems[index] = PantryItem(id: savedId, name: item.name, category: item.category);
        }
      });
    }
  }

  Future<void> _removePantryItem(PantryItem item) async {
    setState(() {
      _pantryItems.remove(item);
    });
    await FirestoreService.deletePantryItem(item.id);
  }

  Future<void> _openAddRecipeDialog() async {
    final titleController = TextEditingController();
    final cuisineController = TextEditingController();
    final cookTimeController = TextEditingController();
    final ingredientsController = TextEditingController();
    final stepsController = TextEditingController();

    final recipe = await showDialog<Recipe>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Recipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Recipe name'),
                ),
                TextField(
                  controller: cuisineController,
                  decoration: const InputDecoration(labelText: 'Cuisine'),
                ),
                TextField(
                  controller: cookTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cook time (minutes)'),
                ),
                TextField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(labelText: 'Ingredients (comma separated)'),
                ),
                TextField(
                  controller: stepsController,
                  decoration: const InputDecoration(labelText: 'Steps (comma separated)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final cuisine = cuisineController.text.trim();
                final cookTime = int.tryParse(cookTimeController.text.trim()) ?? 0;
                final ingredients = ingredientsController.text
                    .split(',')
                    .map((value) => value.trim().toLowerCase())
                    .where((value) => value.isNotEmpty)
                    .toList();
                final steps = stepsController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();

                if (title.isEmpty || cuisine.isEmpty || ingredients.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title, cuisine and ingredients are required.')),
                  );
                  return;
                }

                final newRecipe = Recipe(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  cuisine: cuisine,
                  cookTimeMins: cookTime > 0 ? cookTime : 20,
                  ingredients: ingredients,
                  steps: steps.isNotEmpty ? steps : ['Mix ingredients', 'Cook until ready'],
                );
                Navigator.of(context).pop(newRecipe);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (recipe != null) {
      setState(() {
        _recipes.add(recipe);
      });
      await FirestoreService.saveRecipe(recipe);
    }
  }

  Future<void> _openEditRecipeDialog(Recipe existing) async {
    final titleController = TextEditingController(text: existing.title);
    final cuisineController = TextEditingController(text: existing.cuisine);
    final cookTimeController = TextEditingController(text: existing.cookTimeMins.toString());
    final ingredientsController = TextEditingController(text: existing.ingredients.join(', '));
    final stepsController = TextEditingController(text: existing.steps.join(', '));
    final categoryController = TextEditingController(text: existing.category ?? '');

    final recipe = await showDialog<Recipe>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Recipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Recipe name')),
                TextField(controller: cuisineController, decoration: const InputDecoration(labelText: 'Cuisine')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                TextField(controller: cookTimeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cook time (minutes)')),
                TextField(controller: ingredientsController, decoration: const InputDecoration(labelText: 'Ingredients (comma separated)')),
                TextField(controller: stepsController, decoration: const InputDecoration(labelText: 'Steps (comma separated)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final cuisine = cuisineController.text.trim();
                final category = categoryController.text.trim();
                final cookTime = int.tryParse(cookTimeController.text.trim()) ?? existing.cookTimeMins;
                final ingredients = ingredientsController.text.split(',').map((v) => v.trim().toLowerCase()).where((v) => v.isNotEmpty).toList();
                final steps = stepsController.text.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();

                if (title.isEmpty || cuisine.isEmpty || ingredients.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title, cuisine and ingredients are required.')));
                  return;
                }

                final newRecipe = Recipe(
                  id: existing.id,
                  title: title,
                  cuisine: cuisine,
                  cookTimeMins: cookTime,
                  ingredients: ingredients,
                  steps: steps.isNotEmpty ? steps : existing.steps,
                  category: category.isNotEmpty ? category : existing.category,
                );
                Navigator.of(context).pop(newRecipe);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (recipe != null) {
      setState(() {
        final idx = _recipes.indexWhere((r) => r.id == recipe.id);
        if (idx != -1) _recipes[idx] = recipe;
      });
      await FirestoreService.saveRecipe(recipe);
    }
  }

  void _showRecipeDetails(Recipe recipe) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe)));
  }

  Widget _buildPantryView() {
    final matches = RecipeRepository.matchRecipes(_pantryItems, _recipes);
    final cookNow = matches.where((match) => match.matchType == 'Cook Now').toList();
    final almost = matches.where((match) => match.matchType == 'Almost').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Pantry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pantryController,
                        decoration: const InputDecoration(
                          hintText: 'Add ingredient',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addPantryItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _addPantryItem, child: const Text('Add')),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pantryItems
                        .map(
                          (item) => InputChip(
                            label: Text(item.name),
                            onDeleted: () => _removePantryItem(item),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Cook Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (cookNow.isEmpty)
          const Text('No perfect matches yet')
        else
          ...cookNow.take(4).map((match) => _RecipeTile(match: match, onTap: () => _showRecipeDetails(match.recipe))),
        const SizedBox(height: 16),
        const Text('Almost', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (almost.isEmpty)
          const Text('Add more ingredients to discover recipes')
        else
          ...almost.take(4).map((match) => _RecipeTile(match: match, onTap: () => _showRecipeDetails(match.recipe))),
      ],
    );
  }

  Widget _buildRecipeView() {
    final search = _recipeSearchController.text.trim().toLowerCase();
    final categories = _recipes.map((r) => r.category ?? 'Uncategorized').toSet().toList()..sort();
    final filtered = _recipes.where((r) {
      if (_categoryFilter != null && _categoryFilter!.isNotEmpty && (r.category ?? 'Uncategorized') != _categoryFilter) return false;
      if (search.isEmpty) return true;
      final inTitle = r.title.toLowerCase().contains(search);
      final inIngredients = r.ingredients.any((i) => i.toLowerCase().contains(search));
      return inTitle || inIngredients;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recipes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Saved recipes: ${_recipes.length}'),
                const SizedBox(height: 8),
                const Text('Tap any recipe to view details.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _recipeSearchController,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search recipes or ingredients'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Category: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _categoryFilter,
                      hint: const Text('All'),
                      items: [null, ...categories].map((c) => DropdownMenuItem<String?>(value: c, child: Text(c ?? 'All'))).toList(),
                      onChanged: (v) => setState(() => _categoryFilter = v),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Center(child: Text('No recipes found.'))
        else
          ...filtered.map((recipe) => Dismissible(
                key: ValueKey(recipe.id),
                background: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.delete, color: Colors.white)),
                secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (_) async {
                  setState(() => _recipes.removeWhere((r) => r.id == recipe.id));
                  await FirestoreService.deleteRecipe(recipe.id);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(recipe.title),
                    subtitle: Text('${recipe.cuisine} • ${recipe.cookTimeMins} min • ${recipe.category ?? 'Uncategorized'}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') await _openEditRecipeDialog(recipe);
                        if (value == 'delete') {
                          setState(() => _recipes.removeWhere((r) => r.id == recipe.id));
                          await FirestoreService.deleteRecipe(recipe.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => _showRecipeDetails(recipe),
                  ),
                ),
              )),
        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'PantryChef' : 'Recipe Library'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedIndex == 0 ? _buildPantryView() : _buildRecipeView(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddRecipeDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Recipe'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Pantry'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Recipes'),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.match, required this.onTap});

  final RecipeMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(match.recipe.title),
        subtitle: Text('${match.recipe.cuisine} • ${match.recipe.cookTimeMins} min'),
        trailing: match.missingIngredients.isEmpty
            ? const Chip(label: Text('Cook Now'))
            : Chip(label: Text('Missing ${match.missingIngredients.length}')),
        onTap: onTap,
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({required this.recipe, super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(recipe.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${recipe.cuisine} • ${recipe.cookTimeMins} min', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...recipe.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ingredient)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          const Text('Steps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...recipe.steps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text('$index. ${entry.value}'),
            );
          }),
        ],
      ),
    );
  }
}
