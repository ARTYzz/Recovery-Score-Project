import test from "node:test";
import assert from "node:assert/strict";
import { demoData, emptyData, RecoveryEngine } from "../src/core.js";
import { RecoveryOverview } from "../src/recovery-overview.js";

test("overview waits for enough assessed domains and a personal baseline", () => {
  const assessment = new RecoveryEngine().assess(emptyData());
  const overview = RecoveryOverview.fromAssessment(assessment);
  assert.equal(overview.score, null);
  assert.equal(overview.label, "LEARNING");
  assert.equal(overview.assessed, 0);
});

test("safety concern overrides the visual overview", () => {
  const data = demoData();
  data.checkins.at(-1).headSymptoms = ["New symptoms after head contact"];
  const overview = RecoveryOverview.fromAssessment(new RecoveryEngine().assess(data));
  assert.equal(overview.label, "SAFETY");
  assert.ok(overview.score === null || overview.score <= 29);
  assert.equal(overview.counts.RESTRICTED >= 1, true);
});
