# Feature List — Recovery App for Boxers

**Status:** Design Draft  
**Scope:** v1 — Single-user athlete experience, no coach seat

**Hard constraints:**

- Manual input target ≤ 90 seconds per normal day
- Never diagnose a medical condition
- Never provide concussion clearance
- Never optimise or instruct rapid weight cutting
- Safety rules override normal recovery recommendations

---

## 0. Product One-Liner

Tracks six recovery systems, identifies what is limiting the boxer today, tells them what they can still train, and gives one recovery action for tonight — then learns whether that action appears to help over time.

---

# 1. Six Recovery Domains

Each domain has a simple athlete-facing label.

Technical terminology should stay inside the system rather than being shown unnecessarily in the UI.

| ID | Technical Domain | UI Label | Primary Inputs | Typical Recovery Timescale |
|---|---|---|---|---|
| D1 | Brain & Impact Load | **Brain** | sparring rounds, contact intensity, reported post-impact symptoms, recent sparring exposure | days–weeks |
| D2 | Energy / Nutrition / Weight | **Fuel & Weight** | morning weight trend, urine colour, post-training meal, protein intake, carbohydrate band | hours–days |
| D3 | Autonomic / Sleep Recovery | **Sleep & Heart** | HRV, resting HR, sleep duration, available sleep metrics | hours–days |
| D4 | Neuromuscular Power | **Power & Speed** | punch freshness test, punch count, punch speed/output where available | 24–72 h |
| D5 | Physical / Structural | **Body** | soreness map, pain location, severity, recent training load | days |
| D6 | Mental / Fight Stress | **Mind** | mood, motivation/stress input, camp proximity, recent load pattern | hours–days |

### Domain Rule

The six domains are evaluated independently.

The system must not hide an important limitation behind one averaged recovery number.

The main athlete-facing output is:

```text
Today's Limiter
        +
What You Can Train
        +
What You Should Avoid
```

A summary readiness state may be shown visually, but it must not override individual domain or safety status.

---

# 2. Four Training Load Types

Training load must remain separated into four categories.

| Load | Captured As | Mainly Feeds |
|---|---|---|
| **Sparring** | rounds + perceived/contact intensity | Brain, Body, Sleep & Heart |
| **Boxing / Technical** | rounds or duration + intensity | Body, Power & Speed |
| **Conditioning** | duration + intensity | Sleep & Heart, Fuel & Weight |
| **Strength** | duration + intensity | Body, Power & Speed |

### Rule

The four load types must never be collapsed into one undifferentiated training-load value.

The key reason is that different systems recover at different rates.

Example:

```text
Brain:
Caution

Body:
Ready

Result:
Avoid sparring
Upper-body strength is still allowed
```

---

# 3. Fight Camp Awareness

The application interprets recovery within the context of the athlete's current fight camp.

Suggested phases:

```text
Base
  ↓
Build
  ↓
Peak
  ↓
Taper
  ↓
Fight Week
  ↓
Post-Fight
```

Camp phase affects:

### 3.1 Interpretation

The same sleep, HRV, training-load, or fatigue pattern may have different significance depending on how close the athlete is to competition.

### 3.2 Recommendation Conservatism

Recommendations may become more conservative as the fight approaches.

Safety rules always override camp-phase logic.

### 3.3 Input Depth

Normal daily interaction should remain within the ~90-second budget.

Additional optional prompts may appear close to competition when they provide meaningful safety or recovery information.

They must not be added simply because more data is available.

---

# 4. Wearable & External Data Integration

The application should automatically import information that the athlete's existing devices already collect.

The boxer should manually enter only information that cannot be reliably obtained from the devices.

---

## 4.1 Apple Watch / Apple Health

Initial supported data may include:

- Sleep
- HRV
- Resting Heart Rate
- Heart Rate
- Workout sessions
- Workout duration
- Available activity metrics

Expected flow:

```text
Apple Watch
    ↓
Apple Health
    ↓
Recovery App
```

The application does not need to directly pair with the Apple Watch.

---

## 4.2 Android / Health Connect

Compatible Android wearables may connect through Health Connect.

Expected flow:

```text
Smartwatch
    ↓
Device Health App
    ↓
Health Connect
    ↓
Recovery App
```

Potential imported metrics include:

- Sleep
- HRV
- Resting Heart Rate
- Heart Rate
- Exercise sessions

---

## 4.3 FightCamp

FightCamp is treated as a boxing-specific performance source.

Potential useful metrics include:

- Punch count
- Punch type
- Punch speed
- Punch output
- Round-level information
- Workout/session data

Expected production flow:

