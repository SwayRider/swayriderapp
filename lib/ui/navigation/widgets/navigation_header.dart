import 'package:flutter/material.dart';

import '../../../domain/models/route/route_maneuver.dart';
import '../../../utils/distance_format.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import 'maneuver_icon.dart';

/// Top banner of the navigation screen: the next maneuver's icon, the
/// distance to it and what to do there, plus an end button.
class NavigationHeader extends StatelessWidget {
  const NavigationHeader({
    super.key,
    required this.maneuver,
    required this.distanceMeters,
    required this.arrived,
    required this.offRoute,
    required this.hasLocationError,
    required this.onEnd,
    this.drivesOnRight = true,
    this.eta,
    this.remainingMeters,
  });

  /// The upcoming maneuver, or `null` while waiting for the first GPS fix.
  final RouteManeuver? maneuver;
  final double? distanceMeters;
  final bool arrived;
  final bool offRoute;
  final bool hasLocationError;
  final VoidCallback onEnd;

  /// Side of the road driven on; roundabout icons circle accordingly.
  final bool drivesOnRight;

  /// Expected arrival time and the distance still to go, shown in the top
  /// row of the card (hidden when null or once arrived).
  final DateTime? eta;
  final double? remainingMeters;

  static const _iconSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    final Widget icon;
    final String title;
    String? subtitle;
    if (arrived) {
      icon = const Icon(
        Icons.flag,
        size: _iconSize,
        color: AppColors.apexOrange,
      );
      title = l10n.navigationArrived;
    } else if (maneuver == null) {
      icon = const Icon(
        Icons.gps_not_fixed,
        size: _iconSize,
        color: AppColors.apexOrange,
      );
      title = l10n.navigationWaitingForGps;
    } else {
      icon = ManeuverIcon(
        type: maneuver!.type,
        exitNumber: maneuver!.roundaboutExitCount,
        drivesOnRight: drivesOnRight,
        size: _iconSize,
      );
      title = formatDistance(distanceMeters ?? 0, languageCode: languageCode);
      subtitle = maneuver!.instruction;
    }

    final status = hasLocationError
        ? l10n.navigationLocationError
        : (offRoute ? l10n.navigationOffRoute : null);

    final etaTime = eta;
    final remaining = remainingMeters;
    final showTrip = !arrived && etaTime != null && remaining != null;
    final tripStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: AppColors.black1,
      elevation: 6,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    if (showTrip)
                      Expanded(
                        child: Text(
                          '${l10n.navigationEta} ${_formatTime(context, etaTime)}'
                          '   \u00b7   '
                          '${formatDistance(remaining, languageCode: languageCode)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tripStyle,
                        ),
                      )
                    else
                      const Spacer(),
                    if (arrived)
                      TextButton(
                        onPressed: onEnd,
                        child: Text(l10n.navigationDone),
                      )
                    else
                      IconButton(
                        tooltip: l10n.endNavigation,
                        onPressed: onEnd,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          if (status != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                status,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The clock time in the phone's 12 / 24-hour setting.
  static String _formatTime(BuildContext context, DateTime time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(time),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
}
