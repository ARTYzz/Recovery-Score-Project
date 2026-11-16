# Recovery Score Project

## Flutter mobile MVP

The active app is Flutter for iOS and Android, with a browser preview for UI and manual workflows. The former Capacitor application is in `legacy_capacitor/` for reference.

Wearable data is **real Apple Health data on iPhone**. The app requests read access and imports records from any identifiable Apple Health source in the last 14 days, including compatible watches and rings. Sleep, HRV (Apple Health SDNN), resting heart rate, heart rate, and workout duration stay `Unavailable` until matching records can be read. A connected status confirms at least one readable sourced record, not every metric. The app never creates synthetic wearable values. Health Connect and direct vendor APIs are not integrated. FightCamp punch history is the **only runtime mock source** and is always labelled as such.

Each HealthKit sync reads a 14-day window and merges returned watch days into encrypted local history. Older saved days remain available to Trends. A partial day updates only the metrics returned; an empty read keeps saved history and the connection state, while showing a warning. Records remain separate by source. In Settings → Connected Sources, choose the source used for recovery assessment and trends. Explicit Disconnect clears locally imported watch history.

### Run and test

On a Mac with Xcode and a connected iPhone, run `flutter pub get`, open `ios/Runner.xcworkspace` to select a signing team, and run `flutter run -d DEVICE_ID`. Create a real athlete profile, grant Apple Health read access during onboarding (or later in Settings → Connected Sources), complete the morning check-in, then view Today. The app reads again on unlock, when returning to the app, or when **Sync now** is tapped. It does not currently receive background HealthKit updates. Revoke platform read permission in the iPhone Health app; Disconnect in Boxer Recovery clears imported local records.

Create Profile asks for current weight (kg), height (cm), and an optional target weight for the official weigh-in. Settings → Edit Profile lets the athlete change these values, display name, and fight date. A new morning check-in updates the profile's current weight. Old saved official weigh-in weights load as target weights. Target weight is shown for monitoring only; the app does not calculate a weight-cut plan.

The next fight date is optional. When the scheduled day has passed, the app archives that planned date and weigh-in target, clears the upcoming fight and target, and continues recovery tracking without a camp countdown. The rollover is persisted when the athlete unlocks, returns to the app, or navigates after midnight. A new date can be set later in Settings → Edit Profile.

Settings → Language switches the mobile interface between English and Thai immediately. The choice is stored on the device and also applies to the setup and unlock screens after restarting the app. Health records and source values are unchanged by a language switch.

On Windows, run from the project root:

```powershell
.\.toolchains\flutter\bin\flutter.bat pub get
.\.toolchains\flutter\bin\flutter.bat run -d chrome
```

The browser can exercise profile, manual check-ins, training logs, Nutrition, Recovery Action, and FightCamp mock, but cannot access Apple Health. Wearable metrics remain `Unavailable` there. Run `flutter test` and `flutter analyze` to verify changes.

Existing real athlete accounts keep manually entered records and live HealthKit samples. On the first unlock after this update, old synthetic wearable samples and evaluations derived from them are removed; real manual records remain. Legacy full-demo accounts are retired and show the real profile setup screen. Creating a profile replaces that old demo vault.

The Dart code is organized by responsibility:

- `lib/domain/`: athlete records, personal baselines, six-domain assessment, Safety Gate, training advice, feedback.
- `lib/data/`: encrypted local vault, Apple Health reader, and labelled FightCamp mock source.
- `lib/app/`: navigation, onboarding, synchronization, and check-in state controller.
- `lib/ui/`: reusable mobile components and screens.

### Local storage and backups

On iOS and Android, the athlete profile, check-ins, wearable history, training, safety reviews, and food records are stored in an encrypted SQLCipher database in the app's private support directory. Food photo bytes are stored as encrypted database BLOBs rather than inside the meal JSON row. A database transaction commits each save. The passphrase is required after the app is locked and is not saved in preferences. Chrome and desktop previews continue to use the older encrypted preference vault for UI testing; they are separate installations and do not share data with the phone.

