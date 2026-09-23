# System Specification — Boxer Recovery App

**File:** `.docs/01-requirements/spec.md`  
**Status:** Design Draft  
**Version:** v1 Prototype  
**Primary User:** Professional boxer  
**Scope:** Single-athlete mobile application, no coach seat

---

# 1. Purpose

The Boxer Recovery App is a mobile recovery-support application designed for professional boxers during fight camp.

The system combines wearable data, boxing-specific training information, and short athlete self-reports to answer three daily questions:

1. **What is limiting me today?**
2. **What can I still train, and what should I avoid?**
3. **What is one recovery action I should do tonight?**

The system then observes the athlete's following-day recovery data to determine whether previous recovery actions appear to be helpful for that individual.

The application is not intended to diagnose medical conditions or replace professional medical assessment.

---

# 2. Product Goals

The system SHALL:

- reduce daily manual input to approximately 90 seconds or less under normal use;
- automatically import supported wearable data;
- evaluate recovery across six independent domains;
- distinguish four different types of training load;
- consider the athlete's current fight-camp phase;
- identify a primary recovery limiter;
- provide allowed and restricted training guidance;
- provide one prioritized recovery action;
- track whether recovery actions appear to help over time;
- prioritize safety over performance recommendations.

---

# 3. Product Constraints

The system MUST comply with the following constraints:

- Single athlete account in v1
- No coach dashboard in v1
- No medical diagnosis
- No concussion clearance
- No aggressive weight-cut planning
- No dehydration instructions
- No calorie counting requirement
- No laboratory equipment requirement
- No requirement for blood testing
- No assumption that all athletes use the same wearable brand
- No dependence on unofficial FightCamp APIs

All compliance and safety implementation must follow `rule.md`.

---

# 4. Primary User

The primary user is a professional boxer who:

- trains regularly during a fight camp;
- manages much of their own day-to-day recovery;
- uses a smartphone;
- may own a smartwatch or fitness wearable;
- has access to a body-weight scale;
- may use FightCamp or another boxing-specific tracking device;
- requires fast and actionable information rather than detailed sports-science dashboards.

---

# 5. Core Recovery Model

The application evaluates six recovery domains independently.

| ID | Domain | UI Label |
|---|---|---|
| D1 | Brain & Impact Load | Brain |
| D2 | Energy / Nutrition / Weight | Fuel & Weight |
| D3 | Autonomic / Sleep Recovery | Sleep & Heart |
| D4 | Neuromuscular Power | Power & Speed |
| D5 | Physical / Structural Recovery | Body |
| D6 | Mental / Fight Stress | Mind |

Each domain SHALL produce an independent state.

Suggested states:

```text
READY
CAUTION
RESTRICTED
INSUFFICIENT_DATA
```

The application MAY display these visually as:

```text
Green  = Ready
Yellow = Caution
Red    = Restricted / Safety Concern
Gray   = Insufficient Data
```

A general visual readiness state MAY be shown, but MUST NOT hide or override an individual domain or safety condition.

---

# 6. Training Load Model

The system SHALL maintain four independent training-load categories.

```text
SPARRING
BOXING_TECHNICAL
CONDITIONING
STRENGTH
```

## 6.1 Sparring Load

Possible inputs:

- sparring rounds;
- session duration;
- intensity;
- contact intensity.

Primarily affects:

- Brain;
- Body;
- Sleep & Heart.

---

## 6.2 Boxing / Technical Load

Possible inputs:

- rounds;
- duration;
- intensity.

Examples:

- bag work;
- pads;
- drills;
- shadowboxing;
- technical boxing.

Primarily affects:

- Body;
- Power & Speed.

---

## 6.3 Conditioning Load

Possible inputs:

- duration;
- intensity;
- wearable workout data.

Primarily affects:

- Sleep & Heart;
- Fuel & Weight.

---

## 6.4 Strength Load

Possible inputs:

- duration;
- perceived intensity.

Primarily affects:

- Body;
- Power & Speed.

---

## 6.5 Load Rule

The four load types MUST NOT be reduced into one undifferentiated workload for recovery decisions.

Example:

```text
Brain: CAUTION
Body: READY

Allowed:
- Strength
- Technical boxing

Restricted:
- Sparring
```

