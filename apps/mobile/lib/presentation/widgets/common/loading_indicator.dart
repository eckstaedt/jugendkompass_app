import 'package:jugendkompass_app/presentation/widgets/common/skeleton_loading.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({
    super.key,
    this.message,
  });

  // Skeleton (shimmering outlines) instead of the Material spinner.
  @override
  Widget build(BuildContext context) => const ContentListSkeleton();
}
