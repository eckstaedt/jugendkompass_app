import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';

/// Reusable shimmer skeleton widgets for loading states across the app.

// ─── Base Shimmer Wrapper ────────────────────────────────────────────────────

class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: child,
    );
  }
}

// ─── Skeleton Box ────────────────────────────────────────────────────────────

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Home Screen Skeleton ────────────────────────────────────────────────────

class HomeCardSkeleton extends StatelessWidget {
  const HomeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SkeletonBox(
              width: 160,
              height: 200,
              radius: DesignTokens.radiusMiddleContainers,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSectionSkeleton extends StatelessWidget {
  const HomeSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 140, height: 20, radius: 4),
            const SizedBox(height: 12),
            SkeletonBox(
              width: double.infinity,
              height: 180,
              radius: DesignTokens.radiusMiddleContainers,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Podcast List Skeleton ───────────────────────────────────────────────────

class PodcastListSkeleton extends StatelessWidget {
  const PodcastListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // Featured card skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMedium),
              child: SkeletonBox(
                width: double.infinity,
                height: 220,
                radius: DesignTokens.radiusLargeCards,
              ),
            ),
          ),
          // Category chips skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkeletonBox(width: 70, height: 32, radius: 16),
                  ),
                ),
              ),
            ),
          ),
          // Episode list skeleton
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  children: [
                    SkeletonBox(width: 56, height: 56, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: double.infinity, height: 14, radius: 4),
                          const SizedBox(height: 8),
                          SkeletonBox(width: 120, height: 12, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              childCount: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Video List Skeleton ─────────────────────────────────────────────────────

class VideoListSkeleton extends StatelessWidget {
  const VideoListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                width: double.infinity,
                height: 180,
                radius: DesignTokens.radiusMiddleContainers,
              ),
              const SizedBox(height: 10),
              SkeletonBox(width: 200, height: 16, radius: 4),
              const SizedBox(height: 6),
              SkeletonBox(width: 120, height: 12, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Content / Kiosk Skeleton ────────────────────────────────────────────────

class ContentListSkeleton extends StatelessWidget {
  const ContentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SkeletonBox(width: 80, height: 80, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 14, radius: 4),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 160, height: 12, radius: 4),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 80, height: 10, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Kiosk Grid Skeleton ─────────────────────────────────────────────────────

class KioskGridSkeleton extends StatelessWidget {
  const KioskGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: DesignTokens.radiusMiddleContainers,
              ),
            ),
            const SizedBox(height: 8),
            SkeletonBox(width: 100, height: 12, radius: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Impulse List Skeleton ───────────────────────────────────────────────────

class ImpulseListSkeleton extends StatelessWidget {
  const ImpulseListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SkeletonBox(
            width: double.infinity,
            height: 120,
            radius: DesignTokens.radiusMiddleContainers,
          ),
        ),
      ),
    );
  }
}
