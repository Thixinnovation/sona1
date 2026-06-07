import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  final Map<String, dynamic> currentFilters;

  const FilterSheet({
    super.key,
    required this.onApply,
    this.currentFilters = const {},
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  RangeValues _priceRange = const RangeValues(0, 1000000);
  double _minRating = 0;
  String _sortBy = 'newest';
  List<String> _selectedCategories = [];
  String _location = 'all';

  final List<String> _categories = [
    'Électronique', 'Mode & Fashion', 'Maison & Déco', 'Beauté & Santé', 'Sports & Loisirs'
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Plus récents', 'icon': Icons.fiber_new},
    {'value': 'price_asc', 'label': 'Prix croissant', 'icon': Icons.trending_up},
    {'value': 'price_desc', 'label': 'Prix décroissant', 'icon': Icons.trending_down},
    {'value': 'rating', 'label': 'Meilleures notes', 'icon': Icons.star},
    {'value': 'popularity', 'label': 'Plus populaires', 'icon': Icons.local_fire_department},
  ];

  final List<Map<String, dynamic>> _locationOptions = [
    {'value': 'all', 'label': 'Tous les vendeurs', 'icon': Icons.public},
    {'value': 'near', 'label': 'À proximité', 'icon': Icons.near_me},
    {'value': 'online', 'label': 'Livraison partout', 'icon': Icons.local_shipping},
  ];

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.currentFilters['min_price']?.toDouble() ?? 0,
      widget.currentFilters['max_price']?.toDouble() ?? 1000000,
    );
    _minRating = widget.currentFilters['min_rating']?.toDouble() ?? 0;
    _sortBy = widget.currentFilters['sort_by'] ?? 'newest';
    _selectedCategories = List<String>.from(widget.currentFilters['categories'] ?? []);
    _location = widget.currentFilters['location'] ?? 'all';
  }

  void _applyFilters() {
    widget.onApply({
      'min_price': _priceRange.start,
      'max_price': _priceRange.end,
      'min_rating': _minRating,
      'sort_by': _sortBy,
      'categories': _selectedCategories,
      'location': _location,
    });
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 1000000);
      _minRating = 0;
      _sortBy = 'newest';
      _selectedCategories = [];
      _location = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _resetFilters, child: const Text('Tout effacer')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tri
                  const Text('Trier par', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sortOptions.map((option) => FilterChip(
                      label: Text(option['label']),
                      selected: _sortBy == option['value'],
                      onSelected: (selected) => setState(() => _sortBy = option['value']),
                      selectedColor: const Color(0xFFD4AF37),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Prix
                  const Text('Prix', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 10,
                    labels: RangeLabels(
                      '${_priceRange.start.round()} FCFA',
                      '${_priceRange.end.round()} FCFA',
                    ),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_priceRange.start.round()} FCFA'),
                      Text('${_priceRange.end.round()} FCFA'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Note minimum
                  const Text('Note minimum', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          onChanged: (v) => setState(() => _minRating = v),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(_minRating.toStringAsFixed(1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Catégories
                  const Text('Catégories', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) => FilterChip(
                      label: Text(cat),
                      selected: _selectedCategories.contains(cat),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      }),
                      selectedColor: const Color(0xFFD4AF37),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Localisation
                  const Text('Localisation', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _locationOptions.map((opt) => FilterChip(
                      label: Text(opt['label']),
                      selected: _location == opt['value'],
                      onSelected: (selected) => setState(() => _location = opt['value']),
                      selectedColor: const Color(0xFFD4AF37),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          // Bouton Appliquer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('APPLIQUER LES FILTRES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
