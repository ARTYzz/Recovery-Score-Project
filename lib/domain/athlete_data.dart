import 'dart:convert';

String localDay([DateTime? now]) {
  final day = now ?? DateTime.now();
  return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

DateTime? parsedDay(String? value) =>
    value == null ? null : DateTime.tryParse(value);

double? numberOrNull(Object? value) => value is num ? value.toDouble() : null;
int? intOrNull(Object? value) => value is num ? value.toInt() : null;

class AthleteProfile {
  AthleteProfile(
      {required this.name,
      required this.fightDate,
      this.officialWeighInWeight});
  String name;
  String fightDate;
  double? officialWeighInWeight;

  factory AthleteProfile.fromJson(Map<String, dynamic> json) => AthleteProfile(
        name: json['name'] as String? ?? '',
        fightDate: json['fightDate'] as String? ?? '',
        officialWeighInWeight:
            numberOrNull(json['officialWeighInWeight'] ?? json['fightWeight']),
      );
  Map<String, dynamic> toJson() => {
        'name': name,
        'fightDate': fightDate,
        'officialWeighInWeight': officialWeighInWeight,
      };
}

class WearableSample {
  WearableSample(
      {required this.date,
      required this.source,
      required this.mode,
      this.sleepMinutes,
      this.hrv,
      this.restingHr,
      this.heartRate,
      this.workoutMinutes});
  final String date;
  final String source;
  final String mode;
  final int? sleepMinutes;
  final double? hrv;
  final double? restingHr;
  final double? heartRate;
  final int? workoutMinutes;

  factory WearableSample.fromJson(Map<String, dynamic> json) => WearableSample(
        date: json['date'] as String? ?? '',
        source: json['source'] as String? ?? 'Unavailable',
        mode: json['mode'] as String? ?? 'UNKNOWN',
        sleepMinutes: intOrNull(json['sleepMinutes']),
        hrv: numberOrNull(json['hrv']),
        restingHr: numberOrNull(json['restingHr']),
        heartRate: numberOrNull(json['heartRate']),
        workoutMinutes: intOrNull(json['workoutMinutes']),
      );
  Map<String, dynamic> toJson() => {
        'date': date,
        'source': source,
        'mode': mode,
        'sleepMinutes': sleepMinutes,
        'hrv': hrv,
        'restingHr': restingHr,
        'heartRate': heartRate,
        'workoutMinutes': workoutMinutes,
      };
}

class FightCampSession {
  FightCampSession(
      {required this.date,
      required this.source,
      required this.mode,
      required this.sessionId,
      this.count,
      this.speed,
      this.output,
      this.rounds});
  final String date;
  final String source;
  final String mode;
  final String sessionId;
  final int? count;
  final double? speed;
  final int? output;
  final int? rounds;

  factory FightCampSession.fromJson(Map<String, dynamic> json) =>
      FightCampSession(
        date: json['date'] as String? ?? '',
        source: json['source'] as String? ?? 'FightCamp demo',
        mode: json['mode'] as String? ?? 'DEMO',
        sessionId: json['sessionId'] as String? ?? '',
        count: intOrNull(json['count']),
        speed: numberOrNull(json['speed']),
        output: intOrNull(json['output']),
        rounds: intOrNull(json['rounds']),
      );
  Map<String, dynamic> toJson() => {
        'date': date,
        'source': source,
        'mode': mode,
        'sessionId': sessionId,
        'count': count,
        'speed': speed,
        'output': output,
        'rounds': rounds,
      };
}

class MorningCheckIn {
  MorningCheckIn(
      {required this.date,
      this.weight,
      required this.urine,
      required this.mood,
      this.headSymptoms = false,
      this.soreness = const [],
      this.painSeverity = 'None'});
  final String date;
  final double? weight;
  final int urine;
  final String mood;
  final bool headSymptoms;
  final List<String> soreness;
  final String painSeverity;

  factory MorningCheckIn.fromJson(Map<String, dynamic> json) => MorningCheckIn(
        date: json['date'] as String? ?? '',
        weight: numberOrNull(json['weight']),
        urine: intOrNull(json['urine']) ?? 2,
        mood: json['mood'] as String? ?? 'OK',
        headSymptoms: json['headSymptoms'] is List
            ? (json['headSymptoms'] as List).isNotEmpty
            : json['headSymptoms'] == true,
        soreness:
            (json['soreness'] as List? ?? []).map((e) => e.toString()).toList(),
        painSeverity: json['painSeverity'] as String? ?? 'None',
      );
  Map<String, dynamic> toJson() => {
        'date': date,
        'weight': weight,
        'urine': urine,
        'mood': mood,
        'headSymptoms':
            headSymptoms ? ['New symptoms after head contact'] : <String>[],
        'soreness': soreness,
        'painSeverity': painSeverity,
      };
}

class TrainingSession {
  TrainingSession(
      {required this.date,
      required this.type,
      required this.duration,
      required this.intensity,
      this.rounds = 0,
      this.contact = 'Light',
      this.soreness = const []});
  final String date;
  final String type;
  final int duration;
  final String intensity;
  final int rounds;
  final String contact;
  final List<String> soreness;

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      TrainingSession(
        date: json['date'] as String? ?? '',
        type: json['type'] as String? ?? 'Boxing / Technical',
        duration: intOrNull(json['duration']) ?? 30,
        intensity: json['intensity'] as String? ?? 'Moderate',
        rounds: intOrNull(json['rounds']) ?? 0,
        contact: json['contact'] as String? ?? 'Light',
        soreness:
            (json['soreness'] as List? ?? []).map((e) => e.toString()).toList(),
      );
  Map<String, dynamic> toJson() => {
        'date': date,
        'type': type,
        'duration': duration,
        'intensity': intensity,
        'rounds': rounds,
        'contact': contact,
        'soreness': soreness,
      };
}

class NutritionCheck {
  NutritionCheck(
      {required this.date,
      required this.meal,
      required this.protein,
      required this.carbs});
  final String date;
  final String meal;
  final String protein;
  final String carbs;
  factory NutritionCheck.fromJson(Map<String, dynamic> json) => NutritionCheck(
        date: json['date'] as String? ?? '',
        meal: json['meal'] as String? ?? 'No',
        protein: json['protein'] as String? ?? 'No',
        carbs: json['carbs'] as String? ?? 'Medium',
      );
  Map<String, dynamic> toJson() =>
      {'date': date, 'meal': meal, 'protein': protein, 'carbs': carbs};
}

class FoodMeal {
  FoodMeal(
      {required this.id,
      required this.date,
      required this.time,
      required this.mealType,
      required this.description,
      required this.foodKey,
      required this.portions,
      required this.kcal,
      required this.protein,
      required this.carbs,
      required this.fat,
      this.photoBase64});
  final String id;
  final String date;
  final String time;
  final String mealType;
  final String description;
  final String foodKey;
  final double portions;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String? photoBase64;
  factory FoodMeal.fromJson(Map<String, dynamic> json) => FoodMeal(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        mealType: json['mealType'] as String? ?? 'Meal',
        description: json['description'] as String? ?? 'Food',
        foodKey: json['foodKey'] as String? ?? 'other',
        portions: numberOrNull(json['portions']) ?? 1,
        kcal: intOrNull(json['kcal']) ?? 0,
        protein: intOrNull(json['protein']) ?? 0,
        carbs: intOrNull(json['carbs']) ?? 0,
        fat: intOrNull(json['fat']) ?? 0,
        photoBase64: json['photoBase64'] as String? ?? json['photo'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'mealType': mealType,
        'description': description,
        'foodKey': foodKey,
        'portions': portions,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'photoBase64': photoBase64,
      };
}

class RecoveryActionLog {
  RecoveryActionLog(
      {required this.id,
      required this.date,
      required this.startedAt,
      required this.completedAt,
      this.nextDay});
  final String id;
  final String date;
  final String startedAt;
  final String completedAt;
  Map<String, dynamic>? nextDay;
  factory RecoveryActionLog.fromJson(Map<String, dynamic> json) =>
      RecoveryActionLog(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        startedAt: json['startedAt'] as String? ?? '',
        completedAt: json['completedAt'] as String? ?? '',
        nextDay: json['nextDay'] is Map
            ? Map<String, dynamic>.from(json['nextDay'] as Map)
            : null,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'nextDay': nextDay
      };
}

class AthleteData {
  AthleteData(
      {this.profile,
      this.privacyAcceptedAt,
      this.healthAcceptedAt,
      this.onboardingStage = 'profile',
      this.mockOnly = false,
      this.demoAnchorDay,
      this.demoDayOffset = 0,
      this.notifications = false});
  AthleteProfile? profile;
  String? privacyAcceptedAt;
  String? healthAcceptedAt;
  String onboardingStage;
  bool mockOnly;
  String? demoAnchorDay;
  int demoDayOffset;
  bool notifications;
  final Map<String, String> connections = {};
  final List<WearableSample> wearables = [];
  final List<MorningCheckIn> checkins = [];
  final List<TrainingSession> sessions = [];
  final List<NutritionCheck> nutrition = [];
  final List<FoodMeal> foodMeals = [];
  final List<FightCampSession> fightCampSessions = [];
  final List<RecoveryActionLog> actions = [];
  final List<Map<String, dynamic>> assessments = [];

  DateTime get currentDate => mockOnly
      ? (parsedDay(demoAnchorDay) ?? DateTime.now())
          .add(Duration(days: demoDayOffset))
      : DateTime.now();
  String get currentDay => localDay(currentDate);

  bool get morningDue =>
      onboardingStage == 'complete' &&
      !checkins.any((e) => e.date == currentDay);
  WearableSample? get latestWearable =>
      wearables.isEmpty ? null : wearables.last;
  MorningCheckIn? get latestCheckIn => checkins.isEmpty ? null : checkins.last;
  TrainingSession? get latestTraining =>
      sessions.isEmpty ? null : sessions.last;
  NutritionCheck? get latestNutrition =>
      nutrition.isEmpty ? null : nutrition.last;
  FightCampSession? get latestFightCamp =>
      fightCampSessions.isEmpty ? null : fightCampSessions.last;

  void saveMorning(MorningCheckIn checkIn) {
    checkins.removeWhere((e) => e.date == checkIn.date);
    checkins.add(checkIn);
    checkins.sort((a, b) => a.date.compareTo(b.date));
  }

  factory AthleteData.fromJson(Map<String, dynamic> json) {
    final data = AthleteData(
      profile: json['profile'] is Map
          ? AthleteProfile.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map))
          : null,
      privacyAcceptedAt: json['privacyAcceptedAt'] as String?,
      healthAcceptedAt: json['healthAcceptedAt'] as String?,
      onboardingStage: json['onboardingStage'] as String? ?? 'complete',
      mockOnly: json['mockOnly'] == true,
      demoAnchorDay: json['demoAnchorDay'] as String?,
      demoDayOffset: intOrNull(json['demoDayOffset']) ?? 0,
      notifications: json['notifications'] == true,
    );
    final links = json['connections'];
    if (links is Map) {
      links.forEach((key, value) {
        if (key is String && value is String) data.connections[key] = value;
      });
    }
    void load<T>(
        String key, List<T> target, T Function(Map<String, dynamic>) parse) {
      for (final item in json[key] as List? ?? []) {
        if (item is Map) target.add(parse(Map<String, dynamic>.from(item)));
      }
    }

    load('wearables', data.wearables, WearableSample.fromJson);
    load('checkins', data.checkins, MorningCheckIn.fromJson);
    load('sessions', data.sessions, TrainingSession.fromJson);
    load('nutrition', data.nutrition, NutritionCheck.fromJson);
    load('foodMeals', data.foodMeals, FoodMeal.fromJson);
    load(
        'fightCampSessions', data.fightCampSessions, FightCampSession.fromJson);
    load('actions', data.actions, RecoveryActionLog.fromJson);
    for (final item in json['assessments'] as List? ?? []) {
      if (item is Map) data.assessments.add(Map<String, dynamic>.from(item));
    }
    return data;
  }
  Map<String, dynamic> toJson() => {
        'profile': profile?.toJson(),
        'privacyAcceptedAt': privacyAcceptedAt,
        'healthAcceptedAt': healthAcceptedAt,
        'onboardingStage': onboardingStage,
        'mockOnly': mockOnly,
        'demoAnchorDay': demoAnchorDay,
        'demoDayOffset': demoDayOffset,
        'notifications': notifications,
        'connections': connections,
        'wearables': wearables.map((e) => e.toJson()).toList(),
        'checkins': checkins.map((e) => e.toJson()).toList(),
        'sessions': sessions.map((e) => e.toJson()).toList(),
        'nutrition': nutrition.map((e) => e.toJson()).toList(),
        'foodMeals': foodMeals.map((e) => e.toJson()).toList(),
        'fightCampSessions': fightCampSessions.map((e) => e.toJson()).toList(),
        'actions': actions.map((e) => e.toJson()).toList(),
        'assessments': assessments,
      };

  String encode() => jsonEncode(toJson());
  static AthleteData decode(String value) =>
      AthleteData.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
