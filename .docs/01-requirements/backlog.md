## 1. Purpose

This document defines the product backlog for the Boxing Recovery Tracking Application.

The backlog is organized around the main user journey:

1. Connect health and training data sources.
2. Complete short daily check-ins.
3. Record boxing-specific training information.
4. Evaluate recovery across six domains.
5. Identify the athlete's main limiter.
6. Recommend suitable and restricted training.
7. Provide one recovery action.
8. Track whether recovery actions appear to help over time.

The primary user is a professional boxer using the application independently during a fight camp.

---

# 2. Priority Levels

| Priority | Meaning                         |
| -------- | ------------------------------- |
| P0       | Required for the core prototype |
| P1       | Important for an MVP            |
| P2       | Useful future enhancement       |
| P3       | Optional / long-term feature    |

---

# 3. Epic Overview

| Epic | Description                          | Priority |
| ---- | ------------------------------------ | -------- |
| E1   | Athlete Profile and Fight Camp       | P0       |
| E2   | Wearable and Health Data Integration | P0       |
| E3   | Morning Recovery Check-in            | P0       |
| E4   | Training Logging                     | P0       |
| E5   | Nutrition and Energy Check-in        | P0       |
| E6   | Physical and Mental Check-in         | P0       |
| E7   | Punch Freshness Measurement          | P0       |
| E8   | Recovery Assessment Engine           | P0       |
| E9   | Daily Training Recommendation        | P0       |
| E10  | Recovery Action and Timer            | P0       |
| E11  | Personal Recovery Feedback           | P1       |
| E12  | Safety Rules                         | P0       |
| E13  | History and Insights                 | P1       |
| E14  | Notifications and Reminders          | P2       |
| E15  | Data Privacy and User Control        | P0       |

---

# 4. Product Backlog

## E1 — Athlete Profile and Fight Camp

### US-01 — Create Athlete Profile

**Priority:** P0

As an athlete,
I want to create my personal profile,
so that the application can personalize recovery information to me.

### Acceptance Criteria

* The athlete can create a profile.
* The profile supports basic information required by the recovery system.
* The athlete can edit their profile later.
* Medical diagnosis information is not required for normal onboarding.

---

### US-02 — Set Upcoming Fight

**Priority:** P0

As an athlete,
I want to enter my next fight date,
so that recovery recommendations can consider how close I am to competition.

### Acceptance Criteria

* The athlete can enter an upcoming fight date.
* The application displays the number of days remaining.
* The athlete can update or remove the fight date.
* The system can determine the current fight camp phase from the fight date.

---

### US-03 — Determine Fight Camp Phase

**Priority:** P0

As an athlete,
I want my recovery status to be interpreted according to my fight camp phase,
so that recommendations reflect my current preparation stage.

### Acceptance Criteria

* The system assigns a fight camp phase based on the configured fight date.
* Recovery rules can use fight camp phase as an input.
* The same recovery metric may result in different recommendations in different camp phases.
* Fight camp phase rules must be configurable.

---

# E2 — Wearable and Health Data Integration

### US-04 — Connect Apple Health

**Priority:** P0

As an athlete using an Apple Watch,
I want to connect Apple Health,
so that supported recovery data can be imported automatically.

### Acceptance Criteria

* The application requests explicit permission before accessing health data.
* The athlete can choose whether to grant access.
* Supported data may include:

  * sleep;
  * heart rate;
  * resting heart rate;
  * HRV;
  * workouts;
  * workout duration;
  * available activity metrics.
* The application displays the latest synchronization status.
* The athlete can disconnect the integration.

---

### US-05 — Connect Android Health Data

**Priority:** P1

As an athlete using a compatible Android wearable,
I want to connect through Health Connect,
so that supported health and workout data can be synchronized.

### Acceptance Criteria

* The application supports Health Connect permission flow.
* Supported metrics are normalized into the application's internal format.
* The source of imported data is recorded.
* Missing metrics do not prevent the rest of the application from functioning.

