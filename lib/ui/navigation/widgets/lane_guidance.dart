import 'package:flutter/material.dart';

import '../../../domain/models/route/route_lane.dart';
import '../../core/themes/colors.dart';

/// The icon for the direction a lane leads to.
IconData laneIcon(int direction) => switch (direction) {
  RouteLane.slightLeft => Icons.turn_slight_left,
  RouteLane.left => Icons.turn_left,
  RouteLane.sharpLeft => Icons.turn_sharp_left,
  RouteLane.slightRight => Icons.turn_slight_right,
  RouteLane.right => Icons.turn_right,
  RouteLane.sharpRight => Icons.turn_sharp_right,
  RouteLane.reverse => Icons.u_turn_left,
  RouteLane.mergeToLeft || RouteLane.mergeToRight => Icons.merge,
  _ => Icons.arrow_upward,
};

/// One arrow per lane, left to right; the lanes to use are highlighted and
/// the others dimmed.
class LaneGuidance extends StatelessWidget {
  const LaneGuidance({super.key, required this.lanes});

  final List<RouteLane> lanes;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Lane guidance',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.black1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lane in lanes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _LaneCell(lane: lane),
              ),
          ],
        ),
      ),
    );
  }
}

class _LaneCell extends StatelessWidget {
  const _LaneCell({required this.lane});

  final RouteLane lane;

  @override
  Widget build(BuildContext context) {
    final active = lane.isActive;
    final icon = Icon(
      laneIcon(lane.primaryDirection),
      size: 30,
      color: active ? Colors.white : Colors.white38,
    );
    return Container(
      key: ValueKey(active ? 'lane-active' : 'lane-inactive'),
      width: 38,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.apexOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppColors.apexOrange : Colors.white24,
        ),
      ),
      child: icon,
    );
  }
}
