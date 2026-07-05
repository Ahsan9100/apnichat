import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String senderId,
    required String receiverId,
    required String text,
    required DateTime createdAt,
    @Default(false) bool isRead,
    @Default(false) bool isEdited,
    @Default(false) bool isDeleted,
    String? replyToMessageId,
    
    // Media Sharing fields
    @Default('text') String messageType,
    String? mediaUrl,
    String? fileName,
    int? duration,

    // Reactions: Map of userId -> emoji string e.g. {'uid1': '❤️'}
    @Default({}) Map<String, String> reactions,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
}
