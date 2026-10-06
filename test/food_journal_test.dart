import 'package:flutter_test/flutter_test.dart';
import 'package:boxer_recovery/domain/athlete_data.dart';
import 'package:boxer_recovery/domain/food_journal.dart';

void main() {
  test('preset estimates scale with confirmed servings', () {
    final estimate = FoodJournal().estimate('eggsToast', 1.5);
    expect(estimate.kcal, 585);
    expect(estimate.protein, 35);
    expect(estimate.carbs, 53);
    expect(estimate.fat, 27);
  });

  test('today totals include only meals from the selected day', () {
    FoodMeal meal(String date, int kcal) => FoodMeal(
        id: '$date-$kcal',
        date: date,
        time: '12:00',
        mealType: 'Lunch',
        description: 'Meal',
        foodKey: 'other',
        portions: 1,
        kcal: kcal,
        protein: 20,
        carbs: 30,
        fat: 10);
    final totals = FoodJournal().today([
      meal('2026-10-06', 500),
      meal('2026-10-06', 300),
      meal('2026-10-05', 400)
    ], '2026-10-06');
    expect(totals.kcal, 800);
    expect(totals.protein, 40);
  });
}
