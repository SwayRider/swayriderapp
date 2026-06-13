import 'package:freezed_annotation/freezed_annotation.dart';

part 'me_response.freezed.dart';
part 'me_response.g.dart';

@freezed
sealed class MeResponse with _$MeResponse {
  factory MeResponse({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'email_verified') required bool emailVerified,
  }) = _MeResponse;

  factory MeResponse.fromJson(Map<String, dynamic> json) =>
      _$MeResponseFromJson(json);
}