# Boxing Recovery — Legal, Compliance & Safety Rules

Read this before writing any code that touches user data, health data, wearable integrations, recovery recommendations, or user actions.

The application is a **boxing recovery and training-support application** for professional boxers. It is not intended to diagnose medical conditions or replace medical professionals.

---

## PDPA (Personal Data Protection Act)

**What it is:**
The PDPA is Thailand's law for protecting personal data and controlling how organizations collect, use, disclose, and store people's information.

Health information is treated as sensitive personal data and requires additional protection.

**What it requires:**
Personal data must be collected for a clear purpose and under an appropriate legal basis. Users must be informed about how their data is used. Sensitive health information requires additional safeguards and, where consent is the applicable legal basis, explicit consent.

**Rules for the agent:**

* Clearly tell the user what personal and health data is being collected and why.
* Treat health and recovery information as sensitive personal data.
* Obtain explicit consent where consent is the applicable legal basis for processing sensitive health data.
* Do not use pre-checked consent boxes.
* Collect only data required for recovery, training, safety, and personalization features.
* Do not collect unrelated health or personal information.
* Protect personal and health data using appropriate authentication, authorization, and security controls.
* Sensitive health data must never be publicly accessible.
* Do not expose raw health data in URLs, application logs, error messages, crash reports, or analytics tools.
* Use encrypted connections such as HTTPS/TLS when data is transferred.
* Limit administrative access to sensitive information using authorized roles.
* Record the source of imported health information where possible.
* If user data is shared with a third party, disclose the purpose and receiving party where required.
* Do not use health data for advertising or unrelated profiling.
* Do not sell health data.
* Provide a process for users to request access to their personal data.
* Provide a process for users to correct appropriate inaccurate personal data.
* Provide a process for users to request deletion where no legal retention obligation applies.
* If consent is withdrawn, stop processing that depends on that consent unless another lawful basis applies.
* When personal information is no longer needed, securely delete or anonymize it unless retention is legally required.
* Prefer synthetic or anonymized data during development and testing.
* Do not use real athlete health data as test data without an appropriate lawful basis and protection.
* Never reveal one athlete's recovery or health information to another athlete.

---

## Health & Wearable Data

The application may import data from wearable and health ecosystems such as:

* Apple Health / Apple Watch
* Android Health Connect
* compatible smartwatches
* FightCamp
* future supported training platforms

Potential data includes:

* sleep;
* heart rate;
* resting heart rate;
* HRV;
* workout sessions;
* workout duration;
* activity information;
* punch-related performance data where officially supported.

**Rules for the agent:**

* Request only wearable permissions required by implemented features.
* Do not request every available health permission by default.
* Clearly explain why each category of health information is required.
* The application must continue gracefully when optional wearable permissions are denied.
* Never represent unavailable wearable information as zero.
* Missing HRV is `unavailable`, not `HRV = 0`.
* Record the origin of imported metrics where available.
* Do not assume that the same metric from different manufacturers is calculated identically.
* Prefer comparisons against the athlete's personal baseline rather than direct comparison with other users.
* Do not silently modify raw values received from wearable platforms.
* If normalized values are calculated, preserve enough source information to trace their origin.
* Users must be able to disconnect supported health integrations.

---

## Apple Health / HealthKit

**Rules for the agent:**

* Access Apple Health data only after the user grants the required permissions.
* Request only data necessary for visible user-facing features.
* Explain why the application requires each requested health category.
* Respect permission changes made by the user.
* Do not assume permission remains available indefinitely.
* Do not use HealthKit-derived information for targeted advertising.
* Do not sell HealthKit-derived information.
* Do not expose HealthKit data to unrelated third-party services.

---

## Android Health Connect

**Rules for the agent:**

* Request only Health Connect permissions required for visible features.
* Clearly disclose how Health Connect data will be used.
* Handle denied or revoked permissions safely.
* Do not make unrelated functionality dependent on optional health permissions.
* Securely transmit and store imported Health Connect information.
* Do not use Health Connect information for unrelated advertising or profiling.

---

## FightCamp Integration

FightCamp is considered a boxing-specific performance data source rather than a general smartwatch.

Potential useful information may include:

* punch count;
* punch type;
* punch speed;
* punch output;
* round information;
* workout/session information.

**Rules for the agent:**

