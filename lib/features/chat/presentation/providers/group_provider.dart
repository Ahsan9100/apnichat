import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/models/message_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return const Stream.empty();
  
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getUserGroups(currentUserId);
});

final groupMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupMessages(groupId);
});

final groupControllerProvider = StateNotifierProvider<GroupController, AsyncValue<void>>((ref) {
  return GroupController(ref.watch(groupRepositoryProvider), ref);
});

class GroupController extends StateNotifier<AsyncValue<void>> {
  final GroupRepository _repository;
  final Ref _ref;

  GroupController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> createGroup(String name, File? image, List<String> memberIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final currentUserId = _ref.read(authStateProvider).value?.uid;
      if (currentUserId == null) throw Exception("User not authenticated");
      
      await _repository.createGroup(
        name: name,
        image: image,
        memberIds: memberIds,
        currentUserId: currentUserId,
      );
    });
  }

  Future<void> sendGroupMessage(String groupId, String text) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;
    
    await _repository.sendGroupMessage(
      groupId: groupId,
      currentUserId: currentUserId,
      text: text,
    );
  }

  Future<void> removeMember(String groupId, String memberId) async {
    await _repository.removeMember(groupId, memberId);
  }

  Future<void> makeAdmin(String groupId, String memberId) async {
    await _repository.makeAdmin(groupId, memberId);
  }
}
