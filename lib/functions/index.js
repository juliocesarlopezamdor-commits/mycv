// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger: when a new user is created
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // Create a user profile document in Firestore
  await admin.firestore().collection('users').doc(user.uid).set({
    email: user.email,
    displayName: user.displayName || '',
    photoURL: user.photoURL || '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    plan: 'free',
    taskCount: 0,
  });

  // Send welcome email (using your email service)
  // await sendWelcomeEmail(user.email, user.displayName);
  console.log(`User profile created for ${user.uid}`);
});

// Trigger: when a task is created, increment the counter
exports.onTaskCreated = functions.firestore
  .document('users/{userId}/tasks/{taskId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    await admin.firestore().collection('users').doc(userId).update({
      taskCount: admin.firestore.FieldValue.increment(1),
    });
  });

// Trigger: when a task is deleted, decrement the counter
exports.onTaskDeleted = functions.firestore
  .document('users/{userId}/tasks/{taskId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    await admin.firestore().collection('users').doc(userId).update({
      taskCount: admin.firestore.FieldValue.increment(-1),
    });
  });

// Callable function: generate a weekly report
exports.generateReport = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be signed in to generate a report.'
    );
  }
  const userId = context.auth.uid;
  const tasksRef = admin.firestore()
    .collection('users').doc(userId)
    .collection('tasks');

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const completedTasks = await tasksRef
    .where('isCompleted', '==', true)
    .where('completedAt', '>=', sevenDaysAgo)
    .get();

  const totalTasks = await tasksRef.get();

  return {
    totalTasks: totalTasks.size,
    completedThisWeek: completedTasks.size,
    completionRate: totalTasks.size > 0
      ? ((completedTasks.size / totalTasks.size) * 100).toFixed(1)
      : '0',
    generatedAt: new Date().toISOString(),
  };
});

// Scheduled function: clean up old completed tasks every Sunday
exports.weeklyCleanup = functions.pubsub
  .schedule('0 2 * * 0') // 2 AM every Sunday
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const usersSnapshot = await admin.firestore().collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const oldTasks = await userDoc.ref
        .collection('tasks')
        .where('isCompleted', '==', true)
        .where('completedAt', '<=', thirtyDaysAgo)
        .get();

      const batch = admin.firestore().batch();
      oldTasks.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      console.log(`Cleaned ${oldTasks.size} old tasks for user ${userDoc.id}`);
    }
  });