```text
FightCamp
    ↓
Official API / SDK / Partner Integration
    ↓
Data Integration Layer
    ↓
Recovery Engine
```

### Prototype Rule

Until official FightCamp data access is confirmed:

- realistic mock FightCamp data may be used;
- the architecture should support a FightCamp connector;
- production code must not depend on undocumented or reverse-engineered interfaces.

---

## 4.4 Data Integration Layer

Different wearable platforms may provide similar measurements in different formats.

The application should normalize supported data before sending it to the Recovery Engine.

Example:

```text
Apple Health ─────┐
Health Connect ───┼──→ Data Integration Layer ──→ Recovery Engine
FightCamp ────────┘
```

Each imported measurement should retain its source where available.

Example:

```text
metric: HRV
value: 54
unit: ms
source: apple_health
```

---

# 5. Capture Surfaces — 90-Second Budget

## 5.1 Morning Check-in

**Frequency:** Daily  
**Target:** ~20–30 seconds

Automatically imported where available:

- Sleep
- HRV
- Resting HR

Manual inputs:

- Morning weight
- Urine colour
- Mood

Optional safety-related questions may appear when required.

---

## 5.2 After Training

**Frequency:** Per training session  
**Target:** ~20–30 seconds

Inputs:

- Training type
- Intensity
- Sparring rounds when applicable
- Contact intensity when applicable
- Pain / soreness using body map

If a wearable already detected the workout, duration and available heart-rate information should be pre-filled.

---

## 5.3 Nutrition Check

**Frequency:** Daily  
**Target:** ~10–15 seconds

Inputs:

- Post-training meal: Yes / No
- Protein intake
- Carbohydrates: Low / Medium / High

No calorie counting is required.

---

## 5.4 Punch Freshness Test

**Frequency:** Approximately 3–4 times per week  
**Target:** ~10-second test + short setup

Measures may include:

- Punch count
- Change from personal baseline

Where supported by FightCamp:

- Punch speed
- Punch output
- Other validated punch-performance metrics

The result primarily contributes to the **Power & Speed** domain.

---

## 5.5 Interaction Rule

Normal daily logging must use:

- taps;
- segmented controls;
- steppers;
- sliders;
- body-map selection.

Avoid keyboard entry in the normal daily loop wherever possible.

**Target manual interaction: ≤ 90 seconds per normal day.**

The duration of a recovery activity itself is not counted as data-entry time.

---

# 6. Main Output Surfaces

## 6.1 Today

The Today screen is the primary interface of the product.

It should answer three questions immediately:

1. What is limiting me today?
2. What can I train?
3. What should I do tonight?

### Body Condition Visual

The main visual uses a game-inspired body-condition display.

A human body silhouette shows condition using:

- **Green** — ready / good
- **Yellow** — caution / reduced readiness
- **Red** — safety concern / high restriction

The visual should feel athletic and slightly game-like, but not medical or childish.

It must not imply that the app has medically examined the athlete's body.

---

### Today Screen Content

- Fight countdown
- Current camp phase
- Body condition visualization
- Today's primary limiter
- Short explanation
- Allowed training
- Restricted training
- Six-domain overview
- One recovery action for tonight
- Wearable synchronization state

Example:

```text
18 Days to Fight

TODAY'S LIMITER
Brain & Impact

You Can Train
✓ Technique
✓ Upper-body Strength
✓ Easy Cardio

Avoid Today
✕ Sparring

Tonight
10-min Breathing Reset
[ Start ]
```

---

# 7. Domain Detail

Each domain can provide additional information without overwhelming the Today screen.

Possible content:

- Current state
- Personal baseline
- Recent trend
- Inputs contributing to the assessment
- Recent training exposure
- Reason for current status

Example:

```text
Sleep & Heart
CAUTION

HRV
12% below your recent baseline

Sleep
58 min below baseline

Resting HR
+5 bpm from baseline
```

### Transparency

The screen should show which signals contributed to the result.

Example:

```text
Reads From

Sleep
HRV
Resting HR
```

---

# 8. Personal Baselines

The system should compare recovery signals primarily with the athlete's own historical values.

Examples:

- HRV
- Resting HR
- Sleep duration
- Weight trend
- Punch count
- Punch speed
- Punch output

The application should not assume:

```text
Athlete A HRV = 60
```

means the same thing as:

```text
Athlete B HRV = 60
```

or that metrics produced by different devices are calculated identically.

### Missing Data Rule

Missing data must be represented as unavailable.

Never interpret:

```text
HRV unavailable
```

as:

```text
HRV = 0
```

---

