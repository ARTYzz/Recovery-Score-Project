# Project Charter for Software Engineering Case Studies

* **Project Title:** Recovery Score Project
* **Company:** 5 Rangers Company
* **Course:** 1305493 Software Engineering Case Studies

## Team Members

| Name | Student ID | Role |
| :--- | :--- | :--- |
| Pawornpat Kongdaeng | 6531503111 | Product Owner |
| Thiraphat Kongkan | 6631503023 | AI Lead |
| Theerawut Khamsuetrong | 6631503024 | Designer |
| Chisanucha Vongtalay | 6631503125 | Tech Lead |
| Hassakorn Buaurai | 6631503127 | QA/Tester |

---

## 1. Purpose
To build a combat-specific Decision Support System (DSS) mobile application for amateur and professional boxers. The application translates physiological and subjective recovery metrics into clear, daily actionable training decisions within the context of a fighter's active Fight Camp—without requiring a dedicated sports science team or laboratory-grade equipment.

## 2. Problem Statement
Many amateur and professional boxers must plan daily training intensity and weight management independently without sports scientists or medical staff. Consequently, fighters rely heavily on subjective 'feel,' which often misaligns with actual neurological and physiological recovery. This mismatch leads to mid-camp injuries, overtraining syndrome, cumulative head-impact trauma, unsafe weight cuts, and entering fights under-recovered.