* Use only an officially supported FightCamp API, SDK, partner integration, export, or data-sharing mechanism.
* Do not depend on undocumented APIs.
* Do not bypass authentication or access controls.
* Do not reverse engineer proprietary FightCamp protocols for production integration.
* Do not assume that FightCamp punch data is available through Apple Health.
* Until official access is confirmed, use synthetic or mock FightCamp data for the prototype.
* Keep the FightCamp integration behind a separate integration layer so it can be replaced without changing the Recovery Engine.

---

## Computer Crime Act §26

**What it is:**
Thailand's Computer Crime Act requires applicable service providers to retain qualifying computer traffic data for legal traceability.

**What it requires:**
Applicable computer traffic data must generally be retained for at least 90 days. In a specific case, an authorized official may require retention beyond 90 days, up to the legally permitted maximum.

**Rules for the agent:**

* Determine whether the deployed service falls within an applicable service-provider category before production.
* If the requirement applies, retain required computer traffic data for at least 90 days.
* Support a legally issued extended-retention requirement where applicable.
* Do not automatically delete legally required traffic logs before their required retention period expires.
* Record only the information necessary for legally required traffic or security logging.
* Log timestamps must use a consistent and reliable time source.
* Protect logs against unauthorized modification or deletion.
* Restrict access to traffic and security logs.
* Do not store passwords or authentication tokens in logs.
* Do not unnecessarily place HRV, sleep, weight, pain, symptoms, punch data, or other health information in traffic logs.
* Separate security/traffic logs from detailed recovery records wherever possible.
* Record privileged administrative access to protected logs where appropriate.
* After the required retention period ends, securely remove logs unless another lawful reason requires continued retention.

---

## Electronic Transactions Act §9 / §26 / §28

**What it is:**
Thailand's Electronic Transactions Act provides legal recognition for electronic information and electronic signatures when applicable requirements are met.

Section 9 concerns methods used to satisfy a legal signature requirement.

Section 26 describes characteristics of a reliable electronic signature.

Section 28 applies to providers issuing certificates that support electronic signatures.

**Rules for the agent:**

* When the user gives electronic consent, record evidence of the affirmative action.
* Record which Privacy Notice, Terms of Service, or consent version was accepted.
* Record the date and time of acceptance.
* Associate the acceptance with the authenticated user or another reliable identifier.
* Preserve evidence of what wording the user agreed to.
* Do not use a pre-checked checkbox as evidence of consent.
* Require a clear affirmative user action.
* If consent wording changes materially, preserve the previous version.
* Do not silently modify an agreement after acceptance.
* Protect consent and agreement records against unauthorized modification.
* Restrict administrative access to agreement records.
* Do not store the user's password as evidence of consent or signature.
* If certificate-based electronic signatures are introduced, apply the additional reliability and certificate requirements relevant to Sections 26 and 28.
* Do not implement certificate infrastructure merely for ordinary app consent unless there is a genuine legal or business requirement.

---

# Boxing Recovery Product Safety

## No Medical Diagnosis

The application is intended to support recovery and training decisions.

**Rules for the agent:**

* Do not diagnose concussion.
* Do not diagnose traumatic brain injury.
* Do not diagnose dehydration as a medical condition.
* Do not diagnose musculoskeletal injury.
* Do not diagnose a mental health disorder.
* Do not tell the athlete that they are medically cleared to return to training.

Allowed example:

> Head-impact recovery requires caution today.

Not allowed:

> You have a concussion.

---

## Neurological Safety Gate

Brain and head-impact information requires a separate safety layer.

The normal decision order must be:

```text
Safety Gate
    ↓
Recovery Assessment
    ↓
Training Recommendation
```

**Rules for the agent:**

* Evaluate neurological safety conditions before calculating normal training recommendations.
* A high readiness score must never override a neurological safety restriction.
* Concerning post-impact symptoms may restrict sparring and other head-impact activity.
* When appropriate, advise the athlete to seek qualified medical evaluation.
* Do not convert neurological warning signs into only a lower Recovery Score.

Example:

```text
Overall Readiness: 84%

Safety Flag:
New symptoms reported after head impact.

Recommendation:
Avoid sparring and head-impact training.
Consider appropriate medical evaluation.
```

---

## No Dangerous Weight-Cutting Advice

The application may monitor weight trends but is not a weight-cutting assistant.

**Rules for the agent:**

* Do not calculate dehydration targets.
* Do not instruct athletes to deliberately restrict water.
* Do not recommend diuretics.
* Do not provide sauna dehydration protocols.
* Do not provide extreme food-restriction protocols.
* Do not calculate how much water must be lost to make weight.
* Do not encourage rapid unsafe body-mass reduction.
* The system may show body-weight trends.
* The system may identify concerning changes.
* The system may encourage hydration or qualified professional support.
* Safety considerations take priority over making competition weight.

