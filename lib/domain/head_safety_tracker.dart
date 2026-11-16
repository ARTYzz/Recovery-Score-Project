import 'athlete_data.dart';

/// Finds reported head-impact concerns across the entire saved history.
/// A later symptom-free check-in or elapsed time never resolves a concern.
class HeadSafetyTracker {
  HeadSafetyTracker(this.data);

  final AthleteData data;

  String? get latestIncidentDate {
    final days = <String>[
      for (final check in data.checkins)
        if (check.headSymptoms &&
            parsedDay(check.date) != null &&
            check.date.compareTo(data.currentDay) <= 0)
          check.date,
      for (final session in data.sessions)
        if (_headPainAfterContact(session) &&
            parsedDay(session.date) != null &&
            session.date.compareTo(data.currentDay) <= 0)
          session.date,
    ];
    if (days.isEmpty) return null;
    days.sort();
    return days.last;
  }

  bool get planRecorded {
    final incident = latestIncidentDate;
    if (incident == null) return false;
    return data.headSafetyReviews.any((review) =>
        review.incidentDate == incident &&
        parsedDay(review.recordedAt) != null &&
        localDay(parsedDay(review.recordedAt)!).compareTo(incident) >= 0);
  }

  bool get hasExternalPlan =>
      planRecorded && data.currentDay.compareTo(latestIncidentDate!) > 0;

  bool get needsProfessionalFollowUp =>
      latestIncidentDate != null && !hasExternalPlan;

  bool get newSymptomsToday => data.checkins
      .any((check) => check.date == data.currentDay && check.headSymptoms);

  bool get headPainToday => data.sessions.any((session) =>
      session.date == data.currentDay && _headPainAfterContact(session));

  static bool _headPainAfterContact(TrainingSession session) =>
      session.type == 'Sparring' &&
      session.contact != 'None' &&
      session.soreness.contains('Head') &&
      session.painSeverity != 'Sore';
}
