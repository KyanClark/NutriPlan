import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/recipes.dart';

class MealPlanState {
  final Map<String, List<Recipe>> plannedMealsBySlot; // breakfast/lunch/dinner/snack
  final Set<String> selectedMealIds; // for multi-select actions
  final double totalCalories;
  final Map<String, double> macroTotals; // protein, carbs, fat
  final bool isLoading;
  final String? errorMessage;
  final bool isDeleteMode;

  const MealPlanState({
    this.plannedMealsBySlot = const {'breakfast': [], 'lunch': [], 'dinner': [], 'snack': []},
    this.selectedMealIds = const {},
    this.totalCalories = 0,
    this.macroTotals = const {'protein': 0, 'carbs': 0, 'fat': 0},
    this.isLoading = false,
    this.errorMessage,
    this.isDeleteMode = false,
  });

  MealPlanState copyWith({
    Map<String, List<Recipe>>? plannedMealsBySlot,
    Set<String>? selectedMealIds,
    double? totalCalories,
    Map<String, double>? macroTotals,
    bool? isLoading,
    String? errorMessage,
    bool? isDeleteMode,
  }) {
    return MealPlanState(
      plannedMealsBySlot: plannedMealsBySlot ?? this.plannedMealsBySlot,
      selectedMealIds: selectedMealIds ?? this.selectedMealIds,
      totalCalories: totalCalories ?? this.totalCalories,
      macroTotals: macroTotals ?? this.macroTotals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isDeleteMode: isDeleteMode ?? this.isDeleteMode,
    );
  }
}

class MealPlanCubit extends Cubit<MealPlanState> {
  MealPlanCubit() : super(const MealPlanState());

  void addMeal(String slot, Recipe recipe) {
    final updated = Map<String, List<Recipe>>.from(state.plannedMealsBySlot);
    updated[slot] = [...(updated[slot] ?? []), recipe];
    _emitWithTotals(updated);
  }

  void removeMeal(String slot, Recipe recipe) {
    final updated = Map<String, List<Recipe>>.from(state.plannedMealsBySlot);
    updated[slot] = (updated[slot] ?? []).where((r) => r.id != recipe.id).toList();
    _emitWithTotals(updated);
  }

  void swapMeal(String slot, Recipe oldRecipe, Recipe newRecipe) {
    final updated = Map<String, List<Recipe>>.from(state.plannedMealsBySlot);
    final list = [...(updated[slot] ?? [])];
    final index = list.indexWhere((r) => r.id == oldRecipe.id);
    if (index != -1) {
      list[index] = newRecipe;
      updated[slot] = list;
      _emitWithTotals(updated);
    }
  }

  void toggleSelect(String recipeId) {
    final selected = Set<String>.from(state.selectedMealIds);
    if (selected.contains(recipeId)) {
      selected.remove(recipeId);
    } else {
      selected.add(recipeId);
    }
    emit(state.copyWith(selectedMealIds: selected));
  }

  void clearSelection() => emit(state.copyWith(selectedMealIds: {}));

  void setDeleteMode(bool value) {
    emit(state.copyWith(isDeleteMode: value));
    if (!value) {
      clearSelection();
    }
  }

  void _emitWithTotals(Map<String, List<Recipe>> updated) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final entry in updated.values) {
      for (final r in entry) {
        calories += (r.calories).toDouble();
        protein += (r.macros['protein'] ?? 0).toDouble();
        carbs += (r.macros['carbs'] ?? 0).toDouble();
        fat += (r.macros['fat'] ?? 0).toDouble();
      }
    }

    emit(state.copyWith(
      plannedMealsBySlot: updated,
      totalCalories: calories,
      macroTotals: {'protein': protein, 'carbs': carbs, 'fat': fat},
    ));
  }
}