# 9. Training Recommendation

The system should recommend specific training categories rather than simply saying:

> Rest.

Possible allowed activities include:

- Technical boxing
- Bag / pad work
- Strength training
- Easy conditioning
- Mobility
- Recovery activity

Possible restrictions include:

- Sparring
- Hard conditioning
- High-intensity boxing
- Specific strength work where physical pain makes it inappropriate

Example:

```text
Today's Limiter:
Sleep & Heart

Allowed:
✓ Technical Boxing
✓ Mobility
✓ Easy Zone 2

Avoid:
✕ Hard Conditioning
```

A full-rest recommendation should be reserved for situations where it is genuinely justified.

---

# 10. Tonight — Recovery Action

The application provides one primary recovery action each night.

Example:

```text
Tonight

10-minute breathing reset

Why:
Sleep & Heart is your limiter today.

[ Start ]
```

The screen includes:

- One action
- Short reason
- Timer where appropriate
- Completion tracking

The night screen should use a calmer, darker presentation than the normal daytime interface.

---

# 11. Recovery Feedback Loop

The feedback loop is one of the main differentiators of the product.

The system does not simply recommend an intervention.

It records what happened afterwards.

```text
Identify Limiter
      ↓
Recommend One Recovery Action
      ↓
Athlete Completes It
      ↓
Next Morning Data
      ↓
Compare Recovery Response
      ↓
Update Personal Insight
```

Possible comparison signals include:

- HRV
- Resting HR
- Sleep
- Mood
- Domain status

Over time, the application may rank recovery actions for the individual athlete.

Example:

```text
What Works for You

Breathing
Often followed by better recovery

Earlier Bedtime
Possible benefit

Cold Shower
No clear pattern yet
```

### Important Rule

The application must not present correlation as proven medical causation.

Use language such as:

- Often associated with improvement
- Possible benefit
- No clear pattern
- Not enough data

rather than:

- This treatment caused your recovery
- This intervention will fix the problem

---

# 12. Trends & Insights

The athlete can review longer-term recovery patterns.

Possible views include:

- Six-domain history
- Primary limiter history
- Sleep trend
- HRV trend
- Resting HR trend
- Weight trend
- Training load by category
- Punch performance trend
- Recovery-action effectiveness

Training load must remain visually separated into:

```text
Sparring
Technical Boxing
Conditioning
Strength
```

---

# 13. Camp View

The Camp screen provides context around the upcoming fight.

Possible content:

- Fight date
- Days remaining
- Current camp phase
- Camp timeline
- Recovery trends across camp
- Recent training-load distribution
- Body-weight trend

### Weight Rule

The Camp screen may show:

- Current weight
- Weight history
- Change over time
- Safety warnings for concerning patterns

It must not show:

- how much water to remove;
- dehydration targets;
- aggressive target loss rates;
- sauna protocols;
- methods for making weight faster.

The app monitors weight-related recovery and safety; it is not a weight-cut planner.

---

# 14. Safety Gate

Safety checks happen before normal recovery recommendations.

```text
Incoming Data
     ↓
Safety Gate
     ↓
Recovery Engine
     ↓
Recommendation Engine
```

If a safety condition is triggered, it overrides normal readiness.

---

## 14.1 Brain & Head Impact

Relevant inputs may include:

- Recent sparring exposure
- Contact intensity
- Athlete-reported symptoms
- Relevant recovery trends

### Rules

- Do not diagnose concussion.
- Do not provide concussion clearance.
- Do not allow a high readiness result to override a neurological safety flag.
- Restrict additional head-impact exposure when the configured safety conditions require it.
- Recommend qualified medical evaluation when appropriate.

Example:

```text
HEAD-IMPACT SAFETY

New symptoms were reported after head impact.

Avoid sparring and additional head-impact training.

Consider appropriate medical evaluation.

This app cannot diagnose a concussion.
```

---

## 14.2 Weight Safety

The system can monitor concerning weight and hydration trends.

It must never give instructions for:

- deliberate dehydration;
- rapid unsafe weight reduction;
- diuretic use;
- sauna-based cutting;
- extreme food restriction.

Fixed product principle:

> We monitor recovery around body weight. We do not tell athletes how to dehydrate or make weight faster.

---

# 15. Connected Devices

The athlete should be able to see which data sources are connected.

Example:

```text
Connected Sources

Apple Health
Connected
Last sync: 06:38

Syncing:
✓ Sleep
✓ HRV
✓ Resting HR
✓ Workouts
```

Possible future sources:

- Health Connect
- Garmin
- Samsung Health
- FightCamp
- Other approved integrations

