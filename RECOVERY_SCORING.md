# Recovery scoring in the Flutter prototype

`RecoveryEngine` evaluates six independent domains. There is no average or overall readiness score. Today shows the lowest available domain score as the primary limiter; a Safety Gate flag takes precedence. A missing input or an unready baseline stays unavailable, never zero.

| Domain | Current input | Prototype calculation |
| --- | --- | --- |
| Brain & Impact | Morning head-symptom answer; sparring rounds and contact in the last 7 days | Starts at 100 after a check-in and subtracts contact load with a 3-day exponential decay. Head symptoms or post-contact head pain force 0 and safety restrictions. This warning persists across days even after a symptom-free check-in. Repeated heavy contact caps at 39. |
| Fuel & Weight | Urine colour, post-training meal/protein/carbs, consecutive morning weights | Weighted available components: hydration 50%, routine 35%, 24-hour weight change 15%. Weights are normalized when an input is missing. A change greater than 1.5% in one day is a safety concern, not a weight-loss target. |
| Sleep & Heart | Today's HealthKit sleep duration, HRV SDNN, resting HR | Compares each metric with its own previous 30-day baseline, requiring at least 7 historical days. Available HRV, RHR and sleep components carry 40%, 30% and 30%, with missing components excluded and remaining weights normalized. HRV is not inferred from heart rate. |
| Power & Speed | FightCamp punch count | Compares today's count with the mean of the best 3 from at least 4 prior session days in 30 days, from the same source. The bundled FightCamp connector is explicitly demo data; it is not an API connection. |
| Body | Reported pain area/severity and recent training load | Subtracts more for painful/severe reports, and 1.5 times as much for head, neck, hands or wrists. Long hard sessions and long strength with sore areas add load. Severe pain invokes the Safety Gate. |
| Mind | Morning mood and recent mood history | Maps Good/OK/Flat/Low to 100/75/45/25 and subtracts 15 after three consecutive Flat/Low days. This is a check-in trend, not a diagnosis. |

Scores 80–100 are Ready, 50–79 are Caution, and below 50 are Restricted. These thresholds are prototype heuristics for training guidance, not validated medical scores. Safety restrictions override them. The training advisor returns separate guidance for sparring, technical boxing, conditioning and strength. The completed night action stores its target domain score; the next morning stores the observed change. Feedback needs at least three comparable observations and does not claim causation.

After a head-impact concern, the app pauses training guidance and prompts qualified professional evaluation. A user may record that they received an external return-to-contact plan; this is an unverified self-report, never app-issued clearance. The incident day remains restricted, a later report of symptoms starts a new warning, and subsequent guidance defers to the external plan without marking any of the four training categories unconditionally available.

The supplied formula also mentions reaction/balance tests, rMSSD, deep-sleep efficiency, respiratory rate, motivation/pressure and three-meal protein completion. The current app does not collect those inputs, so it does not invent them. HealthKit's available HRV metric is SDNN. Weight-cut and post weigh-in rehydration instructions from the supplied text are excluded under `.docs/rule.md`.
