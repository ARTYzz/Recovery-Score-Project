# Recovery Score Project

## 1. Project Overview

This project proposes a **boxing recovery tracking application for professional boxers**. The application is designed for athletes to use independently during a fight camp to understand their daily recovery condition and make safer training decisions.

Unlike general fitness or recovery applications that mainly provide a readiness score, this system focuses on answering three practical questions:

1. What is limiting the athlete today?
2. What type of training can still be performed safely?
3. What recovery action should be prioritized tonight?

The application combines automatically collected wearable data with short manual check-ins to create a daily recovery profile while keeping total user input below approximately 90 seconds per day.

The system evaluates recovery across six domains:

* Brain and Impact
* Energy, Nutrition, and Weight
* Nervous System and Sleep
* Power and Speed
* Physical Condition
* Mental Condition

The recovery result is also interpreted in the context of the athlete's current **fight camp phase**, because the same physiological condition may require different training decisions depending on how close the athlete is to competition.

---

## 2. Problem Statement

Professional boxers experience several different types of fatigue and recovery demands during a fight camp. Sparring, technical boxing, conditioning, and strength training can affect the body differently, and these systems may not recover at the same rate.

Existing fitness and recovery applications commonly summarize recovery into a general score based primarily on wearable metrics such as sleep, heart rate, or HRV. However, a single readiness score does not provide enough boxing-specific context to answer an athlete's most important daily question:

> "What can I safely train today?"

For example, an athlete may still be physically capable of strength or technical training while additional head-impact exposure from sparring may not be appropriate. Treating all training load as one general workload can therefore hide important differences between neurological, muscular, cardiovascular, and psychological recovery.

Professional boxers also use different wearable devices and training systems. Important information may already exist across Apple Watch, Android smartwatches, health platforms, and boxing-specific systems such as FightCamp. Requiring athletes to manually re-enter this information would increase friction and reduce long-term adherence.

The proposed application addresses these problems by:

* combining wearable and self-reported recovery data;
* separating training load into boxing-specific categories;
* evaluating six recovery domains independently;
* considering the athlete's current fight camp phase;
* identifying the primary recovery limiter for the day;
* recommending which training types are appropriate or should be avoided;
* providing one simple recovery action for the athlete to complete;
* tracking whether previous recovery actions were followed by measurable improvements.

The application is intended to support training decisions rather than replace medical professionals, diagnose neurological injuries, or provide aggressive weight-cutting guidance.

---

## 3. Target Users

### Primary User

The primary target user is a **professional boxer who manages their own daily recovery during a fight camp**.

The application is designed primarily for individual athlete use rather than for coaches, sports clubs, medical teams, or team administrators.

Typical characteristics of the target user include:

* trains multiple times per week or multiple times per day;
* performs a combination of sparring, technical boxing, conditioning, and strength training;
* follows a structured fight camp leading toward a scheduled competition;
* uses a smartwatch or wearable device;
* may use boxing-specific tracking equipment such as FightCamp;
* wants quick and actionable recovery information without manually recording large amounts of data;
* needs training guidance rather than another dashboard containing only health metrics.

### Available Equipment

The system assumes the athlete can reasonably access:

* a smartphone;
* a smartwatch or wearable device;
* a body-weight scale;
* optional boxing tracking equipment such as FightCamp.

The system does not depend on laboratory equipment, blood testing, EEG measurements, or other specialist sports-science equipment.

---

## 4. User Needs

The target user needs the application to:

* automatically import available sleep, heart-rate, HRV, and workout information from supported wearable ecosystems;
* minimize manual data entry;
* understand recovery in a boxing-specific context;
* distinguish between different training loads;
* identify the most important recovery limitation each day;
* provide clear allowed and restricted training recommendations;
* provide simple and achievable recovery actions;
* adapt recommendations according to the current fight camp phase;
* learn which recovery strategies appear to work for the individual athlete over time.

The application should remain fast enough for daily use, with manual interaction targeted at approximately **90 seconds or less per day** under normal conditions.

---

## 5. Proposed Solution

The proposed application will combine data from multiple sources.

### Automatically Collected Data

Where supported, the application may import:

* sleep duration and sleep-related metrics;
* heart rate;
* resting heart rate;
* HRV;
* workout duration;
* exercise sessions;
* activity-related metrics.

Potential integration sources include:

* Apple Health / Apple Watch;
* Android Health Connect and compatible wearable ecosystems;
* future supported wearable platforms;
* FightCamp or other boxing-specific systems where appropriate integration access is available.

### Athlete-Reported Data

The athlete will manually provide information that wearable devices cannot reliably determine, such as:

* morning body weight;
* urine color;
* mood;
* sparring rounds;
* boxing training type;
* perceived training intensity;
* pain or soreness location;
* basic nutrition completion;
* symptoms requiring safety attention.

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

* today's main recovery limiter;
* training that can be performed;
* training that should be avoided;
* one prioritized recovery action for the evening.

### Personal Recovery Feedback

The application will record completed recovery actions and compare them with subsequent recovery measurements.

Over time, this allows the system to identify which recovery interventions appear to produce positive results for the individual athlete.

---

## 7. Safety Scope

The application is intended as a training and recovery support tool.

It must not:

* diagnose concussion or other neurological conditions;
* replace medical assessment;
* encourage dangerous dehydration;
* provide instructions for aggressive weight cutting.

Where potentially concerning neurological or physical symptoms are reported, safety rules should override normal readiness recommendations and advise the athlete to avoid relevant training exposure and seek appropriate professional evaluation when necessary.