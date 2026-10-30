import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import 'app_theme.dart';

/// Full-area loading indicator.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Empty list / no data placeholder.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(icon,
                size: 72, color: iconColor ?? context.colors.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error placeholder. A 403 is shown as "access denied" and never signs the
/// user out; network problems offer a retry.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final api = e is ApiException ? e : null;

    IconData icon = Icons.error_outline;
    String title = 'Something went wrong';
    String message = api?.message ?? 'An unexpected error occurred.';
    Color color = context.status.danger;

    if (api != null) {
      switch (api.kind) {
        case ApiErrorKind.forbidden:
          icon = Icons.lock_outline;
          title = 'Access denied';
          color = context.status.warning;
          break;
        case ApiErrorKind.notFound:
          icon = Icons.search_off;
          title = 'Not available';
          message = '${api.message}\nIt may have been removed, or you may not '
              'have access to it.';
          color = context.status.neutral;
          break;
        case ApiErrorKind.network:
        case ApiErrorKind.timeout:
          icon = Icons.cloud_off_outlined;
          title = 'Connection problem';
          color = context.status.warning;
          break;
        case ApiErrorKind.unauthorized:
          icon = Icons.logout;
          title = 'Signed out';
          color = context.status.neutral;
          break;
        case ApiErrorKind.configuration:
          icon = Icons.settings_outlined;
          title = 'App not configured';
          break;
        default:
          break;
      }
    }

    final canRetry = onRetry != null &&
        api?.kind != ApiErrorKind.forbidden &&
        api?.kind != ApiErrorKind.unauthorized &&
        api?.kind != ApiErrorKind.configuration;

    return EmptyView(
      icon: icon,
      iconColor: color,
      title: title,
      message: message,
      action: canRetry
          ? FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            )
          : null,
    );
  }
}

/// Inline banner. [color] defaults to the info colour.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  final String message;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.status.info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Brand.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurface)),
          ),
        ],
      ),
    );
  }
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: StatusColors.light.success,
    ));
}

void showError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : 'Something went wrong. Please try again.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: StatusColors.light.danger,
    ));
}