---

# 7. Fight Camp Model

Each active athlete MAY have one active fight camp.

A fight camp SHALL include:

- fight date;
- days remaining;
- current camp phase.

Suggested phases:

```text
BASE
BUILD
PEAK
TAPER
FIGHT_WEEK
POST_FIGHT
```

Fight-camp phase SHALL be available as an input to the Recovery Engine.

The same physiological signal MAY result in different recommendations depending on camp phase.

Safety rules MUST always override camp-phase logic.

---

# 8. Data Sources

The system supports three major categories of data.

## 8.1 Wearable Data

Potential automatically imported information:

- sleep duration;
- sleep-related metrics;
- HRV;
- resting heart rate;
- heart rate;
- workout sessions;
- workout duration;
- available activity metrics.

---

## 8.2 Athlete Self-Report

Manual information may include:

- morning weight;
- urine colour;
- mood;
- pain or soreness;
- training classification;
- training intensity;
- sparring rounds;
- contact intensity;
- nutrition behaviour;
- relevant safety symptoms.

---

## 8.3 Boxing Performance Data

Possible sources include:

- FightCamp through an officially supported integration;
- synthetic FightCamp sessions in the prototype.

Possible metrics:

- punch count;
- punch speed;
- punch output;
- punch type;
- round-level performance.

---

# 9. Wearable Integration

The system SHALL use a platform-based integration strategy instead of attempting to directly pair with every smartwatch model.

---

## 9.1 Apple Ecosystem

Expected flow:

```text
Apple Watch
    ↓
Apple Health
    ↓
HealthKit
    ↓
Mobile App
    ↓
Backend
```

Supported metrics may include:

- sleep;
- HRV;
- resting heart rate;
- heart rate;
- workouts.

The athlete SHALL explicitly grant required permissions.

---

## 9.2 Android Ecosystem

Expected flow:

```text
Compatible Watch
      ↓
Health Application
      ↓
Health Connect
      ↓
Mobile App
      ↓
Backend
```

Supported data SHALL be normalized into the same internal format used for other wearable sources.

---

## 9.3 FightCamp

FightCamp SHALL be treated as a boxing-specific training data source.

Target data may include:

- session data;
- punch count;
- punch speed;
- punch output;
- punch type;
- round performance.

Production integration MUST use an officially supported API, SDK, export, or partnership mechanism.

Until official access is confirmed, the prototype MAY use realistic mock FightCamp data.

---

# 10. Data Integration Layer

The Data Integration Layer SHALL normalize external data before it is used by the Recovery Engine.

A normalized measurement should contain at least:

```text
athlete_id
metric_type
value
unit
source
recorded_at
```

Example:

```json
{
  "metric_type": "hrv",
  "value": 54,
  "unit": "ms",
  "source": "apple_health",
  "recorded_at": "2026-09-21T06:30:00+07:00"
}
```

Possible sources include:

```text
apple_health
health_connect
fightcamp
manual
```

The source SHOULD remain traceable because different devices may calculate similar metrics differently.

---

# 11. Morning Check-In

**Frequency:** Daily  
**Target interaction:** 20–30 seconds

After onboarding, the first Start action SHALL open Morning Check-In. On a later unlock or app return, the application SHALL open it automatically when no check-in is saved for the current local date. A completed check-in SHALL not prompt again that day. Today SHALL not require a manual entry button for this daily flow.

The system SHALL automatically display available:

- sleep;
- HRV;
- resting heart rate.

The athlete SHALL manually enter:

- morning weight;
- urine colour;
- mood.

The system MAY request additional safety information when required.

The normal morning flow SHOULD avoid keyboard input.

---

# 12. Training Log

The athlete SHALL be able to record a completed training session.

The session SHALL include:

- training category;
- duration where available;
- intensity.

For sparring, the system SHOULD additionally support:

- number of rounds;
- contact intensity.

If a wearable workout is already available, the application SHOULD pre-fill:

- start time;
- end time;
- duration;
- supported heart-rate information.

The athlete SHALL still classify the boxing-specific training type because a generic wearable workout cannot reliably determine whether a session was sparring, pads, or technical boxing.

---

# 13. Pain & Soreness

The application SHALL provide a body-based interface for reporting pain or soreness.

