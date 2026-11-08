import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Pull to refresh for a screen that has no list to scroll (nothing found, an error): the content fills the screen
/// and can still be pulled down.
class PullToRefreshFill extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefreshFill({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.brandGreen,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(constraints: BoxConstraints(minHeight: box.maxHeight), child: child),
        ),
      ),
    );
  }
}