### Key Pain Points
* **Generic Recovery Scores:** Existing wellness apps provide a single aggregated score (e.g., '62% Recovered') that fails to identify the daily limiting factor and masks combat-specific risks such as sparring-induced neurological fatigue or the conflict between recovery and weight cutting.
* **High Logging Friction:** Apps that capture granular data (e.g., logging every meal's calories or every weightlifting set) demand too much daily effort relative to immediate value, causing fighters to abandon tracking mid-camp before actionable trends emerge.

## 3. Objectives
1. **Identify Daily Limiting Factors:** Evaluate fighter readiness across six specialized physiological and cognitive domains rather than relying on a single composite percentage.
2. **Deliver Actionable Daily Guidance:** Provide explicit daily recommendations on what to train, what to skip, and one targeted recovery action for that night.
3. **Ensure Low-Friction UX (<90 Seconds/Day):** Restrict total daily manual input to under 90 seconds using only standard gear fighters already own (smartwatch, scale, smartphone).
4. **Enable Fight Camp Context-Awareness:** Dynamically adjust evaluation thresholds based on the current phase of the Fight Camp (e.g., Build Phase vs. Fight Week).

## 4. Scope

### In-Scope
* **6-Domain Recovery Evaluation:** Brain & Impact, Fuel & Weight, Sleep & Heart, Power & Speed, Body, and Mind.
* **4-Category Training Load Separation:** Sparring, Boxing Technical, Conditioning, and Weights.
* **Multi-Source Input Integration:** Automated wearable sync (HRV, Resting HR, Sleep), rapid daily self-reports, and a 10-second smartphone Punch Test.
* **Personalization Feedback Loop:** Tracking next-day recovery responses to evaluate the effectiveness of recommended recovery actions per individual.

### Out-of-Scope & Strict Boundaries
* **No Granular Calorie or Gym Logging:** Excludes meal-by-meal calorie counting and detailed set/rep weightlifting trackers.
* **No Laboratory Hardware Dependency:** Excludes clinical or lab-grade diagnostic devices.
* **Strict Safety Prohibitions:** No medical diagnoses (e.g., diagnosing concussions) and no rapid weight-cutting calculation or prescriptive weight-loss regimens.

## 5. Target Users / Stakeholders
* **Primary Users (Amateur & Professional Boxers):** Competitive fighters actively training on a structured Fight Camp schedule who lack access to full-time sports science or medical support teams.
* **Secondary Stakeholders (Boxing Coaches & Trainers):** Utilize daily readiness insights to adjust sparring intensity, technical drills, and conditioning workloads.
* **External Stakeholders (Ringside Physicians / Medical Professionals):** Serve as escalation points when the system flags cumulative head-impact risk or unsafe physiological trends.

## 6. Proposed Solution
A lightweight mobile decision-support engine that combines passive wearable data with ultra-fast daily check-ins (<90 seconds) and Fight Camp timeline context to generate three clear, actionable daily directives.

### One-Core Workflow (Daily Loop)
1. **Morning Check-in (~30 sec):** Auto-sync HRV, Resting HR, and Sleep from wearable; manually log body weight, urine color, and mood.
2. **Post-Training Log (~30 sec):** Select training type (from 4 categories), round count/intensity, and localized muscle soreness.
3. **Nutrition Check (~15 sec):** Confirm post-training fueling, protein adequacy, and carbohydrate intake level (Low / Moderate / High).
4. **Periodic Power Test (3–4x/week):** Perform a 10-second smartphone Punch Test to benchmark neuromuscular speed and power against personal baselines.
5. **Actionable Output (3 Core Answers):** Deliver (1) Today's Limiting Factor, (2) What to Train vs. What to Skip, and (3) One Tonight Recovery Action with a built-in timer.
6. **Next-Day Personalization Loop:** Evaluate next-morning recovery metrics to verify whether the assigned recovery action improved readiness for that specific athlete.

## 7. Key Features

| # | Feature | Detail |
| :-: | :--- | :--- |
| 1 | **6-Domain Combat Recovery Engine** | Isolates neurological, metabolic, cardiovascular, neuromuscular, musculoskeletal, and psychological readiness. |
| 2 | **Fight Camp Timeline Context Engine** | Interprets biometric shifts relative to camp phase (tolerating higher fatigue in Build Phase vs. prioritizing peak freshness in Fight Week). |
| 3 | **Smart Training Split Recommendations** | Provides targeted training adjustments (e.g., 'Skip sparring due to neural fatigue; upper-body lifting is cleared'). |
| 4 | **90-Second Daily Input & 10s Punch Test** | Ultra-low-friction logging paired with smartphone accelerometer-based neuromuscular readiness testing. |
| 5 | **Guided Recovery Timer** | Prescribes a single, high-impact recovery protocol each evening complete with an integrated execution timer. |

## 8. Success Criteria / KPIs Metric (Before/After)

| Metric | Before (Baseline / Pain Point) | After (Target Goal) |
| :--- | :--- | :--- |
| **Daily Logging Time** | 5–10+ minutes/day (high friction in standard fitness apps) | $\le$ 90 seconds/day total input time |
| **Camp Retention Rate** | High mid-camp drop-off due to tedious data entry | $\ge$ 75% sustained daily usage through Fight Camp completion |
| **Output Actionability** | Generic single % score requiring athlete guesswork | $\ge$ 75% sustained daily usage through Fight Camp completion |
| **Pre-Dev User Validation** | 0 structured interviews (camp-model assumptions only) | 5–10 active boxers interviewed to validate logic & baselines |

*(หมายเหตุ: ในตารางข้อ 8 ต้นฉบับมีชื่อหัวคอลัมน์ที่ 3 ซ้ำกับคอลัมน์ที่ 2 ผมได้ปรับแก้หัวคอลัมน์เป็น "After (Target Goal)" เพื่อให้สอดคล้องกับเนื้อหาครับ)*

## 9. Timeline / Milestones
* **Phase 1 — Problem & Scope Definition:** Conducted 5-Whys Root Cause Analysis; defined 6 recovery domains, 4 training loads, and core safety boundaries.
* **Phase 2 — Prototyping & Requirement Specs:** Developed UI/UX wireframes, interactive prototypes, and Software Requirements Specification (SRS) / business logic documentation.
* **Phase 3 — User Research & Validation:** Conduct structured interviews and prototype testing with 5–10 boxers to validate training frequency assumptions and refine decision thresholds.
* **Phase 4 — MVP Development & Pilot Testing:** Build core wearable integrations and run a live pilot with a small cohort of fighters during an active Fight Camp.

## 10. Risks & Constraints

### Risks
* **Unvalidated Baseline Assumptions:** Current sparring frequency and decision-per-camp estimates rely on standard camp models; misalignment with real-world boxer habits could skew early recommendations.
* **Wearable Sensor Variance:** Differences in HRV and sleep tracking accuracy across consumer smartwatch brands may introduce data noise.

### Constraints
* **Hardware Constraint:** Must function exclusively with consumer hardware fighters already own (smartwatch, standard scale, smartphone)—no medical or lab devices.
* **Time Constraint:** Total daily manual user interaction must strictly remain at or below 90 seconds.

## 11. Assumptions
* **Device Availability:** Target boxers own and regularly use a smartphone, a basic body-weight scale, and a wearable capable of tracking HRV, Resting HR, and sleep.
* **User Compliance:** Fighters will consistently log daily subjective metrics if input time stays under 90 seconds and yields immediate, practical training guidance.
* **Camp Structure Consistency:** Sparring frequency and workload progression across a Fight Camp follow standard competitive boxing structures.

## 12. Legal & Compliance
* **No Medical Diagnosis Policy:** The system operates strictly as a pattern-tracking and wellness decision-support tool. It flags risk patterns (e.g., advising a fighter to pause sparring and consult a physician) and explicitly prohibits diagnosing concussions or any medical condition.
* **No Unsafe Weight-Cutting Guidance:** The application monitors weight trends to alert users of potentially dangerous dehydration or rapid weight loss rates. It strictly prohibits calculating or recommending rapid weight-cut protocols to mitigate severe health risks and legal liability.
* **Data Privacy & Sensitive Health Information (PDPA):** Biometric metrics, body weight, injury reports, and neurological symptom logs constitute sensitive personal health data. Explicit user consent, encrypted storage, and strict access controls are required in compliance with applicable data protection laws (e.g., PDPA).