The application should show when data is:

- Connected
- Syncing
- Missing
- Permission denied
- Disconnected

---

# 16. Notifications

Notifications should remain minimal.

Potential notifications:

### Morning

> Your wearable data is ready. Morning check-in takes about 30 seconds.

### Post-training

> Workout detected. Add the boxing details.

### Evening

> Tonight's recovery action is ready.

### Safety

Safety-related notifications may have higher priority where appropriate.

Notification settings must remain user-controlled.

---

# 17. Post-Camp Report

After the fight camp, the application may generate a personal recovery summary.

Possible insights:

- Most common recovery limiter
- Sparring-load patterns
- Sleep patterns
- Power / speed trend
- Weight trend
- Recovery actions that appeared helpful
- Recovery actions with no clear effect
- Changes across camp phases

The purpose is to carry useful learning into the athlete's next fight camp.

---

# 18. Explicitly Out of Scope for v1

| Feature | Reason |
|---|---|
| Coach / gym staff account | Changes the privacy and trust model of self-reported inputs |
| Team management | Outside the single-athlete v1 scope |
| Bloodwork | Breaks the phone + wearable + scale constraint |
| Force plates / laboratory equipment | Breaks the accessible-device constraint |
| Medical diagnosis | Outside intended product and regulatory scope |
| Concussion clearance | Must remain a medical decision |
| Calorie counting | Adds unnecessary input burden |
| Detailed macro tracking | Conflicts with the low-friction daily experience |
| Meal-photo recognition | Not required for the core recovery hypothesis |
| Aggressive weight-cut planning | Safety and compliance risk |
| Dehydration planning | Explicitly prohibited |
| Social feed | Does not support the core recovery problem |
| Leaderboards | Creates inappropriate incentives around recovery and weight |
| Coach AI chatbot | Not required to prove the core product concept |
| ML-based prediction | Initial version can use transparent rules and personal baselines |
| Direct support for every wearable brand | Initial integration should focus on common health platforms |
| Unofficial FightCamp integration | Production must use an approved integration mechanism |

---

# 19. Prototype Feature Scope

The prototype should demonstrate the full core loop.

### Included

- Athlete profile
- Fight date
- Fight camp phase
- Connected wearable state
- Mock wearable synchronization
- Mock FightCamp data
- Morning check-in
- Body condition visualization
- Training log
- Four training-load types
- Pain / soreness body map
- Nutrition check
- Punch freshness test
- Six recovery domains
- Safety Gate
- Primary limiter
- Allowed training
- Restricted training
- One nightly recovery action
- Recovery timer
- Basic feedback-loop insight
- Trends / history concept

### Not Required to Be Fully Functional in Prototype

- Production Apple Health integration
- Production Health Connect integration
- Production FightCamp integration
- Advanced personalized algorithms
- Long-term intervention ranking
- Production notification system
- Production legal consent infrastructure

Mock data may be used to demonstrate these flows where necessary.

---

# 20. Open Questions

### Punch Test Reliability

Bag stiffness, glove weight, technique, and environment may affect punch measurements.

Question:

> Is within-athlete trend sufficient, or should the freshness test require a standardized calibration condition?

---

### Wearable Coverage

Different watches measure HRV, sleep, and other metrics differently.

Questions:

- Which platforms are required for the first production release?
- What minimum data should the Recovery Engine require?
- How should confidence change when important metrics are unavailable?

---

### FightCamp Access

Official third-party access to detailed punch metrics must be confirmed.

Questions:

- Is a partner API available?
- Which metrics can be exported?
- Is real-time data available or only completed-session data?
- What authorization flow is required?

---

### Baseline Window

The current design assumes approximately 7–10 days before stronger personalized interpretation.

Questions:

- Is this enough for HRV and sleep?
- Should each domain have its own baseline requirement?
- What can safely be shown before sufficient baseline data exists?

---

### Missing-Day Behaviour

When an athlete misses a check-in:

- Should the system show reduced-confidence guidance?
- At what point should the system display "Not enough data"?
- Which recommendations must not be generated from stale information?

The system should never silently treat missing information as normal recovery.

---

### Fight-Week Behaviour

Fight week may justify stricter recovery rules and additional safety prompts.

Questions:

- Which inputs become more important?
- Which training categories should disappear entirely?
- Can any additional prompts remain within the normal interaction budget?

---

### Feedback-Loop Confidence

The system needs enough repeated observations before claiming that a recovery action appears useful.

Questions:

- How many comparable observations are required?
- How should confounding factors such as training load be handled?
- When should the system stop recommending an intervention with consistently poor results?