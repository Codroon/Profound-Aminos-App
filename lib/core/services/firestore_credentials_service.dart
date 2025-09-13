import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crediential_storage_service.dart';

class FirestoreCredentialsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CredentialStorageService _storageService = CredentialStorageService();

  /// Get current user's credentials document reference
  DocumentReference get _userCredentialsDoc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore.collection('user_credentials').doc(user.uid);
  }

  /// Upload current local credentials to Firestore
  Future<void> uploadCredentialsToFirestore() async {
    try {
      final credentials = await _storageService.getCredentials();
      
      // Filter out null values and convert to Map<String, String>
      final cleanCredentials = <String, String>{};
      credentials.forEach((key, value) {
        if (value != null && value.isNotEmpty) {
          cleanCredentials[key] = value;
        }
      });

      await _userCredentialsDoc.set({
        'credentials': cleanCredentials,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[FirestoreCredentials] Credentials uploaded successfully');
    } catch (e) {
      print('[FirestoreCredentials] Failed to upload credentials: $e');
      rethrow;
    }
  }

  /// Download credentials from Firestore and save locally
  Future<void> downloadCredentialsFromFirestore() async {
    try {
      final doc = await _userCredentialsDoc.get();
      
      if (!doc.exists) {
        throw Exception('No credentials found in Firestore');
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['credentials'] == null) {
        throw Exception('Invalid credentials data in Firestore');
      }

      final credentials = Map<String, String>.from(data['credentials']);
      await _storageService.saveCredentials(credentials);

      print('[FirestoreCredentials] Credentials downloaded and saved locally');
    } catch (e) {
      print('[FirestoreCredentials] Failed to download credentials: $e');
      rethrow;
    }
  }

  /// Sync credentials (upload local to Firestore)
  Future<void> syncCredentialsToCloud() async {
    await uploadCredentialsToFirestore();
  }

  /// Sync credentials (download from Firestore to local)
  Future<void> syncCredentialsFromCloud() async {
    await downloadCredentialsFromFirestore();
  }

  /// Check if credentials exist in Firestore
  Future<bool> hasCredentialsInFirestore() async {
    try {
      final doc = await _userCredentialsDoc.get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      print('[FirestoreCredentials] Error checking Firestore credentials: $e');
      return false;
    }
  }

  /// Get credentials info from Firestore (without downloading)
  Future<Map<String, dynamic>?> getCredentialsInfo() async {
    try {
      final doc = await _userCredentialsDoc.get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?;
      return {
        'hasCredentials': data?['credentials'] != null,
        'lastUpdated': data?['lastUpdated'],
        'credentialKeys': data?['credentials']?.keys?.toList() ?? [],
      };
    } catch (e) {
      print('[FirestoreCredentials] Error getting credentials info: $e');
      return null;
    }
  }
}