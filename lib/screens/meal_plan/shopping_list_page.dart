import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/shopping_list_models.dart';
import '../../services/shopping_list_service.dart';
import '../../services/ingredient_tracking_service.dart';

class ShoppingListPage extends StatefulWidget {
  final List<Map<String, dynamic>> meals;
  final DateTime selectedDate;

  const ShoppingListPage({
    super.key,
    required this.meals,
    required this.selectedDate,
  });

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  ShoppingListData? _data;
  bool _hideChecked = false;
  bool _isLoading = true;
  final Map<String, bool> _categoryExpanded = {};

  @override
  void initState() {
    super.initState();
    _generateShoppingList();
  }

  void _generateShoppingList() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration.zero, () {
      final data = ShoppingListService.buildFromMeals(widget.meals);
      setState(() {
        _data = data;
        _isLoading = false;
        _categoryExpanded
          ..clear()
          ..addEntries(data.itemsByCategory.keys.map((key) => MapEntry(key, true)));
      });
    });
  }

  void _toggleAllItems(bool markAsChecked) {
    if (_data == null) return;
    for (final items in _data!.itemsByCategory.values) {
      for (final item in items) {
        item.checked = markAsChecked;
      }
    }
    setState(() {});
  }

  Future<void> _findAlternativeForItem(ShoppingListItem item) async {
    if (_isLoading) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await IngredientTrackingService.parseAndValidateIngredient(item.displayName);
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      final bool found = result['is_valid'] == true;
      final List<dynamic> suggestions = (result['suggestions'] as List<dynamic>?) ?? const [];
      final dynamic match = result['fnri_match'];
      final List<dynamic> alternatives = [
        ...suggestions,
        if (match != null) match.foodName,
      ];

      if (!found && alternatives.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Alternative Found'),
            content: Text(
              'We couldn\'t find a good alternative for "${item.displayName}". '
              'You can keep this ingredient as is or edit it manually.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final List<String> options = [
        ...alternatives.map((e) => e.toString()),
      ].toSet().toList();

      String? selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Alternative Ingredient'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original: ${item.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Suggested alternatives:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...options.map(
                  (alt) => ListTile(
                    title: Text(alt),
                    onTap: () => Navigator.of(context).pop(alt),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Keep Original'),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          final original = item.displayName;
          item.displayName = selected;
          final notePrefix = 'Alternative for "$original"';
          if (item.note == null || item.note!.isEmpty) {
            item.note = notePrefix;
          } else if (!item.note!.contains(notePrefix)) {
            item.note = '$notePrefix\n${item.note}';
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error Finding Alternative'),
          content: const Text(
            'Something went wrong while searching for an alternative. '
            'Please try again later or edit the ingredient manually.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all purchased',
            icon: const Icon(Icons.checklist_rtl),
            onPressed: () => _toggleAllItems(true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null || !_data!.hasItems
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => _generateShoppingList(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      if (_data!.missingMeals.isNotEmpty) _buildMissingMealsBanner(),
                      ..._buildCategorySections(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final formatter = DateFormat('EEEE, MMM d');
    final data = _data!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  formatter.format(widget.selectedDate),
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryStat('${data.mealTitles.length}', 'Recipes'),
                _buildSummaryStat('${data.totalItems}', 'Ingredients'),
              ],
            ),
            const SizedBox(height: 16),
            FilterChip(
              label: const Text('Hide purchased items'),
              selected: _hideChecked,
              onSelected: (value) => setState(() => _hideChecked = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingMealsBanner() {
    final data = _data!;
    final missing = data.missingMeals.take(3).join(', ');
    final remaining = data.missingMeals.length - 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Some meals missing ingredients',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0 ? '$missing and $remaining more' : missing,
            style: TextStyle(color: Colors.orange[800]),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    final sections = <Widget>[];
    final data = _data!;

    // Group by recipe (meal title) instead of category
    for (final recipeName in data.mealTitles) {
      final items = data.itemsByCategory[recipeName] ?? [];
      final visibleItems = items.where((item) => !_hideChecked || !item.checked).toList();
      if (visibleItems.isEmpty) continue;

      sections.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            initiallyExpanded: _categoryExpanded[recipeName] ?? true,
            onExpansionChanged: (expanded) => setState(() {
              _categoryExpanded[recipeName] = expanded;
            }),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recipeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    visibleItems.length.toString(),
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
              ],
            ),
            children: [
              for (final item in visibleItems) _buildShoppingItemTile(item),
            ],
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(_buildEmptyState());
    }

    return sections;
  }

  Widget _buildShoppingItemTile(ShoppingListItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: item.checked ? Colors.grey[100] : Colors.white,
        border: Border.all(
          color: item.checked ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.checked,
            onChanged: (value) => setState(() => item.checked = value ?? false),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.quantityLabel,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                if (item.mealBadges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.mealBadges
                        .map(
                          (meal) => Chip(
                            label: Text(
                              meal,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Find alternative ingredient',
            onPressed: () => _findAlternativeForItem(item),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No ingredients to show',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add meals to your plan to generate a shopping list.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}

