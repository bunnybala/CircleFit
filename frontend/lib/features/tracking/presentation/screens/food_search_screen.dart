import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _results = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final ProductSearchQueryConfiguration configuration = ProductSearchQueryConfiguration(
        parametersList: [SearchTerms(terms: [query])],
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      final SearchResult result = await OpenFoodAPIClient.searchProducts(null, configuration);
      setState(() {
        _results = result.products ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed. Check your connection.')),
      );
    }
  }

  void _showProductDetails(Product product) {
    final double? calories = product.nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _ProductDetailsSheet(product: product, calories: calories),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Search Food', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'e.g. Chicken, Apple, Oats...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _search,
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(color: Color(0xFF6C63FF), backgroundColor: Colors.white),
          Expanded(
            child: _results.isEmpty && !_isLoading
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final product = _results[index];
                    return _FoodResultCard(
                      product: product,
                      onTap: () => _showProductDetails(product),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Search for any food to track calories',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _FoodResultCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _FoodResultCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: product.imageFrontUrl != null
              ? Image.network(product.imageFrontUrl!, width: 60, height: 60, fit: BoxFit.cover)
              : Container(width: 60, height: 60, color: Colors.grey[100], child: const Icon(Icons.fastfood, color: Colors.grey)),
        ),
        title: Text(
          product.productName ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(product.brands ?? 'No brand info', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class _ProductDetailsSheet extends ConsumerWidget {
  final Product product;
  final double? calories;

  const _ProductDetailsSheet({required this.product, this.calories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.imageFrontUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(product.imageFrontUrl!, height: 180, width: double.infinity, fit: BoxFit.contain),
            ),
          const SizedBox(height: 20),
          Text(
            product.productName ?? 'Unknown Product',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            product.brands ?? '',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFF6C63FF)),
                const SizedBox(width: 10),
                Text(
                  calories != null ? '${calories!.toStringAsFixed(1)} kcal / 100g' : 'Calories unknown',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          if (calories != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addCalories(context, ref, calories!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Add 100g to Daily Logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _addCalories(BuildContext context, WidgetRef ref, double caloriesToAdd) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final newTotal = (profile.caloriesConsumed ?? 0) + caloriesToAdd;
    
    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final success = await ref.read(profileProvider.notifier).updateProfile({'caloriesConsumed': newTotal});

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // pop loading
      Navigator.pop(context); // pop sheet
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${caloriesToAdd.toInt()} kcal!'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
