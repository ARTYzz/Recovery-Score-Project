# Case Study: Boxer Recovery App

**Role:** Product Owner /  Developer / Designer / QA tester / Tech Lead

**Timeline:**  Sept 2026 – Nov 2026 

## 1. The Problem

Professional and amateur boxers undergo intense, grueling "fight camps" leading up to a bout. During this phase, balancing training load and recovery is critical to avoid overtraining, injuries, or peaking too early. However, athletes face several massive hurdles:
* **Fragmented Data:** Boxers track data across multiple disjointed sources (smartwatches for sleep, FightCamp for punches, paper logs for sparring).
* **Information Overload:** Wearables provide raw numbers (e.g., HRV, resting HR) but lack actionable, boxing-specific context. 
* **Safety Blind Spots:** Generic fitness apps do not account for neurological risks (head impacts from sparring) or the dangers of extreme weight cutting.
* **Time Constraints:** Boxers need fast insights. They do not have time to navigate complex sports-science dashboards every morning.

**The Goal:** Build a centralized, mobile-first recovery application that takes **less than 90 seconds a day** to use. It must answer three critical questions for the athlete: *What is limiting me today? What can I train (and what should I avoid)? What is one thing I should do tonight to recover?*

---

## 2. The Process

To address these challenges, we defined a strict product backlog and system specification tailored exclusively for fighters.

### A. Establishing Medical Constraints & Safety First (The "Safety Gate")
Before writing any core logic, we established strict non-functional constraints. The app is not a medical device. We built a **Safety Gate** that executes before any recovery recommendations. If an athlete reports severe post-impact head symptoms or extreme rapid weight changes, the app immediately overrides performance metrics, restricts sparring, and flags a safety warning.

### B. Defining the 6-Domain Recovery Model
Instead of a single, vague "Readiness Score," we designed a Recovery Engine that evaluates six independent domains:
1. Brain & Impact Load
2. Energy / Nutrition / Weight
3. Autonomic / Sleep Recovery (Sleep & Heart)
4. Neuromuscular Power (Power & Speed)
5. Physical / Structural Recovery (Body)
6. Mental / Fight Stress (Mind)

### C. Streamlining the User Journey (The 90-Second Loop)
We designed the daily flow to minimize friction:
* **Automated Syncing:** Integrated wearable data architectures (Apple Health / Health Connect) and simulated FightCamp metrics to pull in sleep, HR, and punch data automatically.
* **Morning Check-In:** A fast, 30-second tap-based flow (no typing) for morning weight, urine color, and mood.
* **Smart Training Logs:** Segmented training loads into four boxing-specific categories (Sparring, Boxing/Technical, Conditioning, Strength) so the app knows *exactly* what type of fatigue is accumulating.

### D. User Acceptance Testing (UAT)
We built a functional prototype (Flutter/Android/Web) and took it to a real-world testing environment at MFU Gym. We conducted moderated UAT sessions with amateur and professional boxers, timing their interactions and measuring their task success rates without assistance.

---

## 3. The Outcome

The prototype successfully proved that complex physiological and subjective data could be distilled into fast, actionable daily guidance for fighters. 

### Key Metrics & Successes:
* **Task Success Rate:** Achieved an **85% independent success rate** across all core workflows, exceeding our 80% target.
* **Speed to Insight:** The time it took athletes to assess their readiness and decide if sparring was safe dropped from 120 seconds (manual methods) to just **35 seconds**.
* **Frictionless Input:** The combined Morning Check-in and Post-Training Log was completed by users in an average of **75 seconds**, successfully beating our < 90-second constraint.
* **High Utility (TAM):** The Technology Acceptance Model survey yielded a solid **4.25 / 5.0**, proving that fighters found the tool highly useful for their fight camp planning.

### Lessons Learned & Next Steps:
While the core logic and utility were highly validated, the System Usability Scale (SUS) score came in at **56.9** (below the 68 industry average). User feedback highlighted specific areas for iteration before a production launch:
1. **Visual Polish:** Users found the interface slightly text-heavy. The next iteration will replace text labels with intuitive UI icons.
2. **Localization:** Thai translations require refinement to match natural, conversational gym terminology.
3. **AI Integration:** Boxers explicitly requested an **"AI Advice" (มีAiแนะนำ)** feature to translate the data into an even more conversational, coach-like summary. This has been added to our P1 backlog for the next release.
