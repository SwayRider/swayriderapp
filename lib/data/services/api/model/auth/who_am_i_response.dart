import 'package:freezed_annotation/freezed_annotation.dart';

part 'who_am_i_response.freezed.dart';
part 'who_am_i_response.g.dart';

@freezed
sealed class WhoAmIResponse with _$WhoAmIResponse {
  const factory WhoAmIResponse({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'is_verified') required bool isVerified,
    @JsonKey(name: 'is_admin') required bool isAdmin,
    @JsonKey(name: 'account_type') required String accountType,
  }) = _WhoAmIResponse;

  factory WhoAmIResponse.fromJson(Map<String, dynamic> json) =>
      _$WhoAmIResponseFromJson(json);
}