// Photo meals are estimates confirmed by the athlete, never image recognition.
export class FoodJournal {
  static foods = Object.freeze({
    chickenRice: { name: "Chicken, rice, greens", kcal: 640, protein: 52, carbs: 71, fat: 18 },
    eggsToast: { name: "Eggs and toast", kcal: 390, protein: 23, carbs: 35, fat: 18 },
    oatsYogurt: { name: "Oats and yogurt", kcal: 430, protein: 25, carbs: 58, fat: 11 },
    fishPotatoes: { name: "Fish and potatoes", kcal: 510, protein: 42, carbs: 48, fat: 16 },
    tofuNoodles: { name: "Tofu and noodles", kcal: 540, protein: 28, carbs: 65, fat: 19 },
    other: { name: "Other meal", kcal: 0, protein: 0, carbs: 0, fat: 0 },
  });

  estimate(foodKey, portions = 1) {
    const food = FoodJournal.foods[foodKey];
    if (!food || !Number.isFinite(portions) || portions <= 0 || portions > 4)
      throw Error("Choose a food and a serving size between 0.5 and 4.");
    return Object.fromEntries(
      ["kcal", "protein", "carbs", "fat"].map((key) => [
        key,
        Math.round(food[key] * portions),
      ]),
    );
  }

  createMeal(input) {
    const nutrients = {};
    for (const key of ["kcal", "protein", "carbs", "fat"]) {
      const amount = Number(input[key]);
      if (!Number.isFinite(amount) || amount < 0 || amount > 5000)
        throw Error(`Enter a valid ${key} amount.`);
      nutrients[key] = amount;
    }
    if (!input.foodKey || !FoodJournal.foods[input.foodKey])
      throw Error("Choose the food in the photo.");
    return {
      id: crypto.randomUUID(),
      date: input.date,
      time: input.time,
      mealType: input.mealType,
      foodKey: input.foodKey,
      description: FoodJournal.foods[input.foodKey].name,
      portions: Number(input.portions),
      ...nutrients,
      photo: input.photo || null,
      source: "User confirmed estimate",
    };
  }

  today(meals, day) {
    const list = (meals || []).filter((meal) => meal.date === day);
    const totals = Object.fromEntries(
      ["kcal", "protein", "carbs", "fat"].map((key) => [
        key,
        list.reduce((sum, meal) => sum + (Number(meal[key]) || 0), 0),
      ]),
    );
    return { meals: list, totals };
  }
}

export async function prepareMealPhoto(file) {
  if (!file?.type?.startsWith("image/"))
    throw Error("Choose a food photo.");
  const image = await createImageBitmap(file);
  const scale = Math.min(1, 600 / Math.max(image.width, image.height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(image.width * scale);
  canvas.height = Math.round(image.height * scale);
  canvas.getContext("2d").drawImage(image, 0, 0, canvas.width, canvas.height);
  image.close();
  // Small encrypted images fit in the existing local vault on mobile devices.
  return canvas.toDataURL("image/jpeg", 0.65);
}
