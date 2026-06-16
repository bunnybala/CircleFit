import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class FoodScannerScreen extends ConsumerStatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  ConsumerState<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends ConsumerState<FoodScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isProcessing = false;
  String _lastScannedBarcode = "";

  @override
  void initState() {
    super.initState();
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'CircleFit', url: 'https://circlefit.app');
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;
      if (barcodeValue != null && barcodeValue != _lastScannedBarcode) {
        setState(() {
          _isProcessing = true;
          _lastScannedBarcode = barcodeValue;
        });

        await _fetchProductByBarcode(barcodeValue);
      }
    }
  }

  Future<void> _fetchProductByBarcode(String barcode) async {
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);

      if (result.status == ProductResultV3.statusSuccess && result.product != null) {
        _showProductBottomSheet(result.product!);
      } else {
        _showError('Product not found in OpenFoodFacts database.');
      }
    } catch (e) {
      _showError('Failed to fetch product data.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _searchProductByName(String query) async {
    if (query.isEmpty || _isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final ProductSearchQueryConfiguration configuration = ProductSearchQueryConfiguration(
        parametersList: <Parameter>[
          SearchTerms(terms: [query]),
        ],
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      final SearchResult result = await OpenFoodAPIClient.searchProducts(null, configuration);

      if (result.products != null && result.products!.isNotEmpty) {
        // Show the first matching product for simplicity, or a list if needed
        // Here we just pick the most relevant hit
        _showProductBottomSheet(result.products!.first);
      } else {
        _showError('No products found for "$query".');
      }
    } catch (e) {
      _showError('Search failed.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    // Reset scanner delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _lastScannedBarcode = "");
    });
  }

  void _showProductBottomSheet(Product product) {
    final double? calories100g = product.nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams);
    final String productName = product.productName ?? 'Unknown Product';
    final String? imageUrl = product.imageFrontUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 150, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
                ),
              const SizedBox(height: 20),
              Text(
                productName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (calories100g != null)
                Text(
                  '${calories100g.toStringAsFixed(1)} kcal per 100g',
                  style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.w600),
                )
              else
                const Text(
                  'Calorie information not available.',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 24),
              if (calories100g != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _addCalories(calories100g),
                    child: const Text('Add 100g to Daily Calories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _lastScannedBarcode = ""); // allow rescanning
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              )
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _lastScannedBarcode = "");
    });
  }

  Future<void> _addCalories(double caloriesToAdd) async {
    final profileData = ref.read(profileProvider).value;
    if (profileData == null) return;

    final currentConsumed = profileData.caloriesConsumed ?? 0.0;
    final newConsumed = currentConsumed + caloriesToAdd;

    // Show loading indicator
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final success = await ref.read(profileProvider.notifier).updateProfile({
      'caloriesConsumed': newConsumed,
    });

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // close dialog
      Navigator.pop(context); // close bottom sheet
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Calories added successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to add calories.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan or Search Food'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search food by name (e.g. Chicken)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onSubmitted: (val) {
                      FocusScope.of(context).unfocus();
                      _searchProductByName(val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _searchProductByName(_searchController.text);
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: const Color(0xFF6C63FF),
                )
              ],
            ),
          ),
          
          if (_isProcessing)
            const LinearProgressIndicator(),

          // Scanner View
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleBarcode,
                ),
                // Overlay frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF48CFAD), width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Center barcode in the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
