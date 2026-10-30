import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Compact previous / next pager. Hidden when everything fits on one page.
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int total;
  final int pageSize;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.total,
    required this.pageSize,
    required this.onNext,
    required this.onPrev,
  });

  bool get hasNext => (currentPage * pageSize) < total;
  bool get hasPrev => currentPage > 1;
  int get totalPages => total <= 0 ? 1 : ((total + pageSize - 1) ~/ pageSize);

  @override
  Widget build(BuildContext context) {
    if (!hasNext && !hasPrev) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Previous page',
            onPressed: hasPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              'Page $currentPage of $totalPages  •  $total items',
              textAlign: TextAlign.center,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Next page',
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