Each entry SHOULD contain:

```text
body_part
severity
recorded_at
```

The application SHOULD prefer tap-based body selection over text entry.

Pain information MAY influence:

- Body domain;
- training restrictions;
- Safety Gate.

Pain reporting MUST NOT automatically generate a medical diagnosis.

---

# 14. Nutrition Check

**Frequency:** Daily  
**Target interaction:** 10–15 seconds

The nutrition check SHALL remain intentionally lightweight.

Suggested inputs:

- post-training meal completed: Yes / No;
- protein intake indicator;
- carbohydrate intake: Low / Medium / High.

The system SHALL NOT require calorie counting.

The system SHALL NOT require detailed macro tracking.

---

# 15. FightCamp Performance Data

Power & Speed SHALL use punch and session data from FightCamp where an official integration is available. The athlete is not asked to perform or enter a separate Punch Test.

Until official access is confirmed, the prototype SHALL use a clearly labelled mock FightCamp connector and synthetic sessions. The normalized session model supports punch count and optional speed, output, rounds, and session ID.

After health-data consent and onboarding Start, the prototype SHALL load FightCamp mock sessions automatically. Existing consented local profiles SHALL receive the mock data on unlock. The athlete SHALL not need to press a Connect, Sync, or Load button for this sample source. The UI SHALL state that no real FightCamp account or API is connected.

Punch count SHOULD be compared with a personal baseline from at least four distinct session days from the same source. Missing metrics remain unavailable. FightCamp data contributes primarily to Power & Speed.

---

# 16. Personal Baseline

The Recovery Engine SHOULD evaluate relevant measurements against the athlete's own history.

Potential baseline metrics include:

- HRV;
- resting heart rate;
- sleep duration;
- morning weight;
- punch count;
- punch speed;
- punch output.

The baseline window MAY vary by metric.

The prototype may initially use approximately:

```text
7–10 days
```

before producing stronger personalized recovery interpretations.

Before sufficient baseline data exists, the system SHOULD display:

```text
Learning your baseline
```

rather than pretending that a confident assessment is available.

---

# 17. Missing Data

Missing measurements MUST NOT be interpreted as zero.

Example:

```text
HRV unavailable
```

MUST NOT become:

```text
HRV = 0
```

The Recovery Engine SHALL support partial data.

When insufficient information exists, a domain MAY return:

```text
INSUFFICIENT_DATA
```

The application SHOULD communicate reduced confidence to the athlete.

---

# 18. Safety Gate

The Safety Gate SHALL execute before normal recovery and training recommendations.

Processing order:

```text
Collect Data
    ↓
Safety Gate
    ↓
Recovery Engine
    ↓
Recommendation Engine
```

If the Safety Gate is triggered, safety restrictions SHALL override normal readiness results.

---

# 19. Head-Impact Safety

The system MAY use:

- recent sparring exposure;
- contact intensity;
- athlete-reported symptoms;
- relevant recovery trends.

The system MUST NOT:

- diagnose concussion;
- diagnose traumatic brain injury;
- provide return-to-play medical clearance.

If configured safety criteria are triggered, the system MAY:

- restrict sparring;
- restrict additional head-impact training;
- present an appropriate safety warning;
- recommend professional medical evaluation.

Example:

```text
HEAD-IMPACT SAFETY

New symptoms were reported after head impact.

Avoid sparring and additional head-impact training.

Consider appropriate medical evaluation.

This app cannot diagnose a concussion.
```

---

# 20. Weight Safety

The application MAY monitor:

- morning weight;
- weight trend;
- hydration indicator;
- unusual short-term weight changes.

The application MUST NOT provide:

- dehydration targets;
- water-restriction instructions;
- diuretic guidance;
- aggressive rapid-weight-loss instructions;
- sauna cutting protocols;
- instructions for making weight faster.

The application is a recovery-monitoring system, not a weight-cutting planner.

---

# 21. Recovery Engine

The Recovery Engine SHALL receive normalized data from:

- wearable integrations;
- morning check-in;
- training history;
- nutrition check;
- FightCamp punch and session data;
- pain/soreness data;
- fight-camp context.

The engine SHALL evaluate the six domains independently.

Example output:

