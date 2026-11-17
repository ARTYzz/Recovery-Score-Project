# Problem Review — SECONDARY Evidence

> **SECONDARY.** This repository has no records of real-user interviews with boxers. This review of published research is our Discover evidence for the problem. Pains are also stated in the [Company Charter](Company%20Charter.md) and [spec.md](spec.md).

The problem we set out to solve ([spec.md §2](spec.md)): boxers in fight camp have several kinds of fatigue, but recovery apps give one general readiness score, which cannot tell a boxer what is safe to train today.

## Sources

| # | Source | Finding | Pain it supports | What it does **not** prove |
|---|---|---|---|---|
| S-1 | Saw, Main & Gastin (2016). *Br J Sports Med* 50(5):281–291. [PMC4789708](https://pmc.ncbi.nlm.nih.gov/articles/PMC4789708/) | In 56 studies, athletes' self-reported well-being responded to training load more consistently than common objective measures | Watch data alone is not enough; short self-reports add value | That boxers specifically show this |
| S-2 | Saw, Main & Gastin (2015). *J Sports Sci Med* 14:732–739. [jssm.org](https://www.jssm.org/jssm-14-732.xml-Fulltext) | Self-directed individual-sport athletes completed self-reports 28 ± 40% of the time over 16 weeks; minimal burden and relevant content drive use | Boxers without staff need a very low-effort tool, or they stop using it | Why boxers stopped using any particular app |
| S-3 | Bernick et al. (2015). *Br J Sports Med* 49(15):1007–1011. [doi:10.1136/bjsports-2014-093877](https://doi.org/10.1136/bjsports-2014-093877) | More fight exposure associated with lower brain volumes and slower processing speed in pro boxers and MMA fighters | Head-impact (sparring) load must be treated separately from other training | That sparring load alone causes this, or that an app can prevent it |
| S-4 | Franchini, Brito & Artioli (2012). *J Int Soc Sports Nutr* 9:52. [PMC3607973](https://pmc.ncbi.nlm.nih.gov/articles/PMC3607973/) | Rapid weight loss is reported in about half of combat-sport athletes and has negative effects | Weight and hydration must be monitored safely, without weight-cut advice | How common it is among our target boxers |

## Pains derived

| Pain | Sources | Backlog response |
|---|---|---|
| One readiness score hides which system is tired | S-1, S-3 | Six separate domains (US-22), limiter (US-24) |
| Sparring needs different limits than strength or conditioning | S-3 | Four training categories (US-13, US-14), training to avoid (US-26) |
| Self-monitoring is dropped when it takes effort | S-2 | ≈ 90 s/day manual input target, tap-based check-in (US-08 – US-11) |
| Weight-cut culture is dangerous | S-4 | No weight-cut guidance, flag sudden change (US-09, US-32) |
| Head symptoms must not be overridden by a good score | S-3 | Safety Gate (US-31, US-33) |

**Limits of this review:** it is published research on athletes in general and combat sports, not interviews with our target users. It supports that the problem exists; it does not show that boxers want our solution.
