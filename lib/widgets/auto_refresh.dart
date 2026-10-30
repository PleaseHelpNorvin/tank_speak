import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/app_config.dart';

/// Refreshes a screen every [AppConfig.telemetryRefreshSeconds] while it is
/// mounted and the app is in the foreground. Call [startAutoRefresh] from
/// `initState`; everything is cleaned up in `dispose`.
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoRefreshTimer;
  AppLifecycleListener? _lifecycleListener;

  /// Called on every tick. Implementations should skip if already loading.
  Future<void> onAutoRefresh();

  void startAutoRefresh() {
    _lifecycleListener ??= AppLifecycleListener(
      onResume: () {
        _schedule();
        if (mounted) onAutoRefresh();
      },
      onHide: () => _autoRefreshTimer?.cancel(),
    );
    _schedule();
  }

  void _schedule() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: AppConfig.telemetryRefreshSeconds),
      (_) {
        if (mounted) onAutoRefresh();
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