---

### US-06 — Normalize Wearable Data

**Priority:** P0

As the recovery system,
I want wearable data from different sources to use a common internal structure,
so that the recovery engine does not depend on one device brand.

### Acceptance Criteria

The normalized data model supports at minimum:

* metric type;
* value;
* unit;
* timestamp;
* source;
* user identifier.

Supported normalized metrics should include:

* sleep duration;
* HRV;
* resting heart rate;
* heart rate;
* workout duration;
* workout type.

---

### US-07 — FightCamp Integration

**Priority:** P1

As an athlete using FightCamp,
I want FightCamp training information to be available in the recovery application,
so that boxing performance data can contribute to my recovery assessment.

### Acceptance Criteria

The application architecture must support potential FightCamp data including:

* punch count;
* punch type;
* punch speed;
* punch output;
* round-level data;
* workout/session information.

For the prototype:

* FightCamp data may be represented using realistic mock data.
* The user interface may display FightCamp as a connected training source.

For production:

* Direct integration must not be assumed until official API, SDK, or partner access is confirmed.
* The implementation must comply with FightCamp's supported integration mechanism.

---

# E3 — Morning Recovery Check-in

### US-08 — Complete Morning Check-in

**Priority:** P0

As an athlete,
I want to complete a very short morning check-in,
so that the application can combine my subjective condition with wearable data.

### Acceptance Criteria

The morning check-in allows the athlete to enter:

* morning body weight;
* urine color;
* mood.

The screen also displays available automatic data such as:

* sleep;
* HRV;
* resting heart rate.

The interaction should normally take approximately 30 seconds or less.

---

### US-09 — Record Morning Weight

**Priority:** P0

As an athlete,
I want to record my morning weight,
so that the application can track body-weight trends.

### Acceptance Criteria

* Weight can be entered quickly.
* Historical weight trend is retained.
* The system does not provide unsafe rapid weight-cut instructions.
* Significant changes may trigger a safety-oriented warning.

---

### US-10 — Record Hydration Indicator

**Priority:** P0

As an athlete,
I want to select my urine color,
so that the system has a simple self-reported hydration indicator.

### Acceptance Criteria

* The user can select a urine color using a visual scale.
* No text entry is required.
* The value contributes to the energy/hydration domain.

---

### US-11 — Record Mood

**Priority:** P0

As an athlete,
I want to quickly record my mood,
so that mental condition can contribute to my recovery assessment.

### Acceptance Criteria

* Mood can be entered using a simple tap-based scale.
* The check-in should not require free-text input.
* Mood history can be used as a personal trend.

---

# E4 — Training Logging

### US-12 — Detect Imported Workout

**Priority:** P0

As an athlete,
I want the application to recognize workouts imported from my wearable,
so that I do not have to enter information the device already knows.

### Acceptance Criteria

* Imported workout sessions can display:

  * start time;
  * end time;
  * duration;
  * available heart-rate data.
* The athlete can confirm or classify the workout.
* The application must not assume that a generic boxing workout represents sparring.

---

### US-13 — Classify Boxing Training

**Priority:** P0

As an athlete,
I want to classify my training session,
so that the application can separate different types of recovery load.

### Acceptance Criteria

The user can classify training into at least:

1. Sparring
2. Boxing / Technical Training
3. Conditioning
4. Strength Training

Optional boxing subtypes may include:

* Bag work;
* Pads;
* Shadowboxing;
* Drills.

---

### US-14 — Record Sparring Load

**Priority:** P0

As an athlete,
I want to record sparring rounds and intensity,
so that head-impact-related training load can be treated separately.

### Acceptance Criteria

For sparring sessions, the athlete can record:

* number of rounds;
* perceived intensity.

The interaction should use simple controls rather than text fields.

---

### US-15 — Record Training Intensity

**Priority:** P0

