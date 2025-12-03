class ShoppingListItem {
  final String key;
  final Set<String> sourceMeals;
  final Set<String> mealTypes;
  String displayName;
  double? quantity;
  String? unit;
  String? note;
  final String category;
  bool checked;

  ShoppingListItem({
    required this.key,
    required this.displayName,
    required this.category,
    this.quantity,
    this.unit,
    this.note,
    Set<String>? sourceMeals,
    Set<String>? mealTypes,
    this.checked = false,
  })  : sourceMeals = sourceMeals ?? <String>{},
        mealTypes = mealTypes ?? <String>{};

  String get quantityLabel {
    if (quantity == null && (unit == null || unit!.isEmpty)) {
      return 'As needed';
    }
    if (quantity != null && unit != null && unit!.isNotEmpty) {
      return '${_formatQuantity(quantity!)} $unit';
    }
    if (quantity != null) {
      return _formatQuantity(quantity!);
    }
    return unit ?? 'As needed';
  }

  List<String> get mealBadges {
    final list = sourceMeals.toList()..sort();
    return list;
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(value < 1 ? 2 : 1).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class ShoppingListData {
  final Map<String, List<ShoppingListItem>> itemsByCategory;
  final int mealsIncluded;
  final int totalItems;
  final List<String> mealTitles;
  final List<String> missingMeals;

  const ShoppingListData({
    required this.itemsByCategory,
    required this.mealsIncluded,
    required this.totalItems,
    required this.mealTitles,
    this.missingMeals = const [],
  });

  bool get hasItems => totalItems > 0;

  List<String> get orderedCategories {
    // When grouped by recipe, return meal titles sorted alphabetically
    return mealTitles;
  }
}