```json
{
  "brain": "CAUTION",
  "fuel_weight": "READY",
  "sleep_heart": "CAUTION",
  "power_speed": "READY",
  "body": "READY",
  "mind": "READY"
}
```

The initial prototype MAY use transparent rule-based logic.

Machine learning is NOT required for v1.

---

# 22. Primary Limiter

After domain evaluation, the system SHALL identify the primary recovery limiter when sufficient information exists.

Example:

```text
Today's Limiter
Sleep & Heart
```

The system SHOULD provide a short explanation.

Example:

```text
HRV is below your recent baseline
and sleep was shorter than usual.
```

The primary limiter SHALL NOT override a Safety Gate restriction.

---

# 23. Daily Training Recommendation

The Recommendation Engine SHALL convert recovery information into actionable training guidance.

The system SHALL distinguish:

```text
Allowed Training
```

from:

```text
Restricted Training
```

Example:

```text
You Can Train

✓ Technical Boxing
✓ Upper-body Strength
✓ Easy Cardio

Avoid Today

✕ Sparring
```

The system SHOULD avoid giving a generic "rest" recommendation unless genuinely justified.

The purpose is to identify what the athlete can still safely do.

---

# 24. Today Screen

The Today screen SHALL be the main application screen.

It SHOULD contain:

- fight countdown;
- current camp phase;
- body-condition visualization;
- primary limiter;
- six-domain status;
- allowed training;
- restricted training;
- one recovery action;
- wearable synchronization state.

---

## 24.1 Body Condition Visualization

The Today screen SHOULD include a game-inspired human body condition visual.

Suggested visual states:

```text
Green  = Ready
Yellow = Caution
Red    = Restricted / Safety Concern
Gray   = No Data
```

The design SHALL remain:

- clean;
- calm;
- premium;
- easy to understand.

The visual MUST NOT suggest that the application has medically examined or diagnosed the athlete.

---

# 25. Night Recovery Action

Each day the application SHOULD recommend one primary recovery action.

Example:

```text
Tonight

10-minute breathing reset

Reason:
Sleep & Heart is today's limiter.

[ Start ]
```

The action MAY include a built-in timer.

The system SHALL record:

- recommended action;
- whether it was started;
- whether it was completed;
- completion time.

---

# 26. Recovery Feedback Loop

The system SHOULD compare completed recovery actions with following-day recovery information.

Flow:

```text
Today's Limiter
      ↓
Recovery Action
      ↓
Action Completed
      ↓
Next-Day Recovery Data
      ↓
Compare Response
      ↓
Update Personal Insight
```

Potential comparison data includes:

- HRV;
- resting heart rate;
- sleep;
- mood;
- targeted domain state.

---

# 27. Intervention Insights

After enough repeated observations, the system MAY classify recovery actions using descriptions such as:

```text
Usually Helpful
Possible Benefit
No Clear Pattern
Insufficient Data
```

Example:

```text
Breathing
Usually followed by better recovery

Earlier Bedtime
Possible benefit

Cold Shower
No clear pattern
```

The application MUST NOT present observational correlation as medical causation.

---

# 28. Trends

The athlete SHOULD be able to view historical information.

Potential trends include:

- recovery-domain history;
- primary limiter history;
- HRV;
- resting heart rate;
- sleep;
- weight;
- punch performance;
- training load;
- recovery-action response.

Training-load history SHALL preserve separate categories:

```text
Sparring
Technical Boxing
Conditioning
Strength
```

---

# 29. Connected Devices

The system SHOULD provide a connected-data-source screen.

Example:

```text
Apple Health
Connected

Last Sync
06:38

Syncing
✓ Sleep
✓ HRV
✓ Resting HR
✓ Workouts
```

Supported states SHOULD include:

```text
CONNECTED
SYNCING
PERMISSION_REQUIRED
DATA_UNAVAILABLE
DISCONNECTED
```

---

# 30. Notifications

Notifications SHOULD remain minimal and optional.

Potential notifications include:

### Morning

```text
Your wearable data is ready.
Morning check-in takes about 30 seconds.
```

### Post-Training

```text
Workout detected.
Add the boxing details.
```

### Evening

```text
Tonight's recovery action is ready.
```

Users SHALL be able to manage notification preferences.

---

# 31. Post-Camp Report

