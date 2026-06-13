import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_keys_response.freezed.dart';
part 'public_keys_response.g.dart';

@freezed
sealed class PublicKeysResponse with _$PublicKeysResponse {
  const factory PublicKeysResponse({
    @JsonKey(name: 'keys') required List<String> keys,
  }) = _PublicKeysResponse;

  factory PublicKeysResponse.fromJson(Map<String, dynamic> json) =>
      _$PublicKeysResponseFromJson(json);
}