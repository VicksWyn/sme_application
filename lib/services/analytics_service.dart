// ignore_for_file: deprecated_member_use

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  Future<void> logScreenView(String screenName) async {
    await _analytics.setCurrentScreen(screenName: screenName);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> logWorkoutStart(String workoutType) async {
    await _analytics.logEvent(
      name: 'workout_start',
      parameters: {'workout_type': workoutType},
    );
  }

  Future<void> logWorkoutEnd(String workoutType, int duration) async {
    await _analytics.logEvent(
      name: 'workout_end',
      parameters: {
        'workout_type': workoutType,
        'duration': duration,
      },
    );
  }

  Future<void> logAchievement(String achievementId) async {
    await _analytics.logEvent(
      name: 'unlock_achievement',
      parameters: {'achievement_id': achievementId},
    );
  }
}