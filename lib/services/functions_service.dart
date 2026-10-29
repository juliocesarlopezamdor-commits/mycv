// Calling the report generator from Flutter
import 'package:cloud_functions/cloud_functions.dart';

Future<Map<String, dynamic>> getWeeklyReport() async {
  final callable = FirebaseFunctions.instance.httpsCallable('generateReport');
  final result = await callable.call();
  return Map<String, dynamic>.from(result.data);
}