After completion of a fight camp, the application MAY generate a personal recovery report.

The report may include:

- most common limiter;
- training-load patterns;
- sleep trend;
- HRV trend;
- punch-performance trend;
- weight trend;
- recovery actions that appeared useful;
- recovery actions with no clear effect;
- differences between fight-camp phases.

The report is intended to provide useful historical context for the athlete's next camp.

---

# 32. Functional Requirements

## FR-01 — Athlete Profile

The system SHALL allow the athlete to create and manage a profile.

**Backlog:** US-01

---

## FR-02 — Fight Camp

The system SHALL allow the athlete to configure an upcoming fight date and derive the current camp phase.

**Backlog:** US-02, US-03

---

## FR-03 — Wearable Connection

The system SHALL support connection to approved wearable-data ecosystems.

**Backlog:** US-04, US-05

---

## FR-04 — Data Normalization

The system SHALL normalize wearable measurements into a common internal representation.

**Backlog:** US-06

---

## FR-05 — FightCamp Source

The architecture SHALL support FightCamp as a future external boxing-performance data source.

**Backlog:** US-07

---

## FR-06 — Morning Check-In

The athlete SHALL be able to record morning weight, urine colour, and mood.

**Backlog:** US-08–US-11

---

## FR-07 — Training Log

The athlete SHALL be able to classify and record training sessions.

**Backlog:** US-12–US-15

---

## FR-08 — Nutrition Check

The athlete SHALL be able to complete a lightweight nutrition check without calorie counting.

**Backlog:** US-16, US-17

---

## FR-09 — Pain Logging

The athlete SHALL be able to record pain or soreness using a body-based interface.

**Backlog:** US-18, US-19

---

## FR-10 — FightCamp Punch Performance

The application SHALL support FightCamp punch performance through an authorized integration when available, and a labelled mock connector in the prototype. It SHALL NOT require a separate manual Punch Test.

**Backlog:** US-20, US-21

---

## FR-11 — Six-Domain Assessment

The Recovery Engine SHALL independently evaluate all six recovery domains.

**Backlog:** US-22

---

## FR-12 — Personal Baseline

The Recovery Engine SHALL support comparison against athlete-specific historical baselines.

**Backlog:** US-23

---

## FR-13 — Primary Limiter

The system SHALL identify a primary recovery limiter when sufficient information exists.

**Backlog:** US-24

---

## FR-14 — Training Guidance

The system SHALL provide separate allowed and restricted training categories.

**Backlog:** US-25, US-26

---

## FR-15 — Recovery Action

The system SHALL recommend one primary nightly recovery action.

**Backlog:** US-27

---

## FR-16 — Recovery Timer

Timed recovery actions SHALL support basic timer functionality.

**Backlog:** US-28

---

## FR-17 — Feedback Loop

The system SHALL support comparison between completed recovery actions and following-day recovery information.

**Backlog:** US-29, US-30

---

## FR-18 — Safety Gate

The system SHALL evaluate configured safety conditions before normal recovery recommendations.

**Backlog:** US-31–US-33

---

## FR-19 — Recovery History

The athlete SHALL be able to view relevant historical recovery information.

**Backlog:** US-34, US-35

---

## FR-20 — Data Control

The user SHALL be able to manage health-data access and account/data deletion according to applicable requirements.

**Backlog:** US-38–US-40

---

# 33. Non-Functional Requirements

## NFR-01 — Daily Input Time

Normal mandatory manual input SHOULD remain approximately:

```text
≤ 90 seconds per day
```

excluding the duration of recovery activities themselves.

---

## NFR-02 — Mobile-First

The user experience SHALL be optimized for smartphone use.

---

## NFR-03 — Low Input Friction

Daily flows SHOULD prioritize:

- taps;
- swatches;
- segmented controls;
- sliders;
- steppers.

Keyboard entry SHOULD be avoided in the normal daily loop.

---

## NFR-04 — Data Security

Sensitive health and recovery information SHALL be protected in accordance with `rule.md`.

---

## NFR-05 — Encrypted Transport

Production communication containing personal or health information SHALL use secure encrypted transport.

---

## NFR-06 — Privacy

One athlete SHALL NOT be able to access another athlete's personal recovery information.

---

