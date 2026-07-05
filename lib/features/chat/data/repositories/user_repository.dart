import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Stream<List<UserModel>> searchUsers(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return Stream.value([]);
    }

    final lowerQuery = trimmedQuery.toLowerCase();
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Safety check for older users without a name
          if (data['name'] == null) {
             data['name'] = data['email']?.split('@').first ?? 'Unknown';
          }
          final user = UserModel.fromJson(data);
          
          if (user.name.toLowerCase().contains(lowerQuery) || 
              user.email.toLowerCase().contains(lowerQuery)) {
            users.add(user);
          }
        } catch (e) {
          // Skip users that fail to parse rather than crashing the whole search
          print('Error parsing user ${doc.id}: $e');
        }
      }
      return users;
    });
  }
}
