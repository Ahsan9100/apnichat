import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    @Default('') String name,
    @Default('') String bio,
    @Default('') String profilePicUrl,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    String? fcmToken, // Firebase Cloud Messaging token for push notifications
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
