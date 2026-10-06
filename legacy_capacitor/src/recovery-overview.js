import { DOMAINS } from "./core.js";

/** A glanceable summary. Domain states and the safety gate remain authoritative. */
export class RecoveryOverview {
  static points = { READY: 90, CAUTION: 55, RESTRICTED: 20 };

  static fromAssessment(assessment) {
    const counts = { READY: 0, CAUTION: 0, RESTRICTED: 0, INSUFFICIENT_DATA: 0 };
    for (const domain of DOMAINS)
      counts[assessment.domains[domain].status]++;

    const assessed = DOMAINS.length - counts.INSUFFICIENT_DATA;
    const hasBaseline = assessment.baseline?.hrv?.ready || assessment.baseline?.sleep?.ready;
    const hasSafetyFlag = assessment.safety.length > 0;
    if (assessed < 4 || !hasBaseline) {
      return {
        score: null,
        label: hasSafetyFlag ? "SAFETY" : "LEARNING",
        tone: hasSafetyFlag ? "safety" : "learning",
        assessed,
        counts,
        explanation: hasSafetyFlag
          ? "Safety concern reported. Review restrictions below."
          : `${assessed} of 6 domains assessed · Learning your baseline`,
      };
    }

    const domainPoints = DOMAINS.reduce(
      (total, domain) => total + (RecoveryOverview.points[assessment.domains[domain].status] ?? 0),
      0,
    );
    const rawScore = Math.round(domainPoints / assessed);
    const score = hasSafetyFlag
      ? Math.min(rawScore, 29)
      : counts.RESTRICTED
        ? Math.min(rawScore, 39)
        : rawScore;
    const tone = hasSafetyFlag ? "safety" : score < 40 ? "low" : score < 70 ? "caution" : "ready";
    return {
      score,
      label: hasSafetyFlag ? "SAFETY" : tone === "low" ? "LOW" : tone === "caution" ? "CAUTION" : "READY",
      tone,
      assessed,
      counts,
      explanation: `${assessed} of 6 domains assessed · See each domain below`,
    };
  }
}
