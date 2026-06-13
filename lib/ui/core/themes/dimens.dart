import 'package:flutter/material.dart';

abstract final class Dimens {
  const Dimens();

  /// General horizontal padding used to separate UI items
  static const paddingHorizontal = 20.0;

  /// General vertical padding used to separate UI items
  static const paddingVertical = 24.0;

  /// Horizontal padding for screen edges
  double get paddingScreenHorizontal;

  /// Vertical padding for screen edges
  double get paddingScreenVertical;

  double get profilePictureSize;

  /// Horizontal symetric padding for screen edges
  EdgeInsets get edgeInsetsScreenHorizontal => EdgeInsets.symmetric(
    horizontal: paddingScreenHorizontal,
  );

  /// Symetic padding for screen edges
  EdgeInsets get edgeInsetsScreenSymetric => EdgeInsets.symmetric(
    horizontal: paddingScreenHorizontal,
    vertical: paddingScreenVertical,
  );

  static const Dimens tablet = _DimensTablet();
  static const Dimens mobile = _DimensMobile();

  /// Get the dimensions based on screen size
  factory Dimens.of(BuildContext context) =>
    switch (MediaQuery.sizeOf(context).width) {
      > 600 => tablet,
      _ => mobile,
    };
}

/// Mobile dimensions
final class _DimensMobile extends Dimens {
  const _DimensMobile(); 

  @override
  double get paddingScreenHorizontal => Dimens.paddingHorizontal;
  @override
  double get paddingScreenVertical => Dimens.paddingVertical;
  @override
  double get profilePictureSize => 64.0;
}

/// Tablet dimensions
final class _DimensTablet extends Dimens {
  const _DimensTablet();

  @override
  double get paddingScreenHorizontal => 100.0;
  @override
  double get paddingScreenVertical => 64.0;
  @override
  double get profilePictureSize => 128.0;
}