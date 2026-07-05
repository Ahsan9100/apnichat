import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Provider to hold the current search text
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to fetch real-time search results
final searchUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final currentUser = ref.watch(authStateProvider).value;

  return userRepository.searchUsers(query).map((users) {
    // Filter out the current logged-in user from search results
    if (currentUser != null) {
      return users.where((u) => u.id != currentUser.uid).toList();
    }
    return users;
  });
});