The first successful mobile unlock migrates an existing encrypted preference vault to SQLCipher, reads the new records back to verify them, then removes the old preference copy. If migration fails, the old vault remains available. Settings offers **Export encrypted backup** and **Restore from backup**. The user chooses a backup passphrase and a file location; the app does not upload the file. Restoring replaces the current local account only after a confirmation dialog. Historical imported samples retain their source labels, but Apple Health permissions and the connected state are reset because those permissions are device-specific. Keep the backup file and passphrase safe; losing both the app data and backup means there is no cloud recovery.

### Training guidance in the prototype

`RecoveryEngine` and `TrainingAdvisor` evaluate Sparring, Boxing / Technical, Conditioning, and Strength separately. Recent session duration, intensity, contact, body area, and soreness/pain severity change both domain status and advice. Severe pain or concerning head symptoms go through the Safety Gate first. Decision thresholds are prototype rules, not medical clearance.

Power & Speed reads normalized FightCamp session records. After onboarding, the app loads labelled synthetic FightCamp history. No official FightCamp account or undocumented API is connected.

Nutrition remains a quick Yes/No, protein, and carbohydrate check. The optional Food journal stores a compressed photo and user-confirmed meal estimate. It does not recognize food from a photo.

### Huawei, Garmin and Apple Watch through Apple Health on iPhone

The live path is **watch or ring → its companion app (where required) → Apple Health → Boxer Recovery**. The iOS adapter discovers sources from each readable HealthKit sample's reported source ID and name; it has no brand allowlist and no direct vendor connection. Manually entered Health records are excluded. A HealthKit source may identify a companion app rather than a particular physical device. Missing values remain `Unavailable`; the app does not calculate HRV or sleep from unrelated heart-rate samples. On iPhone, use Settings → Connected Sources → **Sync now** after new records arrive in Apple Health. Select the source whose records should drive Today and Trends.

The Today card labelled **Resting HR** reads Apple Health's resting-heart-rate category, not a general heart-rate sample. HRV is read only from Apple Health's HRV (SDNN) category. If that category has no readable record from the selected source, HRV remains `Unavailable`; Sleep & Heart can still use sleep and resting HR as their own baseline accumulates. Garmin Connect may not write HRV or resting-heart-rate categories to Apple Health; check the Health app's Data Sources for what is actually present. Connected Sources explains whether readable HRV records came from another source or were absent from the HealthKit query. HealthKit does not expose a reliable read-permission-denied status for individual categories.
## 1. Project Overview

This project proposes a **boxing recovery tracking application for professional boxers**. The application is designed for athletes to use independently during a fight camp to understand their daily recovery condition and make safer training decisions.

Unlike general fitness or recovery applications that mainly provide a readiness score, this system focuses on answering three practical questions:

1. What is limiting the athlete today?
2. What type of training can still be performed safely?
3. What recovery action should be prioritized tonight?

The application combines automatically collected wearable data with short manual check-ins to create a daily recovery profile while keeping total user input below approximately 90 seconds per day.

The system evaluates recovery across six domains:

- Brain and Impact
- Energy, Nutrition, and Weight
- Nervous System and Sleep
- Power and Speed
- Physical Condition
- Mental Condition

The recovery result is also interpreted in the context of the athlete's current **fight camp phase**, because the same physiological condition may require different training decisions depending on how close the athlete is to competition.

---

## 2. Problem Statement

Professional boxers experience several different types of fatigue and recovery demands during a fight camp. Sparring, technical boxing, conditioning, and strength training can affect the body differently, and these systems may not recover at the same rate.

Existing fitness and recovery applications commonly summarize recovery into a general score based primarily on wearable metrics such as sleep, heart rate, or HRV. However, a single readiness score does not provide enough boxing-specific context to answer an athlete's most important daily question:

> "What can I safely train today?"

For example, an athlete may still be physically capable of strength or technical training while additional head-impact exposure from sparring may not be appropriate. Treating all training load as one general workload can therefore hide important differences between neurological, muscular, cardiovascular, and psychological recovery.

Professional boxers also use different wearable devices and training systems. Important information may already exist across Apple Watch, Android smartwatches, health platforms, and boxing-specific systems such as FightCamp. Requiring athletes to manually re-enter this information would increase friction and reduce long-term adherence.

The proposed application addresses these problems by:

