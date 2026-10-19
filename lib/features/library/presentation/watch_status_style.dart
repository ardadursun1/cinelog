import 'package:flutter/material.dart';

import '../domain/watch_status.dart';

extension WatchStatusStyle on WatchStatus {
  IconData get icon => switch (this) {
        WatchStatus.planned => Icons.bookmark_outline,
        WatchStatus.watching => Icons.play_circle_outline,
        WatchStatus.watched => Icons.check_circle_outline,
      };

  Color color(ColorScheme scheme) => switch (this) {
        WatchStatus.planned => scheme.tertiary,
        WatchStatus.watching => scheme.primary,
        WatchStatus.watched => Colors.green.shade600,
      };
}
