// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageModelImpl _$$MessageModelImplFromJson(Map<String, dynamic> json) =>
    _$MessageModelImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      replyToMessageId: json['replyToMessageId'] as String?,
      messageType: json['messageType'] as String? ?? 'text',
      mediaUrl: json['mediaUrl'] as String?,
      fileName: json['fileName'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      reactions:
          (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MessageModelImplToJson(_$MessageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'text': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
      'isEdited': instance.isEdited,
      'isDeleted': instance.isDeleted,
      'replyToMessageId': instance.replyToMessageId,
      'messageType': instance.messageType,
      'mediaUrl': instance.mediaUrl,
      'fileName': instance.fileName,
      'duration': instance.duration,
      'reactions': instance.reactions,
    };
