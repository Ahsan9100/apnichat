import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_model.freezed.dart';
part 'group_model.g.dart';

@freezed
class GroupModel with _$GroupModel {
  const factory GroupModel({
    required String id,
    required String name,
    required String groupPicUrl,
    required String ownerId,
    required List<String> adminIds,
    required List<String> memberIds,
    required DateTime createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) => _$GroupModelFromJson(json);
}