---

# Recovery Engine Rules

## Six Recovery Domains

The system evaluates six separate recovery domains:

1. Brain & Impact
2. Energy / Nutrition / Weight
3. Nervous System / Sleep
4. Power / Speed
5. Physical
6. Mental

**Rules for the agent:**

* Do not reduce all health information into one unexplained number.
* Preserve individual domain status.
* Clearly identify the primary limiter where sufficient information exists.
* Display insufficient data when a reliable result cannot be produced.

---

## Four Training Load Categories

Training load must remain separated into:

1. Sparring
2. Boxing / Technical Training
3. Conditioning
4. Strength Training

**Rules for the agent:**

* Do not combine all training into one undifferentiated workload.
* Do not assume muscle readiness means head-impact readiness.
* Do not assume poor readiness in one domain automatically requires complete rest.
* Recommendations may allow one training type while restricting another.

Example:

```text
Avoid:
- Sparring

Allowed:
- Technical boxing
- Upper-body strength
- Easy aerobic work
```

---

## Fight Camp Context

Recovery recommendations must consider where the athlete is in the fight camp.

**Rules for the agent:**

* Store or calculate the athlete's current fight camp phase.
* Allow the same recovery condition to be interpreted differently depending on camp phase where justified.
* Do not hide fight-camp context from recommendation logic.
* Safety rules always override fight-camp performance objectives.

---

## Personal Baselines

**Rules for the agent:**

* Prefer the athlete's own historical baseline for HRV, resting HR, sleep, punch performance, and similar metrics.
* Do not treat population averages as the athlete's personal normal value.
* Avoid direct comparison of raw wearable measurements across different athletes or brands unless the metric is known to be comparable.
* Track changes in measurement source where possible.

---

## Recommendation Transparency

Important recommendations should be understandable.

Preferred example:

```text
Today's Limiter:
Nervous System & Sleep

Main signals:
- HRV below personal baseline
- Sleep below personal baseline
- Resting HR above baseline
```

**Rules for the agent:**

* Do not generate unexplained safety-critical recommendations.
* Do not present uncertain predictions as confirmed facts.
* Clearly distinguish measured data, self-reported information, and system interpretation.

---

# Recovery Intervention Feedback

The application may track whether recommended recovery actions appear to be followed by improvements.

Examples:

* breathing session;
* earlier bedtime;
* mobility session;
* other safe recovery actions.

**Rules for the agent:**

* Record whether an intervention was actually completed.
* Compare future recovery measurements only when enough data exists.
* Do not claim that correlation proves medical causation.
* Use wording such as:

  * "usually associated with better recovery";
  * "possible benefit";
  * "no clear pattern";
  * "not enough data".
* Never claim that an intervention treats or cures a medical condition unless the product has appropriate regulatory support.

---

# Mental Recovery Data

**Rules for the agent:**

* Keep mental check-ins minimal and relevant to recovery.
* Appropriate prototype inputs may include mood, motivation, and perceived stress.
* Do not attempt to diagnose psychological or psychiatric disorders.
* Do not expose mental check-in information to other users.
* Treat this information as sensitive health-related data.

---

# Development and Testing Rules

* Prefer synthetic athlete profiles and synthetic health data.
* Mock Apple Health, Health Connect, and FightCamp data when real integrations are unnecessary for the prototype.
* Never commit real health data to Git.
* Never commit API secrets, wearable tokens, or credentials.
* Never include production health records in screenshots or demo data.
* Do not use another person's real health data as sample data without appropriate authorization.
* Test missing, denied, revoked, and partial wearable permissions.
* Test Safety Gate scenarios independently from normal readiness scenarios.

---

# General Rule for Boxing Recovery

The AI coding agent must treat physical recovery, neurological information, mental check-ins, wearable metrics, and boxing-performance information as sensitive and potentially high-risk user data.

Before adding any feature that collects, processes, displays, shares, stores, exports, or recommends actions from this information, consider:

1. Privacy
2. Data minimization
3. User authorization
4. Security
5. Safety
6. Traceability
7. Source reliability
8. Missing-data behavior
9. User control
10. Applicable legal and platform requirements

When safety and performance conflict, **safety wins**.

---

**5 Rangers Company Members:**
Chisanucha Vongtalay, Hassakorn Buaurai, Thiraphat Kongkan, Theerawut Khamsuetrong, Pawornpat Kongdaeng