- combining wearable and self-reported recovery data;
- separating training load into boxing-specific categories;
- evaluating six recovery domains independently;
- considering the athlete's current fight camp phase;
- identifying the primary recovery limiter for the day;
- recommending which training types are appropriate or should be avoided;
- providing one simple recovery action for the athlete to complete;
- tracking whether previous recovery actions were followed by measurable improvements.

The application is intended to support training decisions rather than replace medical professionals, diagnose neurological injuries, or provide aggressive weight-cutting guidance.

---

## 3. Target Users

### Primary User

The primary target user is a **professional boxer who manages their own daily recovery during a fight camp**.

The application is designed primarily for individual athlete use rather than for coaches, sports clubs, medical teams, or team administrators.

Typical characteristics of the target user include:

- trains multiple times per week or multiple times per day;
- performs a combination of sparring, technical boxing, conditioning, and strength training;
- follows a structured fight camp leading toward a scheduled competition;
- uses a smartwatch or wearable device;
- may use boxing-specific tracking equipment such as FightCamp;
- wants quick and actionable recovery information without manually recording large amounts of data;
- needs training guidance rather than another dashboard containing only health metrics.

### Available Equipment

The system assumes the athlete can reasonably access:

- a smartphone;
- a smartwatch or wearable device;
- a body-weight scale;
- optional boxing tracking equipment such as FightCamp.

The system does not depend on laboratory equipment, blood testing, EEG measurements, or other specialist sports-science equipment.

---

## 4. User Needs

The target user needs the application to:

- automatically import available sleep, heart-rate, HRV, and workout information from supported wearable ecosystems;
- minimize manual data entry;
- understand recovery in a boxing-specific context;
- distinguish between different training loads;
- identify the most important recovery limitation each day;
- provide clear allowed and restricted training recommendations;
- provide simple and achievable recovery actions;
- adapt recommendations according to the current fight camp phase;
- learn which recovery strategies appear to work for the individual athlete over time.

The application should remain fast enough for daily use, with manual interaction targeted at approximately **90 seconds or less per day** under normal conditions.

---

## 5. Proposed Solution

The proposed application will combine data from multiple sources.

### Automatically Collected Data

Where supported, the application may import:

- sleep duration and sleep-related metrics;
- heart rate;
- resting heart rate;
- HRV;
- workout duration;
- exercise sessions;
- activity-related metrics.

Potential integration sources include:

- Apple Health / Apple Watch;
- Android Health Connect and compatible wearable ecosystems;
- future supported wearable platforms;
- FightCamp or other boxing-specific systems where appropriate integration access is available.

### Athlete-Reported Data

The athlete will manually provide information that wearable devices cannot reliably determine, such as:

- morning body weight;
- urine color;
- mood;
- sparring rounds;
- boxing training type;
- perceived training intensity;
- pain or soreness location;
- basic nutrition completion;
- symptoms requiring safety attention.

The interface should prioritize taps, selectors, and simple controls instead of text entry.

---

## 6. Core Product Differentiators

### Fight Camp Context

Recovery is interpreted relative to the athlete's current stage of fight preparation.

For example, the same level of fatigue may be acceptable during an early conditioning phase but may require greater recovery priority close to competition.

### Four Training Load Categories

Training load is not treated as one single value. The system separates:

1. Sparring
2. Boxing / Technical Training
3. Conditioning
4. Strength Training

This allows the application to recognize situations where one type of training should be restricted while another remains appropriate.

### Action-Oriented Recovery Guidance

Instead of only displaying a readiness score, the application provides actionable outputs such as:

- today's main recovery limiter;
- training that can be performed;
- training that should be avoided;
- one prioritized recovery action for the evening.

### Personal Recovery Feedback

The application will record completed recovery actions and compare them with subsequent recovery measurements.

Over time, this allows the system to identify which recovery interventions appear to produce positive results for the individual athlete.

---

## 7. Safety Scope

The application is intended as a training and recovery support tool.

It must not:

- diagnose concussion or other neurological conditions;
- replace medical assessment;
- encourage dangerous dehydration;
- provide instructions for aggressive weight cutting.

Where potentially concerning neurological or physical symptoms are reported, safety rules should override normal readiness recommendations and advise the athlete to avoid relevant training exposure and seek appropriate professional evaluation when necessary.
