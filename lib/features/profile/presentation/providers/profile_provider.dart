import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return null;
  
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUser(authState.value!.uid);
});

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider), ref);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> saveProfile({
    required String name,
    required String bio,
    File? profileImage,
    UserModel? existingProfile,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _ref.read(authStateProvider).value;
      if (user == null) throw Exception("User not authenticated");

      String profilePicUrl = existingProfile?.profilePicUrl ?? '';

      if (profileImage != null) {
        profilePicUrl = await _repository.uploadProfileImage(user.uid, profileImage);
      }

      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: name,
        bio: bio,
        profilePicUrl: profilePicUrl,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _repository.saveUser(userModel);
      
      // ✅ Save the FCM device token to Firestore so other users can send push notifications
      await NotificationService.instance.saveTokenToFirestore(user.uid);
      
      // Refresh the current user profile provider after saving
      _ref.invalidate(currentUserProfileProvider);
    });
  }
}
