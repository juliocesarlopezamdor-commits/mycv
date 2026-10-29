// services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track screen views
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Track custom events
  Future<void> logTaskCreated(String taskType) async {
    await _analytics.logEvent(
      name: 'task_created',
      parameters: {'task_type': taskType},
    );
  }

  Future<void> logTaskCompleted(int daysToComplete) async {
    await _analytics.logEvent(
      name: 'task_completed',
      parameters: {'days_to_complete': daysToComplete},
    );
  }

  // Track user properties for segmentation
  Future<void> setUserPlan(String plan) async {
    await _analytics.setUserProperty(name: 'plan', value: plan);
  }
}