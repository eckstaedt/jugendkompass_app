import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/design_system_widgets.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String? userName;
  final String? avatarUrl;
  final VoidCallback onEditPressed;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RoundedCard(
      glass: true,
      backgroundColor: DesignTokens.glassBackgroundDeep(0.20),
      padding: const EdgeInsets.all(16),
      withShadow: false,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'Benutzer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEditPressed,
          ),
        ],
      ),
    );
  }
}