As an athlete,
I want to record how hard a training session felt,
so that training load can consider subjective intensity.

### Acceptance Criteria

* Intensity can be recorded using a simple predefined scale.
* The system stores intensity with the training session.
* Intensity contributes to the relevant training load category.

---

# E5 — Nutrition and Energy Check-in

### US-16 — Complete Nutrition Check

**Priority:** P0

As an athlete,
I want a very short nutrition check,
so that energy availability can be considered without calorie counting.

### Acceptance Criteria

The check-in includes:

* post-training meal completed: Yes / No;
* protein intake across meals;
* carbohydrate intake: Low / Medium / High.

The interaction should take approximately 15 seconds.

---

### US-17 — Avoid Calorie Tracking Requirement

**Priority:** P0

As an athlete,
I want nutrition tracking to remain simple,
so that I do not need to count every calorie.

### Acceptance Criteria

* The core application does not require calorie counting.
* Users are not required to scan or photograph every meal.
* Nutrition inputs remain simple and behavior-based.

---

# E6 — Physical and Mental Check-in

### US-18 — Record Pain or Soreness

**Priority:** P0

As an athlete,
I want to tap where I feel pain or soreness,
so that physical condition can affect today's recommendation.

### Acceptance Criteria

* The application provides a body-based pain selector.
* The athlete can identify one or more locations.
* Severity can be recorded.
* Significant pain can affect training recommendations.

---

### US-19 — View Body Condition

**Priority:** P0

As an athlete,
I want to see my current body condition visually,
so that I can quickly understand which areas require attention.

### Acceptance Criteria

* The home screen displays a human body visualization.
* Condition is represented using clear status states such as:

  * green = good;
  * yellow = caution;
  * red = high concern.
* The visualization must remain easy to interpret.
* Safety-related red states must not imply a medical diagnosis.

---

# E7 — Punch Freshness Measurement

### US-20 — Perform Punch Freshness Test

**Priority:** P0

As an athlete,
I want to perform a short punch freshness test,
so that the application can track changes in boxing-specific speed and freshness.

### Acceptance Criteria

* The test lasts approximately 10 seconds.
* The athlete can record or import punch performance.
* The result is compared with the athlete's personal baseline.
* The test is intended approximately 3–4 times per week rather than necessarily every day.

---

### US-21 — Use FightCamp Punch Metrics

**Priority:** P1

As an athlete with FightCamp,
I want supported FightCamp punch metrics to contribute to my freshness assessment,
so that manual punch counting can be reduced.

### Acceptance Criteria

Where technically supported, the application may use:

* punch count;
* punch speed;
* punch output;
* round performance.

For prototype demonstrations, realistic mock FightCamp metrics may be used.

---

# E8 — Recovery Assessment Engine

### US-22 — Evaluate Six Recovery Domains

**Priority:** P0

As an athlete,
I want the application to evaluate multiple recovery systems separately,
so that one general score does not hide an important limitation.

### Acceptance Criteria

The system evaluates:

1. Brain and Impact
2. Energy / Nutrition / Weight
3. Nervous System / Sleep
4. Power / Speed
5. Physical
6. Mental

Each domain can produce its own status.

---

### US-23 — Calculate Personal Baselines

**Priority:** P0

As an athlete,
I want recovery metrics compared with my own normal values,
so that differences between wearable brands and individuals are reduced.

### Acceptance Criteria

* Relevant metrics are compared against a personal historical baseline.
* The system does not rely only on population-wide thresholds.
* Baseline calculations must support missing data.
* Changes in data source should be identifiable.

---

### US-24 — Identify Today's Limiter

**Priority:** P0

As an athlete,
I want the application to identify the most important recovery limitation today,
so that I immediately know what needs attention.

### Acceptance Criteria

* The application identifies one primary limiter when sufficient data is available.
* The limiter must map to one of the recovery domains.
* The reasoning can consider multiple signals.
* Safety rules override normal limiter selection where applicable.

Example:

