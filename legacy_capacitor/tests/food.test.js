import test from "node:test";
import assert from "node:assert/strict";
import { FoodJournal } from "../src/food.js";
import { AthleteVault } from "../src/vault.js";

test("food estimates scale with confirmed servings and total only today's meals", () => {
  const journal = new FoodJournal();
  const one = journal.estimate("chickenRice", 1);
  const half = journal.estimate("chickenRice", 0.5);
  assert.equal(one.kcal, 640);
  assert.equal(half.protein, 26);
  const today = journal.today([
    { date: "2026-09-23", ...one },
    { date: "2026-09-23", ...half },
    { date: "2026-09-22", ...one },
  ], "2026-09-23");
  assert.equal(today.meals.length, 2);
  assert.equal(today.totals.kcal, 960);
  assert.equal(today.totals.protein, 78);
});

test("invalid nutrient values cannot be saved", () => {
  const journal = new FoodJournal();
  assert.throws(() => journal.createMeal({ foodKey: "chickenRice", kcal: -1, protein: 1, carbs: 1, fat: 1 }));
});

test("encrypted vault saves and restores a large meal photo", async () => {
  const items = new Map();
  const storage = {
    getItem: (key) => items.get(key) || null,
    setItem: (key, value) => items.set(key, value),
    removeItem: (key) => items.delete(key),
  };
  const photo = `data:image/jpeg;base64,${"A".repeat(500_000)}`;
  const data = { foodMeals: [{ id: "meal-1", photo }] };
  const vault = new AthleteVault(storage);
  await vault.create("large-photo-passphrase", data);
  vault.lock();
  const restored = await vault.unlock("large-photo-passphrase");
  assert.equal(restored.foodMeals[0].photo.length, photo.length);
});