## NFR-07 — Missing Data Resilience

The application SHALL continue functioning when optional wearable measurements are unavailable.

---

## NFR-08 — External Integration Isolation

Wearable and FightCamp integrations SHOULD remain isolated behind the Data Integration Layer.

Failure of one external provider SHOULD NOT require redesigning the Recovery Engine.

---

## NFR-09 — Explainability

Important recovery or training restrictions SHOULD provide a human-readable reason.

---

## NFR-10 — Safety Priority

Safety rules SHALL have higher priority than performance or readiness logic.

---

# 34. Prototype Scope

The prototype SHALL demonstrate the complete core recovery flow.

## Required Prototype Features

- Athlete profile
- Fight date
- Fight camp phase
- Connected wearable state
- Simulated wearable synchronization
- Simulated FightCamp data
- Morning check-in
- Training log
- Four training-load categories
- Pain body map
- Nutrition check
- FightCamp punch and session data view
- Six recovery domains
- Game-inspired body condition view
- Safety Gate
- Primary limiter
- Allowed training
- Restricted training
- Night recovery action
- Recovery timer
- Basic feedback-loop result
- Basic trends

---

# 35. Prototype Data

The prototype MAY use synthetic data.

Example athlete:

```text
Fight in: 18 days
Camp phase: Peak

Sleep: 6h 08m
HRV: 12% below baseline
Resting HR: +5 bpm
Morning weight: 68.4 kg
Mood: Neutral

Yesterday:
8 rounds sparring
Intensity: Hard
```

Possible output:

```text
Today's Limiter
Brain & Impact

Brain          CAUTION
Fuel & Weight  READY
Sleep & Heart  CAUTION
Power & Speed  READY
Body           READY
Mind           READY

You Can Train
✓ Technical Boxing
✓ Upper-body Strength
✓ Easy Cardio

Avoid Today
✕ Sparring

Tonight
10-minute breathing reset
```

---

# 36. Prototype Success Criteria

The prototype is successful when it can demonstrate the following complete journey:

```text
Create Athlete
      ↓
Set Fight Date
      ↓
Connect Wearable
      ↓
Import Recovery Data
      ↓
Morning Check-In
      ↓
Safety Gate
      ↓
Evaluate Six Domains
      ↓
Identify Primary Limiter
      ↓
Show Allowed / Restricted Training
      ↓
Log Training
      ↓
Nutrition / Punch Data
      ↓
Generate Night Recovery Action
      ↓
Complete Action
      ↓
Next-Day Data
      ↓
Show Recovery Feedback
```

A stakeholder should be able to understand the core product value without needing the scoring algorithm explained.

---

# 37. Out of Scope for v1

The following are explicitly outside the initial product scope:

- Coach dashboard
- Team management
- Social feed
- Leaderboards
- Medical diagnosis
- Concussion clearance
- Injury diagnosis
- Bloodwork
- Laboratory testing
- Force plates
- Detailed calorie counting
- Full macro tracking
- Meal image recognition
- Aggressive weight-cut planning
- Dehydration protocols
- Direct Bluetooth support for every watch manufacturer
- Unofficial FightCamp reverse engineering
- AI coach chatbot
- Machine-learning recovery prediction

---

# 38. Related Documentation

This specification should be read together with:

```text
.docs/01-requirements/backlog.md
.docs/01-requirements/legal-requirements.md
.docs/02-design/user-journey.md
.docs/02-design/feature-list.md
rule.md
```

Design diagrams are stored in:

```text
.docs/02-design/diagrams/
```

Including:

```text
erd.png
system-architecture.jpg
use-case.jpg
user-flow.png
```

---

# 39. Requirement Traceability

The expected documentation flow is:

```text
Updated Proposal
      ↓
Product Specification
      ↓
Product Backlog
      ↓
Feature List / User Journey
      ↓
Design Diagrams
      ↓
Implementation
      ↓
Testing
```

Legal and safety requirements follow a parallel trace:

```text
Week 2 Legal Research
      ↓
Legal Requirement Specification
      ↓
rule.md
      ↓
Product Requirements
      ↓
Implementation
      ↓
Compliance Testing
```

When a feature conflicts with a rule in `rule.md`, the compliance and safety rule takes precedence.
