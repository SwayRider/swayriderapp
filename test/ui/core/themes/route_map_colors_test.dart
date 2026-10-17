import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/map/map_style_mode.dart';
import 'package:swayriderapp/ui/core/themes/route_map_colors.dart';

void main() {
  test('light map: petrol route on white, orange dot', () {
    final colors = RouteMapColors.of(MapVariant.light);
    expect(colors.line, '#0F4C5C');
    expect(colors.casing, '#FFFFFF');
    expect(colors.dot, '#FF7A00');
  });

  test('dark map: inverted, orange route on dark, petrol dot', () {
    final colors = RouteMapColors.of(MapVariant.dark);
    expect(colors.line, '#FF7A00');
    expect(colors.casing, '#101010');
    expect(colors.dot, '#0F4C5C');
  });
}
