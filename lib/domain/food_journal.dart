import 'athlete_data.dart';

class FoodPreset {
  const FoodPreset(this.name, this.kcal, this.protein, this.carbs, this.fat);
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
}

class FoodEstimate {
  const FoodEstimate(this.kcal, this.protein, this.carbs, this.fat);
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
}

/// A transparent lookup estimate. Photos are never interpreted as food data.
class FoodJournal {
  static const presets = <String, FoodPreset>{
    'chickenRice': FoodPreset('Chicken, rice, greens', 640, 52, 71, 18),
    'eggsToast': FoodPreset('Eggs and toast', 390, 23, 35, 18),
    'oatsYogurt': FoodPreset('Oats and yogurt', 430, 25, 58, 11),
    'fishPotatoes': FoodPreset('Fish and potatoes', 510, 42, 48, 16),
    'tofuNoodles': FoodPreset('Tofu and noodles', 540, 28, 65, 19),
    'other': FoodPreset('Other meal', 0, 0, 0, 0),
  };

  FoodEstimate estimate(String foodKey, double portions) {
    final preset = presets[foodKey];
    if (preset == null || portions < .5 || portions > 4) {
      throw const FormatException('Choose a meal and 0.5–4 servings.');
    }
    return FoodEstimate(
        (preset.kcal * portions).round(),
        (preset.protein * portions).round(),
        (preset.carbs * portions).round(),
        (preset.fat * portions).round());
  }

  FoodEstimate today(Iterable<FoodMeal> meals, String date) {
    final list = meals.where((meal) => meal.date == date);
    return FoodEstimate(
        list.fold(0, (sum, meal) => sum + meal.kcal),
        list.fold(0, (sum, meal) => sum + meal.protein),
        list.fold(0, (sum, meal) => sum + meal.carbs),
        list.fold(0, (sum, meal) => sum + meal.fat));
  }
}