> Today's Limiter: Nervous System & Sleep

---

# E9 — Daily Training Recommendation

### US-25 — Recommend Allowed Training

**Priority:** P0

As an athlete,
I want to know which training types I can still perform,
so that poor recovery in one area does not automatically result in a complete rest day.

### Acceptance Criteria

The application can recommend training such as:

* technical boxing;
* strength training;
* conditioning;
* mobility;
* easy aerobic training.

Recommendations must consider the current recovery limiter.

---

### US-26 — Recommend Training to Avoid

**Priority:** P0

As an athlete,
I want to know which training should be avoided today,
so that I can reduce unnecessary risk.

### Acceptance Criteria

* The system can mark specific training categories as restricted.
* A restriction does not automatically prohibit unrelated training types.
* Safety-related restrictions override performance recommendations.

Example:

> Avoid Sparring Today

while still allowing:

> Technique
> Upper-body Strength

---

# E10 — Recovery Action and Timer

### US-27 — Receive One Recovery Action

**Priority:** P0

As an athlete,
I want one clear recovery action for tonight,
so that I know what action to prioritize.

### Acceptance Criteria

* The application recommends one primary action.
* The recommendation is concise.
* The action is relevant to the identified limiter.
* The application avoids overwhelming the athlete with long lists.

Example:

> Tonight: 10-minute breathing reset

---

### US-28 — Start Recovery Timer

**Priority:** P0

As an athlete,
I want to start the recommended recovery activity from the app,
so that it is easy to complete.

### Acceptance Criteria

* Timed activities provide a simple timer.
* The athlete can start, pause, and complete the activity.
* Completion is stored for future feedback analysis.

---

# E11 — Personal Recovery Feedback

### US-29 — Track Recovery Intervention Outcome

**Priority:** P1

As an athlete,
I want the application to compare recovery actions with my following-day condition,
so that I can learn which actions appear to help me.

### Acceptance Criteria

The system can associate:

* completed recovery action;
* next-day HRV;
* next-day resting HR;
* sleep;
* mood;
* other relevant recovery signals.

---

### US-30 — Show What Works for the Athlete

**Priority:** P1

As an athlete,
I want to see which recovery habits appear to work for me,
so that my recovery strategy becomes more personalized over time.

### Acceptance Criteria

The application may display results such as:

* usually helpful;
* possible benefit;
* no clear pattern;
* insufficient data.

The application must avoid presenting correlation as guaranteed medical causation.

---

# E12 — Safety Rules

### US-31 — Neurological Safety Gate

**Priority:** P0

As an athlete,
I want concerning post-impact symptoms to trigger a safety response,
so that a normal readiness score does not override potential neurological risk.

### Acceptance Criteria

* Neurological safety rules are evaluated before normal recovery recommendations.
* The application must not diagnose concussion.
* Relevant head-impact training can be restricted when concerning symptoms are reported.
* The athlete may be advised to seek appropriate professional medical evaluation.

---

### US-32 — Prevent Unsafe Weight-Cutting Guidance

**Priority:** P0

As an athlete,
I want the application to support safe recovery without encouraging dangerous weight manipulation.

### Acceptance Criteria

The system must not:

* calculate dangerous dehydration targets;
* instruct the athlete to deliberately dehydrate;
* recommend extreme rapid weight loss;
* provide aggressive weight-cut protocols.

The system may:

* show weight trends;
* identify concerning changes;
* encourage safer hydration and professional support.

---

### US-33 — Safety Overrides Readiness

**Priority:** P0

As an athlete,
I want safety warnings to override normal training readiness,
so that a high general recovery score cannot hide a serious concern.

### Acceptance Criteria

The decision order must follow:

1. Safety Gate
2. Recovery Assessment
3. Training Recommendation

A safety restriction cannot be cancelled by a high readiness result.

---

# E13 — History and Insights

### US-34 — View Recovery History

**Priority:** P1

