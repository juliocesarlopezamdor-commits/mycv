// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Reference to user's tasks collection
  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _db.collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tasks');

  // CREATE - add a new task
  Future<String> addTask({
    required String title,
    required String description,
    List<String> tags = const [],
  }) async {
    final docRef = await _tasksRef.add({
      'title': title,
      'description': description,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'tags': tags,
    });
    return docRef.id;
  }

  // READ - stream all tasks (real-time updates)
  Stream<List<Task>> streamTasks({bool? completedFilter}) {
    Query<Map<String, dynamic>> query = _tasksRef.orderBy('createdAt', descending: true);
    if (completedFilter != null) {
      query = query.where('isCompleted', isEqualTo: completedFilter);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // READ - get a single task
  Future<Task?> getTask(String taskId) async {
    final doc = await _tasksRef.doc(taskId).get();
    if (doc.exists) {
      return Task.fromFirestore(doc);
    }
    return null;
  }

  // UPDATE - toggle task completion
  Future<void> toggleTask(String taskId, bool isCompleted) async {
    await _tasksRef.doc(taskId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  // UPDATE - edit task details
  Future<void> updateTask(String taskId, {
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (tags != null) updates['tags'] = tags;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _tasksRef.doc(taskId).update(updates);
  }

  // DELETE - remove a task
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  // BATCH - complete all tasks at once
  Future<void> completeAllTasks() async {
    final batch = _db.batch();
    final snapshot = await _tasksRef
        .where('isCompleted', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // QUERY - search tasks by tag
  Stream<List<Task>> streamTasksByTag(String tag) {
    return _tasksRef
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // PAGINATION - load tasks in pages of 20
  Future<List<Task>> getTasksPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _tasksRef
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }
}