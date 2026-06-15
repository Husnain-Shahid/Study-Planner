// Quick Firebase Connection Test
// Add this to main.dart temporarily to test Firebase connection

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirebaseConnection() async {
  print('🔍 === FIREBASE CONNECTION TEST ===');

  try {
    // Test 1: Firebase App Initialized
    print('✅ Test 1: Firebase App Check');
    final apps = Firebase.apps;
    print('   Firebase apps initialized: ${apps.length}');

    // Test 2: Current User
    print('✅ Test 2: Current User Check');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('   Current user: ${user.email}');
      print('   User UID: ${user.uid}');
    } else {
      print('   ⚠️ No user logged in');
      return;
    }

    // Test 3: Firestore Connection
    print('✅ Test 3: Firestore Connection Check');
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);

    // Test 4: Read user document
    print('✅ Test 4: Read from Firestore');
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      print('   User document exists ✓');
      print('   User email: ${userDoc['email']}');
    } else {
      print('   ⚠️ User document not found');
    }

    // Test 5: Check subjects collection
    print('✅ Test 5: Subjects Collection Check');
    final subjectsSnapshot = await userRef.collection('subjects').get();
    print('   Subjects count: ${subjectsSnapshot.size}');
    for (final doc in subjectsSnapshot.docs) {
      print('   - ${doc['name']} (${doc['icon']})');
    }

    // Test 6: Write test doc
    print('✅ Test 6: Write Test');
    await userRef.collection('_test').doc('connection-test').set({
      'timestamp': Timestamp.now(),
      'message': 'Firebase connection test successful',
    });
    print('   Successfully wrote test document ✓');

    // Clean up
    await userRef.collection('_test').doc('connection-test').delete();

    print('✅ === ALL TESTS PASSED ===\n');

  } catch (e) {
    print('❌ ERROR: ${e.toString()}');
    print('📍 Stack trace: $e');
  }
}

// Call this in main() during testing:
// await testFirebaseConnection();