As an athlete,
I want to view previous recovery conditions,
so that I can understand trends across my fight camp.

### Acceptance Criteria

History may include:

* recovery domains;
* limiter history;
* sleep;
* HRV;
* training load;
* weight trend;
* recovery actions.

---

### US-35 — View Training Load by Category

**Priority:** P1

As an athlete,
I want to see training load separated by category,
so that I understand which type of training is accumulating.

### Acceptance Criteria

The interface differentiates:

* sparring load;
* technical boxing load;
* conditioning load;
* strength load.

The system must not present all four as one undifferentiated workload.

---

# E14 — Notifications and Reminders

### US-36 — Morning Check-in Reminder

**Priority:** P2

As an athlete,
I want an optional morning reminder,
so that I do not forget my recovery check-in.

### Acceptance Criteria

* Notifications are optional.
* The athlete can disable them.
* Notifications should not be excessive.

---

### US-37 — Recovery Action Reminder

**Priority:** P2

As an athlete,
I want an optional reminder for my evening recovery action,
so that I am more likely to complete it.

### Acceptance Criteria

* The athlete controls notification settings.
* A completed activity must not continue generating unnecessary reminders.

---

# E15 — Data Privacy and User Control

### US-38 — Health Data Consent

**Priority:** P0

As an athlete,
I want control over which health data the application accesses,
so that my sensitive health information remains under my control.

### Acceptance Criteria

* Health data is accessed only after explicit authorization.
* The application requests only data required for supported features.
* The athlete can revoke access.
* Failure to grant optional permissions must be handled gracefully.

---

### US-39 — Identify Data Source

**Priority:** P0

As an athlete,
I want the system to retain the source of imported measurements,
so that health data remains traceable.

### Acceptance Criteria

Each imported record stores an identifiable source where available, such as:

* Apple Health;
* Health Connect;
* FightCamp;
* manual entry;
* other supported integrations.

---

### US-40 — Delete User Data

**Priority:** P1

As an athlete,
I want to request deletion of my stored account and recovery data,
so that I retain control over my personal information.

### Acceptance Criteria

* The application provides a deletion mechanism.
* Deletion requirements must follow applicable legal and platform requirements.
* The system must not continue using deleted personal data except where retention is legally required.

---

# 5. Prototype Scope

The first prototype should focus on proving the core product concept rather than implementing every external integration.

## Included in Prototype

* athlete profile;
* fight countdown;
* fight camp context;
* six recovery domains;
* morning check-in;
* training classification;
* four training load categories;
* nutrition check;
* pain/body condition input;
* punch freshness test;
* wearable data visualization;
* mocked wearable synchronization where required;
* mocked FightCamp punch data;
* today's limiter;
* allowed training;
* restricted training;
* one nightly recovery action;
* recovery timer;
* safety warning scenarios;
* basic personalized recovery insight.

---

## Not Required for Initial Prototype

* production-ready FightCamp API integration;
* support for every smartwatch brand;
* coach dashboard;
* team management;
* social features;
* calorie counting;
* meal recognition;
* medical diagnosis;
* automated injury diagnosis;
* aggressive weight-cut planning;
* machine-learning-based recovery prediction;
* advanced AI coaching.

---

# 6. Prototype Success Criteria

The prototype is considered successful if it can demonstrate the following complete flow:

1. Athlete opens the app.
2. Wearable recovery information is already available or represented as synchronized data.
3. Athlete completes a short morning check-in.
4. Athlete records or confirms recent training.
5. The system evaluates the six recovery domains.
6. The system identifies today's primary limiter.
7. The athlete receives:

   * training that is allowed;
   * training that should be avoided;
   * one recovery action for tonight.
8. The athlete can complete the recovery action using the built-in timer.
9. The application can demonstrate how the following day's recovery data may be compared with the previous recovery action.

The full daily manual interaction should remain consistent with the product goal of approximately **90 seconds or less per day** under normal conditions.
