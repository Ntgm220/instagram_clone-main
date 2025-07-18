import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates or updates a user document in Firestore
  static Future<bool> createOrUpdateUserDocument({
    required String uid,
    required String email,
    String? firstName,S
    String? lastName,
    String? phone,
    String? username,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      // Check if user document already exists
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // User document exists, update it if needed
        await _firestore.collection('users').doc(uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        // Create new user document
        final userData = {
          'uid': uid,
          'email': email,
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'phone': phone ?? '',
          'username': username ?? _generateUsername(email),
          'profileImageUrl': profileImageUrl ?? '',
          'bio': bio ?? '',
          'followerCount': 0,
          'followingCount': 0,
          'postCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(uid).set(userData);
        print('User document created successfully for UID: $uid');
        return true;
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
      return false;
    }
  }

  /// Gets user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Ensures current user has a document in Firestore
  static Future<bool> ensureCurrentUserDocument() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No current user found');
      return false;
    }

    try {
      // Check if user document exists
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print(
          'User document does not exist, creating one for UID: ${currentUser.uid}',
        );
        // Create user document with available information
        return await createOrUpdateUserDocument(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          firstName: currentUser.displayName?.split(' ').first ?? '',
          lastName: currentUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        );
      } else {
        print('User document already exists for UID: ${currentUser.uid}');
        // Update the updatedAt timestamp
        await _firestore.collection('users').doc(currentUser.uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      print('Error ensuring user document: $e');
      return false;
    }
  }

  /// Generates a username from email
  static String _generateUsername(String email) {
    final emailPart = email.split('@')[0];
    return emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  /// Updates user profile data
  static Future<bool> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(uid).update(updateData);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Gets the display name for a user
  static String getDisplayName(Map<String, dynamic>? userData) {
    if (userData == null) return 'Unknown User';

    final firstName = userData['firstName'] as String? ?? '';
    final lastName = userData['lastName'] as String? ?? '';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    return userData['username'] as String? ?? 'Unknown User';
  }

  /// Stream of current user data
  static Stream<Map<String, dynamic>?> getCurrentUserDataStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('No current user for data stream');
      return Stream.value(null);
    }

    print('Creating user data stream for UID: ${currentUser.uid}');
    return _firestore.collection('users').doc(currentUser.uid).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        print('User document found with data: ${doc.data()}');
        return doc.data();
      } else {
        print('User document does not exist for UID: ${currentUser.uid}');
        return null;
      }
    });
  }
}
